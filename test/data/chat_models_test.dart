import 'package:flutter_test/flutter_test.dart';
import 'package:xonadosh/data/models/chat_models.dart';

void main() {
  group('Chat Models Test', () {
    test('ChatMessageModel parses from JSON correctly', () {
      final json = {
        'id': 42,
        'conversation_id': 10,
        'sender_username': 'bekzod_inha',
        'is_me': true,
        'message_type': 'text',
        'body': 'Salom, xonadoshlik bo‘yicha gaplashmoqchi edim',
        'metadata': {'priority': 'high'},
        'is_read': 1,
        'created_at': '2026-11-09T14:30:00Z',
      };

      final msg = ChatMessageModel.fromJson(json);

      expect(msg.id, 42);
      expect(msg.conversationId, 10);
      expect(msg.senderUsername, 'bekzod_inha');
      expect(msg.isMe, isTrue);
      expect(msg.messageType, 'text');
      expect(msg.body, 'Salom, xonadoshlik bo‘yicha gaplashmoqchi edim');
      expect(msg.metadata?['priority'], 'high');
      expect(msg.isRead, isTrue);
    });

    test('ChatConversationModel parses from JSON with listing summary', () {
      final json = {
        'id': 101,
        'type': 'listing_inquiry',
        'title': 'Anvar aka (Uy egasi)',
        'other_username': 'anvar_owner',
        'avatar_url': 'https://honadosh.uz/uploads/avatar.webp',
        'last_message': 'Uy hali bo‘sh, kelib ko‘rishingiz mumkin',
        'last_message_sender': 'anvar_owner',
        'last_message_at': '2026-11-09T14:45:00Z',
        'unread_count': 3,
        'listing': {
          'id': 55,
          'title': '2 xonali shinam kvartira TATU yonida',
          'price': 3500000,
          'district': 'Yunusobod',
          'thumb': 'https://honadosh.uz/uploads/thumb.webp',
        },
      };

      final conv = ChatConversationModel.fromJson(json);

      expect(conv.id, 101);
      expect(conv.type, 'listing_inquiry');
      expect(conv.title, 'Anvar aka (Uy egasi)');
      expect(conv.otherUsername, 'anvar_owner');
      expect(conv.unreadCount, 3);
      expect(conv.listing, isNotNull);
      expect(conv.listing?.id, 55);
      expect(conv.listing?.price, 3500000);
      expect(conv.listing?.district, 'Yunusobod');
    });
  });
}
