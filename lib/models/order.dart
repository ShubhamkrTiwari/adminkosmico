class Order {
  final String id;
  final String userName;
  final double total;
  final String status;
  final String paymentStatus;
  final String? shiprocketOrderId;
  final String? trackingUrl;
  final String? shipmentId;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.userName,
    required this.total,
    required this.status,
    required this.paymentStatus,
    this.shiprocketOrderId,
    this.trackingUrl,
    this.shipmentId,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['_id'] ?? '',
      userName: json['user'] is Map ? (json['user']['name'] ?? 'Guest') : 'Guest',
      total: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['orderStatus'] ?? 'pending',
      paymentStatus: json['paymentStatus'] ?? 'pending',
      shiprocketOrderId: json['shiprocketOrderId'],
      trackingUrl: json['trackingUrl'],
      shipmentId: json['shipmentId'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
