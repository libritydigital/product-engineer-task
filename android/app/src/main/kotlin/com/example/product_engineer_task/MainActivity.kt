package com.example.product_engineer_task

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioManager
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL_METHOD = "com.example.product_engineer_task/volume_buttons"
    private val CHANNEL_EVENT = "com.example.product_engineer_task/volume_button_events"

    private var eventSink: EventChannel.EventSink? = null
    private var isListening = false
    private var lastVolume: Int = -1
    private var volumeReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_METHOD)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startListening" -> {
                        startVolumeListener()
                        result.success(null)
                    }
                    "stopListening" -> {
                        stopVolumeListener()
                        result.success(null)
                    }
                    "vibrate" -> {
                        triggerVibration()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_EVENT)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    eventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })
    }

    // ── BroadcastReceiver for lock-screen volume detection ──

    private fun startVolumeListener() {
        if (isListening) return
        isListening = true

        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        lastVolume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)

        volumeReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (!isListening) return
                val audioMgr = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                val currentVolume = audioMgr.getStreamVolume(AudioManager.STREAM_MUSIC)

                if (currentVolume != lastVolume) {
                    val direction = if (currentVolume > lastVolume) "up" else "down"
                    lastVolume = currentVolume
                    eventSink?.success(direction)
                }
            }
        }

        registerReceiver(
            volumeReceiver,
            IntentFilter("android.media.VOLUME_CHANGED_ACTION")
        )
    }

    private fun stopVolumeListener() {
        if (!isListening) return
        isListening = false
        volumeReceiver?.let {
            unregisterReceiver(it)
            volumeReceiver = null
        }
    }

    // ── Native vibration ──

    private fun triggerVibration() {
        val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val mgr = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            mgr.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(
                VibrationEffect.createOneShot(100, VibrationEffect.DEFAULT_AMPLITUDE)
            )
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(100)
        }
    }

    // ── onKeyDown fallback for when Activity is focused ──
    // When focused, this fires and consumes the event (volume doesn't change),
    // so the BroadcastReceiver won't fire — no duplicates.

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (isListening) {
            when (keyCode) {
                KeyEvent.KEYCODE_VOLUME_UP -> {
                    eventSink?.success("up")
                    return true // consume — volume won't change
                }
                KeyEvent.KEYCODE_VOLUME_DOWN -> {
                    eventSink?.success("down")
                    return true
                }
            }
        }
        return super.onKeyDown(keyCode, event)
    }

    override fun onDestroy() {
        stopVolumeListener()
        super.onDestroy()
    }
}
