import Flutter
import UIKit
import AudioToolbox
import AVFoundation

public class FlutterMidiEnginePlugin: NSObject, FlutterPlugin {
    private var musicPlayer: MusicPlayer?
    private var processingGraph: AUGraph?
    private var samplerNode = AUNode()
    private var ioNode = AUNode()
    private var samplerUnit: AudioUnit?
    private var soundfontLoaded = false

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_midi_engine", binaryMessenger: registrar.messenger())
        let instance = FlutterMidiEnginePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public override init() {
        super.init()
        setupAudioGraph()
    }

    deinit {
        cleanup()
    }

    private func setupAudioGraph() {
        // Create AUGraph
        var status = NewAUGraph(&processingGraph)
        guard status == noErr, let graph = processingGraph else {
            print("Failed to create AUGraph: \(status)")
            return
        }

        // Add sampler node
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

        // Add output node
        var ioDescription = AudioComponentDescription(
            componentType: kAudioUnitType_Output,
            componentSubType: kAudioUnitSubType_RemoteIO,
            componentManufacturer: kAudioUnitManufacturer_Apple,
            componentFlags: 0,
            componentFlagsMask: 0
        )
        status = AUGraphAddNode(graph, &ioDescription, &ioNode)
        guard status == noErr else {
            print("Failed to add IO node: \(status)")
            return
        }

        // Open the graph
        status = AUGraphOpen(graph)
        guard status == noErr else {
            print("Failed to open AUGraph: \(status)")
            return
        }

        // Get the sampler unit
        status = AUGraphNodeInfo(graph, samplerNode, nil, &samplerUnit)
        guard status == noErr else {
            print("Failed to get sampler unit: \(status)")
            return
        }

        // Connect sampler to output
        status = AUGraphConnectNodeInput(graph, samplerNode, 0, ioNode, 0)
        guard status == noErr else {
            print("Failed to connect nodes: \(status)")
            return
        }

        // Initialize graph
        status = AUGraphInitialize(graph)
        guard status == noErr else {
            print("Failed to initialize AUGraph: \(status)")
            return
        }

        // Start graph
        status = AUGraphStart(graph)
        guard status == noErr else {
            print("Failed to start AUGraph: \(status)")
            return
        }
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "loadSoundfont":
            guard let args = call.arguments as? [String: Any],
                  let path = args["path"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Path required", details: nil))
                return
            }
            result(loadSoundfont(path: path))

        case "unloadSoundfont":
            result(unloadSoundfont())

        case "playNote":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Arguments required", details: nil))
                return
            }
            let note = args["note"] as? Int ?? 60
            let velocity = args["velocity"] as? Int ?? 64
            let channel = args["channel"] as? Int ?? 0
            playNote(note: note, velocity: velocity, channel: channel)
            result(nil)

        case "stopNote":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Arguments required", details: nil))
                return
            }
            let note = args["note"] as? Int ?? 60
            let velocity = args["velocity"] as? Int ?? 64
            let channel = args["channel"] as? Int ?? 0
            stopNote(note: note, velocity: velocity, channel: channel)
            result(nil)

        case "changeProgram":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Arguments required", details: nil))
                return
            }
            let program = args["program"] as? Int ?? 0
            let channel = args["channel"] as? Int ?? 0
            changeProgram(program: program, channel: channel)
            result(nil)

        case "setVolume":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Arguments required", details: nil))
                return
            }
            let volume = args["volume"] as? Int ?? 100
            let channel = args["channel"] as? Int ?? 0
            setVolume(volume: volume, channel: channel)
            result(nil)

        case "setPan":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Arguments required", details: nil))
                return
            }
            let pan = args["pan"] as? Int ?? 64
            let channel = args["channel"] as? Int ?? 0
            setPan(pan: pan, channel: channel)
            result(nil)

        case "setReverb":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Arguments required", details: nil))
                return
            }
            let roomSize = args["roomSize"] as? Double ?? 0.2
            let damping = args["damping"] as? Double ?? 0.5
            let width = args["width"] as? Double ?? 0.5
            let level = args["level"] as? Double ?? 0.3
            setReverb(roomSize: roomSize, damping: damping, width: width, level: level)
            result(nil)

        case "setChorus":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Arguments required", details: nil))
                return
            }
            let voices = args["voices"] as? Int ?? 3
            let level = args["level"] as? Double ?? 0.5
            let speed = args["speed"] as? Double ?? 0.3
            let depth = args["depth"] as? Double ?? 0.8
            setChorus(voices: voices, level: level, speed: speed, depth: depth)
            result(nil)

        case "stopAllNotes":
            stopAllNotes()
            result(nil)

        case "resetAllControllers":
            resetAllControllers()
            result(nil)

        case "sendControlChange":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Arguments required", details: nil))
                return
            }
            let controller = args["controller"] as? Int ?? 0
            let value = args["value"] as? Int ?? 0
            let channel = args["channel"] as? Int ?? 0
            sendControlChange(controller: controller, value: value, channel: channel)
            result(nil)

        case "sendPitchBend":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Arguments required", details: nil))
                return
            }
            let value = args["value"] as? Int ?? 0
            let channel = args["channel"] as? Int ?? 0
            sendPitchBend(value: value, channel: channel)
            result(nil)

        case "unmute":
            unmute()
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func loadSoundfont(path: String) -> Bool {
        guard let sampler = samplerUnit else {
            print("Sampler unit not initialized")
            return false
        }

        let soundfontURL = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: path) else {
            print("Soundfont file not found: \(path)")
            return false
        }

        // Load the soundfont
        let status = AudioUnitSetProperty(
            sampler,
            AudioUnitPropertyID(kMusicDeviceProperty_SoundBankURL),
            AudioUnitScope(kAudioUnitScope_Global),
            0,
            &soundfontURL as! UnsafeRawPointer,
            UInt32(MemoryLayout<URL>.size)
        )

        if status != noErr {
            print("Failed to load soundfont: \(status)")
            return false
        }

        soundfontLoaded = true
        print("Soundfont loaded successfully: \(path)")
        return true
    }

    private func unloadSoundfont() -> Bool {
        soundfontLoaded = false
        // Reset the sampler by stopping and restarting the graph
        if let graph = processingGraph {
            AUGraphStop(graph)
            AUGraphStart(graph)
        }
        return true
    }

    private func playNote(note: Int, velocity: Int, channel: Int) {
        guard soundfontLoaded, let sampler = samplerUnit else {
            print("No soundfont loaded")
            return
        }

        let noteCommand = UInt32(0x90 | (channel & 0x0F))
        let status = MusicDeviceMIDIEvent(
            sampler,
            noteCommand,
            UInt32(note & 0x7F),
            UInt32(velocity & 0x7F),
            0
        )

        if status != noErr {
            print("Failed to play note: \(status)")
        }
    }

    private func stopNote(note: Int, velocity: Int, channel: Int) {
        guard soundfontLoaded, let sampler = samplerUnit else { return }

        let noteCommand = UInt32(0x80 | (channel & 0x0F))
        MusicDeviceMIDIEvent(
            sampler,
            noteCommand,
            UInt32(note & 0x7F),
            UInt32(velocity & 0x7F),
            0
        )
    }

    private func changeProgram(program: Int, channel: Int) {
        guard soundfontLoaded, let sampler = samplerUnit else { return }

        let programCommand = UInt32(0xC0 | (channel & 0x0F))
        MusicDeviceMIDIEvent(
            sampler,
            programCommand,
            UInt32(program & 0x7F),
            0,
            0
        )
    }

    private func setVolume(volume: Int, channel: Int) {
        sendControlChange(controller: 7, value: volume, channel: channel)
    }

    private func setPan(pan: Int, channel: Int) {
        sendControlChange(controller: 10, value: pan, channel: channel)
    }

    private func setReverb(roomSize: Double, damping: Double, width: Double, level: Double) {
        // Set reverb level on all channels
        for ch in 0...15 {
            sendControlChange(controller: 91, value: Int(level * 127), channel: ch)
        }
    }

    private func setChorus(voices: Int, level: Double, speed: Double, depth: Double) {
        // Set chorus level on all channels
        for ch in 0...15 {
            sendControlChange(controller: 93, value: Int(level * 127), channel: ch)
        }
    }

    private func stopAllNotes() {
        guard soundfontLoaded else { return }

        for ch in 0...15 {
            sendControlChange(controller: 123, value: 0, channel: ch)
        }
    }

    private func resetAllControllers() {
        guard soundfontLoaded else { return }

        for ch in 0...15 {
            sendControlChange(controller: 121, value: 0, channel: ch)
        }
    }

    private func sendControlChange(controller: Int, value: Int, channel: Int) {
        guard soundfontLoaded, let sampler = samplerUnit else { return }

        let ccCommand = UInt32(0xB0 | (channel & 0x0F))
        MusicDeviceMIDIEvent(
            sampler,
            ccCommand,
            UInt32(controller & 0x7F),
            UInt32(value & 0x7F),
            0
        )
    }

    private func sendPitchBend(value: Int, channel: Int) {
        guard soundfontLoaded, let sampler = samplerUnit else { return }

        // Convert -8192 to 8191 range to 0-16383
        let bendValue = value + 8192
        let lsb = UInt32(bendValue & 0x7F)
        let msb = UInt32((bendValue >> 7) & 0x7F)

        let bendCommand = UInt32(0xE0 | (channel & 0x0F))
        MusicDeviceMIDIEvent(
            sampler,
            bendCommand,
            lsb,
            msb,
            0
        )
    }

    private func unmute() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            print("Audio session unmuted")
        } catch {
            print("Failed to unmute audio session: \(error)")
        }
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
