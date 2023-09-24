# Even when this file doesn't change, version numbering is kept consistent with the lua script.
__version__ = "2.0.5"

# Thanks to arch1t3cht for giving the idea of using this to bypass importing main
def start(argv, args):
    from . import autoclip
    autoclip.start(argv, args)
