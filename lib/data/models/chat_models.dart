import 'dart:convert';

/// Chat xabari modeli (In-App Messaging)
class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.senderUsername,
    required this.isMe,
    required this.messageType,
    required this.body,
    this.metadata,
    this.isRead = false,
    required this.createdAt,
  });

  final int id;
  final int conversationId;
  final String senderUsername;
  final bool isMe;
  final String messageType; // 'text', 'image', 'location', 'system_event'
  final String body;
  final Map<String, dynamic>? metadata;
  final bool isRead;
  final DateTime createdAt;

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse((json['created_at'] ?? '').toString());
    } catch (_) {
      parsedDate = DateTime.now();
    }

    Map<String, dynamic>? meta;
    final rawMeta = json['metadata'];
    if (rawMeta is Map<String, dynamic>) {
      meta = rawMeta;
    } else if (rawMeta is Map) {
      meta = Map<String, dynamic>.from(rawMeta);
    } else if (rawMeta is String && rawMeta.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawMeta);
        if (decoded is Map) meta = Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }

    return ChatMessageModel(
      id: _asInt(json['id']),
      conversationId: _asInt(json['conversation_id']),
      senderUsername: (json['sender_username'] ?? '').toString(),
      isMe: json['is_me'] == true,
      messageType: (json['message_type'] ?? 'text').toString(),
      body: (json['body'] ?? '').toString(),
      metadata: meta,
      isRead: json['is_read'] == true || json['is_read'] == 1,
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversation_id': conversationId,
    'sender_username': senderUsername,
    'is_me': isMe,
    'message_type': messageType,
    'body': body,
    'metadata': metadata,
    'is_read': isRead,
    'created_at': createdAt.toIso8601String(),
  };

  static int _asInt(dynamic v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }
}

/// Chat suhbati modeli (Conversation)
class ChatConversationModel {
  const ChatConversationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.otherUsername,
    this.avatarUrl,
    required this.lastMessage,
    required this.lastMessageSender,
    required this.lastMessageAt,
    this.unreadCount = 0,
    this.listing,
    this.colivingGroupCode,
  });

  final int id;
  final String type; // 'direct', 'listing_inquiry', 'coliving_group'
  final String title;
  final String otherUsername;
  final String? avatarUrl;
  final String lastMessage;
  final String lastMessageSender;
  final DateTime lastMessageAt;
  final int unreadCount;
  final ChatListingSummary? listing;
  final String? colivingGroupCode;

  factory ChatConversationModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse((json['last_message_at'] ?? '').toString());
    } catch (_) {
      parsedDate = DateTime.now();
    }

    ChatListingSummary? listingSummary;
    if (json['listing'] is Map) {
      listingSummary = ChatListingSummary.fromJson(
        Map<String, dynamic>.from(json['listing'] as Map),
      );
    }

    return ChatConversationModel(
      id: _asInt(json['id']),
      type: (json['type'] ?? 'direct').toString(),
      title: (json['title'] ?? 'Suhbat').toString(),
      otherUsername: (json['other_username'] ?? '').toString(),
      avatarUrl: json['avatar_url']?.toString(),
      lastMessage: (json['last_message'] ?? '').toString(),
      lastMessageSender: (json['last_message_sender'] ?? '').toString(),
      lastMessageAt: parsedDate,
      unreadCount: _asInt(json['unread_count']),
      listing: listingSummary,
      colivingGroupCode: json['coliving_group_code']?.toString(),
    );
  }

  static int _asInt(dynamic v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }
}

/// Chat ichida ko'rinadigan e'lon kartasi xulosasi
class ChatListingSummary {
  const ChatListingSummary({
    required this.id,
    required this.title,
    required this.price,
    required this.district,
    this.thumb,
  });

  final int id;
  final String title;
  final double price;
  final String district;
  final String? thumb;

  factory ChatListingSummary.fromJson(Map<String, dynamic> json) {
    return ChatListingSummary(
      id: json['id'] is num ? (json['id'] as num).toInt() : 0,
      title: (json['title'] ?? '').toString(),
      price: json['price'] is num ? (json['price'] as num).toDouble() : 0.0,
      district: (json['district'] ?? '').toString(),
      thumb: json['thumb']?.toString(),
    );
  }
}
