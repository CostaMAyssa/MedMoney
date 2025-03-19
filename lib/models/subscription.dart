class Subscription {
  final String id;
  final String userId;
  final String? planId;
  final String planName;
  final String planType; // 'monthly' ou 'annual'
  final double price;
  final String status;
  final DateTime? startDate;
  final DateTime? nextBillingDate;
  final DateTime? expirationDate;
  final String? paymentId;
  final String? externalReference;
  final DateTime? canceledAt;
  final Map<String, dynamic>? metadata;

  Subscription({
    required this.id,
    required this.userId,
    this.planId,
    required this.planName,
    required this.planType,
    required this.price,
    required this.status,
    this.startDate,
    this.nextBillingDate,
    this.expirationDate,
    this.paymentId,
    this.externalReference,
    this.canceledAt,
    this.metadata,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'],
      userId: json['user_id'],
      planId: json['plan_id'],
      planName: json['plan_name'],
      planType: json['plan_type'],
      price: json['price'] is int 
          ? (json['price'] as int).toDouble() 
          : json['price'],
      status: json['status'],
      startDate: json['start_date'] != null 
          ? DateTime.parse(json['start_date']) 
          : null,
      nextBillingDate: json['next_billing_date'] != null 
          ? DateTime.parse(json['next_billing_date']) 
          : null,
      expirationDate: json['expiration_date'] != null 
          ? DateTime.parse(json['expiration_date']) 
          : null,
      paymentId: json['payment_id'],
      externalReference: json['external_reference'],
      canceledAt: json['canceled_at'] != null
          ? DateTime.parse(json['canceled_at'])
          : null,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'plan_id': planId,
      'plan_name': planName,
      'plan_type': planType,
      'price': price,
      'status': status,
      'start_date': startDate?.toIso8601String(),
      'next_billing_date': nextBillingDate?.toIso8601String(),
      'expiration_date': expirationDate?.toIso8601String(),
      'payment_id': paymentId,
      'external_reference': externalReference,
      'canceled_at': canceledAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  Subscription copyWith({
    String? id,
    String? userId,
    String? planId,
    String? planName,
    String? planType,
    double? price,
    String? status,
    DateTime? startDate,
    DateTime? nextBillingDate,
    DateTime? expirationDate,
    String? paymentId,
    String? externalReference,
    DateTime? canceledAt,
    Map<String, dynamic>? metadata,
  }) {
    return Subscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      planId: planId ?? this.planId,
      planName: planName ?? this.planName,
      planType: planType ?? this.planType,
      price: price ?? this.price,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      expirationDate: expirationDate ?? this.expirationDate,
      paymentId: paymentId ?? this.paymentId,
      externalReference: externalReference ?? this.externalReference,
      canceledAt: canceledAt ?? this.canceledAt,
      metadata: metadata ?? this.metadata,
    );
  }
} 