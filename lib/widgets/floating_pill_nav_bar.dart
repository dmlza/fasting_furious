import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';

class FloatingPillNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;
  final int unreadCount;

  const FloatingPillNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    this.unreadCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1C2333).withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.6),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavItem(
                  icon: Icons.home_filled,
                  label: 'Home',
                  isActive: selectedIndex == 0,
                  onTap: () => onItemTapped(0),
                ),
                _NavItem(
                  icon: Icons.search,
                  label: 'Search',
                  isActive: selectedIndex == 1,
                  onTap: () => onItemTapped(1),
                ),
                _CreateButton(
                  onTap: () => onItemTapped(2),
                ),
                _NavItem(
                  icon: Icons.favorite_outline,
                  activeIcon: Icons.favorite,
                  label: 'Activity',
                  isActive: selectedIndex == 3,
                  onTap: () => onItemTapped(3),
                  badge: unreadCount,
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profile',
                  isActive: selectedIndex == 4,
                  onTap: () => onItemTapped(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final int badge;

  const _NavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive ? AppColors.purple.withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Badge(
                label: badge > 0 ? Text('$badge', style: GoogleFonts.poppins(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)) : null,
                isLabelVisible: badge > 0,
                backgroundColor: AppColors.green,
                smallSize: 16,
                child: Icon(
                  isActive ? (activeIcon ?? icon) : icon,
                  size: 24,
                  color: isActive ? AppColors.purple : AppColors.grey,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? AppColors.purple : AppColors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CreateButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: AppGradients.purpleGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.purple.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 26),
      ),
    );
  }
}
