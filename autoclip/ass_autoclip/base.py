import logging
from collections import namedtuple

threads = 2

logging.basicConfig(format="%(relativeCreated)d %(message)s", level=logging.INFO)
logger = logging.getLogger()

Settings = namedtuple("Settings", ["l_threshold", "c_threshold"])
