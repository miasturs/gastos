import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/category.dart';
import '../../data/models/expense.dart';

class ExpenseTile extends StatelessWidget {
  final Expense expense;
  final Category? category;
  final VoidCallback onTap;

  const ExpenseTile({
    super.key,
    required this.expense,
    required this.onTap,
    this.category,
  });

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor:
              Color(category?.color ?? 0xFFCCCCCC).withOpacity(0.2),
          child: Text(category?.icon ?? '❓', style: const TextStyle(fontSize: 20)),
        ),
        title: Text(expense.description),
        subtitle: Text(DateFormat.yMMMd('es').format(expense.date)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (expense.ticketPhotoPath != null)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.receipt, size: 18),
              ),
            Text(
              money.format(expense.amount),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}