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
    return Coupon(
      id: json['_id'] ?? '',
      code: json['code'] ?? '',
      discountType: json['discountType'] ?? 'percentage',
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      minOrderAmount: (json['minOrderAmount'] as num?)?.toDouble() ?? 0.0,
      expiryDate: json['expiryDate'] != null 
          ? DateTime.parse(json['expiryDate']) 
          : DateTime.now().add(const Duration(days: 30)),
      usageLimit: json['usageLimit'] ?? 1000,
      usedCount: json['usedCount'] ?? 0,
      isActive: json['isActive'] ?? true,
      description: json['description'],
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
