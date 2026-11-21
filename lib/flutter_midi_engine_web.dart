import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:web/web.dart' as web;

import 'src/flutter_midi_engine_platform_interface.dart';

/// Web implementation of [FlutterMidiEnginePlatform].
///
/// Uses SpessaSynth (https://github.com/spessasus/spessasynth_lib, Apache-2.0),
/// an SF2/SF3/DLS synthesizer that runs in an AudioWorklet. The JavaScript
/// files ship as web-only assets of this plugin (see assets/web and
/// tool/build_web_synth.sh), so nothing is loaded from a CDN.
class FlutterMidiEngineWeb extends FlutterMidiEnginePlatform {
  /// Registers this class as the default platform implementation.
  static void registerWith(Registrar registrar) {
    FlutterMidiEnginePlatform.instance = FlutterMidiEngineWeb();
  }

  static const _assetDir = 'packages/flutter_midi_engine/assets/web';
  static const _libScript = '$_assetDir/spessasynth_lib.min.js';
  static const _processorScript = '$_assetDir/spessasynth_processor.min.js';

  // Same small General MIDI soundfont the iOS plugin bundles.
  static const _builtInSoundfont =
      'packages/flutter_midi_engine/ios/flutter_midi_engine/Sources/'
      'flutter_midi_engine/Resources/flutter_midi_engine_basic.sf2';

  static const _soundBankId = 'main';

  web.AudioContext? _context;
  _Synthesizer? _synth;
  Future<_Synthesizer>? _starting;
  bool _loaded = false;
  JSFunction? _gestureListener;

  /// The synth only makes sound once a soundfont is loaded, like on iOS and
  /// macOS.
  _Synthesizer? get _ready => _loaded ? _synth : null;

  static String _assetUrl(String asset) {
    final url = ui_web.assetManager.getAssetUrl(asset);
    // Make it absolute: import() and addModule() resolve relative URLs
    // differently, and the app may use a <base href>.
    return web.URL(url, web.document.baseURI).href;
  }

  Future<_Synthesizer> _ensureSynth() {
    return _starting ??= _start().catchError((Object e) {
      _starting = null;
      throw e;
    });
  }

  Future<_Synthesizer> _start() async {
    final context = web.AudioContext();
    _context = context;
    _resumeOnFirstGesture();

    final module = await importModule(_assetUrl(_libScript).toJS).toDart;
    await context.audioWorklet.addModule(_assetUrl(_processorScript)).toDart;

    final constructor = module.getProperty<JSFunction>('WorkletSynthesizer'.toJS);
    final synth = constructor.callAsConstructor<_Synthesizer>(context);
    synth.connect(context.destination);
    await synth.isReady.toDart;

    _synth = synth;
    return synth;
  }

  /// Browsers keep an AudioContext suspended until the user interacts with
  /// the page. Resume it on the first tap or key press so notes are audible
  /// even when the app never calls [unmute].
  void _resumeOnFirstGesture() {
    if (_gestureListener != null) return;
    void onGesture(web.Event _) {
      _resume();
      if (_context?.state == 'running') _removeGestureListener();
    }

    final listener = onGesture.toJS;
    _gestureListener = listener;
    web.document.addEventListener('pointerdown', listener);
    web.document.addEventListener('keydown', listener);
  }

  void _removeGestureListener() {
    final listener = _gestureListener;
    if (listener == null) return;
    web.document.removeEventListener('pointerdown', listener);
    web.document.removeEventListener('keydown', listener);
    _gestureListener = null;
  }

  /// Not awaited on purpose: browsers only allow resuming during a user
  /// gesture, and the call has to happen before any `await`.
  void _resume() {
    final context = _context;
    if (context != null && context.state != 'running') {
      context.resume();
    }
  }

  @override
  Future<bool> loadSoundfont(String path) async {
    try {
      // On the web a "path" is a URL. An empty path loads the built-in sounds.
      final url = path.isEmpty ? _assetUrl(_builtInSoundfont) : path;
      final response = await web.window.fetch(url.toJS).toDart;
      if (!response.ok) {
        debugPrint('Soundfont not found: $url (HTTP ${response.status})');
        return false;
      }
      final buffer = await response.arrayBuffer().toDart;
      return await _loadBuffer(buffer);
    } catch (e) {
      debugPrint('Error loading soundfont: $e');
      return false;
    }
  }

  @override
  Future<bool> loadSoundfontBytes(Uint8List bytes) async {
    try {
      // Copy: SpessaSynth takes ownership of (detaches) the buffer it gets.
      return await _loadBuffer(Uint8List.fromList(bytes).buffer.toJS);
    } catch (e) {
      debugPrint('Error loading soundfont: $e');
      return false;
    }
  }

  Future<bool> _loadBuffer(JSArrayBuffer buffer) async {
    final synth = await _ensureSynth();
    // Replaces the previous soundfont, if any.
    await synth.soundBankManager.addSoundBank(buffer, _soundBankId).toDart;
    _loaded = true;
    return true;
  }

  @override
  Future<bool> unloadSoundfont() async {
    _loaded = false;
    final starting = _starting;
    _starting = null;
    _synth = null;
    _removeGestureListener();

    final context = _context;
    _context = null;
    try {
      final synth = await starting;
      synth?.stopAll(true);
      synth?.destroy();
    } catch (_) {
      // Start-up failed, so there is nothing to destroy.
    }
    try {
      await context?.close().toDart;
    } catch (_) {}
    return true;
  }

  @override
  Future<void> playNote({
    required int note,
    int velocity = 64,
    int channel = 0,
  }) async {
    _resume();
    _ready?.noteOn(channel, note, velocity);
  }

  @override
  Future<void> stopNote({
    required int note,
    int velocity = 64,
    int channel = 0,
  }) async {
    _ready?.noteOff(channel, note);
  }

  @override
  Future<void> changeProgram({
    required int program,
    int channel = 0,
  }) async {
    _ready?.programChange(channel, program);
  }

  @override
  Future<void> setVolume({
    required int volume,
    int channel = 0,
  }) async {
    _ready?.controllerChange(channel, 7, volume);
  }

  @override
  Future<void> setPan({
    required int pan,
    int channel = 0,
  }) async {
    _ready?.controllerChange(channel, 10, pan);
  }

  /// Sets the reverb send level (CC 91) on all channels. The other
  /// parameters are not used, same as on iOS and macOS.
  @override
  Future<void> setReverb({
    double roomSize = 0.2,
    double damping = 0.5,
    double width = 0.5,
    double level = 0.3,
  }) async {
    _setAllChannels(91, level);
  }

  /// Sets the chorus send level (CC 93) on all channels. The other
  /// parameters are not used, same as on iOS and macOS.
  @override
  Future<void> setChorus({
    int voices = 3,
    double level = 0.5,
    double speed = 0.3,
    double depth = 0.8,
  }) async {
    _setAllChannels(93, level);
  }

  void _setAllChannels(int controller, double level) {
    final synth = _ready;
    if (synth == null) return;
    final value = (level * 127).round().clamp(0, 127);
    for (var channel = 0; channel < 16; channel++) {
      synth.controllerChange(channel, controller, value);
    }
  }

  @override
  Future<void> stopAllNotes() async {
    _ready?.stopAll(false);
  }

  @override
  Future<void> resetAllControllers() async {
    final synth = _ready;
    if (synth == null) return;
    for (var channel = 0; channel < 16; channel++) {
      synth.controllerChange(channel, 121, 0);
    }
  }

  @override
  Future<void> sendControlChange({
    required int controller,
    required int value,
    int channel = 0,
  }) async {
    _ready?.controllerChange(channel, controller, value);
  }

  @override
  Future<void> sendPitchBend({
    required int value,
    int channel = 0,
  }) async {
    // -8192..8191 to the 14-bit 0..16383 range, 8192 = no bend.
    _ready?.pitchWheel(channel, (value + 8192).clamp(0, 16383));
  }

  /// On the web this resumes the audio output, which browsers block until
  /// the user interacts with the page. Call it from a tap handler.
  @override
  Future<void> unmute() async {
    _resume();
  }
}

/// SpessaSynth's `WorkletSynthesizer`.
extension type _Synthesizer._(JSObject _) implements JSObject {
  external JSPromise<JSAny?> get isReady;
  external _SoundBankManager get soundBankManager;
  external web.AudioNode connect(web.AudioNode destination);
  external void destroy();
  external void noteOn(int channel, int midiNote, int velocity);
  external void noteOff(int channel, int midiNote);
  external void stopAll(bool force);
  external void controllerChange(int channel, int controller, int value);
  external void pitchWheel(int channel, int value);
  external void programChange(int channel, int programNumber);
}

extension type _SoundBankManager._(JSObject _) implements JSObject {
  external JSPromise<JSAny?> addSoundBank(JSArrayBuffer buffer, String id);
}
