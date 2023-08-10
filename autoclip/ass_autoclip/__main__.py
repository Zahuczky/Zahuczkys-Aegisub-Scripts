import argparse as ap
import math
from pathlib import Path
import signal
import sys

from . import autoclip

signal.signal(signal.SIGINT, signal.SIG_DFL)

# Parse arguments
parser = ap.ArgumentParser()
parser.add_argument("-i", "--input", dest="video", help="Input file", metavar="FILE", type=Path, required=True)
parser.add_argument("-o", "--output", dest="output", help="Output file", metavar="FILE", type=Path, required=True)
parser.add_argument("-c", "--clip", dest="clip", help="Clip", metavar="CLIP", type=str, required=True)
parser.add_argument("-f", "--first", dest="first", help="First frame", metavar="FRAME", type=int, required=True)
parser.add_argument("-l", "--last", dest="last", help="Last frame", metavar="FRAME", type=int, required=True)
parser.add_argument("-a", "--active", dest="active", help="Current frame", metavar="FRAME", type=int, required=True)
args, _ = parser.parse_known_args()

# target clip is the top left and bottom right coordinates of the clip in the format "x1 y1 x2 y2"
# let's convert this into "width, height, x1, y1"
args.clip = args.clip.split(" ")
args.clip = [int(math.floor(float(args.clip[0]) / 2) * 2),
             int(math.floor(float(args.clip[1]) / 2) * 2),
             int(math.ceil(float(args.clip[2]) / 2) * 2),
             int(math.ceil(float(args.clip[3]) / 2) * 2)]

autoclip.start(sys.argv, args)
