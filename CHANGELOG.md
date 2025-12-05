## 0.1.2

* Fixed Android MidiDriver API compatibility issues
* Updated to use MidiDriver.getInstance() instead of constructor
* Added comprehensive example app with interactive piano keyboard
* Example includes instrument selection, volume control, and visual feedback
* Improved Android build stability

## 0.1.1

* Fixed Android build issue with mididriver dependency
* Added JitPack repository for Android native library
* Updated mididriver to version 1.25

## 0.1.0

* Initial release of Flutter MIDI Engine
* SF2 and SF3 soundfont support on Android and iOS
* Full 16-channel MIDI playback
* Program changes (128 instruments per soundfont)
* Note on/off with velocity control
* Volume and pan control per channel
* Audio effects (reverb and chorus)
* Pitch bend support
* Control change messages
* All notes off and reset controllers
* Asset loading support for soundfonts
* iOS unmute functionality
* Web platform stub implementation
* Comprehensive API documentation
* Example app with piano keyboard
