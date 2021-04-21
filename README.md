<p align=center><img alt="BubbleDrive8" src="./BubbleDrive8%20Logo.svg"></p>

# BubbleDrive8
* Role: 2Mbit bubble memory cartridge hardware emulator
* Purpose: Replacing a notoriously fragile original bubble memory cart</p>
* Original part number: FBM-#101
* Used on: Konami Bubble System
* Manufacturer: Fujitsu

## Changelog
### v0.5 - Jul. 17, 2020
Added several modules and the testbench code for ModelSim.
### v0.6
Added BubbleCalc, a bubble page-position correspondence table generator for Verilog HDL and SPILoader.v(not tested)
### v0.61
Now SPILoader works
### v0.7
We can emulate a bubble memory cartridge on a computer! It works!
### v0.71
Just got a great logo for BubbleDrive8! Thanks to the courtesy of [@Akamig]( https://github.com/Akamig )
### v0.73
Start delay implementation
### v0.78
Critical bug fixes
### v0.79
State machine improved
### v0.83
Design finalized
### v0.85 - Oct. 1, 2020
Minor updates
### v0.86 - Dec. 17, 2020
Added bubble memory signal capture file(sigrok)
### v0.87 - Dec. 27, 2020
Updated TimingGenerator.v and BubbleInterface.v for better emulation. Changed bubble memory signal capture file.
### v0.88 - Jan. 9, 2021
Changed several signals to active low, changed obscure signal names. State machine improved.
### v1.0 - Apr. 14, 2021
It works! v3 branch merged. Tested on a real PCB.
### v1.1 - Apr. 21, 2021
State machine improved. LEDDriver.v removed(for I2C OLED screen driver implementation)