# Flutter MIDI Engine

A MIDI synthesizer plugin for Flutter. Play notes with built-in General MIDI sounds, or load your own SF2 soundfont on iOS and macOS.

## Features

- **Built-in sounds**: `loadSoundfont('')` works with no soundfont file
- **SF2 soundfonts**: load your own `.sf2` on iOS and macOS
- **Multi-Channel MIDI**: Full 16-channel MIDI support for complex arrangements
- **Program Changes**: Switch between 128 different instruments per soundfont
- **Audio Effects**: Built-in reverb and chorus effects
- **Complete MIDI Control**:
  - Note on/off with velocity
  - Volume and pan control per channel
  - Pitch bend messages
  - Control change messages
  - All notes off / reset controllers
- **Automatic Audio Routing**: Audio follows the active output device — plug in or
  unplug a wired/Bluetooth headset mid-playback and sound switches over automatically
  (no manual re-initialization required)
- **Cross-Platform**: Android, iOS and macOS

## Platform Support

| Platform | Status | Technology |
|----------|--------|------------|
| Android  | ✅ Supported (built-in sounds only) | MidiDriver (Sonivox EAS) |
| iOS      | ✅ Supported | AudioToolbox AUSampler |
| macOS    | ✅ Supported | AudioToolbox AUSampler |
| Web      | ❌ Not implemented yet | - |
| Windows  | 🚧 Planned | - |
| Linux    | 🚧 Planned | - |

## Requirements

| Tool | Minimum version |
|------|-----------------|
| Flutter | 3.50.0 |
| Dart | 3.14 |
| Android | `minSdk` 24 (Android 7.0) |
| iOS | 13.0 |
| macOS | 10.15 |

> Tested with Flutter 3.50. The Android module uses built-in Kotlin, so apps
> build with `android.builtInKotlin` set to either `true` or `false`.
>
> Call `loadSoundfont('')` to use built-in sounds with no soundfont file:
> Sonivox General MIDI on Android, Apple's `gs_instruments.dls` on macOS, and a
> small bundled soundfont on iOS (9 basic instruments: piano, electric piano,
> organ, guitars, violin, trumpet, flute, synth lead). For better sound on iOS,
> load your own `.sf2` file.
>
> Android can't load soundfont files. It always plays the built-in Sonivox sounds,
> even if you pass a path.

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_midi_engine: ^0.2.1
```

## Getting Started

### 1. Add a Soundfont (optional)

Skip this to use the built-in sounds with `loadSoundfont('')`. To use your own
SF2 file on iOS and macOS, add it to your assets:

```yaml
flutter:
  assets:
    - assets/soundfonts/piano.sf2
```

### 2. Basic Usage

```dart
import 'package:flutter_midi_engine/flutter_midi_engine.dart';

final midiEngine = FlutterMidiEngine();

// Built-in sounds
await midiEngine.loadSoundfont('');

// Or your own soundfont from assets (iOS and macOS)
// await midiEngine.loadSoundfontFromAsset('assets/soundfonts/piano.sf2');

// Play middle C
await midiEngine.playNote(note: 60, velocity: 100);

// Wait a bit
await Future.delayed(Duration(seconds: 1));

// Stop the note
await midiEngine.stopNote(note: 60);
```

### 3. Advanced Features

#### Change Instruments

```dart
// Change to Church Organ (program 19)
await midiEngine.changeProgram(program: 19);

// Play on different channels with different instruments
await midiEngine.changeProgram(program: 0, channel: 0);  // Piano on channel 0
await midiEngine.changeProgram(program: 40, channel: 1); // Violin on channel 1

await midiEngine.playNote(note: 60, channel: 0);
await midiEngine.playNote(note: 67, channel: 1);
```

#### Add Audio Effects

Only `level` is used for now. The other parameters are accepted but ignored.

```dart
// Set reverb (hall effect)
await midiEngine.setReverb(
  roomSize: 0.8,
  damping: 0.3,
  width: 1.0,
  level: 0.5,
);

// Set chorus
await midiEngine.setChorus(
  voices: 5,
  level: 0.7,
  speed: 0.5,
  depth: 1.0,
);
```

#### Volume and Pan Control

```dart
// Set volume for channel 0
await midiEngine.setVolume(volume: 100, channel: 0);

// Pan channel 1 to the right
await midiEngine.setPan(pan: 127, channel: 1);
```

#### Pitch Bend

```dart
// Bend pitch up
await midiEngine.sendPitchBend(value: 4096, channel: 0);

// Reset to center
await midiEngine.sendPitchBend(value: 0, channel: 0);
```

#### Control Changes

```dart
// Enable sustain pedal
await midiEngine.sendControlChange(controller: 64, value: 127);

// Disable sustain pedal
await midiEngine.sendControlChange(controller: 64, value: 0);
```

## iOS Setup

For iOS, you need to ensure the app can play audio even when the device is muted:

```dart
// Call this before loading the soundfont
await midiEngine.unmute();
await midiEngine.loadSoundfontFromAsset('assets/soundfonts/piano.sf2');
```

## Audio Routing (Headset / Bluetooth)

The engine follows the active audio output device automatically. When a
wired or Bluetooth headset is connected or disconnected during playback, audio is
re-bound to the new route instead of cutting out — in both directions (speaker →
headset and headset → speaker). You don't need to re-initialize the engine yourself.

Under the hood:

- **Android** listens for output-device changes (`AudioDeviceCallback`) and restarts
  the MIDI driver so its audio track re-binds to the current device.
- **iOS** configures the `AVAudioSession` for playback (including Bluetooth A2DP and
  AirPlay), observes route-change and interruption notifications, and restarts the
  audio graph so the sampler follows the new device. It also recovers automatically
  after interruptions such as phone calls.
- **macOS** follows the default output device set in System Settings.

## Example App

Check out the [example](example/) directory for a complete piano app demonstrating all features.

## MIDI Note Reference

MIDI notes range from 0 to 127, where:
- Middle C (C4) = 60
- A4 (440 Hz) = 69

Formula: `MIDI Note = 12 * octave + semitone + 12`

## General MIDI Program Numbers

Some common instrument program numbers:

| Program | Instrument |
|---------|------------|
| 0 | Acoustic Grand Piano |
| 4 | Electric Piano 1 |
| 19 | Church Organ |
| 24 | Acoustic Guitar (nylon) |
| 40 | Violin |
| 56 | Trumpet |
| 73 | Flute |

See the [full General MIDI specification](https://en.wikipedia.org/wiki/General_MIDI#Program_change_events) for all 128 instruments.

## Soundfont Resources

Free soundfonts you can use:

- [FluidR3 GM](https://packages.debian.org/sid/fluid-soundfont-gm)
- [MuseScore Soundfonts](https://musescore.org/en/handbook/3/soundfonts-and-sfz-files)
- [Free Soundfonts](https://sites.google.com/site/soundfonts4u/)

## API Reference

### Core Methods

- `loadSoundfont(String path)` - Load soundfont from file path
- `loadSoundfontFromAsset(String assetPath)` - Load soundfont from assets
- `unloadSoundfont()` - Unload current soundfont
- `playNote({required int note, int velocity, int channel})` - Play MIDI note
- `stopNote({required int note, int velocity, int channel})` - Stop MIDI note

### Instrument Control

- `changeProgram({required int program, int channel})` - Change instrument

### Effects & Mix

- `setVolume({required int volume, int channel})` - Set channel volume (0-127)
- `setPan({required int pan, int channel})` - Set stereo pan (0=left, 64=center, 127=right)
- `setReverb({double roomSize, double damping, double width, double level})` - Configure reverb
- `setChorus({int voices, double level, double speed, double depth})` - Configure chorus

### MIDI Control

- `sendControlChange({required int controller, required int value, int channel})` - Send CC message
- `sendPitchBend({required int value, int channel})` - Send pitch bend (-8192 to 8191)
- `stopAllNotes()` - Stop all playing notes
- `resetAllControllers()` - Reset all MIDI controllers

### iOS-Specific

- `unmute()` - Allow audio playback even when device is muted (no-op on other platforms)

## Troubleshooting

### Android

**Issue**: No sound on Android
- Make sure `loadSoundfont('')` returned `true` before playing notes
- Verify device volume is turned up

**Issue**: My soundfont sounds the same as the default
- Android always uses the built-in Sonivox sounds. Custom soundfonts work on iOS and macOS only.

### iOS

**Issue**: No sound on iOS
- Call `unmute()` before loading soundfont
- Test on a real device (simulator has limited MIDI support)
- Use an SF2 file. SF3 (compressed) files may not load
- A custom soundfont needs a preset at bank 0, program 0

**Issue**: Soundfont not found
- Verify the file path is correct
- When using assets, make sure the file is listed in `pubspec.yaml`

### Audio routing

**Issue**: Sound stops when connecting/disconnecting a headset
- Handled automatically since v0.1.5. Upgrade if you're on an older version.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Credits

Built with:
- Android: [MidiDriver](https://github.com/billthefarmer/mididriver) (Sonivox EAS)
- iOS and macOS: AudioToolbox AUSampler
- Inspired by: [flutter_midi](https://github.com/rodydavis/flutter_midi)
