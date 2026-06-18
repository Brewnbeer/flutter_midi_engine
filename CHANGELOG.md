## 0.1.5

* **Fixed audio routing on headset/Bluetooth connect & disconnect.** Audio now
  follows the active output device instead of cutting out:
  * Android: registers an `AudioDeviceCallback` and restarts the MIDI driver when
    output devices are added/removed so its `AudioTrack` re-binds to the new route.
  * iOS: configures the `AVAudioSession` for playback (with Bluetooth A2DP and AirPlay)
    and observes route-change and interruption notifications, restarting the audio
    graph so the `RemoteIO` unit picks up the new device.
* Hardened iOS support: the audio session is now configured and activated at startup,
  and recovers automatically after interruptions (e.g. phone calls).
* Added support for Flutter 3.44 and Dart 3.12
* Migrated the Android build to built-in Kotlin support (Flutter 3.44 breaking change).
  The `kotlin-android` plugin is now only applied on AGP 8 and earlier, so the plugin
  builds against both AGP 8 and AGP 9 / built-in Kotlin
* Replaced the deprecated `kotlinOptions`/`buildscript` Kotlin classpath with the
  `kotlin { compilerOptions { ... } }` DSL and bumped the Kotlin JVM target to 17
* Bumped Android `compileSdk` to 36 and `minSdk` to 24
* Bumped the minimum iOS deployment target to 13.0
* Fixed placeholder metadata (homepage, author, version) in the iOS podspec

## 0.1.3

* Fixed iOS build issue with AudioUnitSetProperty CFURL parameter
* Resolved Swift compiler error: '&' may only be used to pass an argument to inout parameter

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
