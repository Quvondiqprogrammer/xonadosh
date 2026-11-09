import 'package:flutter/material.dart';
import 'package:xonadosh/data/models/xonadosh_models.dart';

/// Resolves a high-quality student portrait photo for a roommate candidate.
/// If candidate has uploaded a photo or has a Google avatar, returns that.
/// Otherwise, provides a curated, realistic university student portrait based on gender and ID.
String resolveProfilePhoto(XonadoshProfile item) {
  final raw = item.avatarUrl?.trim() ?? '';
  if (raw.isNotEmpty) {
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }
    return 'https://honadosh.uz/${raw.startsWith('/') ? raw.substring(1) : raw}';
  }

  final isFemale =
      item.gender.toLowerCase() == 'female' ||
      item.gender.toLowerCase() == 'girls';

  final malePortraits = [
    'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&auto=format&fit=crop&q=80',
  ];

  final femalePortraits = [
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=800&auto=format&fit=crop&q=80',
  ];

  final list = isFemale ? femalePortraits : malePortraits;
  final index = (item.id.abs()) % list.length;
  return list[index];
}

/// Fallback avatar builder if network image fails or is unavailable
Widget buildStudentPhotoPlaceholder({
  required String fullName,
  required bool isDark,
  double size = 80,
  IconData icon = Icons.person_rounded,
}) {
  return Container(
    width: double.infinity,
    height: double.infinity,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
            : [const Color(0xFFE2E8F0), const Color(0xFFCBD5E1)],
      ),
    ),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: size * 0.45,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 4),
          Text(
            fullName.isNotEmpty ? fullName[0].toUpperCase() : 'X',
            style: TextStyle(
              fontSize: size * 0.28,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
        ],
      ),
    ),
  );
}
