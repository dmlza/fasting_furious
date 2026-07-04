import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config/theme.dart';
import '../providers/habit_provider.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  String _selectedRange = '7D';

  @override
  Widget build(BuildContext context) {
    final habitState = ref.watch(habitProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Statistics',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary cards
            _buildSummaryRow(habitState),
            const SizedBox(height: 24),

            // Fasting chart
            _buildChartSection(habitState),
            const SizedBox(height: 24),

            // Habit streaks
            _buildStreaksSection(habitState),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(HabitState state) {
    final completedFasts = state.history.length;
    final avgHours = completedFasts > 0
        ? (state.history.fold(0, (sum, h) => sum + h.exerciseMinutes) / completedFasts / 60).toStringAsFixed(1)
        : '0';
    final bestStreak = _getBestStreak(state);

    return Row(
      children: [
        _SummaryCard(
          value: '$completedFasts',
          label: 'Fasts',
          color: AppColors.indigo,
          icon: Icons.timer_outlined,
        ),
        const SizedBox(width: 12),
        _SummaryCard(
          value: '${avgHours}h',
          label: 'Avg Duration',
          color: AppColors.emerald,
          icon: Icons.access_time,
        ),
        const SizedBox(width: 12),
        _SummaryCard(
          value: '$bestStreak',
          label: 'Best Streak',
          color: AppColors.amber,
          icon: Icons.local_fire_department_outlined,
        ),
      ],
    );
  }

  Widget _buildChartSection(HabitState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Fasting History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                _buildRangeSelector(),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: _buildChart(state),
            ),
            const SizedBox(height: 16),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendDot(color: AppColors.indigo, label: 'Fasting Hours'),
                const SizedBox(width: 20),
                _LegendDot(color: AppColors.amber, label: 'Goal (16h)'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeSelector() {
    final ranges = ['7D', '14D', '30D'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: ranges.map((r) {
          final isSelected = r == _selectedRange;
          return GestureDetector(
            onTap: () => setState(() => _selectedRange = r),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.indigo : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                r,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChart(HabitState state) {
    final data = _getChartData(state);
    final maxY = data.fold<double>(0, (max, bar) => bar.y > max ? bar.y : max);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY < 24 ? 24 : maxY + 2,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.indigo,
            getTooltipItem: (group, groupIdx, rod, rodIdx) {
              return BarTooltipItem(
                '${rod.toY.toStringAsFixed(1)}h',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
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
                if (idx < data.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      data[idx].x.toStringAsFixed(0),
                      style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodySmall?.color),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}h',
                  style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodySmall?.color),
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
          horizontalInterval: 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data.map((bar) {
          final isGoalMet = bar.y >= 16;
          return BarChartGroupData(
            x: bar.x.toInt(),
            barRods: [
              BarChartRodData(
                toY: bar.y,
                width: 20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                color: isGoalMet ? AppColors.indigo : AppColors.indigo.withValues(alpha: 0.4),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: 16,
                  color: AppColors.amber.withValues(alpha: 0.1),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  List<FlSpot> _getChartData(HabitState state) {
    final days = _selectedRange == '7D' ? 7 : _selectedRange == '14D' ? 14 : 30;
    final now = DateTime.now();
    final spots = <FlSpot>[];

    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = date.toIso8601String().split('T')[0];
      final history = state.history.where((h) => h.date == dateStr).toList();
      final hours = history.isNotEmpty ? history.first.exerciseMinutes / 60.0 : 0.0;
      spots.add(FlSpot((days - 1 - i).toDouble(), hours));
    }

    return spots;
  }

  Widget _buildStreaksSection(HabitState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Current Streaks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _StreakRow(
              label: 'No Sugar',
              days: state.getStreak('no_sugar'),
              emoji: '\u{1F525}',
              color: AppColors.amber,
            ),
            const SizedBox(height: 12),
            _StreakRow(
              label: 'No Smoking',
              days: state.getStreak('no_smoking'),
              emoji: '\u{1F6AB}',
              color: AppColors.coral,
            ),
            const SizedBox(height: 12),
            _StreakRow(
              label: 'Exercise',
              days: state.getStreak('exercise'),
              emoji: '\u{1F3C3}',
              color: AppColors.emerald,
            ),
          ],
        ),
      ),
    );
  }

  int _getBestStreak(HabitState state) {
    int max = 0;
    for (final h in ['exercise', 'no_sugar', 'no_smoking']) {
      final s = state.getStreak(h);
      if (s > max) max = s;
    }
    return max;
  }
}

class _SummaryCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
      ],
    );
  }
}

class _StreakRow extends StatelessWidget {
  final String label;
  final int days;
  final String emoji;
  final Color color;

  const _StreakRow({
    required this.label,
    required this.days,
    required this.emoji,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 18)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              Text('$days day${days != 1 ? 's' : ''}', style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$days',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color),
          ),
        ),
      ],
    );
  }
}
