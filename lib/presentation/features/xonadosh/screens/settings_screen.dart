import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:xonadosh/config/app_config.dart';
import 'package:xonadosh/config/theme.dart';
import 'package:xonadosh/l10n/l10n_ext.dart';
import 'package:xonadosh/presentation/common/xonadosh_logo.dart';
import 'package:xonadosh/presentation/providers/xonadosh_providers.dart';
import 'package:xonadosh/presentation/router/app_routes.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // App Logo & Version
            Center(
              child: Column(
                children: [
                  const XonaDoshLogo.mark(height: 72, width: 72, borderRadius: 20),
                  const SizedBox(height: 10),
                  Text(
                    l10n.appName,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                  Text(
                    'Talabalar uy-joy va xonadosh platformasi • v${AppConfig.appVersion}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Group 1: Preferences (Language & Theme)
            _buildSectionHeader('Ilova sozlamalari'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE8EEF3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.language_rounded, size: 20, color: XonaDoshColors.emerald),
                      const SizedBox(width: 8),
                      Text(
                        l10n.settingsLanguage,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'uz', label: Text('🇺🇿 O‘zbek')),
                        ButtonSegment(value: 'ru', label: Text('🇷🇺 Русский')),
                        ButtonSegment(value: 'en', label: Text('🇬🇧 English')),
                      ],
                      selected: {locale.languageCode},
                      onSelectionChanged: (s) {
                        ref.read(localeProvider.notifier).setLocale(Locale(s.first));
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.dark_mode_outlined, size: 20, color: XonaDoshColors.accentPurple),
                      const SizedBox(width: 8),
                      Text(
                        l10n.settingsTheme,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      segments: [
                        ButtonSegment(value: ThemeMode.light, label: Text(l10n.settingsThemeLight)),
                        ButtonSegment(value: ThemeMode.dark, label: Text(l10n.settingsThemeDark)),
                        ButtonSegment(value: ThemeMode.system, label: Text(l10n.settingsThemeSystem)),
                      ],
                      selected: {themeMode},
                      onSelectionChanged: (s) {
                        ref.read(themeModeProvider.notifier).setMode(s.first);
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Group 2: Legal & About
            _buildSectionHeader('Hujjatlar va Ma’lumot'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE8EEF3)),
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined, color: XonaDoshColors.emerald),
                    title: Text(l10n.settingsPrivacy, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () => _open(AppConfig.privacyUrl),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.description_outlined, color: XonaDoshColors.emerald),
                    title: Text(l10n.settingsTerms, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () => _open(AppConfig.termsUrl),
                  ),
                ],
              ),
              ),
            ),

            const SizedBox(height: 20),

            _buildSectionHeader(l10n.blockUser),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE8EEF3)),
              ),
              child: Material(
                color: Colors.transparent,
                child: ref.watch(blockedUsernamesProvider).when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  error: (_, _) => ListTile(title: Text(l10n.errorGeneric)),
                  data: (blocked) {
                    if (blocked.isEmpty) {
                      return ListTile(
                        leading: const Icon(Icons.block_rounded, color: Color(0xFF94A3B8)),
                        title: Text(l10n.emptyStateTitle, style: const TextStyle(fontSize: 14)),
                      );
                    }
                    return Column(
                      children: [
                        for (final (i, name) in blocked.toList().indexed) ...[
                          if (i > 0) const Divider(height: 1, indent: 56),
                          ListTile(
                            leading: const Icon(Icons.block_rounded, color: Color(0xFFEF4444)),
                            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            trailing: TextButton(
                              onPressed: () async {
                                await ref.read(blockStoreProvider).unblock(name);
                                ref.invalidate(blockedUsernamesProvider);
                                ref.invalidate(xonadoshListingsProvider);
                                ref.invalidate(xonadoshMatchingRoommatesProvider);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(l10n.userUnblocked)),
                                  );
                                }
                              },
                              child: Text(l10n.unblockUser),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Group 3: Account Actions
            _buildSectionHeader('Hisob'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE8EEF3)),
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.logout_rounded, color: Color(0xFFF59E0B)),
                    title: Text(l10n.settingsLogout, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    onTap: () async {
                      await ref.read(authRepositoryProvider).logout();
                      ref.invalidate(authBootstrapProvider);
                      ref.invalidate(xonadoshMyProfileProvider);
                      ref.invalidate(xonadoshMatchingRoommatesProvider);
                      ref.invalidate(xonadoshListingsProvider);
                      if (context.mounted) context.go(AppRoutes.login);
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                    title: Text(
                      l10n.accountDelete,
                      style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    onTap: () async {
                      final passwordCtrl = TextEditingController();
                      try {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: Text(l10n.accountDeleteTitle, style: const TextStyle(fontWeight: FontWeight.w800)),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(l10n.accountDeleteBody, style: const TextStyle(fontSize: 13)),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: passwordCtrl,
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    labelText: l10n.loginPassword,
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text(l10n.commonCancel),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text(l10n.commonDelete),
                              ),
                            ],
                          ),
                        );
                        if (ok == true && context.mounted) {
                          final res = await ref.read(authRepositoryProvider).deleteAccount(
                                password: passwordCtrl.text,
                              );
                          if (!context.mounted) return;
                          if (res['ok'] == true) {
                            ref.invalidate(authBootstrapProvider);
                            ref.invalidate(xonadoshMyProfileProvider);
                            ref.invalidate(xonadoshMatchingRoommatesProvider);
                            ref.invalidate(xonadoshListingsProvider);
                            context.go(AppRoutes.login);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(res['error']?.toString() ?? l10n.errorGeneric),
                              ),
                            );
                          }
                        }
                      } finally {
                        passwordCtrl.dispose();
                      }
                    },
                  ),
                ],
              ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Color(0xFF94A3B8),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
