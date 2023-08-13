from dataclasses import dataclass
import os
from pathlib import Path
from PySide6.QtCore import QMutex, QObject, Property, Qt, QReadWriteLock, QRunnable, Signal, QSize, Slot, QThreadPool
from PySide6.QtGui import QFont, QFontDatabase, QGuiApplication, QImage
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtQuick import QQuickImageProvider
import typing

from .base import logger, Settings, speedtesting, speedtesting_result, threads
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
# { Setting: [ [frame]: Frame, [frame]: Frame ] }
# Every Settings is a unique key. work in ThreadPool will dump their result in
# the table of the settings they use. After that regular thread cleaning will
# remove any caches that's not using the current setting.
# For order, every work will get a new incremental order. The regular thread
# cleaning will check FrameCacheHead, and remove any caches that's older
# than FrameCacheHead - FrameCacheSize.
FrameCache = {}
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
    def __init__(self, frame, frames, settings, time_critical=False):
        super().__init__()

        self.frame = frame
        self.frames = frames
        self.settings = settings
        self.time_critical = time_critical

    def run(self):
        if self.time_critical:
            img = None
            locked = False
            locked2 = False

            if (locked := FrameCacheLock.tryLockForRead()) and \
               self.settings in FrameCache and \
               (locked2 := FrameCache[self.settings][self.frame].lock.tryLock()) and \
               FrameCache[self.settings][self.frame].image:
                logger.debug(f"Loading frame {self.frame} from cache")
                img = FrameCache[self.settings][self.frame].image

                FrameCache[self.settings][self.frame].lock.unlock()
                FrameCacheLock.unlock()

            else:
                if locked2:
                    FrameCache[self.settings][self.frame].lock.unlock()
                if locked:
                    FrameCacheLock.unlock()

                logger.debug(f"Loading frame {self.frame}")
                img = video.get_frame(self.frame, self.settings)
            
            self.update_Frame(img)
            self.update_key()
            self.update_FrameCache(img)

        else:
            self.update_key()

            FrameCacheLock.lockForRead()
            FrameCache[self.settings][self.frame].lock.lock()

            if FrameCache[self.settings][self.frame].image:
                logger.debug(f"Frame {self.frame} in cache")
                img = FrameCache[self.settings][self.frame].image

                FrameCache[self.settings][self.frame].lock.unlock()

                self.update_Frame(img)
            else:
                FrameCache[self.settings][self.frame].lock.unlock()

                logger.debug(f"Preloading frame {self.frame}")
                img = video.get_frame(self.frame, self.settings)

                self.update_Frame(img)
                self.update_FrameCache(img)

            FrameCacheLock.unlock()

    # Write locking FrameCacheLock inside method
    def update_key(self):
        FrameCacheLock.lockForRead()
        if self.settings not in FrameCache:
            FrameCacheLock.unlock()
            FrameCacheLock.lockForWrite()
            if self.settings not in FrameCache:
                FrameCache[self.settings] = []
                for _ in range(self.frames):
                    FrameCache[self.settings].append(FrameItem(image=None, order=None, lock=QMutex()))
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

        FrameCache[self.settings][self.frame].lock.lock()

        if not FrameCache[self.settings][self.frame].image:
            FrameCache[self.settings][self.frame].image = img

            FrameCacheHeadLock.lock()
            FrameCacheHead += 1
            FrameCache[self.settings][self.frame].order = FrameCacheHead
            head = FrameCacheHead
            FrameCacheHeadLock.unlock()

        else:
            FrameCacheHeadLock.lock()
            FrameCache[self.settings][self.frame].order = FrameCacheHead
            FrameCacheHeadLock.unlock()

        FrameCache[self.settings][self.frame].lock.unlock()

        # Clean cache
        if head and head % FrameCacheCleaningFrequency == 0:
            CacheThreadPool.start(CleanCache(self.settings, head - FrameCacheMinimumSize), priority=4)

class CleanCache(QRunnable):
    def __init__(self, settings, before):
        super().__init__()
        self.settings = settings
        self.before = before

    def run(self):
        logger.debug(f"Cleaning cache")
        FrameCacheLock.lockForRead()
        for key in list(FrameCache.keys()):
            if key != self.settings:

                FrameCacheLock.unlock()
                FrameCacheLock.lockForWrite()
                for key in list(FrameCache.keys()):
                    if key != self.settings:
                        del FrameCache[key]
                FrameCacheLock.unlock()
                FrameCacheLock.lockForRead()
                break

        for item in FrameCache[self.settings]:
            item.lock.lock()
            if item.order and item.order <= self.before:
                item.image = None
                item.order = None
            item.lock.unlock()
        FrameCacheLock.unlock()



class Backend(QObject):
    def __init__(self, frames):
        QObject.__init__(self)

        self.frames = frames

        self.activeChanged.connect(self.newFrame)
        self.lumaThresholdChanged.connect(self.newSettings)
        self.chromaThresholdChanged.connect(self.newSettings)

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
    previous_active = 0
    _active = 0
    def active_(self):
        return self._active
    def setActive(self, active):
        if active != self._active:
            self._active = active
            self.activeChanged.emit()
    activeChanged = Signal()
    active = Property(int, active_, setActive, notify=activeChanged)

    # Settings
    _lumaThreshold = 0.10
    def lumaThreshold_(self):
        return self._lumaThreshold
    def setLumaThreshold(self, lumaThreshold):
        if lumaThreshold != self._lumaThreshold:
            self._lumaThreshold = lumaThreshold
            self.lumaThresholdChanged.emit()
    lumaThresholdChanged = Signal()
    lumaThreshold = Property(float, lumaThreshold_, setLumaThreshold, notify=lumaThresholdChanged)

    _chromaThreshold = 0.01
    def chromaThreshold_(self):
        return self._chromaThreshold
    def setChromaThreshold(self, chromaThreshold):
        if chromaThreshold != self._chromaThreshold:
            self._chromaThreshold = chromaThreshold
            self.chromaThresholdChanged.emit()
    chromaThresholdChanged = Signal()
    chromaThreshold = Property(float, chromaThreshold_, setChromaThreshold, notify=chromaThresholdChanged)

    @Slot()
    def newFrame(self):
        global FramesPending

        logger.debug("New frame requested")
        logger.debug(f"  active: {self.active}  previous_active: {self.previous_active}")
        settings = Settings(self.lumaThreshold, self.chromaThreshold)
        request_frame = RequestFrame(self.active, self.frames, settings, time_critical=True)
        locked = FramesPendingLock.tryLockForWrite()
        if not speedtesting:
            CacheThreadPool.clear()
        CacheThreadPool.start(request_frame, priority=6)
        if not locked:
            FramesPendingLock.lockForWrite()
        FramesPending = { "frame": self.active, "prev": FramesPending }
        FramesPendingLock.unlock()

        self.previous_active = self.active

    @Slot()
    def newSettings(self):
        global FramesPending

        logger.debug("New settings requested")
        settings = Settings(self.lumaThreshold, self.chromaThreshold)
        logger.debug(f"  active: {self.active}  settings: {settings}")
        request_frame = RequestFrame(self.active, self.frames, settings, time_critical=True)
        locked = FramesPendingLock.tryLockForWrite()
        CacheThreadPool.clear()
        CacheThreadPool.start(request_frame, priority=6)
        if not locked:
            FramesPendingLock.lockForWrite()
        FramesPending = { "frame": self.active, "prev": None }
        FramesPendingLock.unlock()

        self.previous_active = self.active

    imageReady = Signal()



def start(argv, args):
    global backend
    global video
    
    logger.debug("Loading application")
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
    backend = Backend(args.last - args.first)
    engine.rootContext().setContextProperty("backend", backend)
    engine.rootContext().setContextProperty("speedtesting", speedtesting)

    # Load QML
    qml_file = Path(__file__).with_name("autoclip.qml").as_posix()
    engine.load(qml_file)

    logger.debug("Starting event loop")
    app.exec()

    if not speedtesting:
        # Export to file
        settings = Settings(backend.lumaThreshold, backend.chromaThreshold)
        video.apply_clips(args.output, settings)
    else:
        speedtesting_result()
