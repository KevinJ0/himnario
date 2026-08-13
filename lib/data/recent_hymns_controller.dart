import 'package:flutter/foundation.dart';

import 'recent_hymns_store.dart';

class RecentHymnsController extends ChangeNotifier {
  final RecentHymnsStore _store = RecentHymnsStore();
  List<int> _ids = <int>[];

  /// Orden de consulta, más reciente primero.
  List<int> get ids => List.unmodifiable(_ids);

  bool contains(int numero) => _ids.contains(numero);

  Future<void> load() async {
    _ids = await _store.load();
    notifyListeners();
  }

  Future<void> record(int numero) async {
    await _store.record(numero);
    _ids = await _store.load();
    notifyListeners();
  }

  Future<void> clear() async {
    await _store.clear();
    _ids = <int>[];
    notifyListeners();
  }
}
