import 'package:flutter/material.dart';
import '../config/theme.dart';

class HealthMilestone {
  final String icon;
  final String title;
  final String description;
  final Duration timeFromQuit;
  final Color color;

  const HealthMilestone({
    required this.icon,
    required this.title,
    required this.description,
    required this.timeFromQuit,
    required this.color,
  });
}

List<HealthMilestone> healthMilestones = [
  HealthMilestone(
    icon: '\u2764\uFE0F',
    title: 'Heart Rate Normalizes',
    description: 'Your heart rate drops to normal levels. Blood pressure begins to stabilize.',
    timeFromQuit: Duration(minutes: 20),
    color: AppColors.green,
  ),
  HealthMilestone(
    icon: '\u{1FAC0}',
    title: 'Carbon Monoxide Clears',
    description: 'Carbon monoxide levels in blood drop to normal. Oxygen levels increase.',
    timeFromQuit: Duration(hours: 24),
    color: AppColors.purple,
  ),
  HealthMilestone(
    icon: '\u{1F442}',
    title: 'Taste & Smell Return',
    description: 'Nerve endings begin to regenerate. Food tastes better, smells are stronger.',
    timeFromQuit: Duration(hours: 48),
    color: AppColors.green,
  ),
  HealthMilestone(
    icon: '\u{1F331}',
    title: 'Lung Function Improves',
    description: 'Bronchial tubes relax. Energy increases. Walking becomes easier.',
    timeFromQuit: Duration(days: 3),
    color: AppColors.purple,
  ),
  HealthMilestone(
    icon: '\u{1F4AA}',
    title: 'Circulation Boost',
    description: 'Blood circulation improves significantly. Physical activities feel easier.',
    timeFromQuit: Duration(days: 7),
    color: AppColors.purple,
  ),
  HealthMilestone(
    icon: '\u{1F33F}',
    title: 'Lung Cilia Regrow',
    description: 'Tiny hair-like structures in lungs regrow. Breathing becomes easier.',
    timeFromQuit: Duration(days: 14),
    color: AppColors.green,
  ),
  HealthMilestone(
    icon: '\u2728',
    title: 'Skin Health Improves',
    description: 'Skin tone improves. Premature aging slows down. Teeth whitening begins.',
    timeFromQuit: Duration(days: 30),
    color: AppColors.purple,
  ),
  HealthMilestone(
    icon: '\u{1F3AF}',
    title: 'Heart Disease Risk Halved',
    description: 'Risk of heart disease drops to half that of a smoker. Major milestone!',
    timeFromQuit: Duration(days: 365),
    color: AppColors.green,
  ),
];

class HealthRecoveryTimeline extends StatelessWidget {
  final Duration timeSinceQuit;
  final bool compact;

  const HealthRecoveryTimeline({
    super.key,
    required this.timeSinceQuit,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) return _buildCompactView(context);
    return _buildFullView(context);
  }

  Widget _buildCompactView(BuildContext context) {
    final achieved = _getAchievedMilestones();
    final next = _getNextMilestone();
    final progress = next != null
        ? timeSinceQuit.inSeconds / next.timeFromQuit.inSeconds
        : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${achieved.length}/${healthMilestones.length}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.green),
            ),
            const SizedBox(width: 8),
            Text(
              'Milestones Unlocked',
              style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (next != null) ...[
          Text(
            'Next: ${next.title}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Theme.of(context).dividerColor.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation(AppColors.green),
            borderRadius: BorderRadius.circular(2),
            minHeight: 4,
          ),
          const SizedBox(height: 4),
          Text(
            _formatDuration(next.timeFromQuit - timeSinceQuit),
            style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color),
          ),
        ] else ...[
          Text(
            'All milestones achieved!',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.green),
          ),
        ],
      ],
    );
  }

  Widget _buildFullView(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Health Recovery Timeline',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        ...healthMilestones.map((milestone) {
          final isAchieved = timeSinceQuit >= milestone.timeFromQuit;
          final isNext = _getNextMilestone() == milestone;
          final remaining = milestone.timeFromQuit - timeSinceQuit;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isAchieved
                  ? milestone.color.withValues(alpha: 0.08)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: isNext
                  ? Border.all(color: milestone.color, width: 2)
                  : isAchieved
                      ? Border.all(color: milestone.color.withValues(alpha: 0.3), width: 1)
                      : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isAchieved
                        ? milestone.color.withValues(alpha: 0.15)
                        : theme.dividerColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      milestone.icon,
                      style: TextStyle(
                        fontSize: 24,
                        color: isAchieved ? null : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        milestone.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isAchieved ? theme.textTheme.bodyLarge?.color : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        milestone.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: isAchieved
                              ? theme.textTheme.bodySmall?.color
                              : Colors.grey.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isAchieved)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '\u2713',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.green),
                    ),
                  )
                else if (remaining.isNegative)
                  const SizedBox.shrink()
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.dividerColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _formatDuration(remaining),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.textTheme.bodySmall?.color),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  List<HealthMilestone> _getAchievedMilestones() {
    return healthMilestones.where((m) => timeSinceQuit >= m.timeFromQuit).toList();
  }

  HealthMilestone? _getNextMilestone() {
    for (final m in healthMilestones) {
      if (timeSinceQuit < m.timeFromQuit) return m;
    }
    return null;
  }

  String _formatDuration(Duration d) {
    if (d.inDays > 0) return '${d.inDays}d remaining';
    if (d.inHours > 0) return '${d.inHours}h remaining';
    return '${d.inMinutes}m remaining';
  }
}
