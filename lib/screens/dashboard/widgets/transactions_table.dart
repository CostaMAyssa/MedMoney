import 'package:flutter/material.dart';
import '../../../models/transaction.dart';
import '../../../utils/formatters.dart';
import '../../../utils/theme.dart';

class TransactionsTable extends StatelessWidget {
  final List<Transaction> transactions;
  final bool isLoading;
  final Function(Transaction)? onEdit;
  final Function(String)? onDelete;

  const TransactionsTable({
    Key? key,
    required this.transactions,
    this.isLoading = false,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (transactions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Nenhuma transação encontrada',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Data')),
            DataColumn(label: Text('Descrição')),
            DataColumn(label: Text('Categoria')),
            DataColumn(label: Text('Valor')),
            DataColumn(label: Text('Ações')),
          ],
          rows: transactions.map((transaction) {
            final isIncome = transaction.type == 'income';
            final color = isIncome ? AppTheme.incomeColor : AppTheme.expenseColor;
            
            return DataRow(
              cells: [
                DataCell(Text(formatShortDate(transaction.date))),
                DataCell(Tooltip(
                  message: transaction.description,
                  child: Text(
                    transaction.description,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                )),
                DataCell(Chip(
                  label: Text(
                    transaction.category,
                    style: TextStyle(
                      fontSize: 12,
                      color: isIncome ? Colors.white : Colors.black87,
                    ),
                  ),
                  backgroundColor: color.withOpacity(0.2),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                )),
                DataCell(Text(
                  formatCurrency(transaction.amount),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                )),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onEdit != null)
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        color: Colors.blue,
                        visualDensity: VisualDensity.compact,
                        onPressed: () => onEdit!(transaction),
                      ),
                    if (onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18),
                        color: Colors.red,
                        visualDensity: VisualDensity.compact,
                        onPressed: () => onDelete!(transaction.id),
                      ),
                  ],
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
} 