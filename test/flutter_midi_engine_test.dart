import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_midi_engine/flutter_midi_engine.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterMidiEnginePlatform extends FlutterMidiEnginePlatform with MockPlatformInterfaceMixin {
  @override
  Future<bool> loadSoundfont(String path) async {
    return true;
  }

  @override
  Future<bool> unloadSoundfont() async {
    return true;
  }

  @override
  Future<void> playNote({
    required int note,
    int velocity = 64,
    int channel = 0,
  }) async {
    // Mock implementation
  }

  @override
  Future<void> stopNote({
    required int note,
    int velocity = 64,
    int channel = 0,
  }) async {
    // Mock implementation
  }

  @override
  Future<void> changeProgram({
    required int program,
    int channel = 0,
  }) async {
    // Mock implementation
  }

  @override
  Future<void> setVolume({
    required int volume,
    int channel = 0,
  }) async {
    // Mock implementation
  }

  @override
  Future<void> setPan({
    required int pan,
    int channel = 0,
  }) async {
    // Mock implementation
  }

  @override
  Future<void> setReverb({
    double roomSize = 0.2,
    double damping = 0.5,
    double width = 0.5,
    double level = 0.3,
  }) async {
    // Mock implementation
  }

  @override
  Future<void> setChorus({
    int voices = 3,
    double level = 0.5,
    double speed = 0.3,
    double depth = 0.8,
  }) async {
    // Mock implementation
  }

  @override
  Future<void> stopAllNotes() async {
    // Mock implementation
  }

  @override
  Future<void> resetAllControllers() async {
    // Mock implementation
  }

  @override
  Future<void> sendControlChange({
    required int controller,
    required int value,
    int channel = 0,
  }) async {
    // Mock implementation
  }

  @override
  Future<void> sendPitchBend({
    required int value,
    int channel = 0,
  }) async {
    // Mock implementation
  }

  @override
  Future<void> unmute() async {
    // Mock implementation
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FlutterMidiEngine', () {
    late FlutterMidiEngine midiEngine;
    late MockFlutterMidiEnginePlatform mockPlatform;

    setUp(() {
      mockPlatform = MockFlutterMidiEnginePlatform();
      FlutterMidiEnginePlatform.instance = mockPlatform;
      midiEngine = FlutterMidiEngine();
    });

    test('loadSoundfont returns true on success', () async {
      final result = await midiEngine.loadSoundfont('/path/to/soundfont.sf2');
      expect(result, true);
    });

    test('unloadSoundfont returns true on success', () async {
      final result = await midiEngine.unloadSoundfont();
      expect(result, true);
    });

    test('playNote executes without error', () async {
      await expectLater(
        midiEngine.playNote(note: 60, velocity: 100),
        completes,
      );
    });

    test('stopNote executes without error', () async {
      await expectLater(
        midiEngine.stopNote(note: 60),
        completes,
      );
    });

    test('changeProgram executes without error', () async {
      await expectLater(
        midiEngine.changeProgram(program: 0),
        completes,
      );
    });

    test('setVolume executes without error', () async {
      await expectLater(
        midiEngine.setVolume(volume: 100),
        completes,
      );
    });

    test('setPan executes without error', () async {
      await expectLater(
        midiEngine.setPan(pan: 64),
        completes,
      );
    });

    test('setReverb executes without error', () async {
      await expectLater(
        midiEngine.setReverb(roomSize: 0.5, level: 0.5),
        completes,
      );
    });

    test('setChorus executes without error', () async {
      await expectLater(
        midiEngine.setChorus(voices: 5, level: 0.7),
        completes,
      );
    });

    test('stopAllNotes executes without error', () async {
      await expectLater(
        midiEngine.stopAllNotes(),
        completes,
      );
    });

    test('resetAllControllers executes without error', () async {
      await expectLater(
        midiEngine.resetAllControllers(),
        completes,
      );
    });

    test('sendControlChange executes without error', () async {
      await expectLater(
        midiEngine.sendControlChange(controller: 64, value: 127),
        completes,
      );
    });

    test('sendPitchBend executes without error', () async {
      await expectLater(
        midiEngine.sendPitchBend(value: 4096),
        completes,
      );
    });

    test('unmute executes without error', () async {
      await expectLater(
        midiEngine.unmute(),
        completes,
      );
    });

    group('Input validation', () {
      test('playNote validates note range', () {
        expect(
          () => midiEngine.playNote(note: 128),
          throwsA(isA<AssertionError>()),
        );
      });

      test('playNote validates velocity range', () {
        expect(
          () => midiEngine.playNote(note: 60, velocity: 128),
          throwsA(isA<AssertionError>()),
        );
      });

      test('playNote validates channel range', () {
        expect(
          () => midiEngine.playNote(note: 60, channel: 16),
          throwsA(isA<AssertionError>()),
        );
      });

      test('changeProgram validates program range', () {
        expect(
          () => midiEngine.changeProgram(program: 128),
          throwsA(isA<AssertionError>()),
        );
      });

      test('setVolume validates volume range', () {
        expect(
          () => midiEngine.setVolume(volume: 128),
          throwsA(isA<AssertionError>()),
        );
      });

      test('setPan validates pan range', () {
        expect(
          () => midiEngine.setPan(pan: 128),
          throwsA(isA<AssertionError>()),
        );
      });

      test('sendPitchBend validates value range', () {
        expect(
          () => midiEngine.sendPitchBend(value: 8192),
          throwsA(isA<AssertionError>()),
        );
      });
    });
  });
}
