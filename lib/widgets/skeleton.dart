import 'package:flutter/material.dart';

class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class FeedSkeleton extends StatelessWidget {
  const FeedSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: 3,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SkeletonBox(width: 36, height: 36, borderRadius: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 120, height: 12),
                      const SizedBox(height: 6),
                      SkeletonBox(width: 80, height: 10),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SkeletonBox(width: double.infinity, height: 14),
            const SizedBox(height: 8),
            SkeletonBox(width: 200, height: 14),
            const SizedBox(height: 14),
            Row(
              children: [
                SkeletonBox(width: 60, height: 32, borderRadius: 16),
                const SizedBox(width: 8),
                SkeletonBox(width: 60, height: 32, borderRadius: 16),
                const SizedBox(width: 8),
                SkeletonBox(width: 60, height: 32, borderRadius: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            children: [
              SkeletonBox(width: 72, height: 72, borderRadius: 36),
              const SizedBox(height: 12),
              SkeletonBox(width: 140, height: 18),
              const SizedBox(height: 8),
              SkeletonBox(width: 100, height: 14),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SkeletonBox(width: 100, height: 36, borderRadius: 10),
                  const SizedBox(width: 8),
                  SkeletonBox(width: 100, height: 36, borderRadius: 10),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: SkeletonBox(height: 72, borderRadius: 14)),
            const SizedBox(width: 12),
            Expanded(child: SkeletonBox(height: 72, borderRadius: 14)),
            const SizedBox(width: 12),
            Expanded(child: SkeletonBox(height: 72, borderRadius: 14)),
          ],
        ),
      ],
    );
  }
}

class FriendsSkeleton extends StatelessWidget {
  const FriendsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) => Row(
        children: [
          SkeletonBox(width: 44, height: 44, borderRadius: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 120, height: 14),
                const SizedBox(height: 6),
                SkeletonBox(width: 80, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
