import 'package:shared_preferences/shared_preferences.dart';

/// Local bookmark list for housing listings.
class BookmarkStore {
  static const _key = 'xd_bookmarked_listing_ids_v1';

  Future<Set<int>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? const [])
        .map(int.tryParse)
        .whereType<int>()
        .toSet();
  }

  Future<Set<int>> toggle(int id) async {
    final next = await load();
    if (!next.add(id)) {
      next.remove(id);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, next.map((e) => '$e').toList());
    return next;
  }
}
