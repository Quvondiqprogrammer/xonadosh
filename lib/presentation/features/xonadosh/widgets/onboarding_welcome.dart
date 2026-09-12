import 'package:flutter/material.dart';

import 'package:xonadosh/config/theme.dart';
import 'package:xonadosh/l10n/l10n_ext.dart';

class XonadoshOnboardingSheet extends StatelessWidget {
  const XonadoshOnboardingSheet({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.xonadoshOnboardingTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.4),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.xonadoshOnboardingSubtitle,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: isDark ? XonaDoshColors.slate400 : XonaDoshColors.slate500,
              ),
            ),
            const SizedBox(height: 16),
            _JobRow(
              icon: Icons.home_work_outlined,
              color: XonaDoshColors.emerald,
              title: l10n.xonadoshJobHousingTitle,
              body: l10n.xonadoshJobHousingBody,
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            _JobRow(
              icon: Icons.group_outlined,
              color: XonaDoshColors.accentPurple,
              title: l10n.xonadoshJobMatchTitle,
              body: l10n.xonadoshJobMatchBody,
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            _JobRow(
              icon: Icons.checklist_rounded,
              color: XonaDoshColors.amber,
              title: l10n.xonadoshJobColivingTitle,
              body: l10n.xonadoshJobColivingBody,
              isDark: isDark,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onDone,
              child: Text(l10n.xonadoshOnboardingStart),
            ),
          ],
        ),
      ),
    );
  }
}

class XonadoshJobsHero extends StatelessWidget {
  const XonadoshJobsHero({
    super.key,
    required this.onFindRoom,
    required this.onFindRoommate,
  });

  final VoidCallback onFindRoom;
  final VoidCallback onFindRoommate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: XonaDoshStyles.cardDecoration(isDark, hasShadow: false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.xonadoshHousingHeroTitle,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onFindRoom,
                  icon: const Icon(Icons.home_outlined, size: 18),
                  label: Text(l10n.xonadoshFindRoom),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onFindRoommate,
                  icon: const Icon(Icons.group_outlined, size: 18),
                  label: Text(l10n.xonadoshFindRoommate),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class XonadoshColivingUnlockTip extends StatelessWidget {
  const XonadoshColivingUnlockTip({
    super.key,
    required this.onFindRoom,
    required this.onFindRoommate,
  });

  final VoidCallback onFindRoom;
  final VoidCallback onFindRoommate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : XonaDoshColors.emeraldLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? XonaDoshColors.borderDark : XonaDoshColors.emerald.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.xonadoshColivingUnlockTitle,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.xonadoshColivingUnlockTip,
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: isDark ? XonaDoshColors.slate400 : XonaDoshColors.slate600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                visualDensity: VisualDensity.compact,
                avatar: const Icon(Icons.home_outlined, size: 14),
                label: Text(l10n.xonadoshFindRoom),
                onPressed: onFindRoom,
              ),
              ActionChip(
                visualDensity: VisualDensity.compact,
                avatar: const Icon(Icons.group_outlined, size: 14),
                label: Text(l10n.xonadoshFindRoommate),
                onPressed: onFindRoommate,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _JobRow extends StatelessWidget {
  const _JobRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.isDark,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.2 : 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              const SizedBox(height: 2),
              Text(
                body,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: isDark ? XonaDoshColors.slate400 : XonaDoshColors.slate500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
