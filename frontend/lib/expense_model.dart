class ExpenseModel {
  final String? id; // 🔥 Added so we can delete specific records
  final String userId;
  final double amount;
  final String category;
  final String description;
  final DateTime date;

  ExpenseModel({
    this.id,
    required this.userId,
    required this.amount,
    required this.category,
    required this.description,
    DateTime? date,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id, // Safely include ID if it exists
    'user_id': userId,
    'amount': amount,
    'category': category,
    'description': description,
    'date': date.toIso8601String(),
  };

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      // 🔥 Safely capture the ID from MongoDB (whether they pass it as 'id' or '_id')
      id: json['id']?.toString() ?? json['_id']?.toString(),
      userId: json['user_id'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      category: json['category'] ?? 'other',
      description: json['description'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
    );
  }
}