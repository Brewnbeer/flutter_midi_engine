import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'flutter_midi_engine_method_channel.dart';

/// The interface that platform-specific implementations of flutter_midi_engine must extend.
abstract class FlutterMidiEnginePlatform extends PlatformInterface {
  FlutterMidiEnginePlatform() : super(token: _token);

  static final Object _token = Object();
  static FlutterMidiEnginePlatform _instance = MethodChannelFlutterMidiEngine();

  /// The default instance of [FlutterMidiEnginePlatform] to use.
  static FlutterMidiEnginePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterMidiEnginePlatform] when
  /// they register themselves.
  static set instance(FlutterMidiEnginePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Load a soundfont file from the given path
  /// Supports SF2, SF3, and other compatible formats
  Future<bool> loadSoundfont(String path) {
    throw UnimplementedError('loadSoundfont() has not been implemented.');
  }

  /// Unload the current soundfont and free resources
  Future<bool> unloadSoundfont() {
    throw UnimplementedError('unloadSoundfont() has not been implemented.');
  }

  /// Play a MIDI note
  /// [note] - MIDI note number (0-127)
  /// [velocity] - Note velocity (0-127)
  /// [channel] - MIDI channel (0-15)
  Future<void> playNote({
    required int note,
    int velocity = 64,
    int channel = 0,
  }) {
    throw UnimplementedError('playNote() has not been implemented.');
  }

  /// Stop a MIDI note
  /// [note] - MIDI note number (0-127)
  /// [velocity] - Release velocity (0-127)
  /// [channel] - MIDI channel (0-15)
  Future<void> stopNote({
    required int note,
    int velocity = 64,
    int channel = 0,
  }) {
    throw UnimplementedError('stopNote() has not been implemented.');
  }

  /// Change the program (instrument) on a channel
  /// [program] - Program number (0-127)
  /// [channel] - MIDI channel (0-15)
  Future<void> changeProgram({
    required int program,
    int channel = 0,
  }) {
    throw UnimplementedError('changeProgram() has not been implemented.');
  }

  /// Set the volume for a channel
  /// [volume] - Volume level (0-127)
  /// [channel] - MIDI channel (0-15)
  Future<void> setVolume({
    required int volume,
    int channel = 0,
  }) {
    throw UnimplementedError('setVolume() has not been implemented.');
  }

  /// Set the pan position for a channel
  /// [pan] - Pan position (0=left, 64=center, 127=right)
  /// [channel] - MIDI channel (0-15)
  Future<void> setPan({
    required int pan,
    int channel = 0,
  }) {
    throw UnimplementedError('setPan() has not been implemented.');
  }

  /// Set reverb parameters
  /// [roomSize] - Room size (0.0-1.0)
  /// [damping] - Damping amount (0.0-1.0)
  /// [width] - Stereo width (0.0-1.0)
  /// [level] - Reverb level (0.0-1.0)
  Future<void> setReverb({
    double roomSize = 0.2,
    double damping = 0.5,
    double width = 0.5,
    double level = 0.3,
  }) {
    throw UnimplementedError('setReverb() has not been implemented.');
  }

  /// Set chorus parameters
  /// [voices] - Number of voices (0-99)
  /// [level] - Chorus level (0.0-1.0)
  /// [speed] - LFO speed in Hz (0.29-5.0)
  /// [depth] - LFO depth (0.0-1.0)
  Future<void> setChorus({
    int voices = 3,
    double level = 0.5,
    double speed = 0.3,
    double depth = 0.8,
  }) {
    throw UnimplementedError('setChorus() has not been implemented.');
  }

  /// Stop all currently playing notes on all channels
  Future<void> stopAllNotes() {
    throw UnimplementedError('stopAllNotes() has not been implemented.');
  }

  /// Reset all controllers on all channels
  Future<void> resetAllControllers() {
    throw UnimplementedError('resetAllControllers() has not been implemented.');
  }

  /// Send a raw MIDI control change message
  /// [controller] - Controller number (0-127)
  /// [value] - Controller value (0-127)
  /// [channel] - MIDI channel (0-15)
  Future<void> sendControlChange({
    required int controller,
    required int value,
    int channel = 0,
  }) {
    throw UnimplementedError('sendControlChange() has not been implemented.');
  }

  /// Send a pitch bend message
  /// [value] - Pitch bend value (-8192 to 8191, 0 is center)
  /// [channel] - MIDI channel (0-15)
  Future<void> sendPitchBend({
    required int value,
    int channel = 0,
  }) {
    throw UnimplementedError('sendPitchBend() has not been implemented.');
  }

  /// Unmute the device (iOS specific - allows sound even if device is muted)
  Future<void> unmute() {
    throw UnimplementedError('unmute() has not been implemented.');
  }
}
