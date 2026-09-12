class UserModel {
  const UserModel({
    required this.userId,
    required this.username,
    this.fullName,
    this.phoneNumber,
    this.avatarUrl,
  });

  final int userId;
  final String username;
  final String? fullName;
  final String? phoneNumber;
  final String? avatarUrl;

  String get displayName =>
      (fullName != null && fullName!.trim().isNotEmpty) ? fullName!.trim() : username;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 0;
    }

    return UserModel(
      userId: asInt(json['user_id'] ?? json['id']),
      username: (json['username'] ?? '').toString(),
      fullName: json['full_name']?.toString() ?? json['display_name']?.toString(),
      phoneNumber: json['phone_number']?.toString() ?? json['phone']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'username': username,
        'full_name': fullName,
        'phone_number': phoneNumber,
        'avatar_url': avatarUrl,
      };

  UserModel copyWith({
    int? userId,
    String? username,
    String? fullName,
    String? phoneNumber,
    String? avatarUrl,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
