import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

void playWebAudioChime() {
  try {
    SystemSound.play(SystemSoundType.click);
  } catch (e) {
    debugPrint('Sound note: $e');
  }
}
