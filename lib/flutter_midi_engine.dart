import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'src/flutter_midi_engine_platform_interface.dart';

export 'src/flutter_midi_engine_platform_interface.dart';

/// Flutter MIDI Engine - Advanced MIDI synthesizer with SF2/SF3 soundfont support
///
/// This plugin provides a comprehensive MIDI synthesizer for Flutter applications
/// with support for:
/// - SF2 and SF3 soundfont formats
/// - Multi-channel MIDI playback (16 channels)
/// - Program changes (instrument selection)
/// - Audio effects (reverb, chorus)
/// - Volume and pan control
/// - Pitch bend and control change messages
///
/// Example usage:
/// ```dart
/// final midiEngine = FlutterMidiEngine();
///
/// // Load a soundfont
/// await midiEngine.loadSoundfont('path/to/soundfont.sf2');
///
/// // Play a note
/// await midiEngine.playNote(note: 60, velocity: 100);
///
/// // Change instrument
/// await midiEngine.changeProgram(program: 0); // Piano
///
/// // Stop the note
/// await midiEngine.stopNote(note: 60);
/// ```
class FlutterMidiEngine {
  /// Get the platform-specific implementation
  FlutterMidiEnginePlatform get _platform => FlutterMidiEnginePlatform.instance;

  /// Load a soundfont file from the given path
  ///
  /// [path] - Absolute path to the soundfont file (SF2 or SF3)
  /// Returns true if the soundfont was loaded successfully
  ///
  /// Example:
  /// ```dart
  /// final success = await midiEngine.loadSoundfont('/path/to/soundfont.sf2');
  /// if (success) {
  ///   print('Soundfont loaded!');
  /// }
  /// ```
  Future<bool> loadSoundfont(String path) {
    return _platform.loadSoundfont(path);
  }

  /// Load a soundfont from asset bundle
  ///
  /// [assetPath] - Asset path to the soundfont file
  /// [fileName] - Optional custom filename for the cached file
  ///
  /// Example:
  /// ```dart
  /// await midiEngine.loadSoundfontFromAsset('assets/soundfonts/piano.sf2');
  /// ```
  Future<bool> loadSoundfontFromAsset(
    String assetPath, {
    String? fileName,
  }) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      final file = await _writeBytesToFile(
        byteData,
        fileName ?? assetPath.split('/').last,
      );
      if (file == null) return false;
      return await loadSoundfont(file.path);
    } catch (e) {
      debugPrint('Error loading soundfont from asset: $e');
      return false;
    }
  }

  /// Unload the current soundfont and free resources
  ///
  /// Returns true if successful
  Future<bool> unloadSoundfont() {
    return _platform.unloadSoundfont();
  }

  /// Play a MIDI note
  ///
  /// [note] - MIDI note number (0-127, where 60 is middle C)
  /// [velocity] - Note velocity/volume (0-127, default 64)
  /// [channel] - MIDI channel (0-15, default 0)
  ///
  /// Example:
  /// ```dart
  /// // Play middle C at medium velocity
  /// await midiEngine.playNote(note: 60, velocity: 64);
  ///
  /// // Play a forte note on channel 1
  /// await midiEngine.playNote(note: 72, velocity: 100, channel: 1);
  /// ```
  Future<void> playNote({
    required int note,
    int velocity = 64,
    int channel = 0,
  }) {
    assert(note >= 0 && note <= 127, 'Note must be between 0 and 127');
    assert(velocity >= 0 && velocity <= 127, 'Velocity must be between 0 and 127');
    assert(channel >= 0 && channel <= 15, 'Channel must be between 0 and 15');

    return _platform.playNote(
      note: note,
      velocity: velocity,
      channel: channel,
    );
  }

  /// Stop a MIDI note
  ///
  /// [note] - MIDI note number (0-127)
  /// [velocity] - Release velocity (0-127, default 64)
  /// [channel] - MIDI channel (0-15, default 0)
  ///
  /// Example:
  /// ```dart
  /// await midiEngine.stopNote(note: 60);
  /// ```
  Future<void> stopNote({
    required int note,
    int velocity = 64,
    int channel = 0,
  }) {
    assert(note >= 0 && note <= 127, 'Note must be between 0 and 127');
    assert(velocity >= 0 && velocity <= 127, 'Velocity must be between 0 and 127');
    assert(channel >= 0 && channel <= 15, 'Channel must be between 0 and 15');

    return _platform.stopNote(
      note: note,
      velocity: velocity,
      channel: channel,
    );
  }

  /// Change the program (instrument) on a channel
  ///
  /// [program] - Program number (0-127, e.g., 0=Piano, 40=Violin, 56=Trumpet)
  /// [channel] - MIDI channel (0-15, default 0)
  ///
  /// See General MIDI specification for program numbers:
  /// https://en.wikipedia.org/wiki/General_MIDI#Program_change_events
  ///
  /// Example:
  /// ```dart
  /// // Set channel 0 to Acoustic Grand Piano
  /// await midiEngine.changeProgram(program: 0);
  ///
  /// // Set channel 1 to Church Organ
  /// await midiEngine.changeProgram(program: 19, channel: 1);
  /// ```
  Future<void> changeProgram({
    required int program,
    int channel = 0,
  }) {
    assert(program >= 0 && program <= 127, 'Program must be between 0 and 127');
    assert(channel >= 0 && channel <= 15, 'Channel must be between 0 and 15');

    return _platform.changeProgram(
      program: program,
      channel: channel,
    );
  }

  /// Set the volume for a channel
  ///
  /// [volume] - Volume level (0-127, default 100)
  /// [channel] - MIDI channel (0-15, default 0)
  ///
  /// Example:
  /// ```dart
  /// await midiEngine.setVolume(volume: 100, channel: 0);
  /// ```
  Future<void> setVolume({
    required int volume,
    int channel = 0,
  }) {
    assert(volume >= 0 && volume <= 127, 'Volume must be between 0 and 127');
    assert(channel >= 0 && channel <= 15, 'Channel must be between 0 and 15');

    return _platform.setVolume(
      volume: volume,
      channel: channel,
    );
  }

  /// Set the pan position for a channel
  ///
  /// [pan] - Pan position (0=left, 64=center, 127=right)
  /// [channel] - MIDI channel (0-15, default 0)
  ///
  /// Example:
  /// ```dart
  /// // Pan to center
  /// await midiEngine.setPan(pan: 64);
  ///
  /// // Pan fully to the right
  /// await midiEngine.setPan(pan: 127);
  /// ```
  Future<void> setPan({
    required int pan,
    int channel = 0,
  }) {
    assert(pan >= 0 && pan <= 127, 'Pan must be between 0 and 127');
    assert(channel >= 0 && channel <= 15, 'Channel must be between 0 and 15');

    return _platform.setPan(
      pan: pan,
      channel: channel,
    );
  }

  /// Set reverb parameters for the synthesizer
  ///
  /// [roomSize] - Room size (0.0-1.0, default 0.2)
  /// [damping] - High-frequency damping (0.0-1.0, default 0.5)
  /// [width] - Stereo width (0.0-1.0, default 0.5)
  /// [level] - Reverb mix level (0.0-1.0, default 0.3)
  ///
  /// Example:
  /// ```dart
  /// // Set a large hall reverb
  /// await midiEngine.setReverb(
  ///   roomSize: 0.8,
  ///   damping: 0.3,
  ///   width: 1.0,
  ///   level: 0.5,
  /// );
  /// ```
  Future<void> setReverb({
    double roomSize = 0.2,
    double damping = 0.5,
    double width = 0.5,
    double level = 0.3,
  }) {
    assert(roomSize >= 0.0 && roomSize <= 1.0, 'Room size must be between 0.0 and 1.0');
    assert(damping >= 0.0 && damping <= 1.0, 'Damping must be between 0.0 and 1.0');
    assert(width >= 0.0 && width <= 1.0, 'Width must be between 0.0 and 1.0');
    assert(level >= 0.0 && level <= 1.0, 'Level must be between 0.0 and 1.0');

    return _platform.setReverb(
      roomSize: roomSize,
      damping: damping,
      width: width,
      level: level,
    );
  }

  /// Set chorus parameters for the synthesizer
  ///
  /// [voices] - Number of chorus voices (0-99, default 3)
  /// [level] - Chorus mix level (0.0-1.0, default 0.5)
  /// [speed] - LFO speed in Hz (0.29-5.0, default 0.3)
  /// [depth] - LFO depth (0.0-1.0, default 0.8)
  ///
  /// Example:
  /// ```dart
  /// await midiEngine.setChorus(
  ///   voices: 5,
  ///   level: 0.7,
  ///   speed: 0.5,
  ///   depth: 1.0,
  /// );
  /// ```
  Future<void> setChorus({
    int voices = 3,
    double level = 0.5,
    double speed = 0.3,
    double depth = 0.8,
  }) {
    assert(voices >= 0 && voices <= 99, 'Voices must be between 0 and 99');
    assert(level >= 0.0 && level <= 1.0, 'Level must be between 0.0 and 1.0');
    assert(speed >= 0.29 && speed <= 5.0, 'Speed must be between 0.29 and 5.0');
    assert(depth >= 0.0 && depth <= 1.0, 'Depth must be between 0.0 and 1.0');

    return _platform.setChorus(
      voices: voices,
      level: level,
      speed: speed,
      depth: depth,
    );
  }

  /// Stop all currently playing notes on all channels
  ///
  /// Example:
  /// ```dart
  /// await midiEngine.stopAllNotes();
  /// ```
  Future<void> stopAllNotes() {
    return _platform.stopAllNotes();
  }

  /// Reset all controllers on all channels to their default values
  ///
  /// Example:
  /// ```dart
  /// await midiEngine.resetAllControllers();
  /// ```
  Future<void> resetAllControllers() {
    return _platform.resetAllControllers();
  }

  /// Send a raw MIDI control change message
  ///
  /// [controller] - Controller number (0-127)
  /// [value] - Controller value (0-127)
  /// [channel] - MIDI channel (0-15, default 0)
  ///
  /// Common controllers:
  /// - 1: Modulation
  /// - 7: Volume
  /// - 10: Pan
  /// - 11: Expression
  /// - 64: Sustain pedal
  /// - 91: Reverb level
  /// - 93: Chorus level
  ///
  /// Example:
  /// ```dart
  /// // Enable sustain pedal
  /// await midiEngine.sendControlChange(controller: 64, value: 127);
  ///
  /// // Disable sustain pedal
  /// await midiEngine.sendControlChange(controller: 64, value: 0);
  /// ```
  Future<void> sendControlChange({
    required int controller,
    required int value,
    int channel = 0,
  }) {
    assert(controller >= 0 && controller <= 127, 'Controller must be between 0 and 127');
    assert(value >= 0 && value <= 127, 'Value must be between 0 and 127');
    assert(channel >= 0 && channel <= 15, 'Channel must be between 0 and 15');

    return _platform.sendControlChange(
      controller: controller,
      value: value,
      channel: channel,
    );
  }

  /// Send a pitch bend message
  ///
  /// [value] - Pitch bend value (-8192 to 8191, where 0 is center/no bend)
  /// [channel] - MIDI channel (0-15, default 0)
  ///
  /// Example:
  /// ```dart
  /// // Bend pitch up
  /// await midiEngine.sendPitchBend(value: 4096);
  ///
  /// // Reset to center
  /// await midiEngine.sendPitchBend(value: 0);
  ///
  /// // Bend pitch down
  /// await midiEngine.sendPitchBend(value: -4096);
  /// ```
  Future<void> sendPitchBend({
    required int value,
    int channel = 0,
  }) {
    assert(value >= -8192 && value <= 8191, 'Value must be between -8192 and 8191');
    assert(channel >= 0 && channel <= 15, 'Channel must be between 0 and 15');

    return _platform.sendPitchBend(
      value: value,
      channel: channel,
    );
  }

  /// Unmute the device (iOS specific)
  ///
  /// This allows sound to play even if the device's mute switch is on.
  /// Call this before loading a soundfont to ensure audio playback works.
  ///
  /// Example:
  /// ```dart
  /// await midiEngine.unmute();
  /// await midiEngine.loadSoundfont('path/to/soundfont.sf2');
  /// ```
  Future<void> unmute() {
    return _platform.unmute();
  }

  /// Helper method to write ByteData to a file in the temporary directory
  Future<File?> _writeBytesToFile(ByteData data, String fileName) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');

      final buffer = data.buffer;
      await file.writeAsBytes(
        buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );

      return file;
    } catch (e) {
      debugPrint('Error writing bytes to file: $e');
      return null;
    }
  }
}
