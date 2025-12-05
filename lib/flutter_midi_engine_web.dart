import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'src/flutter_midi_engine_platform_interface.dart';

/// Web implementation of FlutterMidiEnginePlatform
class FlutterMidiEngineWeb extends FlutterMidiEnginePlatform {
  /// Registers this class as the default platform implementation.
  static void registerWith(Registrar registrar) {
    FlutterMidiEnginePlatform.instance = FlutterMidiEngineWeb();
  }

  // Note: Web implementation requires a JavaScript MIDI synthesizer library
  // such as WebAudioFont, sf2-synth-audio-context, or MIDI.js
  // For now, providing stub implementations with warnings

  @override
  Future<bool> loadSoundfont(String path) async {
    debugPrint('Web platform: Soundfont loading not yet implemented');
    debugPrint('Consider using WebAudioFont or sf2-synth-audio-context');
    return false;
  }

  @override
  Future<bool> unloadSoundfont() async {
    debugPrint('Web platform: Soundfont unloading not yet implemented');
    return false;
  }

  @override
  Future<void> playNote({
    required int note,
    int velocity = 64,
    int channel = 0,
  }) async {
    debugPrint('Web platform: Note playback not yet implemented');
    debugPrint('Note: $note, Velocity: $velocity, Channel: $channel');
  }

  @override
  Future<void> stopNote({
    required int note,
    int velocity = 64,
    int channel = 0,
  }) async {
    debugPrint('Web platform: Note stopping not yet implemented');
  }

  @override
  Future<void> changeProgram({
    required int program,
    int channel = 0,
  }) async {
    debugPrint('Web platform: Program change not yet implemented');
  }

  @override
  Future<void> setVolume({
    required int volume,
    int channel = 0,
  }) async {
    debugPrint('Web platform: Volume control not yet implemented');
  }

  @override
  Future<void> setPan({
    required int pan,
    int channel = 0,
  }) async {
    debugPrint('Web platform: Pan control not yet implemented');
  }

  @override
  Future<void> setReverb({
    double roomSize = 0.2,
    double damping = 0.5,
    double width = 0.5,
    double level = 0.3,
  }) async {
    debugPrint('Web platform: Reverb not yet implemented');
  }

  @override
  Future<void> setChorus({
    int voices = 3,
    double level = 0.5,
    double speed = 0.3,
    double depth = 0.8,
  }) async {
    debugPrint('Web platform: Chorus not yet implemented');
  }

  @override
  Future<void> stopAllNotes() async {
    debugPrint('Web platform: Stop all notes not yet implemented');
  }

  @override
  Future<void> resetAllControllers() async {
    debugPrint('Web platform: Reset controllers not yet implemented');
  }

  @override
  Future<void> sendControlChange({
    required int controller,
    required int value,
    int channel = 0,
  }) async {
    debugPrint('Web platform: Control change not yet implemented');
  }

  @override
  Future<void> sendPitchBend({
    required int value,
    int channel = 0,
  }) async {
    debugPrint('Web platform: Pitch bend not yet implemented');
  }

  @override
  Future<void> unmute() async {
    // Not needed for web
  }
}
