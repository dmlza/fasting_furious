import 'package:flutter/material.dart';
import '../config/theme.dart';

class LandingScreen extends StatelessWidget {
  final VoidCallback onGetStarted;
  const LandingScreen({super.key, required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    // Logo
                    Text(
                      'Fasting Furious',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'train hard. fast harder.',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Phone mockup
                    _PhoneMockup(isDark: isDark),

                    const SizedBox(height: 40),

                    // Feature bullets
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        children: [
                          _FeatureRow(
                            icon: Icons.timer_outlined,
                            text: 'Track fasting & workouts',
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),
                          _FeatureRow(
                            icon: Icons.people_outline,
                            text: 'Challenge your friends',
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),
                          _FeatureRow(
                            icon: Icons.local_fire_department_outlined,
                            text: 'Build streaks & earn ranks',
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Bottom CTA
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: onGetStarted,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.indigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Create Account',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: onGetStarted,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.indigo,
                        side: const BorderSide(color: AppColors.indigo),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Log In',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhoneMockup extends StatelessWidget {
  final bool isDark;
  const _PhoneMockup({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 400,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Column(
          children: [
            // Status bar
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('9:41', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black)),
                  Row(
                    children: [
                      Icon(Icons.signal_cellular_4_bar, size: 14, color: isDark ? Colors.white : Colors.black),
                      const SizedBox(width: 4),
                      Icon(Icons.wifi, size: 14, color: isDark ? Colors.white : Colors.black),
                      const SizedBox(width: 4),
                      Icon(Icons.battery_full, size: 14, color: isDark ? Colors.white : Colors.black),
                    ],
                  ),
                ],
              ),
            ),

            // App bar mock
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Fasting Furious', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black)),
                  Icon(Icons.notifications_outlined, color: isDark ? Colors.white : Colors.black),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Timer card mock
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.indigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text('16:8', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.indigo)),
                    const SizedBox(height: 4),
                    Text('FASTING', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.indigo, letterSpacing: 2)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Activity rings mock
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MockRing(color: AppColors.indigo, size: 50),
                const SizedBox(width: 8),
                _MockRing(color: AppColors.emerald, size: 40),
                const SizedBox(width: 8),
                _MockRing(color: AppColors.amber, size: 30),
              ],
            ),
            const SizedBox(height: 16),

            // Feed preview mock
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  CircleAvatar(radius: 12, backgroundColor: AppColors.coral),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Alex completed a fast', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black)),
                        Text('2 hours ago', style: TextStyle(fontSize: 9, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MockRing extends StatelessWidget {
  final Color color;
  final double size;
  const _MockRing({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.2), width: 3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: CircularProgressIndicator(
          value: 0.7,
          strokeWidth: 3,
          backgroundColor: color.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;
  const _FeatureRow({required this.icon, required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.indigo.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.indigo, size: 20),
        ),
        const SizedBox(width: 16),
        Text(text, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black)),
      ],
    );
  }
}
