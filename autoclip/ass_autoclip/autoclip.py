from dataclasses import dataclass
import os
from pathlib import Path
from PySide6.QtCore import QMutex, QObject, Property, Qt, QReadWriteLock, QRunnable, Signal, QSize, Slot, QThreadPool
from PySide6.QtGui import QFont, QFontDatabase, QGuiApplication, QImage
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtQuick import QQuickImageProvider
import typing

from .base import threads, logger
from .magic import Video



# The image provider in autoclip is unsynced.
# When frontend triggers a new frame, the request is sent into priority
# ThreadPool. When a task in the ThreadPool is completed, it checks the linked
# list to see if the result is still needed. If so, it set the QImage to
# Frame, remove anything later than the frame in linked list and trigger a
# rerender
Frame = QImage(QSize(1, 1), QImage.Format.Format_Alpha8)
Frame.fill(0)
# For doublelock Writing, always get FramesPendingLock first and then
# FrameLock
FrameLock = QMutex()
# { "frame": 0, "prev": None }
FramesPending = None
FramesPendingLock = QReadWriteLock()

class ImageProvider(QQuickImageProvider):
    def __init__(self):
        super().__init__(QQuickImageProvider.ImageType.Image)

    def requestImage(self, id, size, requestedSize):
        FrameLock.lock()
        frame = Frame
        FrameLock.unlock()

        return frame



@dataclass
class FrameItem:
    image: typing.Optional[QImage]
    order: typing.Optional[int]
    lock: QMutex
# { "Setting1": [ [frame]: Frame, [frame]: Frame ] }
# For setting, every setting is a unique key. work in ThreadPool will dump
# their result in the table of the settings they use. After that regular
# thread cleaning will remove any caches that's not using the current setting.
# For order, every work will get a new incremental order. The regular thread
# cleaning will check FrameCacheHead, and remove any caches that's older
# than FrameCacheHead - FrameCacheSize.
FrameCache = {}
def KeyFromSetting(difference, show_difference):
    return (difference, show_difference)
FrameCacheHead = 0
FrameCacheHeadLock = QMutex()
FrameCacheMinimumSize = 20
FrameCacheCleaningFrequency = 10
# 𝐹𝑖𝑛𝑒-𝑔𝑟𝑎𝑖𝑛𝑒𝑑 𝑙𝑜𝑐𝑘𝑖𝑛𝑔 in frames so write lock will only be used when cleaning
# or new setting
FrameCacheLock = QReadWriteLock()

# Loading requested frame is QThread.TimeCriticalPriority
# Preloading frames is Qt.NormalPriority
# Cache cleaning is Qt.HighPriority
CacheThreadPool = QThreadPool()
CacheThreadPool.setMaxThreadCount(threads)


class RequestFrame(QRunnable):
    def __init__(self, frame, frames, difference, show_difference, time_critical=False):
        super().__init__()

        self.frame = frame
        self.frames = frames
        self.difference = difference
        self.show_difference = show_difference
        self.key = KeyFromSetting(self.difference, self.show_difference)
        self.time_critical = time_critical

    def run(self):
        if self.time_critical:
            img = None
            locked = False
            locked2 = False

            if (locked := FrameCacheLock.tryLockForRead()) and \
               self.key in FrameCache and \
               (locked2 := FrameCache[self.key][self.frame].lock.tryLock()) and \
               FrameCache[self.key][self.frame].image:
                logger.debug(f"Loading frame {self.frame} from cache")
                img = FrameCache[self.key][self.frame].image

                FrameCache[self.key][self.frame].lock.unlock()
                FrameCacheLock.unlock()

            else:
                if locked2:
                    FrameCache[self.key][self.frame].lock.unlock()
                if locked:
                    FrameCacheLock.unlock()

                logger.debug(f"Loading frame {self.frame}")
                img = video.get_frame(self.frame, self.difference, self.show_difference)
            
            self.update_Frame(img)
            self.update_key()
            self.update_FrameCache(img)

        else:
            self.update_key()

            FrameCacheLock.lockForRead()
            FrameCache[self.key][self.frame].lock.lock()

            if FrameCache[self.key][self.frame].image:
                logger.debug(f"Frame {self.frame} in cache")
                img = FrameCache[self.key][self.frame].image

                FrameCache[self.key][self.frame].lock.unlock()

                self.update_Frame(img)
            else:
                FrameCache[self.key][self.frame].lock.unlock()

                logger.debug(f"Preloading frame {self.frame}")
                img = video.get_frame(self.frame, self.difference, self.show_difference)

                self.update_Frame(img)
                self.update_FrameCache(img)

            FrameCacheLock.unlock()

    # Write locking FrameCacheLock inside method
    def update_key(self):
        FrameCacheLock.lockForRead()
        if self.key not in FrameCache:
            FrameCacheLock.unlock()
            FrameCacheLock.lockForWrite()
            if self.key not in FrameCache:
                FrameCache[self.key] = []
                for _ in range(self.frames):
                    FrameCache[self.key].append(FrameItem(image=None, order=None, lock=QMutex()))
        FrameCacheLock.unlock()

    def update_Frame(self, img):
        global Frame

        FramesPendingLock.lockForRead()
        head = FramesPending
        while head:
            if head["frame"] == self.frame:
                logger.debug(f"Rendering frame {self.frame}")
                FrameLock.lock()
                Frame = img
                FrameLock.unlock()
                backend.imageReady.emit()
                head["prev"] = None
                break

            head = head["prev"]

        FramesPendingLock.unlock()

    # Only Locking Frame.lock inside method
    # Read lock FrameCacheLock before calling
    def update_FrameCache(self, img):
        global FrameCacheHead

        head = None

        FrameCache[self.key][self.frame].lock.lock()

        if not FrameCache[self.key][self.frame].image:
            FrameCache[self.key][self.frame].image = img

            FrameCacheHeadLock.lock()
            FrameCacheHead += 1
            FrameCache[self.key][self.frame].order = FrameCacheHead
            head = FrameCacheHead
            FrameCacheHeadLock.unlock()

        else:
            FrameCacheHeadLock.lock()
            FrameCache[self.key][self.frame].order = FrameCacheHead
            FrameCacheHeadLock.unlock()

        FrameCache[self.key][self.frame].lock.unlock()

        # Clean cache
        if head and head % FrameCacheCleaningFrequency == 0:
            CacheThreadPool.start(CleanCache(self.key, head - FrameCacheMinimumSize), priority=4)

class CleanCache(QRunnable):
    def __init__(self, key, before):
        super().__init__()
        self.key = key
        self.before = before

    def run(self):
        logger.debug(f"Cleaning cache")
        FrameCacheLock.lockForRead()
        for key in list(FrameCache.keys()):
            if key != self.key:

                FrameCacheLock.unlock()
                FrameCacheLock.lockForWrite()
                for key in list(FrameCache.keys()):
                    if key != self.key:
                        del FrameCache[key]
                FrameCacheLock.unlock()
                FrameCacheLock.lockForRead()
                break

        for item in FrameCache[self.key]:
            item.lock.lock()
            if item.order and item.order <= self.before:
                item.image = None
                item.order = None
            item.lock.unlock()
        FrameCacheLock.unlock()



class Backend(QObject):
    def __init__(self, frames, active):
        QObject.__init__(self)

        self.frames = frames
        self.previous_active = active
        self.active = active

        self.activeChanged.connect(self.newFrame)
        self.differenceChanged.connect(self.newSettings)
        self.showDifferenceChanged.connect(self.newSettings)

        self.newFrame()

    # Frames
    _frames = None
    def frames_(self):
        return self._frames
    def setFrames(self, frames):
        if frames != self._frames:
            self._frames = frames
            self.framesChanged.emit()
    framesChanged = Signal()
    frames = Property(int, frames_, setFrames, notify=framesChanged)

    # Frame
    previous_active = None
    _active = None
    def active_(self):
        return self._active
    def setActive(self, active):
        if active != self._active:
            self._active = active
            self.activeChanged.emit()
    activeChanged = Signal()
    active = Property(int, active_, setActive, notify=activeChanged)

    # Settings
    _difference = 0.04
    def difference_(self):
        return self._difference
    def setDifference(self, difference):
        if difference != self._difference:
            self._difference = difference
            self.differenceChanged.emit()
    differenceChanged = Signal()
    difference = Property(float, difference_, setDifference, notify=differenceChanged)

    _showDifference = False
    def showDifference_(self):
        return self._showDifference
    def setShowDifference(self, showDifference):
        self._showDifference = showDifference
        self.showDifferenceChanged.emit()
    showDifferenceChanged = Signal()
    showDifference = Property(bool, showDifference_, setShowDifference, notify=showDifferenceChanged)

    @Slot()
    def newFrame(self):
        global FramesPending

        logger.debug("New frame requested")
        logger.debug(f"  active: {self.active}  previous_active: {self.previous_active}")
        request_frame = RequestFrame(self.active, self.frames, self.difference, self.showDifference, time_critical=True)
        locked = FramesPendingLock.tryLockForWrite()
        CacheThreadPool.clear()
        CacheThreadPool.start(request_frame, priority=6)
        if not locked:
            FramesPendingLock.lockForWrite()
        FramesPending = { "frame": self.active, "prev": FramesPending }
        FramesPendingLock.unlock()

        # XXX Change to cache only on idle
        # if self.previous_active and self.previous_active < self.active:
        #     for f in range(self.active + 1, min(self.frames, self.active + 5)):
        #         CacheThreadPool.start(RequestFrame(f, self.frames, self.difference, self.showDifference), priority=3)
        # elif self.previous_active and self.previous_active > self.active:
        #     for f in range(self.active - 1, max(-1, self.active - 5), -1):
        #         CacheThreadPool.start(RequestFrame(f, self.frames, self.difference, self.showDifference), priority=3)
        # else:
        #     for f in range(self.active + 1, min(self.frames, self.active + 3)):
        #         CacheThreadPool.start(RequestFrame(f, self.frames, self.difference, self.showDifference), priority=3)
        #     for f in range(self.active - 1, max(-1, self.active - 3), -1):
        #         CacheThreadPool.start(RequestFrame(f, self.frames, self.difference, self.showDifference), priority=3)

        self.previous_active = self.active

    @Slot()
    def newSettings(self):
        global FramesPending

        logger.debug("New settings requested")
        logger.debug(f"  active: {self.active}  difference: {self.difference}  showDifference: {self.showDifference}")
        request_frame = RequestFrame(self.active, self.frames, self.difference, self.showDifference, time_critical=True)
        locked = FramesPendingLock.tryLockForWrite()
        CacheThreadPool.clear()
        CacheThreadPool.start(request_frame, priority=6)
        if not locked:
            FramesPendingLock.lockForWrite()
        FramesPending = { "frame": self.active, "prev": None }
        FramesPendingLock.unlock()

        # XXX Change to cache only on idle
        # for f in range(self.active + 1, min(self.frames, self.active + 2)):
        #     CacheThreadPool.start(RequestFrame(f, self.frames, self.difference, self.showDifference), priority=3)
        # for f in range(self.active - 1, max(-1, self.active - 2), -1):
        #     CacheThreadPool.start(RequestFrame(f, self.frames, self.difference, self.showDifference), priority=3)

        self.previous_active = self.active

    imageReady = Signal()



def start(argv, args):
    global backend
    global video
    
    logger.debug("Loading application")
    # os.environ["QT_QUICK_CONTROLS_STYLE"] = "Material"
    # os.environ["QT_QUICK_CONTROLS_MATERIAL_THEME"] = "Dark"
    os.environ["QT_ENABLE_HIGHDPI_SCALING"] = "0"
    QGuiApplication.setAttribute(Qt.AA_EnableHighDpiScaling, 0)
    QGuiApplication.setAttribute(Qt.AA_UseOpenGLES)

    # Create app and engine
    # Passing argv to QCoreApplication because it enables Qt-specific options
    # like --platform, --plugin, interestingly also --qwindowicon,
    # --qwindowtitle, etc.
    app = QGuiApplication(argv)
    engine = QQmlApplicationEngine()

    # Load video
    video = Video(args.video, args.clip, args.first, args.last, args.active)

    # Load font
    font = Path(__file__).with_name("assets").joinpath("NotoSansDisplay-Medium.ttf").as_posix()
    font_id = QFontDatabase.addApplicationFont(font)
    font = QFont(QFontDatabase.applicationFontFamilies(font_id)[0])
    font.setWeight(QFont.Weight.Medium)
    QGuiApplication.setFont(font)

    # Add image provider and backend to root
    image_provider = ImageProvider()
    engine.addImageProvider("backend", image_provider)
    backend = Backend(args.last - args.first, args.active - args.first)
    engine.rootContext().setContextProperty("backend", backend)

    # Load QML
    qml_file = Path(__file__).with_name("autoclip.qml").as_posix()
    engine.load(qml_file)

    logger.debug("Starting event loop")
    app.exec()

    # Export to file
    video.apply_clips(args.output, backend.difference)
