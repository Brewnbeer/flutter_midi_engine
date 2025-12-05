import 'package:flutter/material.dart';
import 'package:flutter_midi_engine/flutter_midi_engine.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter MIDI Engine Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MidiPianoPage(),
    );
  }
}

class MidiPianoPage extends StatefulWidget {
  const MidiPianoPage({super.key});

  @override
  State<MidiPianoPage> createState() => _MidiPianoPageState();
}

class _MidiPianoPageState extends State<MidiPianoPage> {
  final FlutterMidiEngine _midiEngine = FlutterMidiEngine();
  bool _isInitialized = false;
  int _currentProgram = 0;
  int _currentVolume = 100;
  final Set<int> _activeNotes = {};

  static const List<String> _noteNames = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
  ];

  static const Map<String, int> _instruments = {
    'Acoustic Grand Piano': 0,
    'Electric Piano': 4,
    'Church Organ': 19,
    'Acoustic Guitar': 24,
    'Electric Guitar': 27,
    'Violin': 40,
    'Trumpet': 56,
    'Flute': 73,
    'Synth Lead': 80,
  };

  @override
  void initState() {
    super.initState();
    _initializeMidi();
  }

  Future<void> _initializeMidi() async {
    try {
      await _midiEngine.unmute();
      final success = await _midiEngine.loadSoundfont('');

      if (success) {
        await _midiEngine.setVolume(volume: _currentVolume);

        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Failed to initialize MIDI: $e');
    }
  }

  Future<void> _playNote(int note) async {
    if (!_isInitialized) return;

    await _midiEngine.playNote(
      note: note,
      velocity: 100,
    );

    setState(() {
      _activeNotes.add(note);
    });
  }

  Future<void> _stopNote(int note) async {
    if (!_isInitialized) return;

    await _midiEngine.stopNote(note: note);

    setState(() {
      _activeNotes.remove(note);
    });
  }

  Future<void> _changeInstrument(int program) async {
    if (!_isInitialized) return;

    await _midiEngine.changeProgram(program: program);

    setState(() {
      _currentProgram = program;
    });
  }

  Future<void> _changeVolume(double volume) async {
    if (!_isInitialized) return;

    final volumeInt = volume.toInt();
    await _midiEngine.setVolume(volume: volumeInt);

    setState(() {
      _currentVolume = volumeInt;
    });
  }

  String _getNoteName(int midiNote) {
    final octave = (midiNote ~/ 12) - 1;
    final noteIndex = midiNote % 12;
    return '${_noteNames[noteIndex]}$octave';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Flutter MIDI Engine Demo'),
      ),
      body: _isInitialized
          ? Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Instrument',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButton<int>(
                        value: _currentProgram,
                        isExpanded: true,
                        items: _instruments.entries.map((entry) {
                          return DropdownMenuItem(
                            value: entry.value,
                            child: Text(entry.key),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            _changeInstrument(value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Volume',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: _currentVolume.toDouble(),
                              min: 0,
                              max: 127,
                              divisions: 127,
                              label: _currentVolume.toString(),
                              onChanged: _changeVolume,
                            ),
                          ),
                          SizedBox(
                            width: 40,
                            child: Text(
                              _currentVolume.toString(),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildPianoKeyboard(),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[200],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Active Notes:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _activeNotes.isEmpty
                            ? 'None'
                            : _activeNotes
                                .map((n) => _getNoteName(n))
                                .join(', '),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initializing MIDI Engine...'),
                ],
              ),
            ),
    );
  }

  Widget _buildPianoKeyboard() {
    const startNote = 60;
    const numOctaves = 2;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(numOctaves * 12, (index) {
        final note = startNote + index;
        final noteIndex = note % 12;
        final isBlackKey = [1, 3, 6, 8, 10].contains(noteIndex);

        return _buildPianoKey(
          note: note,
          isBlackKey: isBlackKey,
          isActive: _activeNotes.contains(note),
        );
      }),
    );
  }

  Widget _buildPianoKey({
    required int note,
    required bool isBlackKey,
    required bool isActive,
  }) {
    final keyColor = isActive
        ? Colors.blue
        : isBlackKey
            ? Colors.black
            : Colors.white;

    final textColor = isBlackKey || isActive ? Colors.white : Colors.black;

    return GestureDetector(
      onTapDown: (_) => _playNote(note),
      onTapUp: (_) => _stopNote(note),
      onTapCancel: () => _stopNote(note),
      child: Container(
        width: isBlackKey ? 40 : 60,
        height: isBlackKey ? 120 : 200,
        margin: EdgeInsets.only(
          right: isBlackKey ? 0 : 2,
          left: isBlackKey ? 0 : 2,
        ),
        decoration: BoxDecoration(
          color: keyColor,
          border: Border.all(
            color: Colors.grey[800]!,
            width: 1,
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 140),
            child: Text(
              _getNoteName(note),
              style: TextStyle(
                color: textColor,
                fontSize: isBlackKey ? 10 : 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _midiEngine.stopAllNotes();
    _midiEngine.unloadSoundfont();
    super.dispose();
  }
}
