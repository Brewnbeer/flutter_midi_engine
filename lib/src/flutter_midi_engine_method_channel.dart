import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'flutter_midi_engine_platform_interface.dart';

/// An implementation of [FlutterMidiEnginePlatform] that uses method channels.
class MethodChannelFlutterMidiEngine extends FlutterMidiEnginePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_midi_engine');

  @override
  Future<bool> loadSoundfont(String path) async {
    try {
      final result = await methodChannel.invokeMethod<bool>(
        'loadSoundfont',
        {'path': path},
      );
      return result ?? false;
    } catch (e) {
      debugPrint('Error loading soundfont: $e');
      return false;
    }
  }

  @override
  Future<bool> unloadSoundfont() async {
    try {
      final result = await methodChannel.invokeMethod<bool>('unloadSoundfont');
      return result ?? false;
    } catch (e) {
      debugPrint('Error unloading soundfont: $e');
      return false;
    }
  }

  @override
  Future<void> playNote({
    required int note,
    int velocity = 64,
    int channel = 0,
  }) async {
    try {
      await methodChannel.invokeMethod('playNote', {
        'note': note,
        'velocity': velocity,
        'channel': channel,
      });
    } catch (e) {
      debugPrint('Error playing note: $e');
    }
  }

  @override
  Future<void> stopNote({
    required int note,
    int velocity = 64,
    int channel = 0,
  }) async {
    try {
      await methodChannel.invokeMethod('stopNote', {
        'note': note,
        'velocity': velocity,
        'channel': channel,
      });
    } catch (e) {
      debugPrint('Error stopping note: $e');
    }
  }

  @override
  Future<void> changeProgram({
    required int program,
    int channel = 0,
  }) async {
    try {
      await methodChannel.invokeMethod('changeProgram', {
        'program': program,
        'channel': channel,
      });
    } catch (e) {
      debugPrint('Error changing program: $e');
    }
  }

  @override
  Future<void> setVolume({
    required int volume,
    int channel = 0,
  }) async {
    try {
      await methodChannel.invokeMethod('setVolume', {
        'volume': volume,
        'channel': channel,
      });
    } catch (e) {
      debugPrint('Error setting volume: $e');
    }
  }

  @override
  Future<void> setPan({
    required int pan,
    int channel = 0,
  }) async {
    try {
      await methodChannel.invokeMethod('setPan', {
        'pan': pan,
        'channel': channel,
      });
    } catch (e) {
      debugPrint('Error setting pan: $e');
    }
  }

  @override
  Future<void> setReverb({
    double roomSize = 0.2,
    double damping = 0.5,
    double width = 0.5,
    double level = 0.3,
  }) async {
    try {
      await methodChannel.invokeMethod('setReverb', {
        'roomSize': roomSize,
        'damping': damping,
        'width': width,
        'level': level,
      });
    } catch (e) {
      debugPrint('Error setting reverb: $e');
    }
  }

  @override
  Future<void> setChorus({
    int voices = 3,
    double level = 0.5,
    double speed = 0.3,
    double depth = 0.8,
  }) async {
    try {
      await methodChannel.invokeMethod('setChorus', {
        'voices': voices,
        'level': level,
        'speed': speed,
        'depth': depth,
      });
    } catch (e) {
      debugPrint('Error setting chorus: $e');
    }
  }

  @override
  Future<void> stopAllNotes() async {
    try {
      await methodChannel.invokeMethod('stopAllNotes');
    } catch (e) {
      debugPrint('Error stopping all notes: $e');
    }
  }

  @override
  Future<void> resetAllControllers() async {
    try {
      await methodChannel.invokeMethod('resetAllControllers');
    } catch (e) {
      debugPrint('Error resetting controllers: $e');
    }
  }

  @override
  Future<void> sendControlChange({
    required int controller,
    required int value,
    int channel = 0,
  }) async {
    try {
      await methodChannel.invokeMethod('sendControlChange', {
        'controller': controller,
        'value': value,
        'channel': channel,
      });
    } catch (e) {
      debugPrint('Error sending control change: $e');
    }
  }

  @override
  Future<void> sendPitchBend({
    required int value,
    int channel = 0,
  }) async {
    try {
      await methodChannel.invokeMethod('sendPitchBend', {
        'value': value,
        'channel': channel,
      });
    } catch (e) {
      debugPrint('Error sending pitch bend: $e');
    }
  }

  @override
  Future<void> unmute() async {
    try {
      await methodChannel.invokeMethod('unmute');
    } catch (e) {
      debugPrint('Error unmuting: $e');
    }
  }
}
