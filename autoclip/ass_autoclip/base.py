import logging
from PySide6.QtCore import QThread

# threads = QThread.idealThreadCount()
threads = 2

logging.basicConfig(format="%(relativeCreated)d %(message)s", level=logging.DEBUG)
logger = logging.getLogger()
