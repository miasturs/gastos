class Budget {
  final String id;
  final double limitAmount;
  final String period; // 'weekly' | 'monthly'
  final String categoryId;

  Budget({
    required this.id,
    required this.limitAmount,
    required this.period,
    required this.categoryId,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'limit_amount': limitAmount,
        'period': period,
        'category_id': categoryId,
      };

  factory Budget.fromMap(Map<String, dynamic> m) => Budget(
        id: m['id'] as String,
        limitAmount: (m['limit_amount'] as num).toDouble(),
        period: m['period'] as String,
        categoryId: m['category_id'] as String,
      );
}