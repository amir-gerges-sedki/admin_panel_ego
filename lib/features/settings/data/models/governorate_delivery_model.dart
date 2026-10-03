import 'package:equatable/equatable.dart';

class GovernorateDeliveryModel extends Equatable {
  final String id;
  final String nameAr;
  final String nameEn;
  final double deliveryFee;
  final bool isAvailable;

  const GovernorateDeliveryModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.deliveryFee,
    this.isAvailable = true,
  });

  String localizedName(String langCode) => langCode == 'ar' ? nameAr : nameEn;

  GovernorateDeliveryModel copyWith({
    String? id,
    String? nameAr,
    String? nameEn,
    double? deliveryFee,
    bool? isAvailable,
  }) {
    return GovernorateDeliveryModel(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nameAr': nameAr,
        'nameEn': nameEn,
        'deliveryFee': deliveryFee,
        'isAvailable': isAvailable,
      };

  factory GovernorateDeliveryModel.fromJson(Map<String, dynamic> json) {
    return GovernorateDeliveryModel(
      id: json['id']?.toString() ?? '',
      nameAr: json['nameAr']?.toString() ?? '',
      nameEn: json['nameEn']?.toString() ?? '',
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      isAvailable: json['isAvailable'] is bool
          ? json['isAvailable'] as bool
          : (json['isAvailable']?.toString().toLowerCase() != 'false'),
    );
  }

  @override
  List<Object?> get props => [id, nameAr, nameEn, deliveryFee, isAvailable];

  /// All 27 official Egyptian governorates (Admin sets delivery fees)
  static List<GovernorateDeliveryModel> defaultGovernorates() => const [
        // Greater Cairo
        GovernorateDeliveryModel(
          id: 'cairo',
          nameAr: 'القاهرة',
          nameEn: 'Cairo',
          deliveryFee: 0.0,
          isAvailable: true,
        ),
        GovernorateDeliveryModel(
          id: 'giza',
          nameAr: 'الجيزة',
          nameEn: 'Giza',
          deliveryFee: 0.0,
          isAvailable: true,
        ),
        GovernorateDeliveryModel(
          id: 'qalyubia',
          nameAr: 'القليوبية',
          nameEn: 'Qalyubia',
          deliveryFee: 0.0,
          isAvailable: true,
        ),

        // Alexandria & North Coast
        GovernorateDeliveryModel(
          id: 'alexandria',
          nameAr: 'الإسكندرية',
          nameEn: 'Alexandria',
          deliveryFee: 0.0,
          isAvailable: true,
        ),
        GovernorateDeliveryModel(
          id: 'beheira',
          nameAr: 'البحيرة',
          nameEn: 'Beheira',
          deliveryFee: 0.0,
          isAvailable: true,
        ),
        GovernorateDeliveryModel(
          id: 'matrouh',
          nameAr: 'مطروح',
          nameEn: 'Matrouh',
          deliveryFee: 0.0,
          isAvailable: true,
        ),

        // Delta Governorates
        GovernorateDeliveryModel(
          id: 'dakahlia',
          nameAr: 'الدقهلية',
          nameEn: 'Dakahlia',
          deliveryFee: 0.0,
          isAvailable: true,
        ),
        GovernorateDeliveryModel(
          id: 'gharbia',
          nameAr: 'الغربية',
          nameEn: 'Gharbia',
          deliveryFee: 0.0,
          isAvailable: true,
        ),
        GovernorateDeliveryModel(
          id: 'monufia',
          nameAr: 'المنوفية',
          nameEn: 'Monufia',
          deliveryFee: 0.0,
          isAvailable: true,
        ),
        GovernorateDeliveryModel(
          id: 'sharqia',
          nameAr: 'الشرقية',
          nameEn: 'Sharqia',
          deliveryFee: 0.0,
          isAvailable: true,
        ),
        GovernorateDeliveryModel(
          id: 'kafr_el_sheikh',
          nameAr: 'كفر الشيخ',
          nameEn: 'Kafr El Sheikh',
          deliveryFee: 0.0,
          isAvailable: true,
        ),
        GovernorateDeliveryModel(
          id: 'damietta',
          nameAr: 'دمياط',
          nameEn: 'Damietta',
          deliveryFee: 0.0,
          isAvailable: true,
        ),

        // Canal Governorates
        GovernorateDeliveryModel(
          id: 'port_said',
          nameAr: 'بورسعيد',
          nameEn: 'Port Said',
          deliveryFee: 0.0,
          isAvailable: true,
        ),
        GovernorateDeliveryModel(
          id: 'ismailia',
          nameAr: 'الإسماعيلية',
          nameEn: 'Ismailia',
          deliveryFee: 0.0,
          isAvailable: true,
        ),
        GovernorateDeliveryModel(
          id: 'suez',
          nameAr: 'السويس',
          nameEn: 'Suez',
          deliveryFee: 0.0,
          isAvailable: true,
        ),

        // Northern Upper Egypt
        GovernorateDeliveryModel(
          id: 'faiyum',
          nameAr: 'الفيوم',
          nameEn: 'Faiyum',
          deliveryFee: 0.0,
          isAvailable: true,
        ),
        GovernorateDeliveryModel(
          id: 'beni_suef',
          nameAr: 'بني سويف',
          nameEn: 'Beni Suef',
          deliveryFee: 0.0,
          isAvailable: true,
        ),
        GovernorateDeliveryModel(
          id: 'minya',
          nameAr: 'المنيا',
          nameEn: 'Minya',
          deliveryFee: 0.0,
          isAvailable: true,
        ),

        // Central & Southern Upper Egypt
        GovernorateDeliveryModel(
          id: 'asyut',
          nameAr: 'أسيوط',
          nameEn: 'Asyut',
          deliveryFee: 0.0,
          isAvailable: true,
        ),
        GovernorateDeliveryModel(
          id: 'sohag',
          nameAr: 'سوهاج',
          nameEn: 'Sohag',
          deliveryFee: 0.0,
          isAvailable: true,
        ),
        GovernorateDeliveryModel(
          id: 'qena',
          nameAr: 'قنا',
          nameEn: 'Qena',
          deliveryFee: 0.0,
          isAvailable: true,
        ),
        GovernorateDeliveryModel(
          id: 'luxor',
          nameAr: 'الأقصر',
          nameEn: 'Luxor',
          deliveryFee: 0.0,
          isAvailable: true,
        ),
        GovernorateDeliveryModel(
          id: 'aswan',
          nameAr: 'أسوان',
          nameEn: 'Aswan',
          deliveryFee: 0.0,
          isAvailable: true,
        ),

        // Frontier & Sinai Governorates
        GovernorateDeliveryModel(
          id: 'red_sea',
          nameAr: 'البحر الأحمر',
          nameEn: 'Red Sea',
          deliveryFee: 0.0,
          isAvailable: true,
        ),
        GovernorateDeliveryModel(
          id: 'new_valley',
          nameAr: 'الوادي الجديد',
          nameEn: 'New Valley',
          deliveryFee: 0.0,
          isAvailable: true,
        ),
        GovernorateDeliveryModel(
          id: 'north_sinai',
          nameAr: 'شمال سيناء',
          nameEn: 'North Sinai',
          deliveryFee: 0.0,
          isAvailable: true,
        ),
        GovernorateDeliveryModel(
          id: 'south_sinai',
          nameAr: 'جنوب سيناء',
          nameEn: 'South Sinai',
          deliveryFee: 0.0,
          isAvailable: true,
        ),
      ];

  /// Fuzzy lookup helper to match any user string, GPS location, or governorate name
  static GovernorateDeliveryModel? matchGovernorate(
    String? input,
    List<GovernorateDeliveryModel> list,
  ) {
    if (input == null || input.trim().isEmpty) return null;
    final clean = input.trim().toLowerCase();

    // 1. Exact or ID match
    for (final gov in list) {
      if (gov.id.toLowerCase() == clean ||
          gov.nameAr.toLowerCase() == clean ||
          gov.nameEn.toLowerCase() == clean) {
        return gov;
      }
    }

    // 2. Normalized Arabic text search
    String normalize(String s) {
      return s
          .toLowerCase()
          .replaceAll('أ', 'ا')
          .replaceAll('إ', 'ا')
          .replaceAll('آ', 'ا')
          .replaceAll('ة', 'ه')
          .replaceAll('ى', 'ي')
          .replaceAll(RegExp(r'[^a-zA-Z0-9\u0600-\u06FF]'), '');
    }

    final normalizedInput = normalize(clean);
    for (final gov in list) {
      final normAr = normalize(gov.nameAr);
      final normEn = normalize(gov.nameEn);
      if (normalizedInput == normAr || normalizedInput == normEn) {
        return gov;
      }
      if (normalizedInput.contains(normAr) || normalizedInput.contains(normEn)) {
        return gov;
      }
      if (normAr.contains(normalizedInput) || normEn.contains(normalizedInput)) {
        return gov;
      }
    }

    // Common synonyms / transliterations
    final synonyms = {
      'alex': 'alexandria',
      'alexandria': 'alexandria',
      'cairo': 'cairo',
      'giza': 'giza',
      'giza governorate': 'giza',
      'cairo governorate': 'cairo',
      'october': 'giza',
      '6th of october': 'giza',
      'sharm': 'south_sinai',
      'sharm el sheikh': 'south_sinai',
      'hurghada': 'red_sea',
      'el gouna': 'red_sea',
      'mansoura': 'dakahlia',
      'tanta': 'gharbia',
      'zagazig': 'sharqia',
      'port said': 'port_said',
      'ismailia': 'ismailia',
      'suez': 'suez',
    };

    for (final entry in synonyms.entries) {
      if (clean.contains(entry.key)) {
        return list.where((g) => g.id == entry.value).firstOrNull;
      }
    }

    return null;
  }
}
