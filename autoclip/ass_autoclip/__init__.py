# Version number is always kept aligned with version number in Lua script.
__version__ = "2.1.1"

# Thanks to arch1t3cht for giving the idea of using this to bypass importing main
def start(argv, args):
    from . import autoclip
    autoclip.start(argv, args)
