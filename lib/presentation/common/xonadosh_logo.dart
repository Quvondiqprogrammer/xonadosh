import 'package:flutter/material.dart';

import 'package:xonadosh/config/brand_assets.dart';
import 'package:xonadosh/config/theme.dart';

/// Reusable XonaDosh logo image.
class XonaDoshLogo extends StatelessWidget {
  const XonaDoshLogo({
    super.key,
    this.height = 120,
    this.width,
    this.iconOnly = false,
    this.borderRadius,
  });

  /// Compact AppBar / nav mark.
  const XonaDoshLogo.mark({
    super.key,
    this.height = 36,
    this.width = 36,
    this.borderRadius = 10,
  }) : iconOnly = true;

  final double height;
  final double? width;
  final bool iconOnly;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final img = Image.asset(
      iconOnly ? BrandAssets.icon : BrandAssets.logo,
      height: height,
      width: width,
      fit: iconOnly ? BoxFit.cover : BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, _, _) => Icon(
        Icons.home_work_rounded,
        size: height * 0.7,
        color: XonaDoshColors.primary,
      ),
    );
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius!),
        child: img,
      );
    }
    return img;
  }
}
