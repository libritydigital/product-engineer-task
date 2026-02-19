import 'dart:async';
import 'package:flutter/services.dart';

enum VolumeButton { up, down }

/// Listens for physical volume button presses via platform channels.
/// On Android: intercepts key events (prevents volume change while active).
/// On iOS: observes AVAudioSession outputVolume changes (works with headphones).
class VolumeButtonListener {
  static const _methodChannel =
      MethodChannel('com.example.product_engineer_task/volume_buttons');
  static const _eventChannel =
      EventChannel('com.example.product_engineer_task/volume_button_events');

  StreamSubscription? _subscription;
  Timer? _debounce;
  static const _debounceDuration = Duration(milliseconds: 500);

  void startListening(void Function(VolumeButton) onPressed) {
    _methodChannel.invokeMethod('startListening');
    _subscription = _eventChannel.receiveBroadcastStream().listen((event) {
      // Debounce to avoid double-captures from quick presses.
      if (_debounce?.isActive ?? false) return;
      _debounce = Timer(_debounceDuration, () {});

      if (event == 'up') {
        onPressed(VolumeButton.up);
      } else if (event == 'down') {
        onPressed(VolumeButton.down);
      }
    });
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _debounce?.cancel();
    _debounce = null;
    _methodChannel.invokeMethod('stopListening');
  }
}
