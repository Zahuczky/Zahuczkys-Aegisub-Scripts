import argparse as ap
import importlib.util
import json
import math
from pathlib import Path
import signal
import sys

if importlib.util.find_spec("packaging") != None:
    from packaging.version import parse as version
elif importlib.util.find_spec("distutils") != None: # distutils deprecated in Python 3.12
    from distutils.version import LooseVersion as version

from . import __version__, start

signal.signal(signal.SIGINT, signal.SIG_DFL)

# Parse arguments
parser = ap.ArgumentParser()
parser.add_argument("-i", "--input", dest="video", help="Input file (Required)", metavar="FILE", type=Path)
parser.add_argument("-o", "--output", dest="output", help="Output file (Required)", metavar="FILE", type=Path)
parser.add_argument("-c", "--clip", dest="clip", help="Clip (Required)", metavar="CLIP", type=str)
parser.add_argument("-f", "--first", dest="first", help="First frame (Required)", metavar="FRAME", type=int)
parser.add_argument("-l", "--last", dest="last", help="Last fram (Required)e", metavar="FRAME", type=int)
parser.add_argument("-a", "--active", dest="active", help="Current frame (Required)", metavar="FRAME", type=int)
parser.add_argument("--supported-version", dest="supported_v", help="Last supported Version", metavar="VERSION", type=str)
parser.add_argument("--check-dependencies", dest="check_dependencies", help="Check AutoClip dependencies and return", action="store_true")
parser.add_argument("--check-python-dependencies", dest="check_python_dependencies", help="Check AutoClip Python dependencies and return", action="store_true")
parser.add_argument("--check-vs-dependencies", dest="check_vs_dependencies", help="Check AutoClip VapourSynth dependencies and return", action="store_true")
parser.add_argument("--version", action="version", version=f"ass-autoclip {__version__}")
args, _ = parser.parse_known_args()

if args.check_dependencies or args.check_python_dependencies or args.check_vs_dependencies:
    if args.check_dependencies or args.check_vs_dependencies:
        assert(importlib.util.find_spec("vapoursynth") != None)
        from vapoursynth import core
        assert(hasattr(core, "lsmas"))
        assert(hasattr(core, "dfttest"))

    if args.check_dependencies or args.check_python_dependencies:
        assert(importlib.util.find_spec("numpy") != None)
        assert(importlib.util.find_spec("PySide6") != None)
        assert(importlib.util.find_spec("skimage") != None)

    exit(0)

# Check version
if args.supported_v is not None and version(__version__) < version(args.supported_v):
    with args.output.open(mode="w") as f:
        json.dump({ "current_version": __version__ }, f)
    exit(0)

# target clip is the top left and bottom right coordinates of the clip in the format "x1 y1 x2 y2"
# let's convert this into "width, height, x1, y1"
args.clip = args.clip.split(" ")
args.clip = [int(math.floor(float(args.clip[0]) / 2) * 2),
             int(math.floor(float(args.clip[1]) / 2) * 2),
             int(math.ceil(float(args.clip[2]) / 2) * 2),
             int(math.ceil(float(args.clip[3]) / 2) * 2)]

if True:
    start(sys.argv, args)
