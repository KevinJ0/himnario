import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/hymn.dart';

class HymnRepository {
  static const String assetPath = 'assets/himnos.json';

  static Future<List<Hymn>> load() async {
    final data = await rootBundle.loadString(assetPath);
    return loadFromString(data);
  }

  static List<Hymn> loadFromString(String data) {
    final list = jsonDecode(data) as List<dynamic>;
    return list
        .map((e) => Hymn.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}
