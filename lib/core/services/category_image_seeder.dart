import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'firebase_service.dart';

/// Seeds Firestore Categories with EGO-branded category images from the internet.
///
/// Each category has a pre-configured image URL from Unsplash (free to use).
/// Call [seedAllDefaults] to automatically download images from the internet,
/// upload them to Firebase Storage, and update Firestore Categories.
class CategoryImageSeeder {
  CategoryImageSeeder._();

  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Pre-configured EGO category images — real vape product photos from the internet.
  /// Each image shows the actual product type (liquid bottle, pod device, coils, accessories).
  static const Map<String, _CategoryImageConfig> _categoryImages = {
    // E-Liquids: actual e-liquid / vape juice bottles product photo
    'CAT_LIQUIDS': _CategoryImageConfig(
      name: 'E-Liquids (سوائل إلكترونية)',
      fileName: 'ego_liquids.jpg',
      imageUrl:
          'https://images.unsplash.com/photo-1557452997-d0f87f6c1230?w=600&q=80&fit=crop',
    ),
    // Devices & Mods: actual vape pod system / mod device
    'CAT_HARDWARE': _CategoryImageConfig(
      name: 'Devices & Mods (أجهزة ومودات)',
      fileName: 'ego_devices.jpg',
      imageUrl:
          'https://images.unsplash.com/photo-1567922045116-2a00fae2ed03?w=600&q=80&fit=crop',
    ),
    // Coils & Cartridges: vape coils and pod cartridge product
    'CAT_COILS_PODS': _CategoryImageConfig(
      name: 'Coils & Cartridges (كويلات وكارتردج)',
      fileName: 'ego_coils_pods.jpg',
      imageUrl:
          'https://images.unsplash.com/photo-1585386959984-a4155224a1ad?w=600&q=80&fit=crop',
    ),
    // Accessories: vape accessories / batteries / tools
    'CAT_ACCESSORIES': _CategoryImageConfig(
      name: 'Accessories (إكسسوارات)',
      fileName: 'ego_accessories.jpg',
      imageUrl:
          'https://images.unsplash.com/photo-1527613426441-4da17471b66d?w=600&q=80&fit=crop',
    ),
  };

  /// 🚀 One-click: Seeds ALL categories with default internet images.
  ///
  /// Downloads each image from the internet → uploads to Firebase Storage →
  /// updates Firestore Categories document with the Firebase Storage URL.
  ///
  /// Returns a map of {categoryId: result} where result is either
  /// the download URL on success, or an error message.
  static Future<Map<String, String>> seedAllDefaults() async {
    final Map<String, String> results = {};

    for (final entry in _categoryImages.entries) {
      final categoryId = entry.key;
      final config = entry.value;

      try {
        debugPrint('📥 Downloading image for ${config.name}...');
        final url = await seedCategoryImageFromUrl(
          categoryId: categoryId,
          sourceUrl: config.imageUrl,
        );
        results[categoryId] = url;
        debugPrint('✅ ${config.name} → $url');
      } catch (e) {
        debugPrint('❌ Failed ${config.name}: $e');

        // Fallback: save the internet URL directly if upload fails
        try {
          await setCategoryImageUrl(
            categoryId: categoryId,
            imageUrl: config.imageUrl,
          );
          results[categoryId] = config.imageUrl;
          debugPrint('⚠️ ${config.name}: saved direct URL as fallback');
        } catch (e2) {
          results[categoryId] = 'ERROR: $e2';
        }
      }
    }

    return results;
  }

  /// 🚀 One-click: Sets ALL categories with default internet image URLs directly.
  ///
  /// This is faster than [seedAllDefaults] because it skips Firebase Storage
  /// upload and saves the Unsplash URL directly to Firestore.
  static Future<Map<String, String>> seedAllDirectDefaults() async {
    final Map<String, String> results = {};

    for (final entry in _categoryImages.entries) {
      try {
        await setCategoryImageUrl(
          categoryId: entry.key,
          imageUrl: entry.value.imageUrl,
        );
        results[entry.key] = entry.value.imageUrl;
      } catch (e) {
        results[entry.key] = 'ERROR: $e';
      }
    }

    return results;
  }

  /// Seeds a single category with the given [imageBytes].
  /// Uploads to Firebase Storage and updates Firestore.
  static Future<String> seedCategoryImage({
    required String categoryId,
    required Uint8List imageBytes,
    String contentType = 'image/jpeg',
  }) async {
    final config = _categoryImages[categoryId];
    final fileName = config?.fileName ?? '${categoryId.toLowerCase()}.jpg';

    try {
      // 1. Upload to Firebase Storage
      final ref = _storage.ref().child('categories/$fileName');
      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'categoryId': categoryId,
          'uploadedBy': 'admin_panel_ego',
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      await ref.putData(imageBytes, metadata);
      final downloadUrl = await ref.getDownloadURL();

      // 2. Update Firestore Categories document
      await _updateFirestoreCategory(categoryId, downloadUrl, config?.name);

      debugPrint('✅ Category $categoryId image uploaded → $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Failed to seed category $categoryId image: $e');
      rethrow;
    }
  }

  /// Seeds a category image from an external URL.
  /// Downloads the image first, then uploads to Firebase Storage.
  static Future<String> seedCategoryImageFromUrl({
    required String categoryId,
    required String sourceUrl,
  }) async {
    try {
      // Download image bytes from external URL
      final response = await http.get(Uri.parse(sourceUrl));
      if (response.statusCode != 200) {
        throw Exception(
          'Failed to download image from $sourceUrl (HTTP ${response.statusCode})',
        );
      }

      final contentType = response.headers['content-type'] ?? 'image/jpeg';
      return seedCategoryImage(
        categoryId: categoryId,
        imageBytes: response.bodyBytes,
        contentType: contentType,
      );
    } catch (e) {
      debugPrint('❌ Failed to download and seed image for $categoryId: $e');
      rethrow;
    }
  }

  /// Directly update the `image` field on Firestore for a category,
  /// without uploading to Firebase Storage (if you already have
  /// the final hosted URL).
  static Future<void> setCategoryImageUrl({
    required String categoryId,
    required String imageUrl,
  }) async {
    await _updateFirestoreCategory(
      categoryId,
      imageUrl,
      _categoryImages[categoryId]?.name,
    );
    debugPrint('✅ Category $categoryId image URL set → $imageUrl');
  }

  /// Batch-seed all core categories from a map of {categoryId: imageUrl}.
  static Future<Map<String, String>> seedAllFromUrls(
    Map<String, String> categoryUrls,
  ) async {
    final Map<String, String> results = {};
    for (final entry in categoryUrls.entries) {
      try {
        final url = await seedCategoryImageFromUrl(
          categoryId: entry.key,
          sourceUrl: entry.value,
        );
        results[entry.key] = url;
      } catch (e) {
        debugPrint('⚠️ Skipping ${entry.key}: $e');
        results[entry.key] = 'ERROR: $e';
      }
    }
    return results;
  }

  /// Batch-seed all categories by directly setting URLs.
  static Future<void> seedAllDirectUrls(
    Map<String, String> categoryUrls,
  ) async {
    for (final entry in categoryUrls.entries) {
      try {
        await setCategoryImageUrl(
          categoryId: entry.key,
          imageUrl: entry.value,
        );
      } catch (e) {
        debugPrint('⚠️ Skipping ${entry.key}: $e');
      }
    }
  }

  /// Updates the Firestore category document with the image URL.
  /// Creates the document if it doesn't exist.
  static Future<void> _updateFirestoreCategory(
    String categoryId,
    String imageUrl,
    String? categoryName,
  ) async {
    final docRef = FirebaseService.categoriesCollection.doc(categoryId);
    final doc = await docRef.get();

    if (doc.exists) {
      // Update existing document
      await docRef.update({
        'image': imageUrl,
        'Image': imageUrl,
        'imageUrl': imageUrl,
      });
    } else {
      // Create with image if the document doesn't exist
      await docRef.set({
        'id': categoryId,
        'name': categoryName ?? categoryId,
        'image': imageUrl,
        'Image': imageUrl,
        'imageUrl': imageUrl,
        'isFeatured': true,
        'productsCount': 0,
      });
    }
  }

  /// Returns the list of supported category IDs.
  static List<String> get supportedCategoryIds => _categoryImages.keys.toList();

  /// Returns the display name for a category ID.
  static String getCategoryName(String categoryId) =>
      _categoryImages[categoryId]?.name ?? categoryId;

  /// Returns the default image URL for a category.
  static String getDefaultImageUrl(String categoryId) =>
      _categoryImages[categoryId]?.imageUrl ?? '';
}

class _CategoryImageConfig {
  final String name;
  final String fileName;
  final String imageUrl;

  const _CategoryImageConfig({
    required this.name,
    required this.fileName,
    required this.imageUrl,
  });
}
