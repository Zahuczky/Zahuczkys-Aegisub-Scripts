## AutoClip

*Automagically* clip out objects obstructing your sign.

### Install

*Lua*  
* Add `https://raw.githubusercontent.com/Zahuczky/Zahuczkys-Aegisub-Scripts/main/DependencyControl.json` to DependencyControl. You may manually edit DependencyControl's config using the [extraFeeds field](https://github.com/TypesettingTools/DependencyControl#1-global-configuration), or use garret's [DependencyControl Global Config](https://github.com/garret1317/aegisub-scripts#dependencycontrol-global-config) script.  
* Install AutoClip from DependencyControl.  
* If you prefer to manually install AutoClip, AutoClip's dependencies are `ILL.ILL`, `aka.config`, `aka.config2`, `aka.outcome`, `aka.unicode`, which is available at [TypesettingTools/ILL-Aegisub-Scripts](https://github.com/TypesettingTools/ILL-Aegisub-Scripts) and [Akatmks/Akatsumekusa-Aegisub-Scripts](https://github.com/Akatmks/Akatsumekusa-Aegisub-Scripts).  

*Python*  
* Install [Python](https://www.python.org/downloads/) and [VapourSynth](https://github.com/vapoursynth/vapoursynth/releases).  
* AutoClip requires additional VapourSynth plugins to be installed. Run `python3 vsrepo.py install lsmas fmtc dfttest` from VapourSynth's install path.  
* If you are using a portable version of Python and VapourSynth, in Aegisub, Select „Automation > AutoClip > Configure python path“ and paste in the path to your python executable.  

### Usage

1. Time your sign to the whole cut.  
You may already fbf or divide the lines into sections prior to clipping, in which case select all the lines that adds up to the cut. If you have layered the sign prior to clipping, you may only select one layer for AutoClip and copy the result to other layers afterwards.  
2. Create a rect clip that covers your sign. This clip defines the area where AutoClip will be active. Anything outside this clip will not be clipped.  
3. Seek the video to a frame where, ideally, the sign is unobscured from the foreground object.  
4. Select „Automation > AutoClip > AutoClip“ and a new AutoClip window shall open.  
5. In the new window, adjust the slider until you get a satisfactory clip and click „Apply“.  

### License

* *AutoClip is released by Zahuczkys and Akatsumekusa under [BSD 3-Clause License](LICENSE).*  
* *AutoClip uses Noto Sans Display Medium in the UI. Noto Sans Display is released by Google under [SIL OFL 1.1 License](ass_autoclip/assets/LICENSE.OFL.txt).*  

### TODO

- Handle moving signs/tracking data for those  
- Signs with multiple layers? I forgot about that but Im already writing this readme so *shrug*.  
- More sliders (probably bunch of other VS filters to fine-tune the clip area)  
- Simplifying the clips to curves and such.  
- Currently only the longest contour gets taken into account. Maybe combine them? Maybe a slider for this?  
