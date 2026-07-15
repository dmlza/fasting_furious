import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/habit_provider.dart';
import '../../models/models.dart';

class SugarDetailScreen extends ConsumerStatefulWidget {
  const SugarDetailScreen({super.key});

  @override
  ConsumerState<SugarDetailScreen> createState() => _SugarDetailScreenState();
}

class _SugarDetailScreenState extends ConsumerState<SugarDetailScreen> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habitState = ref.watch(habitProvider);
    final history = habitState.history;

    final allStreaks = _computeAllStreaks(history);
    final currentStreak = habitState.getStreak('no_sugar');
    final longestStreak = allStreaks.isEmpty ? 0 : allStreaks.first;
    final totalTracked = history.where((h) => h.date.isNotEmpty).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('No Sugar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // Stats row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Row(
                children: [
                  _StatCard(label: 'Current', value: '$currentStreak', unit: 'days', color: AppColors.purple),
                  const SizedBox(width: 12),
                  _StatCard(label: 'Longest', value: '$longestStreak', unit: 'days', color: AppColors.green),
                  const SizedBox(width: 12),
                  _StatCard(label: 'Tracked', value: '$totalTracked', unit: 'days', color: AppColors.purpleLight),
                ],
              ),
            ),
          ),

          // Calendar header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1)),
                    icon: const Icon(Icons.chevron_left, size: 22),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        _monthLabel(_currentMonth),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1)),
                    icon: const Icon(Icons.chevron_right, size: 22),
                  ),
                ],
              ),
            ),
          ),

          // Calendar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildCalendar(_currentMonth, history, theme),
            ),
          ),

          // Legend
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _LegendDot(color: AppColors.green, label: 'No sugar'),
                  const SizedBox(width: 16),
                  _LegendDot(color: Colors.red, label: 'Had sugar'),
                  const SizedBox(width: 16),
                  _LegendDot(color: theme.colorScheme.surfaceContainerHighest, label: 'No entry'),
                ],
              ),
            ),
          ),

          // Streaks header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Text(
                'STREAK HISTORY',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1, color: theme.textTheme.bodySmall?.color),
              ),
            ),
          ),

          // Streaks list
          if (allStreaks.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Text('\u{1F3AF}', style: TextStyle(fontSize: 40, color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4))),
                    const SizedBox(height: 12),
                    Text('No streaks yet', style: TextStyle(fontSize: 14, color: theme.textTheme.bodySmall?.color)),
                    const SizedBox(height: 4),
                    Text('Start logging your days to build streaks!', style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6))),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.separated(
                itemCount: allStreaks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) => _buildStreakCard(index, allStreaks[index], theme),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  List<int> _computeAllStreaks(List<HabitHistory> history) {
    if (history.isEmpty) return [];
    final streaks = <int>[];
    int current = 0;
    for (final h in history) {
      if (h.noSugar) {
        current++;
      } else {
        if (current > 0) streaks.add(current);
        current = 0;
      }
    }
    if (current > 0) streaks.add(current);
    streaks.sort((a, b) => b.compareTo(a));
    return streaks;
  }

  String _monthLabel(DateTime dt) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  Widget _buildCalendar(DateTime month, List<HabitHistory> history, ThemeData theme) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final startWeekday = firstDay.weekday % 7; // Sun=0
    final daysInMonth = lastDay.day;

    final historyMap = <String, bool>{};
    for (final h in history) {
      historyMap[h.date] = h.noSugar;
    }

    final today = DateTime.now();
    final cells = <Widget>[];

    // Day labels
    for (final label in ['S', 'M', 'T', 'W', 'T', 'F', 'S']) {
      cells.add(
        Center(
          child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5))),
        ),
      );
    }

    // Empty cells before month starts
    for (int i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }

    // Day cells
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final noSugar = historyMap[dateStr];
      final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
      final isFuture = date.isAfter(today);

      Color? bgColor;
      Color textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
      if (isFuture) {
        bgColor = null;
        textColor = textColor.withValues(alpha: 0.25);
      } else if (noSugar == true) {
        bgColor = AppColors.green.withValues(alpha: 0.2);
        textColor = AppColors.green;
      } else if (noSugar == false) {
        bgColor = Colors.red.withValues(alpha: 0.15);
        textColor = Colors.red;
      }

      cells.add(
        Container(
          height: 38,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: isToday ? Border.all(color: AppColors.purple, width: 1.5) : null,
          ),
          child: Center(
            child: Text(
              '$day',
              style: TextStyle(fontSize: 13, fontWeight: isToday ? FontWeight.w700 : FontWeight.w500, color: textColor),
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      childAspectRatio: 1,
      children: cells,
    );
  }

  Widget _buildStreakCard(int index, int streakDays, ThemeData theme) {
    final medals = ['\u{1F947}', '\u{1F948}', '\u{1F949}'];
    final medal = index < 3 ? medals[index] : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppColors.black.withValues(alpha: 0.04), offset: const Offset(0, 2), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          if (medal != null)
            Text(medal, style: const TextStyle(fontSize: 22))
          else
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.grey.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: Text('${index + 1}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: theme.textTheme.bodySmall?.color))),
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streakDays day${streakDays != 1 ? 's' : ''} streak',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                Text(
                  _streakDescription(streakDays),
                  style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
                ),
              ],
            ),
          ),
          if (index == 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Best', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.green)),
            ),
        ],
      ),
    );
  }

  String _streakDescription(int days) {
    if (days >= 30) return 'Legendary discipline!';
    if (days >= 14) return 'Two weeks strong!';
    if (days >= 7) return 'A full week clean!';
    if (days >= 3) return 'Building momentum!';
    return 'Getting started!';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: AppColors.black.withValues(alpha: 0.04), offset: const Offset(0, 2), blurRadius: 8),
          ],
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(unit, style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.textTheme.bodySmall?.color)),
          ],
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
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
      ],
    );
  }
}
