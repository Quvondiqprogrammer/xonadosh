import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:xonadosh/config/theme.dart';
import 'package:xonadosh/core/services/xonadosh_retention_notification_service.dart';
import 'package:xonadosh/l10n/l10n_ext.dart';
import 'package:xonadosh/presentation/common/xonadosh_logo.dart';
import 'package:xonadosh/presentation/providers/xonadosh_providers.dart';
import 'package:xonadosh/presentation/router/app_routes.dart';

/// Unique first-run (3 screens) for Uzbekistan university roommate/housing.
/// Not shared with Ikkinchi/VCall — campus-scoped copy + Campus Fit preview.
class FirstRunOnboardingScreen extends ConsumerStatefulWidget {
  const FirstRunOnboardingScreen({super.key});

  @override
  ConsumerState<FirstRunOnboardingScreen> createState() =>
      _FirstRunOnboardingScreenState();
}

class _FirstRunOnboardingScreenState
    extends ConsumerState<FirstRunOnboardingScreen> {
  final _pageController = PageController();
  int _index = 0;

  static const _pages = <_OnboardPageData>[
    _OnboardPageData(
      icon: Icons.school_rounded,
      color: XonaDoshColors.emerald,
      titleKey: 'housing',
    ),
    _OnboardPageData(
      icon: Icons.diversity_3_rounded,
      color: XonaDoshColors.accentPurple,
      titleKey: 'match',
    ),
    _OnboardPageData(
      icon: Icons.checklist_rtl_rounded,
      color: XonaDoshColors.amber,
      titleKey: 'coliving',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish({bool enableNotifications = false}) async {
    await ref.read(onboardingStoreProvider).markSeen();
    ref.invalidate(firstRunSeenProvider);

    if (enableNotifications) {
      final retention = ref.read(xonadoshRetentionNotificationServiceProvider);
      await retention.requestPermission();
      await retention.setupAllRetentionHooks();
    }

    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  void _next() {
    if (_index >= _pages.length - 1) {
      _finish(enableNotifications: true);
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titles = [
      l10n.xdFirstRunHousingTitle,
      l10n.xdFirstRunMatchTitle,
      l10n.xdFirstRunColivingTitle,
    ];
    final bodies = [
      l10n.xdFirstRunHousingBody,
      l10n.xdFirstRunMatchBody,
      l10n.xdFirstRunColivingBody,
    ];
    final chips = [
      [
        l10n.xdFirstRunChipTashkent,
        l10n.xdFirstRunChipSamarkand,
        l10n.xdFirstRunChipNearCampus,
      ],
      [
        l10n.xdFirstRunChipSleep,
        l10n.xdFirstRunChipClean,
        l10n.xdFirstRunChipBudget,
        l10n.xdFirstRunChipSameUni,
      ],
      [
        l10n.xdFirstRunChipChores,
        l10n.xdFirstRunChipGroceries,
        l10n.xdFirstRunChipExpenses,
      ],
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: [
                  const XonaDoshLogo.mark(
                    height: 36,
                    width: 36,
                    borderRadius: 10,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l10n.appName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _finish,
                    child: Text(l10n.xdFirstRunSkip),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final page = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(flex: 1),
                        Center(
                          child: Container(
                            width: 112,
                            height: 112,
                            decoration: BoxDecoration(
                              color: page.color.withValues(
                                alpha: isDark ? 0.22 : 0.14,
                              ),
                              borderRadius: BorderRadius.circular(32),
                            ),
                            child: Icon(page.icon, size: 56, color: page.color),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          titles[i],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          bodies[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.45,
                            color: isDark
                                ? XonaDoshColors.slate400
                                : XonaDoshColors.slate600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final c in chips[i])
                              Chip(
                                label: Text(
                                  c,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                                backgroundColor: page.color.withValues(
                                  alpha: isDark ? 0.18 : 0.12,
                                ),
                                side: BorderSide.none,
                              ),
                          ],
                        ),
                        if (i == 1) ...[
                          const SizedBox(height: 20),
                          _CampusFitPreviewCard(isDark: isDark),
                        ],
                        const Spacer(flex: 2),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final active = i == _index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active
                              ? XonaDoshColors.primary
                              : (isDark
                                    ? Colors.white24
                                    : const Color(0xFFCBD5E1)),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _next,
                      child: Text(
                        _index == _pages.length - 1
                            ? l10n.xdFirstRunDone
                            : l10n.xdFirstRunNext,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
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

class _CampusFitPreviewCard extends StatelessWidget {
  const _CampusFitPreviewCard({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [XonaDoshColors.accentPurple, XonaDoshColors.emerald],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              '87%',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.xdCampusFitTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.xdCampusFitPreviewBody,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: isDark
                        ? XonaDoshColors.slate400
                        : XonaDoshColors.slate500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardPageData {
  const _OnboardPageData({
    required this.icon,
    required this.color,
    required this.titleKey,
  });

  final IconData icon;
  final Color color;
  final String titleKey;
}
