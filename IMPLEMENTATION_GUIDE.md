# Flutter MIDI Engine - Implementation Guide

This document provides technical details about the implementation of Flutter MIDI Engine.

## Architecture Overview

The plugin follows Flutter's federated plugin architecture with platform-specific implementations:

```
flutter_midi_engine/
├── lib/
│   ├── flutter_midi_engine.dart              # Main API
│   ├── flutter_midi_engine_web.dart           # Web platform implementation
│   └── src/
│       ├── flutter_midi_engine_platform_interface.dart  # Platform interface
│       └── flutter_midi_engine_method_channel.dart      # Method channel impl
├── android/                                    # Android implementation
│   └── src/main/kotlin/.../FlutterMidiEnginePlugin.kt
└── ios/                                       # iOS implementation
    └── Classes/FlutterMidiEnginePlugin.swift
```

## Platform Implementations

### Android (Kotlin + MidiDriver)

**Technology**: MidiDriver library (FluidSynth-based synthesizer)

**Key Features**:
- Native MIDI message handling
- SF2/SF3 soundfont support via FluidSynth
- 16-channel polyphonic synthesis
- Low latency audio output

**Implementation Details**:
- Uses `io.github.billthefarmer:mididriver` library
- Direct MIDI message construction (NOTE_ON, NOTE_OFF, PROGRAM_CHANGE, etc.)
- Soundfont loaded via file path
- Real-time MIDI event processing

**Location**: `android/src/main/kotlin/com/midiengine/flutter_midi_engine/FlutterMidiEnginePlugin.kt`

### iOS (Swift + AVFoundation)

**Technology**: AVFoundation AudioUnit Sampler

**Key Features**:
- Hardware-accelerated synthesis
- Native SF2 support
- Core Audio integration
- Low-latency audio processing

**Implementation Details**:
- Uses `AUGraph` for audio processing graph
- `kAudioUnitSubType_Sampler` for MIDI synthesis
- Soundfont loaded via `kMusicDeviceProperty_SoundBankURL`
- `MusicDeviceMIDIEvent` for real-time MIDI messages

**Location**: `ios/Classes/FlutterMidiEnginePlugin.swift`

### Web (Dart + JavaScript - Stub)

**Status**: Experimental/Stub Implementation

**Planned Technologies**:
- WebAudioFont
- sf2-synth-audio-context
- MIDI.js

**Current State**: Logs method calls, no actual synthesis

**Location**: `lib/flutter_midi_engine_web.dart`

## Method Channel Protocol

### Channel Name
```
flutter_midi_engine
```

### Methods

#### loadSoundfont
```dart
Arguments: {"path": String}
Returns: bool (success)
```

#### playNote
```dart
Arguments: {
  "note": int,      // 0-127
  "velocity": int,  // 0-127
  "channel": int    // 0-15
}
Returns: void
```

#### stopNote
```dart
Arguments: {
  "note": int,      // 0-127
  "velocity": int,  // 0-127
  "channel": int    // 0-15
}
Returns: void
```

#### changeProgram
```dart
Arguments: {
  "program": int,   // 0-127
  "channel": int    // 0-15
}
Returns: void
```

#### setReverb
```dart
Arguments: {
  "roomSize": double,  // 0.0-1.0
  "damping": double,   // 0.0-1.0
  "width": double,     // 0.0-1.0
  "level": double      // 0.0-1.0
}
Returns: void
```

## MIDI Message Format

### Note On
```
Status: 0x90 | channel
Data 1: note (0-127)
Data 2: velocity (0-127)
```

### Note Off
```
Status: 0x80 | channel
Data 1: note (0-127)
Data 2: velocity (0-127)
```

### Program Change
```
Status: 0xC0 | channel
Data 1: program (0-127)
```

### Control Change
```
Status: 0xB0 | channel
Data 1: controller number (0-127)
Data 2: value (0-127)
```

### Pitch Bend
```
Status: 0xE0 | channel
Data 1: LSB (0-127)
Data 2: MSB (0-127)
Value Range: -8192 to 8191 (converted to 0-16383)
```

## Audio Graph (iOS)

```
┌──────────────┐    ┌──────────────┐
│   Sampler    │───▶│    Output    │
│  AudioUnit   │    │   (RemoteIO) │
└──────────────┘    └──────────────┘
```

The iOS implementation uses a simple audio processing graph:
1. Sampler node receives MIDI events
2. Generates audio based on loaded soundfont
3. Output node sends audio to device speakers

## Soundfont Loading

### Android
1. Receives absolute file path
2. Validates file exists
3. Calls `MidiDriver.config(path)`
4. FluidSynth loads and parses soundfont

### iOS
1. Receives absolute file path
2. Creates `URL` from path
3. Sets `kMusicDeviceProperty_SoundBankURL` on sampler
4. AudioUnit loads soundfont into memory

## Performance Considerations

### Memory
- Soundfonts are loaded entirely into memory
- Large SF2/SF3 files (>50MB) may cause issues on low-memory devices
- Consider using compressed SF3 format

### Latency
- Android: ~10-20ms (device dependent)
- iOS: ~5-10ms (hardware accelerated)
- Web: TBD (depends on implementation)

### Polyphony
- Both platforms support 128+ simultaneous notes
- Limited by device hardware and soundfont complexity

## Testing

### Unit Tests
Location: `test/flutter_midi_engine_test.dart`

### Integration Tests
- Test with real devices (simulators have limited MIDI support)
- Use various soundfont formats (SF2, SF3)
- Test all MIDI channels
- Verify effects parameters

### Recommended Test Soundfonts
- FluidSynth GM soundfont (small, ~2MB)
- MuseScore General soundfont (medium, ~30MB)
- Large orchestral soundfonts (100MB+)

## Debugging

### Android
Enable verbose logging:
```bash
adb logcat | grep FlutterMidiEngine
```

### iOS
Check Xcode console for debug prints

### Common Issues

**Android: No sound**
- Check MidiDriver initialization
- Verify soundfont path is correct
- Ensure audio focus is granted

**iOS: Soundfont not loading**
- Verify SF2 format (SF3 support varies)
- Check file permissions
- Test on real device, not simulator

**Both: Crackling/distortion**
- Reduce polyphony
- Use smaller soundfont
- Check CPU usage

## Future Enhancements

### Planned Features
1. MIDI file playback (.mid, .midi)
2. Real-time recording
3. Soundfont preload/caching
4. Advanced effects (EQ, compression)
5. macOS platform support
6. Windows platform support
7. Linux platform support
8. Full web implementation

### Web Implementation TODO
- Integrate WebAudioFont or sf2-synth-audio-context
- Implement Web Audio API synthesis
- Add Web Worker for audio processing
- Create JavaScript interop layer

## Contributing

### Code Style
- Dart: Follow official Dart style guide
- Kotlin: Follow Android Kotlin style guide
- Swift: Follow Swift API Design Guidelines

### Adding New Features
1. Update platform interface
2. Implement in all platforms (Android, iOS, Web)
3. Add unit tests
4. Update documentation
5. Add example usage

### Platform-Specific Contributions
Each platform can be enhanced independently, but the API should remain consistent across platforms.

## Resources

### Documentation
- [MIDI 1.0 Specification](https://www.midi.org/specifications)
- [General MIDI](https://en.wikipedia.org/wiki/General_MIDI)
- [SoundFont 2.04 Spec](http://www.synthfont.com/sfspec24.pdf)

### Libraries
- Android: [MidiDriver](https://github.com/billthefarmer/mididriver)
- iOS: [AVFoundation](https://developer.apple.com/documentation/avfoundation/)
- FluidSynth: [Official Site](https://www.fluidsynth.org/)

### Tools
- [Polyphone](https://www.polyphone-soundfonts.com/) - Soundfont editor
- [Viena](https://www.synthfont.com/viena.html) - SF2 editor (Windows)
- [MIDI-OX](http://www.midiox.com/) - MIDI monitoring (Windows)
