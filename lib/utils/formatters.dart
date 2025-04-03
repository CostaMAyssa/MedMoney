import 'package:intl/intl.dart';

// Formatação de valores monetários
String formatCurrency(double value) {
  final formatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );
  return formatter.format(value);
}

// Formatação de data curta (DD/MM/YYYY)
String formatShortDate(DateTime date) {
  final formatter = DateFormat('dd/MM/yyyy');
  return formatter.format(date);
}

// Formatação de data longa (DD de Mês de YYYY)
String formatLongDate(DateTime date) {
  final formatter = DateFormat("dd 'de' MMMM 'de' yyyy", 'pt_BR');
  return formatter.format(date);
}

// Formatação de data e hora
String formatDateTime(DateTime date) {
  final formatter = DateFormat('dd/MM/yyyy HH:mm');
  return formatter.format(date);
}

// Formatação de percentual
String formatPercent(double value) {
  final formatter = NumberFormat.percentPattern('pt_BR');
  return formatter.format(value / 100);
}

// Formatação de números
String formatNumber(double value) {
  final formatter = NumberFormat.decimalPattern('pt_BR');
  return formatter.format(value);
}

// Formatação de nomes de mês
String getMonthName(int month) {
  final date = DateTime(2022, month);
  final formatter = DateFormat('MMMM', 'pt_BR');
  return formatter.format(date).toUpperCase();
}

// Formatação de data abreviada (Mês/Ano)
String formatMonthYear(DateTime date) {
  final formatter = DateFormat('MMM/yyyy', 'pt_BR');
  return formatter.format(date);
}

// Obter lista de meses abreviados em pt-BR
List<String> getMonthsAbbr() {
  final months = <String>[];
  for (int i = 1; i <= 12; i++) {
    final date = DateTime(2022, i);
    months.add(DateFormat('MMM', 'pt_BR').format(date));
  }
  return months;
}

// Obter lista de meses completos em pt-BR
List<String> getMonths() {
  final months = <String>[];
  for (int i = 1; i <= 12; i++) {
    final date = DateTime(2022, i);
    months.add(DateFormat('MMMM', 'pt_BR').format(date));
  }
  return months;
} 