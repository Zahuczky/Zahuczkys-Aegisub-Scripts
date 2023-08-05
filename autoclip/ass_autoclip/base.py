import logging
from PySide6.QtCore import QThread

threads = QThread.idealThreadCount()

logging.basicConfig(format="%(relativeCreated)d %(message)s", level=logging.DEBUG)
logger = logging.getLogger()
