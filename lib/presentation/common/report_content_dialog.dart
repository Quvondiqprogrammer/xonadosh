import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:xonadosh/l10n/l10n_ext.dart';
import 'package:xonadosh/presentation/providers/xonadosh_providers.dart';

enum ReportTargetType { listing, profile }

/// Shows a dialog to report user-generated content (listing or profile).
Future<void> showReportContentDialog(
  BuildContext context,
  WidgetRef ref, {
  required ReportTargetType targetType,
  required String targetId,
  required String subjectLabel,
}) async {
  final l10n = context.l10n;
  final reasons = [
    l10n.reportReasonSpam,
    l10n.reportReasonInappropriate,
    l10n.reportReasonHarassment,
    l10n.reportReasonScam,
    l10n.reportReasonOther,
  ];
  var selected = reasons.first;
  final detailsCtrl = TextEditingController();
  var submitting = false;

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.reportContentTitle, style: const TextStyle(fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                subjectLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(ctx).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(l10n.reportContentBody, style: const TextStyle(fontSize: 13, height: 1.4)),
              const SizedBox(height: 16),
              ...reasons.map(
                (reason) {
                  final picked = selected == reason;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Icon(
                      picked ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                      color: picked ? Theme.of(ctx).colorScheme.primary : Colors.grey,
                      size: 22,
                    ),
                    title: Text(reason, style: const TextStyle(fontSize: 13)),
                    onTap: submitting
                        ? null
                        : () => setState(() => selected = reason),
                  );
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: detailsCtrl,
                enabled: !submitting,
                maxLines: 3,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: l10n.reportDetailsHint,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: submitting ? null : () => Navigator.pop(ctx),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: submitting
                ? null
                : () async {
                    setState(() => submitting = true);
                    final details = detailsCtrl.text.trim();
                    final reason = details.isEmpty ? selected : '$selected — $details';
                    final res = await ref.read(xonadoshRepositoryProvider).submitReport(
                          targetType: targetType == ReportTargetType.listing ? 'listing' : 'profile',
                          targetId: targetId,
                          reason: reason,
                        );
                    if (!ctx.mounted) return;
                    if (res['ok'] == true) {
                      Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.reportSubmitted)),
                        );
                      }
                    } else {
                      setState(() => submitting = false);
                      final err = res['error']?.toString() ?? l10n.errorGeneric;
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(err)));
                    }
                  },
            child: submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(l10n.reportSubmit),
          ),
        ],
      ),
    ),
  );
  detailsCtrl.dispose();
}
