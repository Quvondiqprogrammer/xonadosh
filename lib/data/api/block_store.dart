import 'package:shared_preferences/shared_preferences.dart';

/// Local block list for UGC safety (Apple 1.2).
class BlockStore {
  static const _key = 'xd_blocked_usernames_v1';

  Future<Set<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? const [])
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet();
  }

  Future<Set<String>> block(String username) async {
    final id = username.trim().toLowerCase();
    if (id.isEmpty) return load();
    final next = await load()..add(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, next.toList());
    return next;
  }

  Future<Set<String>> unblock(String username) async {
    final id = username.trim().toLowerCase();
    final next = await load()..remove(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, next.toList());
    return next;
  }

  Future<bool> isBlocked(String username) async {
    return (await load()).contains(username.trim().toLowerCase());
  }
}
