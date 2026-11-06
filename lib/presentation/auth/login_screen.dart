import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:xonadosh/config/theme.dart';
import 'package:xonadosh/domain/uz_phone.dart';
import 'package:xonadosh/l10n/l10n_ext.dart';
import 'package:xonadosh/presentation/auth/apple_sign_in_button.dart';
import 'package:xonadosh/presentation/auth/auth_error.dart';
import 'package:xonadosh/presentation/auth/google_sign_in_button.dart';
import 'package:xonadosh/presentation/common/xonadosh_logo.dart';
import 'package:xonadosh/presentation/providers/app_providers.dart';
import 'package:xonadosh/presentation/router/app_routes.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _loginCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final raw = _loginCtrl.text.trim();
    final login = IntlPhone.isValid(raw) ? IntlPhone.normalize(raw) : raw;
    final res = await ref
        .read(authRepositoryProvider)
        .login(login: login, password: _passwordCtrl.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (res['ok'] == true) {
      ref.invalidate(authBootstrapProvider);
      if (context.mounted) context.go(AppRoutes.shell);
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
                    // Top dismiss bar for Lazy Auth (guests can return to browsing)
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
                      'XonaDoshga kirish',
                      style: XonaDoshStyles.h1.copyWith(
                        color: isDark ? Colors.white : XonaDoshColors.slate900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Maklersiz uylar va xonadoshlar olamiga kiring',
                      style: XonaDoshStyles.body(isDark),
                    ),
                    const SizedBox(height: 24),

                    // 1-TAP SOCIAL SIGN-IN AT THE VERY TOP (Airbnb / Kaspi style)
                    const GoogleSignInButton(),
                    const SizedBox(height: 10),
                    const AppleSignInButton(),
                    const SizedBox(height: 20),

                    // Elegant Divider
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

                    // Phone / Username Input
                    TextFormField(
                      controller: _loginCtrl,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.none,
                      autocorrect: false,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Telefon raqam yoki login',
                        hintText: '+998 90 123 45 67',
                        prefixIcon: const Icon(
                          Icons.phone_iphone_rounded,
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
                          (v == null || v.trim().isEmpty) ? 'Raqam yoki loginni kiriting' : null,
                    ),
                    const SizedBox(height: 12),

                    // Password Input
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscure,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Parol',
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
                      validator: (v) => (v == null || v.isEmpty) ? 'Parolni kiriting' : null,
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

                    // Primary CTA: Deep Teal
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
                              'Kirish',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                    const SizedBox(height: 14),

                    // Bottom Register Link
                    TextButton(
                      onPressed: () => context.go(AppRoutes.register),
                      child: RichText(
                        text: TextSpan(
                          text: 'Hisobingiz yo‘qmi? ',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? XonaDoshColors.slate400 : XonaDoshColors.slate600,
                          ),
                          children: const [
                            TextSpan(
                              text: 'Ro‘yxatdan o‘tish',
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
