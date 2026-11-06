import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:xonadosh/config/theme.dart';
import 'package:xonadosh/core/services/xonadosh_retention_notification_service.dart';
import 'package:xonadosh/domain/uz_phone.dart';
import 'package:xonadosh/l10n/l10n_ext.dart';
import 'package:xonadosh/presentation/auth/apple_sign_in_button.dart';
import 'package:xonadosh/presentation/auth/auth_error.dart';
import 'package:xonadosh/presentation/auth/country_picker_sheet.dart';
import 'package:xonadosh/presentation/auth/google_sign_in_button.dart';
import 'package:xonadosh/presentation/common/xonadosh_logo.dart';
import 'package:xonadosh/presentation/providers/app_providers.dart';
import 'package:xonadosh/presentation/router/app_routes.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;
  PhoneCountry _country = PhoneCountry.uzbekistan;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCountry() async {
    final next = await showCountryPickerSheet(context, selected: _country);
    if (next == null || !mounted || next.iso == _country.iso) return;
    setState(() => _country = next);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final normalizedPhone = IntlPhone.normalize(_phoneCtrl.text, country: _country);
    final autoUsername = 'user_${IntlPhone.digits(normalizedPhone).replaceAll(RegExp(r'\D'), '')}';

    final res = await ref.read(authRepositoryProvider).register(
          fullName: _nameCtrl.text.trim(),
          username: autoUsername,
          phone: normalizedPhone,
          password: _passwordCtrl.text,
        );

    if (!mounted) return;
    setState(() => _loading = false);

    if (res['ok'] == true) {
      ref.invalidate(authBootstrapProvider);
      try {
        final retention = ref.read(xonadoshRetentionNotificationServiceProvider);
        await retention.sendWelcomeNotification();
        await retention.setupAllRetentionHooks();
      } catch (_) {}
      if (mounted) context.go(AppRoutes.shell);
    } else {
      setState(() => _error = localizedAuthError(context.l10n, res));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? XonaDoshColors.bgDark : XonaDoshColors.bgLight,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top dismiss bar for Lazy Auth
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const XonaDoshLogo.mark(height: 36, width: 36, borderRadius: 10),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 22),
                          tooltip: 'Yopish',
                          onPressed: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            } else {
                              context.go(AppRoutes.shell);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Ro‘yxatdan o‘tish',
                      style: XonaDoshStyles.h1.copyWith(
                        color: isDark ? Colors.white : XonaDoshColors.slate900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '30 soniyada o‘z profilingizni yarating',
                      style: XonaDoshStyles.body(isDark),
                    ),
                    const SizedBox(height: 24),

                    // 1-TAP SOCIAL SIGN-IN AT THE VERY TOP
                    const GoogleSignInButton(),
                    const SizedBox(height: 10),
                    const AppleSignInButton(),
                    const SizedBox(height: 20),

                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: isDark ? XonaDoshColors.borderDark : XonaDoshColors.borderLight,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'yoki telefon orqali',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? XonaDoshColors.slate400 : XonaDoshColors.slate500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: isDark ? XonaDoshColors.borderDark : XonaDoshColors.borderLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Full Name Input
                    TextFormField(
                      controller: _nameCtrl,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Ism va familiyangiz',
                        hintText: 'Ali Valiyev',
                        prefixIcon: const Icon(
                          Icons.person_outline_rounded,
                          color: XonaDoshColors.emerald,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: isDark ? XonaDoshColors.cardDark : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark ? XonaDoshColors.borderDark : XonaDoshColors.borderLight,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark ? XonaDoshColors.borderDark : XonaDoshColors.borderLight,
                          ),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Ismingizni kiriting' : null,
                    ),
                    const SizedBox(height: 12),

                    // Phone Input with Country Code
                    TextFormField(
                      controller: _phoneCtrl,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Telefon raqam',
                        hintText: '90 123 45 67',
                        prefixIcon: InkWell(
                          onTap: _pickCountry,
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_country.flag, style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 4),
                                Text(
                                  '+${_country.dial}',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                                const Icon(Icons.arrow_drop_down, size: 16),
                              ],
                            ),
                          ),
                        ),
                        filled: true,
                        fillColor: isDark ? XonaDoshColors.cardDark : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark ? XonaDoshColors.borderDark : XonaDoshColors.borderLight,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark ? XonaDoshColors.borderDark : XonaDoshColors.borderLight,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Telefon raqamni kiriting';
                        if (!IntlPhone.isValid(v, country: _country)) {
                          return 'To‘liq telefon raqamni kiriting';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Password Input
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscure,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Parol o‘ylab toping',
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          color: XonaDoshColors.emerald,
                          size: 20,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            size: 18,
                          ),
                        ),
                        filled: true,
                        fillColor: isDark ? XonaDoshColors.cardDark : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark ? XonaDoshColors.borderDark : XonaDoshColors.borderLight,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark ? XonaDoshColors.borderDark : XonaDoshColors.borderLight,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.length < 6) {
                          return 'Parol kamida 6 belgidan iborat bo‘lsin';
                        }
                        return null;
                      },
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Primary CTA
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: XonaDoshColors.emerald,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Ro‘yxatdan o‘tish',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                    const SizedBox(height: 14),

                    // Bottom Login Link
                    TextButton(
                      onPressed: () => context.go(AppRoutes.login),
                      child: RichText(
                        text: TextSpan(
                          text: 'Hisobingiz bormi? ',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? XonaDoshColors.slate400 : XonaDoshColors.slate600,
                          ),
                          children: const [
                            TextSpan(
                              text: 'Kirish',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: XonaDoshColors.emerald,
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
          ),
        ),
      ),
    );
  }
}
