import 'dart:async';
import 'package:flutter/services.dart';

enum VolumeButton { up, down }

/// Listens for physical volume button presses via platform channels.
/// Triggers a capture only on a **down → up** combo within [_comboWindow].
///
/// Lock-screen support:
/// - Android: Uses a BroadcastReceiver for VOLUME_CHANGED_ACTION.
/// - iOS: Uses AVAudioSession KVO with background audio mode.
class VolumeButtonListener {
  static const _methodChannel =
      MethodChannel('com.example.product_engineer_task/volume_buttons');
  static const _eventChannel =
      EventChannel('com.example.product_engineer_task/volume_button_events');

  StreamSubscription? _subscription;

  /// How fast the second press must follow the first.
  static const _comboWindow = Duration(milliseconds: 600);

  bool _waitingForUp = false;
  Timer? _comboTimer;

  void startListening(void Function(VolumeButton) onPressed) {
    _methodChannel.invokeMethod('startListening');
    _subscription = _eventChannel.receiveBroadcastStream().listen((event) {
      if (event == 'down') {
        // First press: start waiting for volume-up.
        _waitingForUp = true;
        _comboTimer?.cancel();
        _comboTimer = Timer(_comboWindow, () {
          _waitingForUp = false;
        });
      } else if (event == 'up' && _waitingForUp) {
        // Second press within window — combo detected!
        _waitingForUp = false;
        _comboTimer?.cancel();
        onPressed(VolumeButton.up);
      }
    });
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _comboTimer?.cancel();
    _comboTimer = null;
    _waitingForUp = false;
    _methodChannel.invokeMethod('stopListening');
  }

  /// Triggers a native vibration (works on lock screen).
  static Future<void> vibrate() async {
    await _methodChannel.invokeMethod('vibrate');
  }
}
