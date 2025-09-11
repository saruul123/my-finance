import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/loan.dart';
import '../providers/settings_provider.dart';

class LoanProgressChart extends StatelessWidget {
  final Loan loan;
  final List<Payment> payments;
  final SettingsProvider settingsProvider;

  const LoanProgressChart({
    super.key,
    required this.loan,
    required this.payments,
    required this.settingsProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChartHeader(),
          const SizedBox(height: 20),
          Expanded(child: _buildChart()),
        ],
      ),
    );
  }

  Widget _buildChartHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.trending_down, color: Colors.blue, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Зээлийн төлөлт',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${loan.progressPercentage.toStringAsFixed(1)}% төлөгдсөн',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: loan.remainingBalance > 0
                ? Colors.orange.withOpacity(0.1)
                : Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            loan.remainingBalance > 0 ? 'Идэвхтэй' : 'Дууссан',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: loan.remainingBalance > 0 ? Colors.orange : Colors.green,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChart() {
    final chartData = _generateChartData();

    if (chartData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'Төлбөрийн түүх байхгүй',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval:
              chartData.map((e) => e.y).reduce((a, b) => a > b ? a : b) / 4,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.blue.withOpacity(0.1), strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    settingsProvider.formatAmount(value),
                    style: TextStyle(
                      color: Colors.blue.shade600,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < chartData.length) {
                  final date = chartData[value.toInt()].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${date.month}/${date.year.toString().substring(2)}',
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Colors.blue.withOpacity(0.2), width: 1),
            left: BorderSide(color: Colors.blue.withOpacity(0.2), width: 1),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: chartData.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.y);
            }).toList(),
            isCurved: true,
            gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.blue.shade600],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: Colors.blue.shade600,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade200.withOpacity(0.3),
                  Colors.blue.shade100.withOpacity(0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        minY: 0,
        maxY: loan.principal * 1.1,
      ),
    );
  }

  List<ChartDataPoint> _generateChartData() {
    if (payments.isEmpty) return [];

    // Group payments by month and calculate remaining balance over time
    final monthlyData = <DateTime, double>{};

    // Start with the original loan amount
    final startDate = DateTime(loan.startDate.year, loan.startDate.month);
    monthlyData[startDate] = loan.principal;

    // Sort payments by date
    final sortedPayments = List<Payment>.from(payments)
      ..sort((a, b) => a.date.compareTo(b.date));

    double runningBalance = loan.principal;

    for (final payment in sortedPayments) {
      runningBalance -= payment.amount;
      final monthKey = DateTime(payment.date.year, payment.date.month);
      monthlyData[monthKey] = runningBalance;
    }

    // Convert to chart data points
    final sortedEntries = monthlyData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return sortedEntries
        .map(
          (entry) => ChartDataPoint(
            date: entry.key,
            y: entry.value.abs(), // Ensure positive values
          ),
        )
        .toList();
  }
}

class ChartDataPoint {
  final DateTime date;
  final double y;

  ChartDataPoint({required this.date, required this.y});
}
