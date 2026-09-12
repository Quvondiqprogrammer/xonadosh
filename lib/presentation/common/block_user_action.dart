import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:xonadosh/l10n/l10n_ext.dart';
import 'package:xonadosh/presentation/providers/xonadosh_providers.dart';
import 'package:xonadosh/presentation/router/app_routes.dart';

Future<void> confirmAndBlockUser(
  BuildContext context,
  WidgetRef ref, {
  required String username,
  bool popAfter = false,
}) async {
  final id = username.trim();
  if (id.isEmpty) return;
  final l10n = context.l10n;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(l10n.blockUserTitle, style: const TextStyle(fontWeight: FontWeight.w800)),
      content: Text(l10n.blockUserBody, style: const TextStyle(fontSize: 13, height: 1.4)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.commonCancel)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.blockUser),
        ),
      ],
    ),
  );
  if (ok != true) return;
  await ref.read(blockStoreProvider).block(id);
  ref.invalidate(blockedUsernamesProvider);
  ref.invalidate(xonadoshListingsProvider);
  ref.invalidate(xonadoshMatchingRoommatesProvider);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.userBlocked)));
  if (popAfter) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go(AppRoutes.shell);
    }
  }
}
