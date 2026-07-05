import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
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
                    const SizedBox(height: 48),
                    FadeInDown(
                      duration: const Duration(milliseconds: 800),
                      child: Text(
                        'Fasting Furious',
                        style: GoogleFonts.poppins(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: AppColors.purple,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadeInDown(
                      delay: const Duration(milliseconds: 200),
                      duration: const Duration(milliseconds: 800),
                      child: Text(
                        'train hard. fast harder.',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: AppColors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 44),
                    FadeInUp(
                      delay: const Duration(milliseconds: 400),
                      duration: const Duration(milliseconds: 800),
                      child: _PhoneMockup(isDark: isDark),
                    ),
                    const SizedBox(height: 44),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        children: [
                          FadeInLeft(
                            delay: const Duration(milliseconds: 600),
                            duration: const Duration(milliseconds: 600),
                            child: _FeatureRow(
                              icon: Icons.timer_outlined,
                              text: 'Track fasting & workouts',
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(height: 18),
                          FadeInLeft(
                            delay: const Duration(milliseconds: 750),
                            duration: const Duration(milliseconds: 600),
                            child: _FeatureRow(
                              icon: Icons.people_outline,
                              text: 'Challenge your friends',
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(height: 18),
                          FadeInLeft(
                            delay: const Duration(milliseconds: 900),
                            duration: const Duration(milliseconds: 600),
                            child: _FeatureRow(
                              icon: Icons.local_fire_department_outlined,
                              text: 'Build streaks & earn ranks',
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            FadeInUp(
              delay: const Duration(milliseconds: 1000),
              duration: const Duration(milliseconds: 600),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: onGetStarted,
                        child: const Text(
                          'Create Account',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: onGetStarted,
                        child: const Text(
                          'Log In',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
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
      width: 240,
      height: 440,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8F8FA),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withOpacity(0.08),
            blurRadius: 50,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: Column(
          children: [
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Fasting Furious', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black)),
                  Icon(Icons.notifications_outlined, color: isDark ? Colors.white : Colors.black),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppGradients.purpleGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text('16:8', style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('FASTING', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white70, letterSpacing: 2)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MockRing(color: AppColors.purple, size: 50),
                const SizedBox(width: 8),
                _MockRing(color: AppColors.green, size: 40),
                const SizedBox(width: 8),
                _MockRing(color: AppColors.purple, size: 30),
              ],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  CircleAvatar(radius: 14, backgroundColor: AppColors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Alex completed a fast', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black)),
                        Text('2 hours ago', style: GoogleFonts.poppins(fontSize: 9, color: (isDark ? Colors.white : Colors.black).withOpacity(0.5))),
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
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.purple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.purple, size: 22),
        ),
        const SizedBox(width: 16),
        Text(text, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black)),
      ],
    );
  }
}
