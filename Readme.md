### The daily_stream branch contains regular updates and experimental features are already implemented. Might no be stable, or could not work as expected. 

There are two scripts in this repo right now, zah.perspective.moon, which is just the original Perspective.moon by Alendt with a few tweaks, <br>and Aegisub-Perspective-Motion, on which this readme focuses.

## Extended docs(TBD) and tutorial(recommended): https://zahuczky.com/aegisub-perspective-motion/

#### Pull requests, comments, feature requests and issues are very welcome!

#### Basic usage of Aegisub-Perspective-Motion:<br>

- Right now it only works with Mocha.<br>
- First, you need to track your sign, and run Aegisub-Motion on it with After Effects Transform Data, as you usually would, but with scaling disabled. Make sure you have no fscx or fscy tags in your line.<br>
- Select all your tracked lines, and run Aegisub-Perspective-Motion, and paste After Effects POWER PIN data, that you axported from Mocha into it.<br>
- Bam, now you got perspective tracking.<br>
- Keep in mind, depending on the placement of your sign inside your track, you might have to do seperate tracks. One for specifying the exact position of your sign, and one for the plane from which the perspective gets calculated. 

Credits: The part of this script that calculates the perspective itself, is from Alendts perspective.moon. 

### Caveats, bugs, problems:<br>
- The base scale is the first frame of the tracking.<br>
    That means, that your first frame is used for the reference \fscx100\fscy100. Planned to be fixed in v0.3.
- Every bug from perspective.moon is present here as well. If that didn't work for you in a case, this won't work as well.
- You can't set your base fscx/fscy beforehand for the first frame. Planned to be fixed in v0.3.
- Your perspective is calulated fully from the track, no information is taken from your lines to be used, like base perspective.

## Changelog:
- v0.1.0 <br> 
    Scipt created.
- v0.2.0 <br> 
    Initial GitHub release. <br> 
    Handling scaling over to my script, instead of letting Aegisub-Motion handling it. <br>
    Preparations for DependecyControl use. 
- v0.2.1 <br>
    Fixing DependencyControl stuff, adding optional usage. 

### TODO:<br>
- Making developer documentation.<br>
- ~~Fixing depctrl stuff inside my files.~~ (fixed[supposedly])<br>
- New scaling calculations(preferably that calculates the scaling for the position of the sign, not for the middle of our plane[howtomath]).<br>
- Fixing perspective.moon so it works on more extreme angles, and with different fscx and fscy scalings(like \fscx120\fscy180).<br>
- Full video tutorial.<br>
- Relative tracking to position in video. <br>
- Relative perspective transformation to tags already in the line.<br>
- ~~Less crying, more coding.~~
