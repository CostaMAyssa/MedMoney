class Transaction {
  final String id;
  final DateTime date;
  final double amount;
  final String category;
  final String description;
  final String type; // 'income' ou 'expense'
  final String? userId;

  Transaction({
    required this.id,
    required this.date,
    required this.amount,
    required this.category,
    required this.description,
    required this.type,
    this.userId,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      date: json['date'] != null 
          ? DateTime.parse(json['date']) 
          : DateTime.now(),
      amount: json['amount'] is int 
          ? (json['amount'] as int).toDouble() 
          : json['amount'],
      category: json['category'] ?? 'Outros',
      description: json['description'] ?? '',
      type: json['type'] ?? 'expense',
      userId: json['user_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'amount': amount,
      'category': category,
      'description': description,
      'type': type,
      'user_id': userId,
    };
  }

  Transaction copyWith({
    String? id,
    DateTime? date,
    double? amount,
    String? category,
    String? description,
    String? type,
    String? userId,
  }) {
    return Transaction(
      id: id ?? this.id,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      type: type ?? this.type,
      userId: userId ?? this.userId,
    );
  }
} 