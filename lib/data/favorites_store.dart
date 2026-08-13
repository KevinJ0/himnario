import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class FavoritesStore {
  static const String _key = 'favoritos';

  Future<Set<int>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return <int>{};
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => e as int).toSet();
  }

  Future<void> toggle(int numero) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await load();
    final updated = {...current};
    if (updated.contains(numero)) {
      updated.remove(numero);
    } else {
      updated.add(numero);
    }
    final list = updated.toList()..sort();
    await prefs.setString(_key, jsonEncode(list));
  }

  Future<bool> contains(int numero) async {
    final current = await load();
    return current.contains(numero);
  }
}
