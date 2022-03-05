There are two scripts in this repo right now, zah.perspective.moon, which is just the original Perspective.moon by Alendt with a few tweaks, <br>and Aegisub-Perspective-Motion, on which this readme focuses.

## Extended docs and tutorial(recommended): https://zahuczky.com/aegisub-perspective-motion/

#### Pull requests, comments and issues are very welcome!

#### Basic usage of Aegisub-Perspective-Motion:<br>

- Right now it only works with Mocha.<br>
- First, you need to track your sign, and run Aegisub-Motion on it with After Effects Transform Data, as you usually would, but with scaling disabled. Make sure you have no fscx or fscy tags in your line.<br>
- Select all your tracked lines, and run Aegisub-Perspective-Motion, and paste After Effects POWER PIN data, that you axported from Mocha into it.<br>
- Bam, now you got perspective tracking.<br>
- Keep in mind, depending on the placement of your sign inside your track, you might have to do seperate tracks. One for specifying the exact position of your sign, and one for the plane from which the perspective gets calculated. 
