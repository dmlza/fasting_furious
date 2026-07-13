import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/habit_provider.dart';
import '../models/models.dart';
import '../widgets/health_recovery_timeline.dart';

const _triggers = [
  ('Stress', '\u{1F6CB}\uFE0F'),
  ('Social', '\u{1F37B}'),
  ('After meals', '\u{1F35D}'),
  ('Boredom', '\u{1F634}'),
  ('Alcohol', '\u{1F378}'),
  ('Cravings', '\u{1F525}'),
  ('Morning', '\u2600\uFE0F'),
  ('Driving', '\u{1F697}'),
  ('Work break', '\u{1F4BC}'),
  ('Other', '\u{2753}'),
];

String _formatDateShort(DateTime dt) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final today = DateTime.now();
  final isToday = dt.year == today.year && dt.month == today.month && dt.day == today.day;
  final yesterday = today.subtract(const Duration(days: 1));
  final isYesterday = dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day;
  if (isToday) return 'Today';
  if (isYesterday) return 'Yesterday';
  return '${months[dt.month - 1]} ${dt.day}';
}

const _dailyTips = [
  'Take deep breaths when cravings hit. They pass in 3-5 minutes.',
  'Drink water slowly. Cravings often mask dehydration.',
  'Move your body — even a 5-minute walk reduces urge intensity.',
  'Chew gum or eat a crunchy snack to occupy your mouth.',
  'Call a friend. Social support cuts relapse risk by 40%.',
  'Remind yourself: the craving is your body healing, not suffering.',
  'Avoid triggers for the first 2 weeks. Different route, different routine.',
  'Every cigarette not smoked saves 11 minutes of life.',
  'Your sense of taste returns in 48 hours. Food will taste incredible.',
  'After 1 year, your heart disease risk drops to half.',
  'The hardest days are 3-5. After that, it gets significantly easier.',
  'You are not "giving up" something. You are freeing yourself.',
];

class NoSmokeScreen extends ConsumerStatefulWidget {
  const NoSmokeScreen({super.key});

  @override
  ConsumerState<NoSmokeScreen> createState() => _NoSmokeScreenState();
}

class _NoSmokeScreenState extends ConsumerState<NoSmokeScreen> {
  String _habitName = 'No Smoking';
  String _habitIcon = '\u{1F6AB}';
  late DateTime _currentMonth;
  double _packPrice = 10.0;
  int _cigsPerPack = 20;
  int _baselineCigs = 10;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _habitName = prefs.getString('ff_nosmoke_name') ?? 'No Smoking';
        _habitIcon = prefs.getString('ff_nosmoke_icon') ?? '\u{1F6AB}';
        _packPrice = prefs.getDouble('ff_pack_price') ?? 10.0;
        _cigsPerPack = prefs.getInt('ff_cigs_per_pack') ?? 20;
        _baselineCigs = prefs.getInt('ff_baseline_cigs') ?? 10;
      });
    }
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ff_nosmoke_name', _habitName);
    await prefs.setString('ff_nosmoke_icon', _habitIcon);
    await prefs.setDouble('ff_pack_price', _packPrice);
    await prefs.setInt('ff_cigs_per_pack', _cigsPerPack);
    await prefs.setInt('ff_baseline_cigs', _baselineCigs);
  }

  @override
  Widget build(BuildContext context) {
    final habitState = ref.watch(habitProvider);
    final streak = habitState.getStreak('no_smoking');
    final isCheckedToday = habitState.habits.noSmoking;
    final smokingLog = habitState.smokingLog;
    final timeSinceQuit = Duration(days: streak);
    final theme = Theme.of(context);
    final dailyTip = _dailyTips[DateTime.now().day % _dailyTips.length];

    final stats = _computeStats(habitState.history, smokingLog);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(_habitName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            onPressed: _showSettingsSheet,
            icon: const Icon(Icons.settings_outlined, size: 20),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
        children: [
          // Hero streak ring
          FadeInDown(
            duration: const Duration(milliseconds: 500),
            child: _buildStreakHero(streak, isCheckedToday, theme),
          ),
          const SizedBox(height: 20),

          // Stats row
          FadeInUp(
            duration: const Duration(milliseconds: 500),
            delay: const Duration(milliseconds: 80),
            child: _buildStatsRow(stats, theme),
          ),
          const SizedBox(height: 20),

          // Check-in
          FadeInUp(
            duration: const Duration(milliseconds: 500),
            delay: const Duration(milliseconds: 100),
            child: _buildCheckInCard(streak, isCheckedToday, theme),
          ),
          const SizedBox(height: 20),

          // Daily tip
          FadeInUp(
            duration: const Duration(milliseconds: 500),
            delay: const Duration(milliseconds: 150),
            child: _buildTipCard(dailyTip, theme),
          ),
          const SizedBox(height: 24),

          // Calendar
          FadeInUp(
            duration: const Duration(milliseconds: 500),
            delay: const Duration(milliseconds: 180),
            child: _buildCalendarSection(habitState.history, smokingLog, theme),
          ),
          const SizedBox(height: 24),

          // Trigger analysis
          if (stats.triggerCounts.isNotEmpty)
            FadeInUp(
              duration: const Duration(milliseconds: 500),
              delay: const Duration(milliseconds: 200),
              child: _buildTriggerAnalysis(stats, theme),
            ),
          if (stats.triggerCounts.isNotEmpty) const SizedBox(height: 24),

          // Health milestones
          FadeInUp(
            duration: const Duration(milliseconds: 500),
            delay: const Duration(milliseconds: 220),
            child: HealthRecoveryTimeline(
              timeSinceQuit: timeSinceQuit,
              compact: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakHero(int streak, bool isCheckedToday, ThemeData theme) {
    final ringColor = streak > 0 ? AppColors.green : AppColors.grey;
    final progress = streak > 0 ? (streak / 365).clamp(0.0, 1.0) : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ringColor.withValues(alpha: 0.08),
            Theme.of(context).scaffoldBackgroundColor,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: streak > 0 ? progress : 1.0,
                    strokeWidth: 12,
                    backgroundColor: theme.dividerColor.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation(
                      streak > 0 ? ringColor : ringColor.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$streak',
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                        color: streak > 0 ? ringColor : ringColor.withValues(alpha: 0.4),
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'day${streak != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: streak > 0 ? ringColor : ringColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _getMotivationalMessage(streak),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color),
          ),
          const SizedBox(height: 4),
          Text(
            _getMotivationalSubtext(streak),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: theme.textTheme.bodySmall?.color),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(_SmokingStats stats, ThemeData theme) {
    return Row(
      children: [
        _StatPill(
          icon: Icons.savings_outlined,
          value: '\$${stats.moneySaved.toStringAsFixed(0)}',
          label: 'saved',
          color: AppColors.green,
        ),
        const SizedBox(width: 8),
        _StatPill(
          icon: Icons.smoke_free_outlined,
          value: '${stats.cigsAvoided}',
          label: 'avoided',
          color: AppColors.purple,
        ),
        const SizedBox(width: 8),
        _StatPill(
          icon: Icons.local_fire_department_outlined,
          value: '${stats.longestStreak}',
          label: 'best',
          color: AppColors.green,
        ),
      ],
    );
  }

  Widget _buildCheckInCard(int streak, bool isCheckedToday, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: isCheckedToday
            ? Border.all(color: AppColors.green.withValues(alpha: 0.3), width: 2)
            : null,
        boxShadow: [
          BoxShadow(color: AppColors.black.withValues(alpha: 0.04), offset: const Offset(0, 2), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          Text(
            isCheckedToday ? 'Checked in today' : 'Ready to check in?',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isCheckedToday ? AppColors.green : theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isCheckedToday ? 'Keep going! Every day counts.' : 'Confirm your status for today.',
            style: TextStyle(fontSize: 13, color: theme.textTheme.bodySmall?.color),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: isCheckedToday
                ? OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.check_circle, size: 20),
                    label: const Text('Done for today', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.green,
                      disabledForegroundColor: AppColors.green,
                      side: BorderSide(color: AppColors.green.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: () => _showCheckInDialog(),
                    icon: const Icon(Icons.local_fire_department, size: 20, color: Colors.white),
                    label: Text(
                      streak == 0 ? 'Start Streak' : 'Check In',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(String tip, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.purple.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('\u{1F4A1}', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily Tip', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.purple)),
                const SizedBox(height: 4),
                Text(tip, style: TextStyle(fontSize: 13, color: theme.textTheme.bodySmall?.color, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarSection(List<HabitHistory> history, List<SmokingLog> log, ThemeData theme) {
    // Merge habit history (primary) with smoking log (supplementary details)
    final mergedMap = <String, SmokingLog>{};
    for (final h in history) {
      mergedMap[h.date] = SmokingLog(
        date: h.date,
        cigarettes: h.noSmoking ? 0 : 1,
      );
    }
    // Smoking log overrides with actual cigarette count
    for (final entry in log) {
      mergedMap[entry.date] = entry;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.calendar_today, size: 18, color: AppColors.purple),
            const SizedBox(width: 8),
            const Text('Tracking Calendar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 12),
        // Month navigation
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1)),
              icon: const Icon(Icons.chevron_left, size: 22),
            ),
            Expanded(
              child: Center(
                child: Text(_monthLabel(_currentMonth), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1)),
              icon: const Icon(Icons.chevron_right, size: 22),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildCalendar(_currentMonth, mergedMap, theme),
        const SizedBox(height: 12),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(color: AppColors.green, label: 'Current streak'),
            const SizedBox(width: 10),
            _LegendDot(color: AppColors.green.withValues(alpha: 0.3), label: 'Past smoke-free'),
            const SizedBox(width: 10),
            _LegendDot(color: Colors.orange, label: 'Slip'),
            const SizedBox(width: 10),
            _LegendDot(color: Colors.red, label: 'Relapse'),
          ],
        ),
      ],
    );
  }

  Widget _buildCalendar(DateTime month, Map<String, SmokingLog> logMap, ThemeData theme) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final startWeekday = firstDay.weekday % 7;
    final daysInMonth = lastDay.day;
    final today = DateTime.now();
    final cells = <Widget>[];

    // Compute streak days in this month (consecutive smoke-free days ending today or yesterday)
    final streakDays = _computeStreakDays(logMap, today);

    for (final label in ['S', 'M', 'T', 'W', 'T', 'F', 'S']) {
      cells.add(Center(
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5))),
      ));
    }

    for (int i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final entry = logMap[dateStr];
      final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
      final isFuture = date.isAfter(today);
      final isStreakDay = streakDays.contains(dateStr);

      Color? bgColor;
      Color textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
      String? icon;

      if (isFuture) {
        textColor = textColor.withValues(alpha: 0.25);
      } else if (isStreakDay && isToday) {
        // Current streak day + today: show streak count
        bgColor = AppColors.green;
        textColor = Colors.white;
        icon = '${streakDays.length}';
      } else if (isStreakDay) {
        // Part of current streak: bright green, connected look
        bgColor = AppColors.green.withValues(alpha: 0.3);
        textColor = AppColors.green;
        icon = '\u2713';
      } else if (entry != null) {
        if (entry.isSmokeFree) {
          bgColor = AppColors.green.withValues(alpha: 0.12);
          textColor = AppColors.green.withValues(alpha: 0.7);
          icon = '\u2713';
        } else if (entry.isSlip) {
          bgColor = Colors.orange.withValues(alpha: 0.15);
          textColor = Colors.orange;
          icon = '${entry.cigarettes}';
        } else {
          bgColor = Colors.red.withValues(alpha: 0.15);
          textColor = Colors.red;
          icon = '${entry.cigarettes}';
        }
      }

      cells.add(
        GestureDetector(
          onTap: isFuture ? null : () => _showDayEditDialog(date, entry),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: isToday
                  ? Border.all(color: isStreakDay ? Colors.white.withValues(alpha: 0.5) : AppColors.purple, width: 1.5)
                  : null,
              boxShadow: isStreakDay && isToday
                  ? [BoxShadow(color: AppColors.green.withValues(alpha: 0.3), blurRadius: 8)]
                  : null,
            ),
            child: Center(
              child: icon != null
                  ? Text(icon, style: TextStyle(fontSize: isStreakDay && isToday ? 15 : 13, fontWeight: FontWeight.w700, color: textColor))
                  : Text('$day', style: TextStyle(fontSize: 13, fontWeight: isToday ? FontWeight.w700 : FontWeight.w500, color: textColor)),
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

  Widget _buildTriggerAnalysis(_SmokingStats stats, ThemeData theme) {
    final sorted = stats.triggerCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppColors.black.withValues(alpha: 0.04), offset: const Offset(0, 2), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('\u{1F3AF}', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              const Text('Common Triggers', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          ...sorted.take(5).map((entry) {
            final trigger = _triggers.firstWhere(
              (t) => t.$1 == entry.key,
              orElse: () => (entry.key, '\u{2753}'),
            );
            final maxCount = sorted.first.value;
            final fraction = maxCount > 0 ? entry.value / maxCount : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(trigger.$2, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 80,
                    child: Text(trigger.$1, style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: fraction,
                        backgroundColor: theme.dividerColor.withValues(alpha: 0.3),
                        valueColor: AlwaysStoppedAnimation(Colors.orange),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${entry.value}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textTheme.bodySmall?.color)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Check-in dialog ───

  void _showCheckInDialog() {
    final habitState = ref.read(habitProvider);
    final streak = habitState.getStreak('no_smoking');

    if (streak == 0) {
      _showStartStreakDialog();
    } else {
      _showDailyCheckIn();
    }
  }

  void _showStartStreakDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [const Text('\u{1F525}', style: TextStyle(fontSize: 24)), const SizedBox(width: 8), const Text('Start Your Streak', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This is a big decision. Every journey starts with one day.', style: TextStyle(fontSize: 14, height: 1.5)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('What to expect:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.green)),
                  const SizedBox(height: 6),
                  Text(
                    '\u2022 Cravings peak at days 3-5\n\u2022 Heart rate normalizes in 20 min\n\u2022 Taste returns in 48 hours\n\u2022 Lung function improves in 2 weeks',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color, height: 1.6),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Not yet')),
          ElevatedButton(
            onPressed: () { Navigator.of(ctx).pop(); _doSmokeFreeCheckIn(); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text("Let's go!", style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showDailyCheckIn() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CheckInSheet(
        date: DateTime.now(),
        onSmokeFree: () { Navigator.of(ctx).pop(); _doSmokeFreeCheckIn(); },
        onSmoked: (cigs, trigger, craving) { Navigator.of(ctx).pop(); _doSmokedCheckIn(cigs, trigger, craving); },
      ),
    );
  }

  void _showDayEditDialog(DateTime date, SmokingLog? existing) {
    final isToday = date.year == DateTime.now().year && date.month == DateTime.now().month && date.day == DateTime.now().day;
    final isFuture = date.isAfter(DateTime.now());
    if (isFuture) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CheckInSheet(
        date: date,
        existing: existing,
        onSmokeFree: () async {
          Navigator.of(ctx).pop();
          final user = ref.read(currentUserProvider);
          if (user == null) return;
          final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          await ref.read(supabaseServiceProvider).saveSmokingLog(user.id, date: dateStr, cigarettes: 0);
          // Update habits table too if it's today
          if (isToday) {
            await ref.read(habitProvider.notifier).setHabit(user.id, 'no_smoking', true);
          }
          await ref.read(habitProvider.notifier).fetchSmokingLog(user.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${_formatDateShort(date)} marked smoke-free'), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            );
          }
        },
        onSmoked: (cigs, trigger, craving) async {
          Navigator.of(ctx).pop();
          final user = ref.read(currentUserProvider);
          if (user == null) return;
          final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          await ref.read(supabaseServiceProvider).saveSmokingLog(
            user.id, date: dateStr, cigarettes: cigs, trigger: trigger, cravingIntensity: craving,
          );
          await ref.read(habitProvider.notifier).fetchSmokingLog(user.id);
          if (mounted) {
            final label = cigs <= 2 ? 'Slip' : 'Relapse';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${_formatDateShort(date)}: $label logged ($cigs cigarette${cigs != 1 ? 's' : ''})'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _doSmokeFreeCheckIn() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    HapticFeedback.heavyImpact();
    final today = DateTime.now().toIso8601String().split('T')[0];

    // Save to smoking log
    await ref.read(supabaseServiceProvider).saveSmokingLog(user.id, date: today, cigarettes: 0);

    // Set habit to smoke-free (not toggle, to avoid flipping off if already on)
    await ref.read(habitProvider.notifier).setHabit(user.id, 'no_smoking', true);
    await ref.read(habitProvider.notifier).fetchSmokingLog(user.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('\u{1F525} Smoke-free day logged!'), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      );
    }
  }

  Future<void> _doSmokedCheckIn(int cigarettes, String? trigger, int? craving) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    HapticFeedback.mediumImpact();
    final today = DateTime.now().toIso8601String().split('T')[0];

    await ref.read(supabaseServiceProvider).saveSmokingLog(
      user.id, date: today, cigarettes: cigarettes, trigger: trigger, cravingIntensity: craving,
    );
    await ref.read(habitProvider.notifier).fetchSmokingLog(user.id);

    if (mounted) {
      final label = cigarettes <= 2 ? 'Slip' : 'Relapse';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label logged. $cigarettes cigarette${cigarettes != 1 ? 's' : ''}. Tomorrow is a new day.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // ─── Settings ───

  void _showSettingsSheet() {
    final nameController = TextEditingController(text: _habitName);
    final priceController = TextEditingController(text: _packPrice.toStringAsFixed(0));
    final packController = TextEditingController(text: '$_cigsPerPack');
    final baselineController = TextEditingController(text: '$_baselineCigs');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(left: 24, right: 24, top: 12, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              const Text('Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextField(controller: nameController, decoration: const InputDecoration(hintText: 'Habit name')),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Pack price', prefixText: '\$ ')),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: packController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Cigs/pack'))),
                ],
              ),
              const SizedBox(height: 12),
              TextField(controller: baselineController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Your baseline cigs/day')),
              const SizedBox(height: 8),
              Text('Used to calculate cigarettes avoided.', style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _habitName = nameController.text.trim().isNotEmpty ? nameController.text.trim() : 'No Smoking';
                      _packPrice = double.tryParse(priceController.text) ?? 10.0;
                      _cigsPerPack = int.tryParse(packController.text) ?? 20;
                      _baselineCigs = int.tryParse(baselineController.text) ?? 10;
                    });
                    _savePrefs();
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helpers ───

  _SmokingStats _computeStats(List<HabitHistory> history, List<SmokingLog> log) {
    int totalCigs = 0;
    int smokeFreeDays = 0;
    int longestStreak = 0;
    int currentStreak = 0;
    final triggerCounts = <String, int>{};

    // Build merged timeline from habit history
    final sortedHistory = List<HabitHistory>.from(history)..sort((a, b) => a.date.compareTo(b.date));
    final smokingLogMap = <String, SmokingLog>{};
    for (final entry in log) {
      smokingLogMap[entry.date] = entry;
    }

    for (final h in sortedHistory) {
      final logEntry = smokingLogMap[h.date];
      final cigs = logEntry?.cigarettes ?? (h.noSmoking ? 0 : 1);
      totalCigs += cigs;
      if (cigs == 0) {
        smokeFreeDays++;
        currentStreak++;
        if (currentStreak > longestStreak) longestStreak = currentStreak;
      } else {
        currentStreak = 0;
        if (logEntry?.trigger != null) {
          triggerCounts[logEntry!.trigger!] = (triggerCounts[logEntry.trigger!] ?? 0) + 1;
        }
      }
    }

    final baselineTotal = _baselineCigs * smokeFreeDays;
    final cigsAvoided = baselineTotal - totalCigs;
    final packsAvoided = cigsAvoided / _cigsPerPack;
    final moneySaved = packsAvoided * _packPrice;

    return _SmokingStats(
      moneySaved: moneySaved > 0 ? moneySaved : 0,
      cigsAvoided: cigsAvoided > 0 ? cigsAvoided : 0,
      longestStreak: longestStreak,
      triggerCounts: triggerCounts,
    );
  }

  String _monthLabel(DateTime dt) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  String _getMotivationalMessage(int streak) {
    if (streak == 0) return 'Ready to begin?';
    if (streak == 1) return 'One day at a time.';
    if (streak < 7) return 'Building momentum!';
    if (streak < 14) return 'One full week strong!';
    if (streak < 30) return 'Your body is healing.';
    if (streak < 90) return 'Incredible discipline.';
    if (streak < 365) return 'A true non-smoker.';
    return 'Unstoppable.';
  }

  String _getMotivationalSubtext(int streak) {
    if (streak == 0) return 'Every champion was once a beginner.';
    if (streak < 7) return 'The hardest part is behind you.';
    if (streak < 14) return 'Cravings are getting weaker.';
    if (streak < 30) return 'Lung function improving daily.';
    if (streak < 90) return 'Heart disease risk dropping.';
    if (streak < 365) return 'Your lungs are almost fully healed.';
    return 'Your risk is now half of a smoker\'s.';
  }

  Set<String> _computeStreakDays(Map<String, SmokingLog> logMap, DateTime today) {
    final streakDays = <String>{};
    // Walk backwards from today, collecting consecutive smoke-free days
    var date = today;
    while (true) {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final entry = logMap[dateStr];
      if (entry != null && entry.isSmokeFree) {
        streakDays.add(dateStr);
        date = date.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streakDays;
  }
}

// ─── Check-in Sheet ───

class _CheckInSheet extends StatefulWidget {
  final DateTime date;
  final SmokingLog? existing;
  final VoidCallback onSmokeFree;
  final void Function(int cigarettes, String? trigger, int? craving) onSmoked;

  const _CheckInSheet({required this.date, this.existing, required this.onSmokeFree, required this.onSmoked});

  @override
  State<_CheckInSheet> createState() => _CheckInSheetState();
}

class _CheckInSheetState extends State<_CheckInSheet> {
  late int _cigarettes;
  String? _selectedTrigger;
  late int _cravingIntensity;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _cigarettes = widget.existing!.cigarettes;
      _selectedTrigger = widget.existing!.trigger;
      _cravingIntensity = widget.existing!.cravingIntensity ?? 3;
    } else {
      _cigarettes = 0;
      _cravingIntensity = 3;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text(_formatDateShort(widget.date), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            widget.existing != null
                ? (widget.existing!.isSmokeFree ? 'Logged as smoke-free' : '${widget.existing!.cigarettes} cigarette${widget.existing!.cigarettes != 1 ? 's' : ''}')
                : 'No entry yet',
            style: TextStyle(fontSize: 13, color: theme.textTheme.bodySmall?.color),
          ),
          const SizedBox(height: 20),

          // Smoke-free button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: widget.onSmokeFree,
              icon: const Icon(Icons.check_circle, size: 20, color: Colors.white),
              label: const Text('Smoke-free today', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
          ),
          const SizedBox(height: 16),
          Center(child: Text('OR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textTheme.bodySmall?.color))),
          const SizedBox(height: 16),

          // Cigarette count
          Text('How many cigarettes?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.textTheme.bodySmall?.color)),
          const SizedBox(height: 8),
          Row(
            children: [1, 2, 3, 5, 10].map((n) {
              final isSelected = _cigarettes == n;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: GestureDetector(
                    onTap: () => setState(() => _cigarettes = n),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (n <= 2 ? Colors.orange.withValues(alpha: 0.12) : Colors.red.withValues(alpha: 0.12))
                            : theme.dividerColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                        border: isSelected
                            ? Border.all(color: n <= 2 ? Colors.orange : Colors.red, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: Text('$n', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isSelected ? (n <= 2 ? Colors.orange : Colors.red) : theme.textTheme.bodySmall?.color)),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_cigarettes > 0) ...[
            const SizedBox(height: 16),
            // Trigger
            Text('What triggered it?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.textTheme.bodySmall?.color)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _triggers.map((t) {
                final isSelected = _selectedTrigger == t.$1;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTrigger = isSelected ? null : t.$1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.orange.withValues(alpha: 0.12) : theme.dividerColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: isSelected ? Border.all(color: Colors.orange, width: 1.5) : null,
                    ),
                    child: Text('${t.$2} ${t.$1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? Colors.orange : theme.textTheme.bodySmall?.color)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Craving intensity
            Text('Craving intensity: $_cravingIntensity/5', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.textTheme.bodySmall?.color)),
            const SizedBox(height: 4),
            Slider(
              value: _cravingIntensity.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              activeColor: Colors.orange,
              onChanged: (v) => setState(() => _cravingIntensity = v.round()),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Mild', style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color)),
                Text('Extreme', style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color)),
              ],
            ),
          ],
          const SizedBox(height: 20),

          if (_cigarettes > 0)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => widget.onSmoked(_cigarettes, _selectedTrigger, _cravingIntensity),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: Text('Log ${_cigarettes} cigarette${_cigarettes != 1 ? 's' : ''}', style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Stat Pill ───

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatPill({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: AppColors.black.withValues(alpha: 0.04), offset: const Offset(0, 2), blurRadius: 8)],
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 1),
            Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
          ],
        ),
      ),
    );
  }
}

// ─── Legend Dot ───

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodySmall?.color)),
      ],
    );
  }
}

// ─── Stats Data ───

class _SmokingStats {
  final double moneySaved;
  final int cigsAvoided;
  final int longestStreak;
  final Map<String, int> triggerCounts;

  const _SmokingStats({
    required this.moneySaved,
    required this.cigsAvoided,
    required this.longestStreak,
    required this.triggerCounts,
  });
}
