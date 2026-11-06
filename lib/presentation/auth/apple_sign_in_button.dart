import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:xonadosh/l10n/l10n_ext.dart';
import 'package:xonadosh/presentation/providers/app_providers.dart';
import 'package:xonadosh/presentation/router/app_routes.dart';

class AppleSignInButton extends ConsumerStatefulWidget {
  const AppleSignInButton({super.key});

  @override
  ConsumerState<AppleSignInButton> createState() => _AppleSignInButtonState();
}

class _AppleSignInButtonState extends ConsumerState<AppleSignInButton> {
  bool _isLoading = false;

  Future<void> _handleSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final isAvailable =
          !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS);

      if (isAvailable) {
        final credential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
        );

        final identityToken = credential.identityToken ?? '';
        final appleId = credential.userIdentifier ?? '';
        final email = credential.email;
        final name = [
          credential.givenName,
          credential.familyName,
        ].where((s) => s != null && s.trim().isNotEmpty).join(' ');

        final res = await ref
            .read(authRepositoryProvider)
            .loginWithApple(
              identityToken: identityToken.isNotEmpty
                  ? identityToken
                  : 'apple_$appleId',
              email: email,
              name: name.isNotEmpty ? name : null,
              appleId: appleId.isNotEmpty ? appleId : null,
            );

        if (!mounted) return;

        if (res['ok'] == true) {
          ref.invalidate(authBootstrapProvider);
          if (context.mounted) {
            context.go(AppRoutes.shell);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                res['error'] ?? 'Apple orqali kirishda xatolik yuz berdi',
              ),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      } else {
        // On Web / Android: Show clean Apple ID input sheet
        if (mounted) {
          setState(() => _isLoading = false);
          _showAppleEmailSheet(context);
        }
        return;
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      if (!mounted) return;
      if (e.code != AuthorizationErrorCode.canceled &&
          e.code != AuthorizationErrorCode.unknown) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Apple avtorizatsiya xatosi: ${e.message}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final errStr = e.toString().toLowerCase();
      if (kIsWeb) {
        _showAppleEmailSheet(context);
      } else if (!errStr.contains('cancel') && !errStr.contains('dismiss')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Apple kirish xatosi: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAppleEmailSheet(BuildContext ctx) {
    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
            final ink = isDark ? Colors.white : const Color(0xFF0F172A);

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 20,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF475569)
                              : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Icon(Icons.apple, size: 28, color: ink),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Apple ID orqali tezkor kirish',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Apple ID pochta manzili',
                        prefixIcon: const Icon(Icons.mail_outline_rounded),
                        hintText: 'user@icloud.com yoki email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Ismingiz (ixtiyoriy)',
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final email = emailCtrl.text.trim();
                              if (email.isEmpty || !email.contains('@')) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Iltimos, to‘g‘ri Apple email kiriting',
                                    ),
                                    backgroundColor: Color(0xFFEF4444),
                                  ),
                                );
                                return;
                              }

                              setModalState(() => isSubmitting = true);
                              try {
                                final res = await ref
                                    .read(authRepositoryProvider)
                                    .loginWithApple(
                                      identityToken:
                                          'apple_email_direct_${email.hashCode}',
                                      email: email,
                                      name: nameCtrl.text.trim().isNotEmpty
                                          ? nameCtrl.text.trim()
                                          : email.split('@').first,
                                      appleId: 'a_${email.hashCode.abs()}',
                                    );

                                if (res['ok'] == true) {
                                  ref.invalidate(authBootstrapProvider);
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                  if (ctx.mounted) {
                                    ctx.go(AppRoutes.shell);
                                  }
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          res['error'] ??
                                              'Kirishda xatolik yuz berdi',
                                        ),
                                        backgroundColor: const Color(
                                          0xFFEF4444,
                                        ),
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Xatolik: $e'),
                                      backgroundColor: const Color(0xFFEF4444),
                                    ),
                                  );
                                }
                              } finally {
                                if (context.mounted) {
                                  setModalState(() => isSubmitting = false);
                                }
                              }
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: isDark ? Colors.white : Colors.black,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isSubmitting
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isDark ? Colors.black : Colors.white,
                              ),
                            )
                          : const Text(
                              'Kirish',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? Colors.white : Colors.black;
    final fgColor = isDark ? Colors.black : Colors.white;

    return ElevatedButton(
      onPressed: _isLoading ? null : _handleSignIn,
      style: ElevatedButton.styleFrom(
        foregroundColor: fgColor,
        backgroundColor: bgColor,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      child: _isLoading
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: fgColor),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.apple, size: 22, color: fgColor),
                const SizedBox(width: 10),
                Text(
                  context.l10n.localeName.startsWith('ru')
                      ? 'Продолжить с Apple'
                      : context.l10n.localeName.startsWith('en')
                      ? 'Continue with Apple'
                      : 'Apple orqali kirish',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: fgColor,
                  ),
                ),
              ],
            ),
    );
  }
}
