import FlutterMacOS
import AudioToolbox
import CoreAudio

// macOS version of the iOS plugin. Same AUSampler setup, but macOS has no
// AVAudioSession, so the output goes through the DefaultOutput unit and we
// listen to CoreAudio for default output device changes instead.
public class FlutterMidiEnginePlugin: NSObject, FlutterPlugin {
    private var processingGraph: AUGraph?
    private var samplerNode = AUNode()
    private var ioNode = AUNode()
    private var samplerUnit: AudioUnit?
    private var soundfontLoaded = false
    private var soundbankURL: URL?

    // General MIDI sound bank that ships with every Mac. Used when no
    // soundfont path is given, like the built-in Sonivox sounds on Android.
    private static let systemSoundbankPath =
        "/System/Library/Components/CoreAudio.component/Contents/Resources/gs_instruments.dls"
    private var deviceListener: AudioObjectPropertyListenerBlock?

    private static var defaultOutputAddress = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultOutputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        // 0 = kAudioObjectPropertyElementMain (that name needs macOS 12+)
        mElement: AudioObjectPropertyElement(0)
    )

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_midi_engine", binaryMessenger: registrar.messenger)
        let instance = FlutterMidiEnginePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public override init() {
        super.init()
        setupAudioGraph()
        listenForOutputDeviceChanges()
    }

    deinit {
        if let listener = deviceListener {
            AudioObjectRemovePropertyListenerBlock(
                AudioObjectID(kAudioObjectSystemObject),
                &FlutterMidiEnginePlugin.defaultOutputAddress,
                DispatchQueue.main,
                listener
            )
        }
        cleanup()
    }

    // Restart the graph when the default output device changes (headphones,
    // Bluetooth, USB interface) so audio moves to the new device.
    private func listenForOutputDeviceChanges() {
        let listener: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            self?.restartAudioGraph()
        }
        let status = AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &FlutterMidiEnginePlugin.defaultOutputAddress,
            DispatchQueue.main,
            listener
        )
        if status == noErr {
            deviceListener = listener
        } else {
            print("Failed to add output device listener: \(status)")
        }
    }

    private func restartAudioGraph() {
        guard let graph = processingGraph else { return }

        var isRunning: DarwinBoolean = false
        AUGraphIsRunning(graph, &isRunning)
        if isRunning.boolValue {
            AUGraphStop(graph)
        }

        let status = AUGraphStart(graph)
        if status != noErr {
            print("Failed to restart AUGraph after device change: \(status)")
        }
    }

    private func setupAudioGraph() {
        var status = NewAUGraph(&processingGraph)
        guard status == noErr, let graph = processingGraph else {
            print("Failed to create AUGraph: \(status)")
            return
        }

        var samplerDescription = AudioComponentDescription(
            componentType: kAudioUnitType_MusicDevice,
            componentSubType: kAudioUnitSubType_Sampler,
            componentManufacturer: kAudioUnitManufacturer_Apple,
            componentFlags: 0,
            componentFlagsMask: 0
        )
        status = AUGraphAddNode(graph, &samplerDescription, &samplerNode)
        guard status == noErr else {
            print("Failed to add sampler node: \(status)")
            return
        }

        // DefaultOutput plays to whatever device is selected in System Settings.
        var ioDescription = AudioComponentDescription(
            componentType: kAudioUnitType_Output,
            componentSubType: kAudioUnitSubType_DefaultOutput,
            componentManufacturer: kAudioUnitManufacturer_Apple,
            componentFlags: 0,
            componentFlagsMask: 0
        )
        status = AUGraphAddNode(graph, &ioDescription, &ioNode)
        guard status == noErr else {
            print("Failed to add output node: \(status)")
            return
        }

        status = AUGraphOpen(graph)
        guard status == noErr else {
            print("Failed to open AUGraph: \(status)")
            return
        }

        status = AUGraphNodeInfo(graph, samplerNode, nil, &samplerUnit)
        guard status == noErr else {
            print("Failed to get sampler unit: \(status)")
            return
        }

        status = AUGraphConnectNodeInput(graph, samplerNode, 0, ioNode, 0)
        guard status == noErr else {
            print("Failed to connect nodes: \(status)")
            return
        }

        status = AUGraphInitialize(graph)
        guard status == noErr else {
            print("Failed to initialize AUGraph: \(status)")
            return
        }

        status = AUGraphStart(graph)
        guard status == noErr else {
            print("Failed to start AUGraph: \(status)")
            return
        }
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any]

        switch call.method {
        case "loadSoundfont":
            guard let path = args?["path"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Path required", details: nil))
                return
            }
            result(loadSoundfont(path: path))

        case "unloadSoundfont":
            result(unloadSoundfont())

        case "stopAllNotes":
            stopAllNotes()
            result(nil)

        case "resetAllControllers":
            resetAllControllers()
            result(nil)

        case "unmute":
            // Only needed on iOS (silent switch). Nothing to do on macOS.
            result(nil)

        case "playNote", "stopNote", "changeProgram", "setVolume", "setPan",
             "setReverb", "setChorus", "sendControlChange", "sendPitchBend":
            guard let args = args else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Arguments required", details: nil))
                return
            }
            handleMidiCall(call.method, args)
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func handleMidiCall(_ method: String, _ args: [String: Any]) {
        let channel = args["channel"] as? Int ?? 0

        switch method {
        case "playNote":
            playNote(note: args["note"] as? Int ?? 60, velocity: args["velocity"] as? Int ?? 64, channel: channel)
        case "stopNote":
            stopNote(note: args["note"] as? Int ?? 60, velocity: args["velocity"] as? Int ?? 64, channel: channel)
        case "changeProgram":
            changeProgram(program: args["program"] as? Int ?? 0, channel: channel)
        case "setVolume":
            sendControlChange(controller: 7, value: args["volume"] as? Int ?? 100, channel: channel)
        case "setPan":
            sendControlChange(controller: 10, value: args["pan"] as? Int ?? 64, channel: channel)
        case "setReverb":
            setAllChannels(controller: 91, level: args["level"] as? Double ?? 0.3)
        case "setChorus":
            setAllChannels(controller: 93, level: args["level"] as? Double ?? 0.5)
        case "sendControlChange":
            sendControlChange(controller: args["controller"] as? Int ?? 0, value: args["value"] as? Int ?? 0, channel: channel)
        case "sendPitchBend":
            sendPitchBend(value: args["value"] as? Int ?? 0, channel: channel)
        default:
            break
        }
    }

    private func loadSoundfont(path: String) -> Bool {
        guard samplerUnit != nil else {
            print("Sampler unit not initialized")
            return false
        }

        let file = path.isEmpty ? FlutterMidiEnginePlugin.systemSoundbankPath : path
        guard FileManager.default.fileExists(atPath: file) else {
            print("Soundfont file not found: \(file)")
            return false
        }

        soundbankURL = URL(fileURLWithPath: file)
        let status = loadInstrument(program: 0)
        if status != noErr {
            print("Failed to load soundfont: \(status)")
            soundbankURL = nil
            return false
        }

        soundfontLoaded = true
        return true
    }

    // AUSampler plays one instrument at a time, so a program change loads
    // that preset from the current sound bank (SF2 or DLS).
    private func loadInstrument(program: Int) -> OSStatus {
        guard let sampler = samplerUnit, let url = soundbankURL else { return -1 }

        let cfURL = url as CFURL
        return withExtendedLifetime(cfURL) {
            var data = AUSamplerInstrumentData(
                fileURL: Unmanaged.passUnretained(cfURL),
                instrumentType: UInt8(kInstrumentType_DLSPreset), // also used for SF2
                bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                bankLSB: UInt8(kAUSampler_DefaultBankLSB),
                presetID: UInt8(program & 0x7F)
            )
            return AudioUnitSetProperty(
                sampler,
                AudioUnitPropertyID(kAUSamplerProperty_LoadInstrument),
                AudioUnitScope(kAudioUnitScope_Global),
                0,
                &data,
                UInt32(MemoryLayout<AUSamplerInstrumentData>.size)
            )
        }
    }

    private func unloadSoundfont() -> Bool {
        soundfontLoaded = false
        soundbankURL = nil
        if let graph = processingGraph {
            AUGraphStop(graph)
            AUGraphStart(graph)
        }
        return true
    }

    private func send(_ status: Int, _ data1: Int, _ data2: Int) {
        guard soundfontLoaded, let sampler = samplerUnit else { return }
        MusicDeviceMIDIEvent(sampler, UInt32(status), UInt32(data1 & 0x7F), UInt32(data2 & 0x7F), 0)
    }

    private func playNote(note: Int, velocity: Int, channel: Int) {
        send(0x90 | (channel & 0x0F), note, velocity)
    }

    private func stopNote(note: Int, velocity: Int, channel: Int) {
        send(0x80 | (channel & 0x0F), note, velocity)
    }

    private func changeProgram(program: Int, channel: Int) {
        guard soundfontLoaded else { return }
        let status = loadInstrument(program: program)
        if status != noErr {
            print("Failed to load program \(program): \(status)")
        }
    }

    private func sendControlChange(controller: Int, value: Int, channel: Int) {
        send(0xB0 | (channel & 0x0F), controller, value)
    }

    private func setAllChannels(controller: Int, level: Double) {
        for ch in 0...15 {
            sendControlChange(controller: controller, value: Int(level * 127), channel: ch)
        }
    }

    private func stopAllNotes() {
        for ch in 0...15 {
            sendControlChange(controller: 123, value: 0, channel: ch)
        }
    }

    private func resetAllControllers() {
        for ch in 0...15 {
            sendControlChange(controller: 121, value: 0, channel: ch)
        }
    }

    // value is -8192..8191, MIDI wants 0..16383 split into two 7-bit bytes
    private func sendPitchBend(value: Int, channel: Int) {
        let bend = value + 8192
        send(0xE0 | (channel & 0x0F), bend & 0x7F, (bend >> 7) & 0x7F)
    }

    private func cleanup() {
        if let graph = processingGraph {
            AUGraphStop(graph)
            AUGraphUninitialize(graph)
            AUGraphClose(graph)
            DisposeAUGraph(graph)
        }
        processingGraph = nil
        samplerUnit = nil
    }
}
