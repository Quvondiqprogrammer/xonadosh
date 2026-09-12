import 'package:flutter/material.dart';

import 'package:xonadosh/config/theme.dart';
import 'package:xonadosh/l10n/l10n_ext.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.action,
    this.secondaryAction,
    this.accentColor,
  });

  final String? title;
  final String? subtitle;
  final IconData icon;
  final Widget? action;
  final Widget? secondaryAction;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = accentColor ?? XonaDoshColors.emerald;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: isDark ? 0.16 : 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: accent),
            ),
            const SizedBox(height: 16),
            Text(
              title ?? l10n.emptyStateTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle ?? l10n.emptyStateSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? XonaDoshColors.slate400 : XonaDoshColors.slate500,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 18),
              action!,
            ],
            if (secondaryAction != null) ...[
              const SizedBox(height: 8),
              secondaryAction!,
            ],
          ],
        ),
      ),
    );
  }
}
