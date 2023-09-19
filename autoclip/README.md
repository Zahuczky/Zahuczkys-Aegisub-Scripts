## AutoClip

*Automagically* clip out objects obstructing your sign.  

### Install

*Lua*   
* Install AutoClip from DependencyControl.  
* If you prefer to manually install AutoClip, AutoClip's direct dependencies are [`ILL.ILL`](https://github.com/TypesettingTools/ILL-Aegisub-Scripts), [`aka.config`](https://github.com/Akatmks/Akatsumekusa-Aegisub-Scripts), [`aka.outcome`](https://github.com/Akatmks/Akatsumekusa-Aegisub-Scripts), [`aka.unsemantic`](https://github.com/Akatmks/Akatsumekusa-Aegisub-Scripts), and [`petzku.util`](https://github.com/petzku/Aegisub-Scripts).  

*Python*  
* Install [Python](https://www.python.org/downloads/) and [VapourSynth](https://github.com/vapoursynth/vapoursynth/releases).  

There will be a setup wizard when you run AutoClip from Aegisub for the first time. Follow the setup wizard to install necessary pip and vsrepo packages.  

### Usage

1. Time your sign to the whole cut.  
2. Seek the video to a reference frame where, ideally, the sign is unobscured from the foreground object.  
3. Create a rect clip that covers your sign at the reference frame. This clip defines the area where AutoClip should be active. Anything outside this clip will not be clipped.  
4. Select all the lines that make up the sign. This can include already fbfed or layered lines. AutoClip recognises lines not based on their order, but their start and end time.  
5. With the video seek head at the reference frame and all lines selected, run „Automation > AutoClip > AutoClip“ and a new AutoClip window shall open.  
6. In the new window, adjust the sliders until you get a satisfactory clip. AutoClip tests the absolute difference of a pixel at current frame against reference frame, and clips away the pixel if it has difference above the specified thresholds.  
7. Click „Apply“ to apply the clip to subtitle.  

### License

* *AutoClip is released by Zahuczky and Akatsumekusa under [BSD 3-Clause License](LICENSE).*  
* *AutoClip uses Noto Sans Display Medium in the UI. Noto Sans Display is released by Google under [SIL OFL 1.1 License](ass_autoclip/assets/LICENSE.OFL.txt).*  

### Known bugs

- AutoClip UI shows nested clips but nested clips don't work.

### TODO

- Handle moving signs/tracking data for those  
- More sliders (probably bunch of other VS filters to fine-tune the clip area)  
- ~~Simplifying the clips to curves and such.~~  
- ~~Currently only the longest contour gets taken into account. Maybe combine them? Maybe a slider for this?~~  
- Add clips to existing clips on the line.  
