import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:xonadosh/l10n/l10n_ext.dart';
import 'package:xonadosh/presentation/providers/app_providers.dart';
import 'package:xonadosh/presentation/router/app_routes.dart';

const String _kGoogleWebClientId =
    '1062554549724-j9d4uiqhht6443bats7uj3oipduc9bn2.apps.googleusercontent.com';

class GoogleSignInButton extends ConsumerStatefulWidget {
  const GoogleSignInButton({super.key});

  @override
  ConsumerState<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends ConsumerState<GoogleSignInButton> {
  bool _isLoading = false;

  Future<void> _handleSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final googleSignIn = GoogleSignIn(
        serverClientId: _kGoogleWebClientId,
        scopes: const ['email', 'profile'],
      );

      final account = await googleSignIn.signIn();
      if (account == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final auth = await account.authentication;
      final token = auth.idToken ?? auth.accessToken ?? '';

      final res = await ref.read(authRepositoryProvider).loginWithGoogle(
            idToken: token.isNotEmpty ? token : 'google_auth_${account.id}',
            email: account.email,
            name: account.displayName ?? account.email.split('@').first,
            avatarUrl: account.photoUrl,
            id: account.id,
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
            content: Text(res['error'] ?? 'Google orqali kirishda xatolik yuz berdi'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google kirish xatosi: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return OutlinedButton(
      onPressed: _isLoading ? null : _handleSignIn,
      style: OutlinedButton.styleFrom(
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 0,
      ),
      child: _isLoading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF2563EB),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildGoogleIcon(),
                const SizedBox(width: 12),
                Text(
                  context.l10n.localeName.startsWith('ru')
                      ? 'Продолжить с Google'
                      : context.l10n.localeName.startsWith('en')
                          ? 'Continue with Google'
                          : 'Google orqali kirish',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildGoogleIcon() {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Draw Google 4-color 'G'
    final paint = Paint()..isAntiAlias = true;

    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    // We can paint standard Google colors
    // Blue, Red, Yellow, Green arcs
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Red: 225 to 315 deg (top)
    paint.color = const Color(0xFFEA4335);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = w * 0.22;
    canvas.drawArc(rect.deflate(paint.strokeWidth / 2), 3.14159 * 1.15, 3.14159 * 0.65, false, paint);

    // Yellow: 135 to 225 deg (left)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect.deflate(paint.strokeWidth / 2), 3.14159 * 0.75, 3.14159 * 0.45, false, paint);

    // Green: 45 to 135 deg (bottom)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect.deflate(paint.strokeWidth / 2), 3.14159 * 0.1, 3.14159 * 0.68, false, paint);

    // Blue: right bar & top-right arc
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect.deflate(paint.strokeWidth / 2), -3.14159 * 0.25, 3.14159 * 0.40, false, paint);

    // Blue horizontal crossbar
    paint.style = PaintingStyle.fill;
    final barRect = Rect.fromLTWH(
      center.dx - 1,
      center.dy - (paint.strokeWidth / 2),
      radius + 1,
      paint.strokeWidth,
    );
    canvas.drawRect(barRect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
