import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

@JS('playNotificationChime')
external void _playNotificationChime();

void playWebAudioChime() {
  try {
    SystemSound.play(SystemSoundType.click);
  } catch (_) {}

  try {
    _playNotificationChime();
  } catch (e) {
    debugPrint('Web audio chime note: $e');
  }
}
