import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _scrollCtrl = ScrollController();
  final _nameCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _nameFocus = FocusNode();
  final _userFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  bool _submitted = false;
  String? _error;
  PhoneCountry _country = PhoneCountry.uzbekistan;

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _nameCtrl.dispose();
    _userCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _nameFocus.dispose();
    _userFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (!(_formKey.currentState?.validate() ?? false)) {
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    final res = await ref
        .read(authRepositoryProvider)
        .register(
          fullName: _nameCtrl.text.trim(),
          username: AuthUsername.normalize(_userCtrl.text),
          phone: IntlPhone.normalize(_phoneCtrl.text, country: _country),
          password: _passwordCtrl.text,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    if (res['ok'] == true) {
      ref.invalidate(authBootstrapProvider);
      ref
          .read(xonadoshRetentionNotificationServiceProvider)
          .sendWelcomeNotification();
      ref
          .read(xonadoshRetentionNotificationServiceProvider)
          .setupAllRetentionHooks();
      if (context.mounted) context.go(AppRoutes.shell);
    } else {
      setState(() => _error = localizedAuthError(context.l10n, res));
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _pickCountry() async {
    final next = await showCountryPickerSheet(context, selected: _country);
    if (next == null || !mounted || next.iso == _country.iso) return;
    setState(() {
      _country = next;
      final d = IntlPhone.digits(_phoneCtrl.text);
      if (d.length > next.maxNational) {
        final cut = d.substring(0, next.maxNational);
        _phoneCtrl.text = IntlPhone.formatNational(cut, next);
      }
    });
  }

  void _onPhoneChanged(String v) {
    final t = v.trim();
    if (!(t.startsWith('+') || t.startsWith('00'))) return;
    final detected = IntlPhone.detectCountry(t);
    if (detected == null || detected.iso == _country.iso) return;
    final national = IntlPhone.nationalDigits(t, detected);
    final formatted = IntlPhone.formatNational(national, detected);
    setState(() => _country = detected);
    _phoneCtrl.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.opaque,
              child: Form(
                key: _formKey,
                autovalidateMode: _submitted
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: ListView(
                  controller: _scrollCtrl,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        tooltip: l10n.login,
                        onPressed: _loading
                            ? null
                            : () => context.go(AppRoutes.login),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                    ),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: XonaDoshColors.emerald.withValues(
                                alpha: 0.18,
                              ),
                              blurRadius: 18,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const XonaDoshLogo.mark(
                          height: 64,
                          width: 64,
                          borderRadius: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.registerTitle,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.registerSubtitle,
                      style: TextStyle(
                        color: muted,
                        fontSize: 14,
                        height: 1.35,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 22),
                    AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _nameCtrl,
                            focusNode: _nameFocus,
                            enabled: !_loading,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            autofillHints: const [AutofillHints.name],
                            onFieldSubmitted: (_) => _userFocus.requestFocus(),
                            decoration: InputDecoration(
                              labelText: l10n.registerFullName,
                              hintText: l10n.registerFullNameHint,
                              prefixIcon: const Icon(
                                Icons.badge_outlined,
                                color: XonaDoshColors.emerald,
                              ),
                            ),
                            validator: (v) {
                              final t = (v ?? '').trim();
                              if (t.length < 2) return l10n.registerNameInvalid;
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _userCtrl,
                            focusNode: _userFocus,
                            enabled: !_loading,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.none,
                            autocorrect: false,
                            enableSuggestions: false,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [
                              AutofillHints.username,
                              AutofillHints.newUsername,
                            ],
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[A-Za-z0-9._]'),
                              ),
                              TextInputFormatter.withFunction((
                                oldValue,
                                newValue,
                              ) {
                                final lower = newValue.text.toLowerCase();
                                if (lower == newValue.text) return newValue;
                                return newValue.copyWith(
                                  text: lower,
                                  selection: TextSelection.collapsed(
                                    offset: lower.length,
                                  ),
                                );
                              }),
                            ],
                            onFieldSubmitted: (_) => _phoneFocus.requestFocus(),
                            decoration: InputDecoration(
                              labelText: l10n.registerUsername,
                              hintText: l10n.registerUsernameHint,
                              helperText: l10n.registerUsernameHelper,
                              helperMaxLines: 2,
                              prefixIcon: const Icon(
                                Icons.person_outline_rounded,
                                color: XonaDoshColors.emerald,
                              ),
                            ),
                            validator: (v) {
                              if (!AuthUsername.isValid(v ?? '')) {
                                return l10n.registerUsernameInvalid;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phoneCtrl,
                            focusNode: _phoneFocus,
                            enabled: !_loading,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [
                              AutofillHints.telephoneNumber,
                            ],
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9+ ]'),
                              ),
                              PhoneNationalFormatter(_country),
                            ],
                            onChanged: _onPhoneChanged,
                            onFieldSubmitted: (_) =>
                                _passwordFocus.requestFocus(),
                            decoration: InputDecoration(
                              labelText: l10n.registerPhone,
                              hintText: _country.hint.isNotEmpty
                                  ? _country.hint
                                  : '90 123 45 67',
                              helperText: l10n.registerPhoneCountryHint,
                              helperMaxLines: 2,
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 118,
                                minHeight: 48,
                              ),
                              prefixIcon: SizedBox(
                                width: 118,
                                child: InkWell(
                                  onTap: _loading ? null : _pickCountry,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      left: 8,
                                      right: 2,
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          _country.flag,
                                          style: const TextStyle(fontSize: 18),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            _country.dial.isEmpty
                                                ? '+'
                                                : '+${_country.dial}',
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                              color: isDark
                                                  ? Colors.white
                                                  : XonaDoshColors.slate800,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          Icons.expand_more_rounded,
                                          size: 18,
                                          color: isDark
                                              ? const Color(0xFF94A3B8)
                                              : XonaDoshColors.slate500,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            validator: (v) {
                              if (!IntlPhone.isValid(
                                v ?? '',
                                country: _country,
                              )) {
                                return l10n.registerPhoneInvalid;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordCtrl,
                            focusNode: _passwordFocus,
                            enabled: !_loading,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.newPassword],
                            onFieldSubmitted: (_) =>
                                _confirmFocus.requestFocus(),
                            decoration: InputDecoration(
                              labelText: l10n.registerPassword,
                              helperText: l10n.registerPasswordHint,
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                color: XonaDoshColors.emerald,
                              ),
                              suffixIcon: IconButton(
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                ),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.length < 8) {
                                return l10n.registerPasswordHint;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _confirmCtrl,
                            focusNode: _confirmFocus,
                            enabled: !_loading,
                            obscureText: _obscureConfirm,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.newPassword],
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: l10n.registerPasswordConfirm,
                              prefixIcon: const Icon(
                                Icons.lock_reset_outlined,
                                color: XonaDoshColors.emerald,
                              ),
                              suffixIcon: IconButton(
                                onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm,
                                ),
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                ),
                              ),
                            ),
                            validator: (v) {
                              if (v != _passwordCtrl.text) {
                                return l10n.registerPasswordMismatch;
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(
                              0xFFEF4444,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                l10n.registerButton,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            context.l10n.localeName.startsWith('ru')
                                ? 'или'
                                : context.l10n.localeName.startsWith('en')
                                ? 'or'
                                : 'yoki',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const GoogleSignInButton(),
                    const SizedBox(height: 10),
                    const AppleSignInButton(),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () => context.go(AppRoutes.login),
                      child: Text(
                        l10n.registerHaveAccount,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
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
