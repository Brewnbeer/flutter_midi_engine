package com.midiengine.flutter_midi_engine

import android.content.Context
import android.media.AudioManager
import android.media.SoundPool
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import org.billthefarmer.mididriver.MidiDriver
import java.io.File

/** FlutterMidiEnginePlugin */
class FlutterMidiEnginePlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var midiDriver: MidiDriver? = null
    private var soundfontLoaded = false

    companion object {
        private const val TAG = "FlutterMidiEngine"
        private const val CHANNEL_NAME = "flutter_midi_engine"

        // MIDI message constants
        private const val NOTE_OFF = 0x80
        private const val NOTE_ON = 0x90
        private const val CONTROL_CHANGE = 0xB0
        private const val PROGRAM_CHANGE = 0xC0
        private const val PITCH_BEND = 0xE0

        // Controller numbers
        private const val CC_VOLUME = 7
        private const val CC_PAN = 10
        private const val CC_REVERB = 91
        private const val CC_CHORUS = 93
        private const val CC_ALL_NOTES_OFF = 123
        private const val CC_RESET_ALL_CONTROLLERS = 121
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        try {
            when (call.method) {
                "loadSoundfont" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        result.success(loadSoundfont(path))
                    } else {
                        result.error("INVALID_ARGUMENT", "Path cannot be null", null)
                    }
                }
                "unloadSoundfont" -> {
                    result.success(unloadSoundfont())
                }
                "playNote" -> {
                    val note = call.argument<Int>("note") ?: 60
                    val velocity = call.argument<Int>("velocity") ?: 64
                    val channel = call.argument<Int>("channel") ?: 0
                    playNote(note, velocity, channel)
                    result.success(null)
                }
                "stopNote" -> {
                    val note = call.argument<Int>("note") ?: 60
                    val velocity = call.argument<Int>("velocity") ?: 64
                    val channel = call.argument<Int>("channel") ?: 0
                    stopNote(note, velocity, channel)
                    result.success(null)
                }
                "changeProgram" -> {
                    val program = call.argument<Int>("program") ?: 0
                    val channel = call.argument<Int>("channel") ?: 0
                    changeProgram(program, channel)
                    result.success(null)
                }
                "setVolume" -> {
                    val volume = call.argument<Int>("volume") ?: 100
                    val channel = call.argument<Int>("channel") ?: 0
                    setVolume(volume, channel)
                    result.success(null)
                }
                "setPan" -> {
                    val pan = call.argument<Int>("pan") ?: 64
                    val channel = call.argument<Int>("channel") ?: 0
                    setPan(pan, channel)
                    result.success(null)
                }
                "setReverb" -> {
                    val roomSize = call.argument<Double>("roomSize") ?: 0.2
                    val damping = call.argument<Double>("damping") ?: 0.5
                    val width = call.argument<Double>("width") ?: 0.5
                    val level = call.argument<Double>("level") ?: 0.3
                    setReverb(roomSize, damping, width, level)
                    result.success(null)
                }
                "setChorus" -> {
                    val voices = call.argument<Int>("voices") ?: 3
                    val level = call.argument<Double>("level") ?: 0.5
                    val speed = call.argument<Double>("speed") ?: 0.3
                    val depth = call.argument<Double>("depth") ?: 0.8
                    setChorus(voices, level, speed, depth)
                    result.success(null)
                }
                "stopAllNotes" -> {
                    stopAllNotes()
                    result.success(null)
                }
                "resetAllControllers" -> {
                    resetAllControllers()
                    result.success(null)
                }
                "sendControlChange" -> {
                    val controller = call.argument<Int>("controller") ?: 0
                    val value = call.argument<Int>("value") ?: 0
                    val channel = call.argument<Int>("channel") ?: 0
                    sendControlChange(controller, value, channel)
                    result.success(null)
                }
                "sendPitchBend" -> {
                    val value = call.argument<Int>("value") ?: 0
                    val channel = call.argument<Int>("channel") ?: 0
                    sendPitchBend(value, channel)
                    result.success(null)
                }
                "unmute" -> {
                    // Android doesn't need unmute like iOS
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error handling method ${call.method}", e)
            result.error("ERROR", e.message, null)
        }
    }

    private fun loadSoundfont(path: String): Boolean {
        return try {
            val file = File(path)
            if (!file.exists()) {
                Log.e(TAG, "Soundfont file not found: $path")
                return false
            }

            // Initialize MIDI driver if not already done
            if (midiDriver == null) {
                midiDriver = MidiDriver()
                midiDriver?.start()
            }

            // Load soundfont using MidiDriver's config method
            val config = byteArrayOf(
                0xF0.toByte(), // SysEx start
                0x7D.toByte(), // Non-real time
                0x00.toByte(), // Device ID
                0x00.toByte(), // Sub ID
                path.toByteArray().size.toByte() // Length
            ) + path.toByteArray() + byteArrayOf(0xF7.toByte()) // SysEx end

            midiDriver?.config(path)
            soundfontLoaded = true

            Log.i(TAG, "Soundfont loaded successfully: $path")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to load soundfont", e)
            false
        }
    }

    private fun unloadSoundfont(): Boolean {
        return try {
            midiDriver?.stop()
            midiDriver = null
            soundfontLoaded = false
            Log.i(TAG, "Soundfont unloaded")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to unload soundfont", e)
            false
        }
    }

    private fun playNote(note: Int, velocity: Int, channel: Int) {
        if (!soundfontLoaded) {
            Log.w(TAG, "No soundfont loaded, cannot play note")
            return
        }

        val event = byteArrayOf(
            (NOTE_ON or (channel and 0x0F)).toByte(),
            (note and 0x7F).toByte(),
            (velocity and 0x7F).toByte()
        )
        midiDriver?.write(event)
    }

    private fun stopNote(note: Int, velocity: Int, channel: Int) {
        if (!soundfontLoaded) return

        val event = byteArrayOf(
            (NOTE_OFF or (channel and 0x0F)).toByte(),
            (note and 0x7F).toByte(),
            (velocity and 0x7F).toByte()
        )
        midiDriver?.write(event)
    }

    private fun changeProgram(program: Int, channel: Int) {
        if (!soundfontLoaded) return

        val event = byteArrayOf(
            (PROGRAM_CHANGE or (channel and 0x0F)).toByte(),
            (program and 0x7F).toByte()
        )
        midiDriver?.write(event)
    }

    private fun setVolume(volume: Int, channel: Int) {
        sendControlChange(CC_VOLUME, volume, channel)
    }

    private fun setPan(pan: Int, channel: Int) {
        sendControlChange(CC_PAN, pan, channel)
    }

    private fun setReverb(roomSize: Double, damping: Double, width: Double, level: Double) {
        // Set reverb level on all channels
        for (ch in 0..15) {
            sendControlChange(CC_REVERB, (level * 127).toInt(), ch)
        }
        // Note: FluidSynth's reverb parameters (room size, damping, width)
        // would need SysEx messages or a custom FluidSynth build
    }

    private fun setChorus(voices: Int, level: Double, speed: Double, depth: Double) {
        // Set chorus level on all channels
        for (ch in 0..15) {
            sendControlChange(CC_CHORUS, (level * 127).toInt(), ch)
        }
        // Note: FluidSynth's chorus parameters would need SysEx messages
    }

    private fun stopAllNotes() {
        if (!soundfontLoaded) return

        for (ch in 0..15) {
            sendControlChange(CC_ALL_NOTES_OFF, 0, ch)
        }
    }

    private fun resetAllControllers() {
        if (!soundfontLoaded) return

        for (ch in 0..15) {
            sendControlChange(CC_RESET_ALL_CONTROLLERS, 0, ch)
        }
    }

    private fun sendControlChange(controller: Int, value: Int, channel: Int) {
        if (!soundfontLoaded) return

        val event = byteArrayOf(
            (CONTROL_CHANGE or (channel and 0x0F)).toByte(),
            (controller and 0x7F).toByte(),
            (value and 0x7F).toByte()
        )
        midiDriver?.write(event)
    }

    private fun sendPitchBend(value: Int, channel: Int) {
        if (!soundfontLoaded) return

        // Convert -8192 to 8191 range to 0-16383
        val bendValue = value + 8192
        val lsb = bendValue and 0x7F
        val msb = (bendValue shr 7) and 0x7F

        val event = byteArrayOf(
            (PITCH_BEND or (channel and 0x0F)).toByte(),
            lsb.toByte(),
            msb.toByte()
        )
        midiDriver?.write(event)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        unloadSoundfont()
    }
}
