import 'package:flutter/foundation.dart';

import 'favorites_store.dart';

class FavoritesController extends ChangeNotifier {
  final FavoritesStore _store = FavoritesStore();
  Set<int> _ids = <int>{};

  Set<int> get ids => _ids;

  bool isFavorite(int numero) => _ids.contains(numero);

  Future<void> load() async {
    _ids = await _store.load();
    notifyListeners();
  }

  Future<void> toggle(int numero) async {
    await _store.toggle(numero);
    _ids = await _store.load();
    notifyListeners();
  }
}
