import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Desktop/web da mobil UI ni markazda, telefon kengligida saqlaydi.
/// Telefon va planshetda odatdagidek to‘liq ekran.
class AppViewport extends StatelessWidget {
  const AppViewport({super.key, required this.child});

  final Widget? child;

  static const double phoneMax = 480;
  static const double tabletMax = 840;

  @override
  Widget build(BuildContext context) {
    final content = child ?? const SizedBox.shrink();
    if (!kIsWeb) return content;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        if (w <= tabletMax) return content;

        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        return ColoredBox(
          color: isDark ? const Color(0xFF020617) : const Color(0xFFECFDF5),
          child: Center(
            child: Container(
              width: phoneMax,
              height: constraints.maxHeight,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                    blurRadius: 40,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  size: Size(phoneMax, constraints.maxHeight),
                ),
                child: content,
              ),
            ),
          ),
        );
      },
    );
  }
}
