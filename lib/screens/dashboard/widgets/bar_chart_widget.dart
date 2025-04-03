import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../utils/theme.dart';
import '../../../utils/formatters.dart';

class BarChartWidget extends StatelessWidget {
  final Map<String, dynamic> monthlyData;
  final bool isLoading;

  const BarChartWidget({
    Key? key,
    required this.monthlyData,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 250,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (monthlyData.isEmpty) {
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

    // Ordenar os meses cronologicamente
    final sortedMonths = monthlyData.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    // Limitar a 6 últimos meses para não sobrecarregar o gráfico
    final displayMonths = sortedMonths.length <= 6
        ? sortedMonths
        : sortedMonths.sublist(sortedMonths.length - 6);

    return SizedBox(
      height: 250,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: _getMaxValue(displayMonths) * 1.2,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                tooltipBgColor: Colors.black87,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final month = displayMonths[group.x.toInt()];
                  final monthData = monthlyData[month];
                  final value = rodIndex == 0
                      ? monthData['income']
                      : monthData['expense'];
                  
                  return BarTooltipItem(
                    '${rodIndex == 0 ? 'Receita' : 'Despesa'}\n${formatCurrency(value)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 && value.toInt() < displayMonths.length) {
                      final month = displayMonths[value.toInt()];
                      final parts = month.split('-');
                      final monthNum = int.parse(parts[1]);
                      final year = parts[0].substring(2);
                      
                      // Formatação abreviada do mês e ano
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          '${getMonthsAbbr()[monthNum - 1]}/$year',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }
                    return const Text('');
                  },
                  reservedSize: 30,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(
                        'R\$${(value / 1000).toStringAsFixed(0)}K',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                  reservedSize: 40,
                ),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: false,
                ),
              ),
              topTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: false,
                ),
              ),
            ),
            gridData: FlGridData(
              show: true,
              horizontalInterval: _getMaxValue(displayMonths) / 5,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey.withOpacity(0.2),
                  strokeWidth: 1,
                );
              },
            ),
            borderData: FlBorderData(
              show: false,
            ),
            barGroups: _getBarGroups(displayMonths),
          ),
        ),
      ),
    );
  }

  List<BarChartGroupData> _getBarGroups(List<String> months) {
    final barGroups = <BarChartGroupData>[];
    
    for (int i = 0; i < months.length; i++) {
      final month = months[i];
      final monthData = monthlyData[month];
      
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: monthData['income'] ?? 0,
              color: AppTheme.incomeColor,
              width: 12,
              borderRadius: BorderRadius.circular(4),
            ),
            BarChartRodData(
              toY: monthData['expense'] ?? 0,
              color: AppTheme.expenseColor,
              width: 12,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }
    
    return barGroups;
  }

  double _getMaxValue(List<String> months) {
    double maxValue = 0;
    
    for (final month in months) {
      final monthData = monthlyData[month];
      final income = monthData['income'] as double? ?? 0;
      final expense = monthData['expense'] as double? ?? 0;
      
      final maxMonthValue = income > expense ? income : expense;
      if (maxMonthValue > maxValue) {
        maxValue = maxMonthValue;
      }
    }
    
    return maxValue;
  }
} 