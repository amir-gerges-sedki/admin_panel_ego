import 'dart:async';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'web_file_picker_stub.dart';
import 'web_file_picker_stub.dart'
    if (dart.library.js_interop) 'web_file_picker_helper.dart' as web_picker;
export 'web_file_picker_stub.dart' show PickedFilePayload;

/// Centralized service for image picking and Firebase Storage upload across the EGO ecosystem
class FirebaseStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final ImagePicker _picker = ImagePicker();

  /// Ensures a valid, token-refreshed authenticated session is active before storage operations.
  static Future<void> _ensureAuth({bool forceRefresh = false}) async {
    try {
      if (forceRefresh) {
        await FirebaseAuth.instance.signOut();
      }

      User? user = FirebaseAuth.instance.currentUser;
      user ??= await FirebaseAuth.instance.authStateChanges().first;

      if (user == null) {
        final cred = await FirebaseAuth.instance.signInAnonymously();
        user = cred.user;
        debugPrint('🔑 [FirebaseStorage] Initialized anonymous auth session (uid: ${user?.uid})');
      }

      if (user != null) {
        try {
          await user.getIdToken(true);
        } catch (tokenErr) {
          debugPrint('⚠️ [FirebaseStorage] Token refresh failed, recreating session: $tokenErr');
          await FirebaseAuth.instance.signOut();
          final cred = await FirebaseAuth.instance.signInAnonymously();
          user = cred.user;
          await user?.getIdToken(true);
        }
      }
    } catch (e) {
      debugPrint('⚠️ [FirebaseStorage] Auth session error: $e');
      if (FirebaseAuth.instance.currentUser == null) {
        throw Exception(
          'فشل تسجيل الدخول التلقائي في Firebase Authentication.\n'
          'يُرجى التأكد من تفعيل "Anonymous Sign-in" من لوحة تحكم Firebase Console > Authentication > Sign-in method.'
        );
      }
    }
  }

  /// Uploads bytes to [ref] with automatic auth refresh & Web REST support.
  static Future<String> _putDataWithAuthRetry({
    required Reference ref,
    required Uint8List bytes,
    required String contentType,
    void Function(double progress)? onProgress,
  }) async {
    if (kIsWeb) {
      for (int attempt = 0; attempt < 2; attempt++) {
        try {
          onProgress?.call(0.25);
          await _ensureAuth(forceRefresh: attempt > 0);
          final url = await _uploadViaRestApi(
            bucket: ref.bucket,
            storagePath: ref.fullPath,
            bytes: bytes,
            contentType: contentType,
          );
          onProgress?.call(1.0);
          return url;
        } on FirebaseException catch (e) {
          if (e.code == 'unauthenticated' &&
              attempt == 0 &&
              !(e.message ?? '').contains('App Check')) {
            continue;
          }
          rethrow;
        }
      }
    }

    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        await _ensureAuth(forceRefresh: attempt > 0);
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
        return await completedSnapshot.ref.getDownloadURL();
      } on FirebaseException catch (e) {
        if (e.code == 'unauthenticated') {
          if (attempt == 0) {
            debugPrint('🔄 [FirebaseStorage] Received unauthenticated; refreshing auth session and retrying...');
            continue;
          }
          debugPrint('🔄 [FirebaseStorage] SDK still unauthenticated; using authenticated REST upload fallback...');
          final url = await _uploadViaRestApi(
            bucket: ref.bucket,
            storagePath: ref.fullPath,
            bytes: bytes,
            contentType: contentType,
          );
          onProgress?.call(1.0);
          return url;
        }
        rethrow;
      }
    }
    throw FirebaseException(
      plugin: 'firebase_storage',
      code: 'unauthenticated',
      message: 'User is not authenticated for Firebase Storage.',
    );
  }

  /// Direct authenticated REST upload to Firebase Storage JSON API using the active Firebase ID token.
  static Future<String> _uploadViaRestApi({
    required String bucket,
    required String storagePath,
    required Uint8List bytes,
    required String contentType,
  }) async {
    await _ensureAuth();
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken(true);
    if (idToken == null || idToken.isEmpty) {
      throw FirebaseException(
        plugin: 'firebase_storage',
        code: 'unauthenticated',
        message: 'Could not obtain Firebase Auth ID token.',
      );
    }

    final cleanBucket = bucket.replaceFirst('gs://', '').trim();
    final encodedPath = Uri.encodeComponent(storagePath);
    final uri = Uri.parse(
      'https://firebasestorage.googleapis.com/v0/b/$cleanBucket/o?uploadType=media&name=$encodedPath',
    );

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Firebase $idToken',
        'Content-Type': contentType,
      },
      body: bytes,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final name = (data['name'] ?? storagePath).toString();
      final rawTokens = (data['downloadTokens'] ?? '').toString();
      final token = rawTokens.split(',').first.trim();
      final encodedName = Uri.encodeComponent(name);
      if (token.isNotEmpty) {
        return 'https://firebasestorage.googleapis.com/v0/b/$cleanBucket/o/$encodedName?alt=media&token=$token';
      }
      return 'https://firebasestorage.googleapis.com/v0/b/$cleanBucket/o/$encodedName?alt=media';
    }

    throw FirebaseException(
      plugin: 'firebase_storage',
      code: response.statusCode == 401 ? 'unauthenticated' : 'upload-failed',
      message: 'REST upload failed (${response.statusCode}): ${response.body}',
    );
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
      final String downloadUrl = await _putDataWithAuthRetry(
        ref: ref,
        bytes: bytes,
        contentType: contentType,
        onProgress: onProgress,
      );
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
      final String storagePath = '$folder/$fileName';
      final Reference ref = _storage.ref().child(storagePath);
      return await _putDataWithAuthRetry(
        ref: ref,
        bytes: bytes,
        contentType: contentType,
      );
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
        final url = await _putDataWithAuthRetry(
          ref: ref,
          bytes: payload.bytes,
          contentType: _resolveContentType(ext),
        );
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
