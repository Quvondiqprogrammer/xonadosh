import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/app_update_service.dart';

class AppUpdateBarrier extends ConsumerWidget {
  const AppUpdateBarrier({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateState = ref.watch(appUpdateNotifierProvider);
    final info = updateState.updateInfo;

    if (info == null || !info.isUpdateAvailable) {
      return child;
    }

    if (info.isForceUpdate) {
      return PopScope(
        canPop: false,
        child: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.system_update_rounded,
                      size: 64,
                      color: Color(0xFF059669),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    info.title.isNotEmpty
                        ? info.title
                        : 'Yangilash talab qilinadi',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    info.releaseNotes.isNotEmpty
                        ? info.releaseNotes
                        : 'Ilovaning yangi versiyasidan foydalanish uchun iltimos, yangilang.',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () =>
                          ref.read(appUpdateNotifierProvider.notifier).startUpdate(),
                      child: Text(
                        updateState.isUpdating
                            ? updateState.statusMessage
                            : 'Yangilash',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Soft update floating banner
    return Stack(
      children: [
        child,
        Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).cardColor,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.system_update_rounded,
                        color: Color(0xFF059669),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          info.title.isNotEmpty
                              ? info.title
                              : 'Yangi versiya mavjud',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    info.releaseNotes.isNotEmpty
                        ? info.releaseNotes
                        : 'XonaDosh ilovasining yangi versiyasida yaxshilanishlar bor.',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => ref
                            .read(appUpdateNotifierProvider.notifier)
                            .dismissOptionalUpdate(),
                        child: const Text('Keyinroq'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                        ),
                        onPressed: () => ref
                            .read(appUpdateNotifierProvider.notifier)
                            .startUpdate(),
                        child: const Text('Yangilash'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
