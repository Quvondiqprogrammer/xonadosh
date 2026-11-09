import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:xonadosh/config/theme.dart';
import 'package:xonadosh/data/models/chat_models.dart';
import 'package:xonadosh/presentation/features/xonadosh/screens/chat_screen.dart';
import 'package:xonadosh/presentation/providers/xonadosh_providers.dart';

/// Foydalanuvchining barcha chat suhbatlari ro'yxati ekrani
class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => const ConversationsScreen(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final convsAsync = ref.watch(chatConversationsProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Muloqotlar',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 0.5,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      ),
      body: RefreshIndicator(
        color: XonaDoshColors.primary,
        onRefresh: () async {
          ref.invalidate(chatConversationsProvider);
        },
        child: convsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator.adaptive()),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
                  const SizedBox(height: 12),
                  Text('Xatolik: $err', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(chatConversationsProvider),
                    child: const Text('Qayta urinish'),
                  ),
                ],
              ),
            ),
          ),
          data: (convs) {
            if (convs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: XonaDoshColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 52,
                          color: XonaDoshColors.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Hozircha xabarlar yo‘q',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Yoqqan uy e\'lonlari yoki xonadoshlar anketasiga kirib, to‘g‘ridan-to‘g‘ri muloqot boshlashingiz mumkin.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: convs.length,
              separatorBuilder: (ctx, index) => Divider(
                height: 1,
                indent: 76,
                color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
              ),
              itemBuilder: (context, index) {
                final c = convs[index];
                return _buildConversationTile(context, c, isDark);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildConversationTile(
    BuildContext context,
    ChatConversationModel c,
    bool isDark,
  ) {
    final now = DateTime.now();
    final isToday = c.lastMessageAt.year == now.year &&
        c.lastMessageAt.month == now.month &&
        c.lastMessageAt.day == now.day;

    final timeStr = isToday
        ? DateFormat('HH:mm').format(c.lastMessageAt)
        : DateFormat('dd.MM').format(c.lastMessageAt);

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          ChatScreen.route(
            conversationId: c.id,
            title: c.title,
            avatarUrl: c.avatarUrl,
            listing: c.listing,
          ),
        );
      },
      child: Container(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: XonaDoshColors.primary.withValues(alpha: 0.15),
                  backgroundImage: c.avatarUrl != null && c.avatarUrl!.isNotEmpty
                      ? NetworkImage(c.avatarUrl!)
                      : null,
                  child: c.avatarUrl == null || c.avatarUrl!.isEmpty
                      ? Text(
                          c.title.isNotEmpty ? c.title[0].toUpperCase() : 'X',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: XonaDoshColors.primary,
                          ),
                        )
                      : null,
                ),
                if (c.unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          c.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: c.unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 12,
                          color: c.unreadCount > 0
                              ? XonaDoshColors.primary
                              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.lastMessage.isNotEmpty ? c.lastMessage : 'Yangi suhbat',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: c.unreadCount > 0
                                ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                            fontWeight: c.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (c.unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: XonaDoshColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            c.unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
