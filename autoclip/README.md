## AutoClip

*Automagically* clip out objects obstructing your sign.  

![Autoclip gif](/misc/autoclip.gif)

### Recommended installation procedure (not following these may lead to errors)

- **Prerequisites**
  - Install Python 3.11
    - At the time of writing, vapoursynth doesn't support 3.12. Earlier versions going back to 3.8 may work, but the latest version was only validated on 3.11.7
    - It is highly recommended to install Python for all users. (configurable in the installer on Windows)
  - Install Vapoursynth from here: https://github.com/vapoursynth/vapoursynth/releases
    - Installation through pip may lead to problems, so it's recommended to use the installers from the link above unless you know what you're doing.
    - Recommended to also install for all users. (configurable in the installer on Windows)

- **Installing the Aegisub script** 
  - Install AutoClip from DependencyControl. (recommended) 
  - If you prefer to manually install AutoClip, AutoClip's direct dependencies are [`ILL.ILL`](https://github.com/TypesettingTools/ILL-Aegisub-Scripts), [`aka.config`](https://github.com/Akatmks/Akatsumekusa-Aegisub-Scripts), [`aka.outcome`](https://github.com/Akatmks/Akatsumekusa-Aegisub-Scripts), [`aka.unsemantic`](https://github.com/Akatmks/Akatsumekusa-Aegisub-Scripts), and [`petzku.util`](https://github.com/petzku/Aegisub-Scripts).  

- **First-time Setup**
  - When you start Autoclip from Aegisub for the first time, a setup wizard is shown, follow the steps, and always check whether the settings match your system.
  - The wizard is **going to run commands on your system**, but will always show them and give you a chance beforehand to edit them if necessary


### Usage

1. Time your sign to the whole cut.  
2. Seek the video to a reference frame where, ideally, the sign is unobscured from the foreground object.  
3. Create a **rectangular clip** that covers your sign at the reference frame. This clip defines the area where AutoClip should be active. Anything outside this clip will not be clipped.  
4. Select all the lines that make up the sign. This can include already fbfed or layered lines. AutoClip recognises lines not based on their order, but their start and end time.  
5. With the video seek head at the reference frame and all lines selected, run „Automation > AutoClip > AutoClip“ and a new AutoClip window shall open.  
6. In the new window, adjust the sliders until you get a satisfactory clip. AutoClip tests the absolute difference of a pixel at the current frame against the reference frame, and clips away the pixel if it has a difference above the specified thresholds.  
7. Click „Apply“ to apply the clip to your subtitles.
8. Be aware, that not fbf lines are going to be converted to fbf. If you need to apply motion tracking or similar to your sign, make sure you do them before using autoclip.   

### License

* *AutoClip is released by Zahuczky and Akatsumekusa under [BSD 3-Clause License](LICENSE).*  
* *AutoClip uses Noto Sans Display Medium in the UI. Noto Sans Display is released by Google under [SIL OFL 1.1 License](ass_autoclip/assets/LICENSE.OFL.txt).*  

### Known bugs

- AutoClip UI shows nested clips but nested clips don't work.

### TODO

- Handle moving signs/tracking data for those  
- More sliders (probably a bunch of other VS filters to fine-tune the clip area)  
- ~~Simplifying the clips to curves and such.~~  
- ~~Currently only the longest contour gets taken into account. Maybe combine them? Maybe a slider for this?~~  
- Add clips to existing clips on the line.  
