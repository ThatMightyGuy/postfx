TMG PostFX
============

*Stylized HDR postprocessing stack with some game-specific shaders*

## Features
* ACES tonemapper
* Digital autoexposure
* Barrel distortion
* Chroma subsampling
* Color filtering
* Light-biased digital noise
* Edge detection night vision *(like in Elite: Dangerous)*
* Exposure correction
* Mask blurring (smudges etc.)
* Texture overlays
* NVG phosphor burn-in
* Digital sensor blowout

## Usage
1. Install [ReShade](https://reshade.me/#download) for any game of your choosing
2. Copy the `reshade-shaders` folder from this repository to the game executable's folder
3. Start the game
4. Open the ReShade UI (`Home` by default)
5. Enable the `Color Expand` and `Color Collapse` shaders. Move `Color Expand` before `Color Collapse`
6. Now, put any of the supplied shaders in between. Go wild with the settings!
7. Make sure to save your preset at the end

## Quirks/Bugs
Most shaders allow values to go beyond sane limits, because it's fun.

Digital autoexposure does not work at a 0 ms sampling interval.

Edge detection night vision (`EdgeDetectNV.fx`) supports the default SDR pipeline, but uses HDR for continuity. Check out the file if you want it to use SDR instead.

Edge detection night vision is also *very* fiddly to get right. I should provide a ReShade preset at some point.

`MaskBlur` somehow has no blur to it?

There are several debugging shaders. They're not intended to look good, and instead give you some information about the pipeline's HDR content.\
These shaders are `Luminosity` and `FakeColor`. They should probably be swapped around or even removed as they are showing the same information in two different ways.

## Credits
This project contains a couple functions from other sources.

The list is as follows:
* `Utils.fxh/rand()`: [this](https://www.shadertoy.com/view/4djSRW) ShaderToy shader by Dave_Hoskins. The function in question is `hash32`.
* `Utils.fxh`: YCbCr conversion formulas and matrices from [Wikipedia](https://en.wikipedia.org/wiki/YCbCr#ITU-R_BT.709_conversion). Funnily enough, they're sitting as dead code.
* `Utils.fxh/getLuma(), sat()`: PD80 Base Effects (another ReShade shader pack)
