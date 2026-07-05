import 'dart:ui';
import 'package:flutter/material.dart';

class ClipStatusBar extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();

    path.moveTo(0, h * 0.1);
    path.quadraticBezierTo(0, h * 0.1, w * 0.4, h * 0.1);
    path.lineTo(w * 0.5, h * 0.1);
    path.quadraticBezierTo(w, h * 0.1, w, h * 0.25);
    path.lineTo(w, h * 0.75);
    path.quadraticBezierTo(w, h * 0.9, w * 0.5, h * 0.9);
    path.lineTo(w * 0.4, h * 0.9);
    path.quadraticBezierTo(0, h * 0.9, 0, h);

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class GlassPostCard extends StatelessWidget {
  final Widget child;
  final LinearGradient? gradient;
  final VoidCallback? onTap;
  final double radius;

  const GlassPostCard({
    super.key,
    required this.child,
    this.gradient,
    this.onTap,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 35,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: gradient != null
              ? Container(
                  decoration: BoxDecoration(gradient: gradient),
                  child: child,
                )
              : child,
        ),
      ),
    );
  }
}

class GlassSidebar extends StatelessWidget {
  final List<Widget> children;

  const GlassSidebar({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: ClipStatusBar(),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 85,
          color: Colors.white.withValues(alpha: 0.2),
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: children,
          ),
        ),
      ),
    );
  }
}

class GlassActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isActive;
  final Color? activeColor;

  const GlassActionButton({
    super.key,
    required this.icon,
    this.onTap,
    this.isActive = false,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? (activeColor ?? Colors.white).withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}
