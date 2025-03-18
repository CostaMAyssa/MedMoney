class Subscription {
  final String id;
  final String userId;
  final String planType;
  final String billingFrequency;
  final double amount;
  final String status;
  final DateTime? startDate;
  final DateTime? nextBillingDate;
  final DateTime? expirationDate;
  final String? paymentId;
  final String? externalReference;
  final Map<String, dynamic>? metadata;

  Subscription({
    required this.id,
    required this.userId,
    required this.planType,
    required this.billingFrequency,
    required this.amount,
    required this.status,
    this.startDate,
    this.nextBillingDate,
    this.expirationDate,
    this.paymentId,
    this.externalReference,
    this.metadata,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'],
      userId: json['user_id'],
      planType: json['plan_type'],
      billingFrequency: json['billing_frequency'],
      amount: json['amount'] is int 
          ? (json['amount'] as int).toDouble() 
          : json['amount'],
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
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'plan_type': planType,
      'billing_frequency': billingFrequency,
      'amount': amount,
      'status': status,
      'start_date': startDate?.toIso8601String(),
      'next_billing_date': nextBillingDate?.toIso8601String(),
      'expiration_date': expirationDate?.toIso8601String(),
      'payment_id': paymentId,
      'external_reference': externalReference,
      'metadata': metadata,
    };
  }

  Subscription copyWith({
    String? id,
    String? userId,
    String? planType,
    String? billingFrequency,
    double? amount,
    String? status,
    DateTime? startDate,
    DateTime? nextBillingDate,
    DateTime? expirationDate,
    String? paymentId,
    String? externalReference,
    Map<String, dynamic>? metadata,
  }) {
    return Subscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      planType: planType ?? this.planType,
      billingFrequency: billingFrequency ?? this.billingFrequency,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      expirationDate: expirationDate ?? this.expirationDate,
      paymentId: paymentId ?? this.paymentId,
      externalReference: externalReference ?? this.externalReference,
      metadata: metadata ?? this.metadata,
    );
  }
} 