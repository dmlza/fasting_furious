import 'dart:math';
import 'package:flutter/material.dart';
import '../config/theme.dart';

class FastingTimerRing extends StatelessWidget {
  final double progress;
  final Duration remaining;
  final Duration total;
  final String phase;
  final bool isActive;
  final String? preset;

  const FastingTimerRing({
    super.key,
    required this.progress,
    required this.remaining,
    required this.total,
    required this.phase,
    this.isActive = false,
    this.preset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring - progress
          SizedBox(
            width: 260,
            height: 260,
            child: CustomPaint(
              painter: _RingPainter(
                progress: progress.clamp(0.0, 1.0),
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.06),
                gradientColors: isActive
                    ? [AppColors.purple, AppColors.purple.withValues(alpha: 0.6)]
                    : [AppColors.purple.withValues(alpha: 0.3), AppColors.purple.withValues(alpha: 0.1)],
                strokeWidth: 12,
              ),
            ),
          ),

          // Inner ring - decorative
          SizedBox(
            width: 220,
            height: 220,
            child: CustomPaint(
              painter: _RingPainter(
                progress: 1.0,
                backgroundColor: Colors.transparent,
                gradientColors: [
                  theme.dividerColor.withValues(alpha: 0.3),
                  theme.dividerColor.withValues(alpha: 0.3),
                ],
                strokeWidth: 2,
              ),
            ),
          ),

          // Center content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (preset != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    preset!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.purple,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                '${remaining.inHours.toString().padLeft(2, '0')}:${(remaining.inMinutes % 60).toString().padLeft(2, '0')}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  color: theme.textTheme.bodyLarge?.color,
                  letterSpacing: 2,
                  height: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                phase.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isActive ? AppColors.purple : theme.textTheme.bodySmall?.color,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),

          // Milestone markers
          ..._buildMilestoneMarkers(context),
        ],
      ),
    );
  }

  List<Widget> _buildMilestoneMarkers(BuildContext context) {
    final milestones = [0.25, 0.5, 0.75];
    final labels = ['4h', '8h', '12h'];
    final theme = Theme.of(context);

    return List.generate(3, (i) {
      final angle = (milestones[i] * 2 * pi) - pi / 2;
      final radius = 130.0;
      final x = radius * cos(angle);
      final y = radius * sin(angle);
      final isReached = progress >= milestones[i];

      return Transform.translate(
        offset: Offset(x, y),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isReached ? AppColors.purple : theme.scaffoldBackgroundColor,
            border: Border.all(
              color: isReached ? AppColors.purple : theme.dividerColor,
              width: 2,
            ),
            boxShadow: isReached
                ? [BoxShadow(color: AppColors.purple.withValues(alpha: 0.3), blurRadius: 8)]
                : null,
          ),
          child: Center(
            child: Text(
              isReached ? '✓' : labels[i],
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: isReached ? Colors.white : theme.textTheme.bodySmall?.color,
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final List<Color> gradientColors;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.backgroundColor,
    required this.gradientColors,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: -pi / 2,
          endAngle: -pi / 2 + 2 * pi * progress,
          colors: gradientColors,
        ).createShader(Rect.fromCircle(center: center, radius: radius));

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.gradientColors != gradientColors;
  }
}
