import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../utils/theme.dart';
import '../../../utils/formatters.dart';

class PieChartWidget extends StatefulWidget {
  final Map<String, double> categoryData;
  final String type; // 'income' ou 'expense'
  final bool isLoading;

  const PieChartWidget({
    Key? key,
    required this.categoryData,
    required this.type,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<PieChartWidget> createState() => _PieChartWidgetState();
}

class _PieChartWidgetState extends State<PieChartWidget> {
  int touchedIndex = -1;
  
  final Map<String, Color> incomeColors = {
    'Salário': AppTheme.incomeColor,
    'Plantão': Colors.blue,
    'Freelance': Colors.purple,
    'Bônus': Colors.teal,
    'Outros': Colors.amber,
  };
  
  final Map<String, Color> expenseColors = {
    'Alimentação': AppTheme.expenseColor,
    'Transporte': Colors.orange,
    'Moradia': Colors.brown,
    'Saúde': Colors.red,
    'Educação': Colors.indigo,
    'Lazer': Colors.deepPurple,
    'Outros': Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const SizedBox(
        height: 250,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (widget.categoryData.isEmpty) {
      return const SizedBox(
        height: 250,
        child: Center(
          child: Text(
            'Nenhum dado disponível',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    double total = widget.categoryData.values.fold(0, (sum, value) => sum + value);

    // Ordenar as categorias por valor (decrescente)
    final sortedCategories = widget.categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 250,
          child: Row(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            touchedIndex = -1;
                            return;
                          }
                          touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(
                      show: false,
                    ),
                    sectionsSpace: 0,
                    centerSpaceRadius: 40,
                    sections: _getSections(sortedCategories, total),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: sortedCategories
                        .take(5) // Limitar a 5 para não sobrecarregar
                        .map((entry) {
                      final isIncome = widget.type == 'income';
                      final colorMap = isIncome ? incomeColors : expenseColors;
                      final color = colorMap[entry.key] ?? 
                          (isIncome ? AppTheme.incomeColor : AppTheme.expenseColor);
                      
                      final percent = entry.value / total * 100;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: _buildIndicator(
                          color: color, 
                          text: entry.key,
                          value: entry.value,
                          percent: percent,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _getSections(
      List<MapEntry<String, double>> entries, double total) {
    final isIncome = widget.type == 'income';
    final colorMap = isIncome ? incomeColors : expenseColors;
    
    return entries.asMap().map((index, entry) {
      final isTouched = index == touchedIndex;
      final fontSize = isTouched ? 20.0 : 16.0;
      final radius = isTouched ? 110.0 : 100.0;
      
      final category = entry.key;
      final value = entry.value;
      final percent = value / total * 100;
      
      final color = colorMap[category] ?? 
          (isIncome ? AppTheme.incomeColor : AppTheme.expenseColor);
      
      return MapEntry(
        index,
        PieChartSectionData(
          color: color,
          value: value,
          title: percent >= 5 ? '${percent.toStringAsFixed(0)}%' : '',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }).values.toList();
  }

  Widget _buildIndicator({
    required Color color,
    required String text,
    required double value,
    required double percent,
  }) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formatCurrency(value),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    '${percent.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
} 