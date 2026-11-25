import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'web_file_picker_stub.dart';
import 'web_file_picker_stub.dart'
    if (dart.library.js_interop) 'web_file_picker_helper.dart' as web_picker;
export 'web_file_picker_stub.dart' show PickedFilePayload;

/// Centralized service for image picking and Firebase Storage upload across the EGO ecosystem
class FirebaseStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final ImagePicker _picker = ImagePicker();

  /// Ensures an authenticated session is active before performing storage operations
  static Future<void> _ensureAuth() async {
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
        debugPrint('🔑 [FirebaseStorage] Initialized anonymous auth session for storage upload');
      }
    } catch (e) {
      debugPrint('⚠️ [FirebaseStorage] Auth check/anonymous sign-in notice: $e');
    }
  }

  /// Prompts user to pick an image from device gallery/storage and uploads directly to Firebase Storage.
  /// Works reliably on Windows Desktop, Web, Android & iOS.
  /// Returns the permanent HTTPS download URL, or null if cancelled.
  static Future<String?> pickAndUploadImage({
    required String folder, // e.g. 'products', 'brands', 'banners', 'variations'
    String? customFileName,
    void Function(double progress)? onProgress,
  }) async {
    try {
      await _ensureAuth();
      Uint8List? bytes;
      String? originalFileName;

      // 1. Try with FilePicker first (native file dialog on Windows/macOS/Linux/Web/Mobile)
      try {
        final PlatformFile? picked = await FilePicker.pickFile(
          type: FileType.custom,
          allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'gif', 'svg'],
        );

        if (picked != null) {
          bytes = await picked.xFile.readAsBytes();
          originalFileName = picked.name;
        } else {
          return null; // User cancelled
        }
      } catch (e) {
        debugPrint('⚠️ [FirebaseStorage] FilePicker note, attempting ImagePicker fallback: $e');
        // 2. Fallback to ImagePicker
        try {
          final XFile? file = await _picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 85,
          );
          if (file != null) {
            bytes = await file.readAsBytes();
            originalFileName = file.name;
          } else {
            return null;
          }
        } catch (e2) {
          debugPrint('⚠️ [FirebaseStorage] ImagePicker fallback note: $e2');
          if (kIsWeb) {
            final webFile = await web_picker.pickFileFromWeb();
            if (webFile != null) {
              bytes = webFile.bytes;
              originalFileName = webFile.name;
            } else {
              return null;
            }
          } else {
            rethrow;
          }
        }
      }

      if (bytes.isEmpty) return null;

      final String extension = _resolveExtension(originalFileName);
      final String fileName = customFileName != null && customFileName.isNotEmpty
          ? '$customFileName.$extension'
          : '${DateTime.now().millisecondsSinceEpoch}_${_sanitize(originalFileName)}.$extension';

      final String storagePath = '$folder/$fileName';
      final Reference ref = _storage.ref().child(storagePath);

      final String contentType = _resolveContentType(extension);
      final UploadTask uploadTask = ref.putData(
        bytes,
        SettableMetadata(contentType: contentType),
      );

      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          if (snapshot.totalBytes > 0) {
            final double prog = snapshot.bytesTransferred / snapshot.totalBytes;
            onProgress(prog.clamp(0.0, 1.0));
          }
        });
      }

      final TaskSnapshot completedSnapshot = await uploadTask;
      final String downloadUrl = await completedSnapshot.ref.getDownloadURL();
      debugPrint('📸 [FirebaseStorage] Uploaded successfully to $storagePath -> $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('⚠️ [FirebaseStorage Error] pickAndUploadImage failed: $e');
      rethrow;
    }
  }

  /// Uploads raw image bytes directly to Firebase Storage.
  static Future<String> uploadBytes({
    required Uint8List bytes,
    required String folder,
    required String fileName,
    String contentType = 'image/jpeg',
  }) async {
    try {
      await _ensureAuth();
      final String storagePath = '$folder/$fileName';
      final Reference ref = _storage.ref().child(storagePath);

      final UploadTask uploadTask = ref.putData(
        bytes,
        SettableMetadata(contentType: contentType),
      );

      final TaskSnapshot completedSnapshot = await uploadTask;
      final String downloadUrl = await completedSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('⚠️ [FirebaseStorage Error] uploadBytes failed: $e');
      rethrow;
    }
  }

  /// Prompts user to pick multiple images and uploads them all in batch.
  /// Returns a list of uploaded download URLs.
  static Future<List<String>> pickAndUploadMultipleImages({
    required String folder,
    void Function(int completed, int total)? onProgress,
  }) async {
    try {
      await _ensureAuth();
      final List<PickedFilePayload> payloads = [];

      // 1. Try with FilePicker first
      try {
        final List<PlatformFile> picked = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'gif', 'svg'],
        );

        if (picked.isNotEmpty) {
          for (final f in picked) {
            final b = await f.xFile.readAsBytes();
            if (b.isNotEmpty) {
              payloads.add(PickedFilePayload(bytes: b, name: f.name));
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ [FirebaseStorage] FilePicker pickMultiple failed, attempting fallback: $e');
      }

      // 2. Fallback to ImagePicker if FilePicker was empty
      if (payloads.isEmpty) {
        try {
          final List<XFile> files = await _picker.pickMultiImage(imageQuality: 85);
          for (final f in files) {
            final b = await f.readAsBytes();
            payloads.add(PickedFilePayload(bytes: b, name: f.name));
          }
        } catch (e) {
          debugPrint('⚠️ [FirebaseStorage] pickMultiImage failed, attempting Web fallback: $e');
          if (kIsWeb) {
            final webFiles = await web_picker.pickMultipleFilesFromWeb();
            payloads.addAll(webFiles);
          }
        }
      }

      if (payloads.isEmpty) return [];

      final List<String> urls = [];
      for (int i = 0; i < payloads.length; i++) {
        final payload = payloads[i];
        final String ext = _resolveExtension(payload.name);
        final String fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.$ext';

        final String storagePath = '$folder/$fileName';
        final Reference ref = _storage.ref().child(storagePath);
        final UploadTask task = ref.putData(
          payload.bytes,
          SettableMetadata(contentType: _resolveContentType(ext)),
        );

        final snap = await task;
        final url = await snap.ref.getDownloadURL();
        urls.add(url);

        if (onProgress != null) {
          onProgress(i + 1, payloads.length);
        }
      }

      return urls;
    } catch (e) {
      debugPrint('⚠️ [FirebaseStorage Error] pickAndUploadMultipleImages failed: $e');
      rethrow;
    }
  }

  /// Deletes an image from storage if it's hosted on Firebase Storage
  static Future<void> deleteImageByUrl(String url) async {
    if (!url.contains('firebasestorage.googleapis.com')) return;
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
      debugPrint('🗑️ [FirebaseStorage] Deleted image: $url');
    } catch (e) {
      debugPrint('⚠️ [FirebaseStorage] Delete ignored/failed: $e');
    }
  }

  static String _resolveExtension(String fileName) {
    if (fileName.contains('.')) {
      final ext = fileName.split('.').last.toLowerCase().trim();
      if (['jpg', 'jpeg', 'png', 'webp', 'gif', 'svg'].contains(ext)) {
        return ext;
      }
    }
    return 'jpg';
  }

  static String _resolveContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'svg':
        return 'image/svg+xml';
      default:
        return 'image/jpeg';
    }
  }

  static String _sanitize(String name) {
    return name
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
  }
}
