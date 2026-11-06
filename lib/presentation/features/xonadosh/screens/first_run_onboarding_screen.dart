import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:xonadosh/config/theme.dart';
import 'package:xonadosh/core/services/xonadosh_retention_notification_service.dart';
import 'package:xonadosh/data/models/xonadosh_models.dart';
import 'package:xonadosh/presentation/common/xonadosh_logo.dart';
import 'package:xonadosh/presentation/providers/xonadosh_providers.dart';
import 'package:xonadosh/presentation/router/app_routes.dart';

/// Single-Screen Interactive Visual Onboarding (Instant 3-Second Clarity)
/// Lets students choose their university with 1 tap and immediately explore homes.
class FirstRunOnboardingScreen extends ConsumerStatefulWidget {
  const FirstRunOnboardingScreen({super.key});

  @override
  ConsumerState<FirstRunOnboardingScreen> createState() =>
      _FirstRunOnboardingScreenState();
}

class _FirstRunOnboardingScreenState
    extends ConsumerState<FirstRunOnboardingScreen> {
  final _searchController = TextEditingController();
  XonadoshUniversity? _selectedUni;
  String _searchQuery = '';

  static const List<Map<String, String>> _popularUniPresets = [
    {'name': 'TATU', 'short': 'TATU', 'city': 'Toshkent'},
    {'name': 'O‘zMU', 'short': 'O‘zMU', 'city': 'Toshkent'},
    {'name': 'TDTU (Politex)', 'short': 'TDTU', 'city': 'Toshkent'},
    {'name': 'Inha Universiteti', 'short': 'Inha', 'city': 'Toshkent'},
    {'name': 'Webster Universiteti', 'short': 'Webster', 'city': 'Toshkent'},
    {'name': 'MDIS (Singapur)', 'short': 'MDIS', 'city': 'Toshkent'},
    {'name': 'TDIU (Narxoz)', 'short': 'TDIU', 'city': 'Toshkent'},
    {'name': 'Jahondillari (O‘zDJTU)', 'short': 'O‘zDJTU', 'city': 'Toshkent'},
    {'name': 'Boshqa / OTM emas', 'short': 'Boshqa', 'city': 'Barcha'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _proceed({XonadoshUniversity? uni}) async {
    if (uni != null) {
      ref.read(xonadoshSelectedUniProvider.notifier).state = uni;
    }

    await ref.read(onboardingStoreProvider).markSeen();
    ref.invalidate(firstRunSeenProvider);

    try {
      final retention = ref.read(xonadoshRetentionNotificationServiceProvider);
      await retention.requestPermission();
      await retention.setupAllRetentionHooks();
    } catch (_) {}

    if (!mounted) return;
    context.go(AppRoutes.shell);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final allUnisAsync = ref.watch(xonadoshUniversitiesProvider);
    final liveUnis = allUnisAsync.valueOrNull ?? [];

    return Scaffold(
      backgroundColor: isDark ? XonaDoshColors.bgDark : XonaDoshColors.bgLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Brand Header
              Row(
                children: [
                  const XonaDoshLogo.mark(height: 36, width: 36, borderRadius: 10),
                  const SizedBox(width: 10),
                  Text(
                    'XonaDosh',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : XonaDoshColors.slate900,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _proceed(uni: null),
                    child: Text(
                      'O‘tkazib yuborish',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? XonaDoshColors.slate400 : XonaDoshColors.slate500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Headline & Visual Prompt
              Text(
                'Qaysi OTM yonidan uy yoki xonadosh qidiryapsiz?',
                style: XonaDoshStyles.h1.copyWith(
                  color: isDark ? Colors.white : XonaDoshColors.slate900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Universitetingizni tanlang, 12 daqiqalik radiusdagi eng arzon va maklersiz uylarni ko‘rsatamiz.',
                style: XonaDoshStyles.body(isDark),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),

              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: isDark ? XonaDoshColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? XonaDoshColors.borderDark : XonaDoshColors.borderLight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim().toLowerCase();
                    });
                  },
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'OTM yoki institut nomi...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: isDark ? XonaDoshColors.slate400 : XonaDoshColors.slate500,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: XonaDoshColors.emerald,
                      size: 22,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // University Chips Grid / Scrollable list
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mashhur OTMlar',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? XonaDoshColors.slate400 : XonaDoshColors.slate500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _buildUniChips(liveUnis, isDark),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Bottom Primary CTA
              Container(
                padding: const EdgeInsets.only(top: 12),
                child: FilledButton(
                  onPressed: () => _proceed(uni: _selectedUni),
                  style: FilledButton.styleFrom(
                    backgroundColor: XonaDoshColors.emerald,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _selectedUni != null
                            ? '${_selectedUni!.shortName} yonidagi uylarni ko‘rish →'
                            : 'Uylarni ko‘rish →',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildUniChips(List<XonadoshUniversity> liveUnis, bool isDark) {
    final list = <Widget>[];

    // If query is empty, show presets first matched with liveUnis
    for (final preset in _popularUniPresets) {
      if (_searchQuery.isNotEmpty) {
        final matchesName = preset['name']!.toLowerCase().contains(_searchQuery);
        final matchesShort = preset['short']!.toLowerCase().contains(_searchQuery);
        if (!matchesName && !matchesShort) continue;
      }

      // Check if matching live university exists
      XonadoshUniversity? matched;
      for (final u in liveUnis) {
        if (u.shortName.toLowerCase() == preset['short']!.toLowerCase() ||
            u.nameUz.toLowerCase().contains(preset['short']!.toLowerCase())) {
          matched = u;
          break;
        }
      }

      final isSelected = _selectedUni?.shortName.toLowerCase() == preset['short']!.toLowerCase();

      list.add(
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedUni = null;
              } else if (matched != null) {
                _selectedUni = matched;
              } else if (preset['short'] == 'Boshqa') {
                _selectedUni = null;
              } else {
                _selectedUni = XonadoshUniversity(
                  id: 0,
                  nameUz: preset['name']!,
                  shortName: preset['short']!,
                  city: preset['city']!,
                  district: 'Yunusobod',
                  address: preset['name']!,
                  latitude: 41.311081,
                  longitude: 69.240562,
                );
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? XonaDoshColors.emerald
                  : (isDark ? XonaDoshColors.cardDark : Colors.white),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? XonaDoshColors.emerald
                    : (isDark ? XonaDoshColors.borderDark : XonaDoshColors.borderLight),
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? XonaDoshColors.emerald.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                  blurRadius: isSelected ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  preset['short'] == 'Boshqa' ? Icons.location_city_rounded : Icons.school_rounded,
                  size: 16,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? XonaDoshColors.slate400 : XonaDoshColors.slate600),
                ),
                const SizedBox(width: 8),
                Text(
                  preset['name']!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white : XonaDoshColors.slate900),
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return list;
  }
}
