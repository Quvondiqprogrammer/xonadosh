import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xonadosh/config/theme.dart';
import 'package:xonadosh/l10n/l10n_ext.dart';

/// Telefon / Telegram / ulashish — web va mobil bir xil UX.
class ContactActions {
  ContactActions._();

  static String digitsOnly(String phone) =>
      phone.replaceAll(RegExp(r'[^\d+]'), '');

  static Future<void> callPhone(BuildContext context, String phone) async {
    final raw = phone.trim();
    if (raw.isEmpty) return;

    final uri = Uri(scheme: 'tel', path: raw);
    var launched = false;
    try {
      if (await canLaunchUrl(uri)) {
        launched = await launchUrl(uri);
      }
    } catch (_) {
      launched = false;
    }

    // Desktop web da tel: odatda ishlamaydi — nusxa + WhatsApp/Telegram variantlari.
    if (!launched && context.mounted) {
      await showContactSheet(context, phone: raw);
    }
  }

  static Future<void> openTelegram(BuildContext context, String? handle) async {
    if (handle == null || handle.trim().isEmpty) return;
    final h = handle.trim().replaceAll('@', '');
    final uri = Uri.parse('https://t.me/$h');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.xonadoshOpenLinkFailed)),
      );
    }
  }

  static Future<void> shareText(BuildContext context, String text) async {
    try {
      await SharePlus.instance.share(ShareParams(text: text));
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.xonadoshCopiedToClipboard)),
        );
      }
    }
  }

  static Future<void> copyPhone(BuildContext context, String phone) async {
    await Clipboard.setData(ClipboardData(text: phone.trim()));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.xonadoshPhoneCopied)),
      );
    }
  }

  static Future<void> showContactSheet(
    BuildContext context, {
    required String phone,
    String? telegramHandle,
  }) {
    final digits = digitsOnly(phone).replaceAll('+', '');
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final l10n = ctx.l10n;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.xonadoshContactOptions,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  phone,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.call_rounded, color: XonaDoshColors.primary),
                  title: Text(l10n.xonadoshCallBtn),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final uri = Uri(scheme: 'tel', path: phone);
                    try {
                      await launchUrl(uri);
                    } catch (_) {
                      if (context.mounted) await copyPhone(context, phone);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.copy_rounded),
                  title: Text(l10n.xonadoshCopyPhone),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await copyPhone(context, phone);
                  },
                ),
                if (digits.length >= 9)
                  ListTile(
                    leading: const Icon(Icons.chat_rounded, color: Color(0xFF25D366)),
                    title: Text(l10n.xonadoshWhatsApp),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final uri = Uri.parse('https://wa.me/$digits');
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                  ),
                if (telegramHandle != null && telegramHandle.trim().isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.send_rounded, color: Color(0xFF0284C7)),
                    title: const Text('Telegram'),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await openTelegram(context, telegramHandle);
                    },
                  ),
                if (kIsWeb)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      l10n.xonadoshWebCallHint,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
