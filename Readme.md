# Zahuczky's Aegisub Scripts
This repository contains a collection of scripts for the subtitle editor Aegisub. The scripts are written in either Python, Lua or MoonScript and are intended to automate various tasks in the subtitling process, mainly for typesetting.

# Scripts 
"Main" scripts, they are available in Dependency Control.
## [Autoclip](/autoclip)
Automagically clip out objects obstructing your sign.

![Autoclip gif](/misc/autoclip.gif)


## [Aegisub Color Tracking](/macros/aegi-color-track)

Tracking the color of a pixel or moving object in a video.

![Color Tracking gif](/misc/colortrack.gif)


## Aegisub Perspective Motion

Deprecated in favor of arch1t3cht's [Perspective Motion](https://github.com/TypesettingTools/arch1t3cht-Aegisub-Scripts?tab=readme-ov-file#perspectivemotion).

## Miscellaneous scripts

You can find them [here](/miscellaneous_scripts).
These are not available in Dependency Control, most of the are one-offs or experiments.

#### [Transform clip from move](/miscellaneous_scripts/zah.clipmove.lua)
If you have a \move tag and rectangular \clip tag in the same line, running this will make the same movement on the clip.

#### [DialBlur](/miscellaneous_scripts/zah.dialblur.lua)
Adds or subtracts 0.1 from the blur value of the selected line
Intended use is with a keyboard dial that you set to execute this script in aegisub. 

#### [HTML syntax KFX](/miscellaneous_scripts/zah.html_syntax.lua)
**Deprecated in favor of [JavaScript version](https://github.com/Zahuczky/zahuczkys-kfx-guide/blob/main/tools/assSyntax.js).**
Prints syntax highlighted HTML code to the debug console
Intended to be used with the KFX template line, but works with any line

#### [Motion Blur](/miscellaneous_scripts/zah.motionblur.lua)
Calculates motion blur for tracked lines.
It expects a base amount of blur to be already set in all lines.
Intensity is used for the amount of blur ADDED to what's already in the line.
Blur will equal the base amount plus the distance traveled by the line from the previous frame divided by 100, times the intensity. 
(generally try something in the 5-10 range)

#### [!Zahuczky's ShadShake](/miscellaneous_scripts/zah.shadshake.lua)
Adds a shaking motion to xshad and yshad tags

#### [!Zahuczky's ShapeShaker](/miscellaneous_scripts/zah.shapeshaker.lua)
Randomizes points of a shape
Buncha hardcoded stuff, sharing for the lulz  <-this line was suggested by github copilot, therefore it stays

#### [!Zahuczky's TenKen Boxer](/miscellaneous_scripts/zah.tenkenbox.lua)
Generates a box around the given clip in the style how they look in the TenKen anime.
No other usefulness other than typesetting TenKen.

#### [!Zahuczky's t2s](/miscellaneous_scripts/zah.textshape.lua)
Quickly turn a text into a shape
Bunch of hardcoded stuff, sharing for the lulz

#### [!Zahuczky's Timeshake](/miscellaneous_scripts/zah.timeshake.lua)
Adds some randomness to the start time of the line
Bunch of hardcoded stuff, sharing for the lulz

