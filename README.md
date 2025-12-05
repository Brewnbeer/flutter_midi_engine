# Flutter MIDI Engine

An advanced MIDI synthesizer plugin for Flutter with comprehensive support for SF2 and SF3 soundfont formats.

## Features

- **Multi-Format Support**: Load and play SF2 and SF3 soundfont files
- **Multi-Channel MIDI**: Full 16-channel MIDI support for complex arrangements
- **Program Changes**: Switch between 128 different instruments per soundfont
- **Audio Effects**: Built-in reverb and chorus effects
- **Complete MIDI Control**:
  - Note on/off with velocity
  - Volume and pan control per channel
  - Pitch bend messages
  - Control change messages
  - All notes off / reset controllers
- **Cross-Platform**: Works on Android, iOS, and Web (Web support is experimental)

## Platform Support

| Platform | Status | Technology |
|----------|--------|------------|
| Android  | ✅ Fully Supported | MidiDriver (FluidSynth-based) |
| iOS      | ✅ Fully Supported | AVFoundation AudioUnit Sampler |
| Web      | ⚠️ Experimental | Stub implementation (requires JS library) |
| macOS    | 🚧 Planned | Similar to iOS |
| Windows  | 🚧 Planned | - |
| Linux    | 🚧 Planned | - |

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_midi_engine: ^0.1.0
```

## Getting Started

### 1. Add a Soundfont to Your Project

Place your SF2 or SF3 soundfont file in your assets folder:

```yaml
flutter:
  assets:
    - assets/soundfonts/piano.sf2
```

### 2. Basic Usage

```dart
import 'package:flutter_midi_engine/flutter_midi_engine.dart';

final midiEngine = FlutterMidiEngine();

// Load a soundfont from assets
await midiEngine.loadSoundfontFromAsset('assets/soundfonts/piano.sf2');

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

- [FluidSynth Soundfonts](https://packages.debian.org/sid/fluid-soundfont-gm)
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

- `unmute()` - Allow audio playback even when device is muted

## Troubleshooting

### Android

**Issue**: No sound on Android
- Make sure you've called `loadSoundfont()` with a valid SF2/SF3 file
- Check that the soundfont file exists in your assets
- Verify device volume is turned up

### iOS

**Issue**: No sound on iOS
- Call `unmute()` before loading soundfont
- Test on a real device (simulator has limited MIDI support)
- Ensure SF2 file is properly formatted (SF3 support may vary)

**Issue**: Soundfont not found
- Verify the file path is correct
- When using assets, make sure the file is listed in `pubspec.yaml`

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Credits

Built with:
- Android: [MidiDriver](https://github.com/billthefarmer/mididriver) (FluidSynth)
- iOS: AVFoundation AudioUnit Sampler
- Inspired by: [flutter_midi](https://github.com/rodydavis/flutter_midi)
