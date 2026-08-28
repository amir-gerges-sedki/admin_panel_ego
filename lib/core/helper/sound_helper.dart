import 'sound_helper_stub.dart'
    if (dart.library.js_interop) 'sound_helper_web.dart';

/// Central Sound and Audio Effects Helper
class SoundHelper {
  SoundHelper._();

  /// Plays a sweet, audible push notification chime & sound
  static void playNotificationSound() {
    playWebAudioChime();
  }
}
