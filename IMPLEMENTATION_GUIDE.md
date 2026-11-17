# Implementation Guide

How the plugin works on each platform.

## Layout

```
lib/
  flutter_midi_engine.dart                  public API
  flutter_midi_engine_web.dart              web stub (does nothing yet)
  src/flutter_midi_engine_platform_interface.dart
  src/flutter_midi_engine_method_channel.dart
android/src/main/kotlin/.../FlutterMidiEnginePlugin.kt
ios/Classes/FlutterMidiEnginePlugin.swift
ios/Resources/flutter_midi_engine_basic.sf2  default iOS soundfont
macos/Classes/FlutterMidiEnginePlugin.swift
tool/generate_soundfont.py                  builds the iOS soundfont
```

All platforms use one method channel named `flutter_midi_engine`.

## Android

- Uses `io.github.nikita36078:mididriver:v1.30`, a build of
  [billthefarmer/mididriver](https://github.com/billthefarmer/mididriver)
  with 16 KB page alignment. It wraps the Sonivox EAS synth.
- Sonivox has fixed General MIDI sounds. It can't load soundfont files.
  `loadSoundfont('')` starts the driver. A non-empty path must exist, but its
  contents are not used.
- MIDI messages are written as raw bytes with `MidiDriver.write`.
- An `AudioDeviceCallback` restarts the driver when output devices change.
- Reverb and chorus only send CC 91 / CC 93 with `level`.

## iOS

- `AUGraph` with an AUSampler connected to RemoteIO.
- `AVAudioSession` is set to playback (Bluetooth A2DP and AirPlay allowed).
  Route changes and interruptions restart the graph.
- `loadSoundfont('')` loads `flutter_midi_engine_basic.sf2` from the
  `flutter_midi_engine_sounds` resource bundle. Any other path is loaded as an
  SF2 file.
- AUSampler holds one instrument at a time, so `changeProgram` loads that
  preset with `kAUSamplerProperty_LoadInstrument` (bank 0). Loading a
  soundfont starts with program 0, so a custom file needs a preset there.

## macOS

- Same AUSampler setup as iOS, connected to the DefaultOutput unit.
- A CoreAudio listener restarts the graph when the default output device changes.
- `loadSoundfont('')` loads Apple's built-in General MIDI bank:
  `/System/Library/Components/CoreAudio.component/Contents/Resources/gs_instruments.dls`.
- `unmute` does nothing.

## Web

Not implemented. Every method only prints a debug message.

## Built-in iOS soundfont

`tool/generate_soundfont.py` writes `ios/Resources/flutter_midi_engine_basic.sf2`.
All sounds are synthesized by the script, so the file has no third-party licence.
It has 9 presets in bank 0: programs 0, 4, 19, 24, 27, 40, 56, 73 and 80.

```
python tool/generate_soundfont.py
```

## Method channel

| Method | Arguments |
|--------|-----------|
| `loadSoundfont` | `path` |
| `unloadSoundfont` | - |
| `playNote` / `stopNote` | `note`, `velocity`, `channel` |
| `changeProgram` | `program`, `channel` |
| `setVolume` | `volume`, `channel` |
| `setPan` | `pan`, `channel` |
| `setReverb` | `roomSize`, `damping`, `width`, `level` |
| `setChorus` | `voices`, `level`, `speed`, `depth` |
| `sendControlChange` | `controller`, `value`, `channel` |
| `sendPitchBend` | `value` (-8192..8191), `channel` |
| `stopAllNotes` / `resetAllControllers` / `unmute` | - |

Notes, velocities, programs and CC values are 0-127. Channels are 0-15.

## Testing

```
flutter test
cd example
flutter run -d <device>
```

Check that keys make sound, that changing instrument changes the sound, and that
audio moves when headphones are plugged in or out.

## Debugging

- Android: `adb logcat | grep FlutterMidiEngine`
- iOS / macOS: Xcode console
