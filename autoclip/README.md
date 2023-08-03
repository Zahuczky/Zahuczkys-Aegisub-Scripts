# Autoclip

*Automagically* clip out objects obstructing your sign.

## Usage:
- Create a sign.
- Add a rectangular clip to the first line of the sign, that clip is going to be the watched area.
- Anything entering that clip will be clipped out.
- Run AutoClip from the Automation menu.
- Fiddle with the sliders.
- Click "Apply clips"

## Installation:
- Install a recent version of [Python](https://www.python.org/downloads/ "Python"). (testing was done on 3.11.3, but should work on any recent 3.X)
- Install [Vapoursynth](https://www.vapoursynth.com/ "Vapoursynth"). (testing was done on R63)
- Download the contents of the /autoclip folder of this repo.
- Place` autoclip/include/zah/autoclip/autoclip.vpy` into your `aegisub/automation/include/zah/autoclip/` folder.
Place `autoclip/zah.autoclip.lua` into  your `aegisub/automation/autoload` folder.
- Place the `requirements.txt` *somewhere*.
- Open a terminal and `cd` to wherever you put the `requirements.txt`.
- Run `pip install -r requirements.txt`.
- Run `vsrepo.py install lsmas`.
- Install `ILL Library` and `PetzkuLib` from DependencyControl in Aegisub.

## TODO
- Handle moving signs/tracking data for those
- Signs with multiple layers? I forgot about that but Im already writing this readme so *shrug*. 
- More sliders (probably bunch of other VS filters to fine-tune the clip area)
- depctrl

