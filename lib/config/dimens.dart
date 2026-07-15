import 'package:flutter/material.dart';

abstract final class Dimens {
  static const paddingHorizontal = 20.0;
  static const paddingVertical = 24.0;
  static const cardRadius = 24.0;
  static const buttonRadius = 16.0;
  static const chipRadius = 999.0;

  double get paddingScreenHorizontal;
  double get paddingScreenVertical;
  double get cardSpacing;
  double get iconSize;
  double get avatarSize;

  static const Dimens mobile = DimensMobile();
  static const Dimens desktop = DimensDesktop();

  factory Dimens.of(BuildContext context) =>
      switch (MediaQuery.sizeOf(context).width) {
        > 600 && < 840 => desktop,
        >= 840 => desktop,
        _ => mobile,
      };
}

final class DimensMobile implements Dimens {
  const DimensMobile();

  @override
  final double paddingScreenHorizontal = 20.0;

  @override
  final double paddingScreenVertical = 24.0;

  @override
  final double cardSpacing = 16.0;

  @override
  final double iconSize = 24.0;

  @override
  final double avatarSize = 48.0;
}

final class DimensDesktop implements Dimens {
  const DimensDesktop();

  @override
  final double paddingScreenHorizontal = 32.0;

  @override
  final double paddingScreenVertical = 32.0;

  @override
  final double cardSpacing = 24.0;

  @override
  final double iconSize = 28.0;

  @override
  final double avatarSize = 56.0;
}
