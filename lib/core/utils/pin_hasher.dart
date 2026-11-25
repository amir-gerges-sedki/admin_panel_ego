import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Secure utility for hashing and verifying staff PIN codes using SHA-256 with salt.
class PinHasher {
  static const String _salt = 'ego_vape_pos_salt_2026_#';

  /// Generates a SHA-256 hash string from a 4-6 digit PIN
  static String hashPin(String pin) {
    final clean = pin.trim();
    if (clean.isEmpty) return '';
    final bytes = utf8.encode('$_salt$clean$_salt');
    return sha256.convert(bytes).toString();
  }

  /// Verifies a candidate plain PIN against a stored hash or legacy plain string
  static bool verifyPin({
    required String candidatePin,
    required String storedHashOrPlain,
  }) {
    final cleanCandidate = candidatePin.trim();
    final cleanStored = storedHashOrPlain.trim();

    if (cleanCandidate.isEmpty || cleanStored.isEmpty) return false;

    // 1. Check against computed SHA-256 hash
    final computedHash = hashPin(cleanCandidate);
    if (computedHash == cleanStored) return true;

    // 2. Backward compatibility fallback for legacy unhashed PINs
    if (cleanCandidate == cleanStored) return true;

    return false;
  }

  /// Checks whether a stored string is already a 64-character hex SHA-256 hash
  static bool isHashed(String value) {
    final clean = value.trim();
    if (clean.length != 64) return false;
    return RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(clean);
  }
}
