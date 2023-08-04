import signal
import sys

import argparse as ap
from pathlib import Path
import signal
import sys

from .autoclip import load

# Even when this file doesn't change, version numbering is kept consistent with the lua script.
__version__ = "1.0.1"

if __name__ == "__main__":
    signal.signal(signal.SIGINT, signal.SIG_DFL)

    # Parse arguments
    parser = ap.ArgumentParser()
    parser.add_argument("-i", "--input", dest="video", help="input file", metavar="FILE", type=Path)
    parser.add_argument("-o", "--output", dest="output", help="output file", metavar="FILE", type=Path)
    parser.add_argument("-c", "--clip", dest="clip", help="clip", metavar="CLIP", type=str)
    parser.add_argument("-f", "--first", dest="first", help="first frame", metavar="FRAME", type=int)
    parser.add_argument("-l", "--last", dest="last", help="last frame", metavar="FRAME", type=int)
    parser.add_argument("-a", "--active", dest="active", help="current video frame in aegi", metavar="FRAME", type=int)
    args = parser.parse_args()

    # target clip is the top left and bottom right coordinates of the clip in the format "x1 y1 x2 y2"
    # let's convert this into "width, height, x1, y1"
    args["clip"] = args["clip"].split(" ")
    args["clip"] = [args["clip"][2] - args["clip"][0], args["clip"][3] - args["clip"][1], args["clip"][0], args["clip"][1]]
    args["clip"] = [round(float(x)) for x in args["clip"]]

    app = load(args)
    app.exec()
