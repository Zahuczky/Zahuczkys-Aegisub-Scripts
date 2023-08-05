import argparse as ap
import math
from pathlib import Path
import signal

import autoclip

# Even when this file doesn't change, version numbering is kept consistent with the lua script.
__version__ = "1.0.1"

if __name__ == "__main__":
    signal.signal(signal.SIGINT, signal.SIG_DFL)

    # Parse arguments
    parser = ap.ArgumentParser()
    parser.add_argument("-i", "--input", dest="video", help="Input file", metavar="FILE", type=Path, required=True)
    parser.add_argument("-o", "--output", dest="output", help="Output file", metavar="FILE", type=Path, required=True)
    parser.add_argument("-c", "--clip", dest="clip", help="Clip", metavar="CLIP", type=str, required=True)
    parser.add_argument("-f", "--first", dest="first", help="First frame", metavar="FRAME", type=int, required=True)
    parser.add_argument("-l", "--last", dest="last", help="Last frame", metavar="FRAME", type=int, required=True)
    parser.add_argument("-a", "--active", dest="active", help="Current video frame in aegi", metavar="FRAME", type=int, required=True)
    args, unknown_argv = parser.parse_known_args()

    # target clip is the top left and bottom right coordinates of the clip in the format "x1 y1 x2 y2"
    # let's convert this into "width, height, x1, y1"
    args.clip = args.clip.split(" ")
    args.clip = [int(math.ceil(float(args.clip[2])) - math.floor(float(args.clip[0]))),
                 int(math.ceil(float(args.clip[3])) - math.floor(float(args.clip[1]))),
                 int(math.floor(float(args.clip[0]))),
                 int(math.floor(float(args.clip[1])))]

    autoclip.start(unknown_argv, args)
