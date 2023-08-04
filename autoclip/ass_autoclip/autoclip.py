import os
from pathlib import Path
from PySide6.QtCore import QObject, QMutex, Property, Qt, QRunnable, Signal, QSize, Slot, QThread, QThreadPool
from PySide6.QtGui import QGuiApplication, QImage
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtQuick import QQuickImageProvider



# The image provider in autoclip is unsynced.
# When frontend triggers a new frame, the request is sent into priority
# ThreadPool. When a task in the ThreadPool is completed, it checks the linked
# list to see if the result is still needed. If so, it set the QImage to
# Frame, remove anything later than the frame in linked list and trigger a
# rerender
Frame = QImage(QSize(1, 1), QImage.Format_Alpha8)
Frame.fill(0)
# { "frame": 0, "prev": None }
FramesPending = None
FrameLock = QMutex()

class ImageProvider(QQuickImageProvider):
    def __init__(self):
        super(ImageProvider, self).__init__(QQuickImageProvider.ImageType.Image)

    def requestImage(self, id, requestedSize):
        Frame, Frame.size()



# { "Setting1": { [frame]: (order, QImage), [frame]: (order, QImage) } }
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
FrameCacheSize = 10
FrameCacheCleaningFrequency = 10
FrameCacheLock = QMutex()

# Loading requested frame is QThread.TimeCriticalPriority
# Preloading frames is Qt.NormalPriority
# Cache cleaning is Qt.HighPriority
CacheThreadPool = QThreadPool()
CacheThreadPool.setMaxThreadCount(8)
CacheThreadPoolLock = QMutex()


class RequestFrame(QRunnable):
    def __init__(self, frame, difference, show_difference, time_critical=False):
        super(RequestFrame, self).__init__()

        self.frame = frame
        self.difference = difference
        self.show_difference = show_difference
        self.key = KeyFromSetting(self.difference, self.show_difference)

        # This is the only case in the script that a single thread acquire a
        # second lock before releasing previous lock
        FrameCacheLock.lock()
        if self.key not in FrameCache:
            FrameCache[self.key] = {}
        FrameCache[self.key][self.frame] = (FrameCacheHead, None)
        FrameCacheLock.unlock()

        self.time_critical = time_critical

    def run(self):
        if self.time_critical:
            if self.key in FrameCache and \
               self.frame in FrameCache[self.key] and \
               FrameCache[self.key][self.frame][1]:
                img = FrameCache[self.key][self.frame][1]
            else:
                img = TODO()

            self.update_Frame(img)
            self.update_FrameCache(img)

        else:
            if self.key in FrameCache and \
               self.frame in FrameCache[self.key] and \
               FrameCache[self.key][self.frame][1]:

                self.update_Frame(img)
            else:
                img = TODO()

                self.update_Frame(img)
                self.update_FrameCache(img)

    def update_Frame(self, img):
        FrameLock.lock()
        head = FramesPending
        while head:
            if head["frame"] == self.frame:
                Frame = img
                backend.imageReady.emit()
                head["prev"] = None
                break

            head = head["prev"]
        FrameLock.unlock()

    def uodate_FrameCache(self, img):
        head = None

        FrameCacheLock.lock()
        if self.key not in FrameCache:
            FrameCache[self.key] = {}
        if self.frame not in FrameCache[self.key] or \
           FrameCache[self.key][self.frame][1] is None:
            FrameCacheHead += 1
            head = FrameCacheHead
        FrameCache[self.key][self.frame] = (FrameCacheHead, img)
        FrameCacheLock.unlock()

        # Clean cache
        if head and head % FrameCacheCleaningFrequency == 0:
            CacheThreadPoolLock.lock()
            CacheThreadPool.start(CleanCache(self.key, head - FrameCacheCleaningFrequency),
                                  priority=QThread.Priority.HighPriority)
            CacheThreadPoolLock.unlock()

class CleanCache(QRunnable):
    def __init__(self, key, before):
        super(CleanCache, self).__init__()
        self.key = key
        self.before = before

    def run(self):
        FrameCacheLock.lock()
        for key in list(FrameCache.keys()):
            if key != self.key:
                del FrameCache[key]
        for frame in list(FrameCache[key].keys()):
            if FrameCache[key][frame][0] <= self.before:
                del FrameCache[key][frame]
        FrameCacheLock.unlock()



class Backend(QObject):
    def __init__(self, frames, active):
        QObject.__init__(self)

        self.activeChanged.connect(self.newFrame)
        self.differenceChanged.connect(self.newSettings)
        self.showDifferenceChanged.connect(self.newSettings)

        self.frames = frames
        self.previous_active = active
        self.active = active

    # Frames
    _frames = 0
    def frames_(self):
        return self._frames
    def setFrames(self, frames):
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
        self._active = active
        self.activeChanged.emit()
    activeChanged = Signal()
    active = Property(int, active_, setActive, notify=activeChanged)

    # Settings
    _difference = 0.04
    def difference_(self):
        return self._difference
    def setDifference(self, difference):
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

    @Slot
    def newFrame(self):
        locked = FrameLock.tryLock()
        CacheThreadPool.lock()
        CacheThreadPool.start(RequestFrame(self.active, self.difference, self.show_difference, time_critical=True),
                              priority=QThread.Priority.TimeCriticalPriority)
        if not locked:
            FrameLock.lock()
        FramesPending = { "frame": self.active, "prev": FramesPending }
        FrameLock.unlock()

        if self.previous_active and self.previous_active < self.active:
            for f in range(self.active + 1, min(self.frames, self.active + 7)):
                CacheThreadPool.start(RequestFrame(f, self.difference, self.show_difference),
                                      priority=QThread.NormalPriority)
        elif self.previous_active and self.previous_active > self.active:
            for f in range(self.active - 1, max(-1, self.active - 7), -1):
                CacheThreadPool.start(RequestFrame(f, self.difference, self.show_difference),
                                      priority=QThread.NormalPriority)
        else:
            for f in range(self.active + 1, min(self.frames, self.active + 4)):
                CacheThreadPool.start(RequestFrame(f, self.difference, self.show_difference),
                                      priority=QThread.NormalPriority)
            for f in range(self.active - 1, max(-1, self.active - 4), -1):
                CacheThreadPool.start(RequestFrame(f, self.difference, self.show_difference),
                                      priority=QThread.NormalPriority)

        self.previous_active = self.active
        CacheThreadPool.unlock()

    @Slot
    def newSettings(self):
        locked = FrameLock.tryLock()
        CacheThreadPool.lock()
        CacheThreadPool.start(RequestFrame(self.frame, self.difference, self.show_difference, time_critical=True),
                              priority=QThread.Priority.TimeCriticalPriority)
        if not locked:
            FrameLock.lock()
        FramesPending = { "frame": self.active, "prev": None }
        FrameLock.unlock()

        for f in range(self.active + 1, min(self.frames, self.active + 4)):
            CacheThreadPool.start(RequestFrame(f, self.difference, self.show_difference),
                                  priority=QThread.NormalPriority)
        for f in range(self.active - 1, max(-1, self.active - 4), -1):
            CacheThreadPool.start(RequestFrame(f, self.difference, self.show_difference),
                                  priority=QThread.NormalPriority)

        CacheThreadPool.unlock()

    imageReady = Signal()



def load(args):
    global backend
    
    os.environ["QT_QUICK_CONTROLS_STYLE"] = "Material"
    os.environ["QT_QUICK_CONTROLS_MATERIAL_THEME"] = "Dark"
    os.environ["QT_ENABLE_HIGHDPI_SCALING"] = "0"
    QGuiApplication.setAttribute(Qt.AA_EnableHighDpiScaling, 0)
    QGuiApplication.setAttribute(Qt.AA_UseOpenGLES)

    # Create app and engine
    # Passing argv to QCoreApplication because it enables Qt-specific options
    # like --platform, --plugin, interestingly also --qwindowicon,
    # --qwindowtitle, etc.
    app = QGuiApplication([])
    engine = QQmlApplicationEngine()

    # Add image provider and backend to root
    image_provider = ImageProvider()
    engine.addImageProvider("backend", ImageProvider())
    backend = Backend(args.last - args.first, args.active - args.first)
    engine.rootContext().setContextProperty("backend", backend)

    # Load QML
    qml_file = Path(__file__).with_name("autoclip.qml").as_posix()
    engine.load(qml_file)

    return app
