import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Almacén de himnos recientes: una lista ordenada por uso (más reciente
/// primero), sin duplicados y limitada a [maxEntries] himnos.
class RecentHymnsStore {
  static const String _key = 'himnos_recientes';
  static const int maxEntries = 20;

  Future<List<int>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return <int>[];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => e as int).toList();
  }

  /// Registra un himno como recién consultado: se mueve al inicio y se recorta
  /// a [maxEntries].
  Future<void> record(int numero) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await load();
    final updated = [numero, ...current.where((e) => e != numero)];
    final trimmed = updated.take(maxEntries).toList();
    await prefs.setString(_key, jsonEncode(trimmed));
  }

  /// Elimina todos los recientes.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}