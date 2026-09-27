import 'package:flutter/material.dart';

/// Core product category classifications for EGO Vaping & Lifestyle store.
enum ProductCategoryType {
  liquid,
  disposable,
  device,
  pod,
  coil,
  accessory;

  static List<ProductCategoryType> get visibleTypes => const [
    ProductCategoryType.liquid,
    ProductCategoryType.disposable,
    ProductCategoryType.device,
    ProductCategoryType.pod,
    ProductCategoryType.accessory,
  ];

  String get id {
    switch (this) {
      case ProductCategoryType.liquid:
        return 'CAT_LIQUIDS';
      case ProductCategoryType.disposable:
        return 'CAT_DISPOSABLES';
      case ProductCategoryType.device:
        return 'CAT_HARDWARE';
      case ProductCategoryType.pod:
      case ProductCategoryType.coil:
        return 'CAT_COILS_PODS';
      case ProductCategoryType.accessory:
        return 'CAT_ACCESSORIES';
    }
  }

  String get displayName {
    switch (this) {
      case ProductCategoryType.liquid:
        return 'E-Liquids';
      case ProductCategoryType.disposable:
        return 'Disposables';
      case ProductCategoryType.device:
        return 'Devices & Mods';
      case ProductCategoryType.pod:
      case ProductCategoryType.coil:
        return 'Coils & Cartridges';
      case ProductCategoryType.accessory:
        return 'Accessories';
    }
  }

  String get arabicName {
    switch (this) {
      case ProductCategoryType.liquid:
        return 'سوائل إلكترونية (Liquid)';
      case ProductCategoryType.disposable:
        return 'سحبات جاهزة (Disposable)';
      case ProductCategoryType.device:
        return 'أجهزة ومودات (Device)';
      case ProductCategoryType.pod:
      case ProductCategoryType.coil:
        return 'كويلات وكارتردج (Coils & Cartridges)';
      case ProductCategoryType.accessory:
        return 'إكسسوارات ومستلزمات';
    }
  }

  String get description {
    switch (this) {
      case ProductCategoryType.liquid:
        return 'سولت نيكوتين وفري بيز مع النكهات وسحب MTL/DL';
      case ProductCategoryType.disposable:
        return 'سحبات جاهزة مع النكهات وعدد السحبات (Puffs) وسحب MTL/DL';
      case ProductCategoryType.device:
        return 'أجهزة فيب وبود كيت مع خيارات الألوان والبطارية';
      case ProductCategoryType.pod:
      case ProductCategoryType.coil:
        return 'كويلات مقاومة وبودات وكارتردج مع قيم المقاومة ونطاق الواط (Wattage)';
      case ProductCategoryType.accessory:
        return 'بطاريات وشواحن وقطن وزجاج وأدوات الصيانة';
    }
  }

  IconData get icon {
    switch (this) {
      case ProductCategoryType.liquid:
        return Icons.water_drop_rounded;
      case ProductCategoryType.disposable:
        return Icons.auto_awesome_rounded;
      case ProductCategoryType.device:
        return Icons.vape_free_rounded;
      case ProductCategoryType.pod:
      case ProductCategoryType.coil:
        return Icons.flash_on_rounded;
      case ProductCategoryType.accessory:
        return Icons.handyman_rounded;
    }
  }

  Color get accentColor {
    switch (this) {
      case ProductCategoryType.liquid:
        return const Color(0xFF0EA5E9); // Ocean Cyan
      case ProductCategoryType.disposable:
        return const Color(0xFFF59E0B); // Amber / Gold
      case ProductCategoryType.device:
        return const Color(0xFF6366F1); // Indigo
      case ProductCategoryType.pod:
      case ProductCategoryType.coil:
        return const Color(0xFF10B981); // Emerald Green
      case ProductCategoryType.accessory:
        return const Color(0xFFEC4899); // Rose Pink
    }
  }

  static ProductCategoryType fromString(String? raw) {
    if (raw == null) return ProductCategoryType.liquid;
    final r = raw.toLowerCase();
    if (r.contains('dispos') ||
        r.contains('puff') ||
        r.contains('سحب') ||
        r.contains('جاهز')) {
      return ProductCategoryType.disposable;
    }
    if (r.contains('liquid') ||
        r.contains('salt') ||
        r.contains('freebase') ||
        r.contains('juice') ||
        r.contains('flavor') ||
        r.contains('local') ||
        r.contains('prem') ||
        r.contains('prim')) {
      return ProductCategoryType.liquid;
    }
    if (r.contains('pod') ||
        r.contains('cartridge') ||
        r.contains('coil') ||
        r.contains('mesh') ||
        r.contains('resistance')) {
      return ProductCategoryType.pod;
    }
    if (r.contains('accessory') ||
        r.contains('battery') ||
        r.contains('charger') ||
        r.contains('cotton') ||
        r.contains('glass') ||
        r.contains('tool')) {
      return ProductCategoryType.accessory;
    }
    if (r.contains('device') ||
        r.contains('kit') ||
        r.contains('mod') ||
        r.contains('hardware')) {
      return ProductCategoryType.device;
    }
    return ProductCategoryType.liquid;
  }
}
