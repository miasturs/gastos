class Expense {
  final String id;
  final double amount;
  final DateTime date;
  final String description;
  final String categoryId;
  final String? budgetId;
  final String? ticketPhotoPath;
  final DateTime updatedAt;
  final bool synced;

  Expense({
    required this.id,
    required this.amount,
    required this.date,
    required this.description,
    required this.categoryId,
    this.budgetId,
    this.ticketPhotoPath,
    required this.updatedAt,
    this.synced = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'amount': amount,
        'date': date.toIso8601String(),
        'description': description,
        'category_id': categoryId,
        'budget_id': budgetId,
        'ticket_photo_path': ticketPhotoPath,
        'updated_at': updatedAt.toIso8601String(),
        'synced': synced ? 1 : 0,
      };

  factory Expense.fromMap(Map<String, dynamic> m) => Expense(
        id: m['id'] as String,
        amount: (m['amount'] as num).toDouble(),
        date: DateTime.parse(m['date'] as String),
        description: m['description'] as String,
        categoryId: m['category_id'] as String,
        budgetId: m['budget_id'] as String?,
        ticketPhotoPath: m['ticket_photo_path'] as String?,
        updatedAt: DateTime.parse(m['updated_at'] as String),
        synced: (m['synced'] as int? ?? 0) == 1,
      );

  Expense copyWith({
    double? amount,
    DateTime? date,
    String? description,
    String? categoryId,
    String? budgetId,
    String? ticketPhotoPath,
    bool? synced,
  }) =>
      Expense(
        id: id,
        amount: amount ?? this.amount,
        date: date ?? this.date,
        description: description ?? this.description,
        categoryId: categoryId ?? this.categoryId,
        budgetId: budgetId ?? this.budgetId,
        ticketPhotoPath: ticketPhotoPath ?? this.ticketPhotoPath,
        updatedAt: DateTime.now(),
        synced: synced ?? this.synced,
      );
}