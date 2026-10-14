import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/statistics_controller.dart';
import '../../core/constants/app_colors.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatisticsController>().refreshData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: const Text('Vision Analytics & Telemetry'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.neonAccent),
            tooltip: 'Refresh Telemetry',
            onPressed: () => context.read<StatisticsController>().refreshData(),
          ),
        ],
      ),
      body: Consumer<StatisticsController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.totalDetections == 0) {
            return RefreshIndicator(
              color: AppColors.neonAccent,
              onRefresh: controller.refreshData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(Icons.bar_chart_rounded, size: 48, color: AppColors.mutedText),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'No Telemetry Data Recorded',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryText),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Run object detections with the live camera scanner to build neural analytics and trends.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: AppColors.secondaryText),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.neonAccent,
            onRefresh: controller.refreshData,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildSummaryCards(context, controller),
                const SizedBox(height: 24),

                _buildSectionTitle('Detection Frequency', 'Top detected object classes'),
                const SizedBox(height: 10),
                _buildFrequencyChart(context, controller),
                const SizedBox(height: 24),

                _buildSectionTitle('Time of Day Distribution', 'Detection activity by period'),
                const SizedBox(height: 10),
                _buildTimePieChart(context, controller),
                const SizedBox(height: 24),

                _buildSectionTitle('7-Day Trend Analysis', 'Historical daily detection volume'),
                const SizedBox(height: 10),
                _buildTrendLineChart(context, controller),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryText),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: AppColors.mutedText),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(BuildContext context, StatisticsController controller) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: [
        _buildStatCard('Total Detections', controller.totalDetections.toString(), Icons.analytics_outlined, AppColors.primaryViolet),
        _buildStatCard('Unique Objects', controller.uniqueObjects.toString(), Icons.category_outlined, AppColors.brightViolet),
        _buildStatCard('Most Detected', controller.mostDetected, Icons.star_rounded, AppColors.neonAccent),
        _buildStatCard('Today\'s Count', controller.todayDetections.toString(), Icons.today_rounded, AppColors.success),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: AppColors.secondaryText, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primaryText),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyChart(BuildContext context, StatisticsController controller) {
    final frequency = controller.frequency;
    if (frequency.isEmpty) return const SizedBox.shrink();

    // Take top 5 objects
    final topObjects = frequency.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final displayObjects = topObjects.take(5).toList();

    double maxY = displayObjects.isNotEmpty ? displayObjects.first.value.toDouble() : 10;
    maxY = (maxY * 1.25).ceilToDouble();

    return Container(
      height: 240,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: AppColors.elevatedSurface,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${displayObjects[group.x].key}\n${rod.toY.toInt()} events',
                  const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 11),
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
                  final idx = value.toInt();
                  if (idx >= 0 && idx < displayObjects.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        displayObjects[idx].key.toUpperCase(),
                        style: const TextStyle(fontSize: 9, color: AppColors.secondaryText, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 9, color: AppColors.mutedText),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.borderSubtle, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barGroups: displayObjects.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.value.toDouble(),
                  gradient: const LinearGradient(
                    colors: [AppColors.neonAccent, AppColors.deepViolet],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  width: 18,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTimePieChart(BuildContext context, StatisticsController controller) {
    final timeData = controller.timeBased;
    if (timeData.values.every((v) => v == 0)) return const SizedBox.shrink();

    final colors = [
      AppColors.warning,      // Morning
      AppColors.neonAccent,   // Afternoon
      AppColors.primaryViolet,// Evening
      AppColors.deepViolet,   // Night
    ];

    int i = 0;
    final sections = timeData.entries.map((e) {
      final color = colors[i % colors.length];
      i++;
      return PieChartSectionData(
        color: color,
        value: e.value.toDouble(),
        title: '${e.value}',
        radius: 45.0,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 36,
                sections: sections,
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegendItem('Morning', colors[0]),
              _buildLegendItem('Afternoon', colors[1]),
              _buildLegendItem('Evening', colors[2]),
              _buildLegendItem('Night', colors[3]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
        ],
      ),
    );
  }

  Widget _buildTrendLineChart(BuildContext context, StatisticsController controller) {
    final trend = controller.weeklyTrend;
    if (trend.isEmpty) return const SizedBox.shrink();

    final sortedKeys = trend.keys.toList()..sort();

    double maxY = 10;
    for (var val in trend.values) {
      if (val > maxY) maxY = val.toDouble();
    }
    maxY = (maxY * 1.25).ceilToDouble();

    List<FlSpot> spots = [];
    for (int i = 0; i < sortedKeys.length; i++) {
      spots.add(FlSpot(i.toDouble(), trend[sortedKeys[i]]!.toDouble()));
    }

    return Container(
      height: 240,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.borderSubtle, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int idx = value.toInt();
                  if (idx >= 0 && idx < sortedKeys.length) {
                    try {
                      final d = DateFormat('yyyy-MM-dd').parse(sortedKeys[idx]);
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          DateFormat('MM/dd').format(d),
                          style: const TextStyle(fontSize: 9, color: AppColors.mutedText),
                        ),
                      );
                    } catch (_) {}
                  }
                  return const Text('');
                },
                reservedSize: 26,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 9, color: AppColors.mutedText),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (sortedKeys.length - 1).toDouble(),
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.neonAccent,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: AppColors.neonAccent,
                    strokeWidth: 2,
                    strokeColor: AppColors.cardBackground,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.neonAccent.withValues(alpha: 0.28),
                    AppColors.primaryViolet.withValues(alpha: 0.02),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
