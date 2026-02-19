package com.example.product_engineer_task

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

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_METHOD)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startListening" -> {
                        isListening = true
                        result.success(null)
                    }
                    "stopListening" -> {
                        isListening = false
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

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (isListening) {
            when (keyCode) {
                KeyEvent.KEYCODE_VOLUME_UP -> {
                    eventSink?.success("up")
                    return true // consume event — volume won't change
                }
                KeyEvent.KEYCODE_VOLUME_DOWN -> {
                    eventSink?.success("down")
                    return true
                }
            }
        }
        return super.onKeyDown(keyCode, event)
    }
}
