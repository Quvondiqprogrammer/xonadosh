import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:xonadosh/config/theme.dart';
import 'package:xonadosh/l10n/l10n_ext.dart';
import 'package:xonadosh/presentation/common/xonadosh_logo.dart';
import 'package:xonadosh/presentation/features/xonadosh/widgets/onboarding_welcome.dart';
import 'package:xonadosh/presentation/providers/xonadosh_providers.dart';
import 'package:xonadosh/presentation/router/app_routes.dart';

import 'tabs/coliving_tab.dart';
import 'tabs/housing_tab.dart';
import 'tabs/matching_tab.dart';

/// Root shell of the XonaDosh app with high-end modern AppBar & Floating Frosted Dock.
class XonadoshShell extends ConsumerStatefulWidget {
  const XonadoshShell({super.key});

  @override
  ConsumerState<XonadoshShell> createState() => _XonadoshShellState();
}

class _XonadoshShellState extends ConsumerState<XonadoshShell> {
  static const _tabs = <Widget>[
    XonadoshHousingTab(),
    XonadoshMatchingTab(),
    XonadoshColivingTab(),
  ];

  bool _onboardingPrompted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowOnboarding());
  }

  Future<void> _maybeShowOnboarding() async {
    if (_onboardingPrompted || !mounted) return;
    _onboardingPrompted = true;
    final seen = await ref.read(onboardingStoreProvider).isSeen();
    if (!mounted || seen) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (ctx) => XonadoshOnboardingSheet(
        onDone: () {
          Navigator.of(ctx).pop();
        },
      ),
    );
    await ref.read(onboardingStoreProvider).markSeen();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final myProfile = ref.watch(xonadoshMyProfileProvider).valueOrNull;
    final currentIndex = ref.watch(xonadoshShellTabIndexProvider).clamp(0, 2);

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const XonaDoshLogo.mark(height: 32, width: 32, borderRadius: 10),
            const SizedBox(width: 10),
            Text(
              l10n.appName,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l10n.commonEdit,
            onPressed: () => context.push('${AppRoutes.shell}/profile-edit'),
            icon: CircleAvatar(
              radius: 14,
              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              backgroundImage: myProfile?.avatarUrl != null && myProfile!.avatarUrl!.isNotEmpty
                  ? NetworkImage(myProfile.avatarUrl!)
                  : null,
              child: myProfile?.avatarUrl == null || myProfile!.avatarUrl!.isEmpty
                  ? Text(
                      myProfile?.fullName.isNotEmpty == true ? myProfile!.fullName[0].toUpperCase() : 'U',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    )
                  : null,
            ),
          ),
          IconButton(
            tooltip: l10n.settings,
            icon: const Icon(Icons.settings_outlined, size: 22),
            onPressed: () => context.push(AppRoutes.settings),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: currentIndex,
          children: _tabs,
        ),
      ),
      bottomNavigationBar: _buildFloatingDock(context, isDark, l10n, currentIndex),
    );
  }

  Widget _buildFloatingDock(BuildContext context, bool isDark, dynamic l10n, int currentIndex) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF1E293B) : Colors.white).withValues(alpha: isDark ? 0.94 : 0.96),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: NavigationBar(
                selectedIndex: currentIndex,
                height: 60,
                elevation: 0,
                backgroundColor: Colors.transparent,
                indicatorColor: XonaDoshColors.primary.withValues(alpha: isDark ? 0.2 : 0.12),
                onDestinationSelected: (idx) {
                  if (!kIsWeb) {
                    HapticFeedback.selectionClick();
                  }
                  ref.read(xonadoshShellTabIndexProvider.notifier).state = idx;
                },
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.home_outlined),
                    selectedIcon: const Icon(Icons.home_rounded, color: XonaDoshColors.primary),
                    label: l10n.xonadoshHousingTab,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.group_outlined),
                    selectedIcon: const Icon(Icons.group_rounded, color: XonaDoshColors.primary),
                    label: l10n.xonadoshMatchingTab,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.checklist_rounded),
                    selectedIcon: const Icon(Icons.checklist_rounded, color: XonaDoshColors.primary),
                    label: l10n.xonadoshColivingTab,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
