class Coupon {
  final String id;
  final String code;
  final String discountType;
  final double discountAmount;
  final double minOrderAmount;
  final DateTime expiryDate;
  final int usageLimit;
  final int usedCount;
  final bool isActive;
  final String? description;

  Coupon({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountAmount,
    required this.minOrderAmount,
    required this.expiryDate,
    required this.usageLimit,
    required this.usedCount,
    required this.isActive,
    this.description,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    // Helper to parse double safely
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    // Helper to parse int safely
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now().add(const Duration(days: 30));
      try {
        return DateTime.parse(value.toString());
      } catch (e) {
        return DateTime.now().add(const Duration(days: 30));
      }
    }

    return Coupon(
      id: json['_id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      discountType: json['discountType']?.toString() ?? 'percentage',
      discountAmount: parseDouble(json['discountAmount']),
      minOrderAmount: parseDouble(json['minOrderAmount']),
      expiryDate: parseDate(json['expiryDate']),
      usageLimit: parseInt(json['usageLimit'] ?? 1000),
      usedCount: parseInt(json['usedCount']),
      isActive: json['isActive'] == true || json['isActive'] == 'true',
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'discountType': discountType,
      'discountAmount': discountAmount,
      'minOrderAmount': minOrderAmount,
      'expiryDate': expiryDate.toIso8601String(),
      'usageLimit': usageLimit,
      'description': description,
    };
  }
}
