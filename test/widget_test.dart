import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:himnario/data/hymn_repository.dart';
import 'package:himnario/data/recent_hymns_store.dart';
import 'package:himnario/models/hymn.dart';

void main() {
  test('Hymn.fromJson parsea secciones', () {
    final hymn = Hymn.fromJson({
      'numero': 1,
      'titulo': 'EL APOSENTO ALTO',
      'secciones': [
        {'tipo': 'estrofa', 'texto': 'Primera línea\nSegunda línea'},
        {'tipo': 'coro', 'texto': '//¡Dios manda tu gran poder!//'},
      ],
    });

    expect(hymn.numero, 1);
    expect(hymn.tituloCompleto, '1. EL APOSENTO ALTO');
    expect(hymn.secciones, hasLength(2));
    expect(hymn.secciones.first.isChorus, isFalse);
    expect(hymn.secciones.last.isChorus, isTrue);
  });

  test('carga todos los himnos del asset', () async {
    final data = await File('assets/himnos.json').readAsString();
    final himnos = HymnRepository.loadFromString(data);

    expect(himnos, hasLength(398));
    expect(himnos.first.numero, 1);
    expect(himnos.first.titulo, 'EL APOSENTO ALTO');
    expect(himnos.last.numero, 400);
    expect(himnos.last.titulo, 'MARAVILLOSA GRACIA');
    for (final h in himnos) {
      expect(h.secciones, isNotEmpty);
      expect(h.numero, inInclusiveRange(1, 400));
    }
  });

  test('RecentHymnsStore registra sin duplicados y con máximo', () async {
    SharedPreferences.setMockInitialValues({});
    final store = RecentHymnsStore();

    await store.record(5);
    await store.record(12);
    await store.record(5);
    await store.record(3);

    final ids = await store.load();
    expect(ids, [3, 5, 12]);

    await store.clear();
    expect(await store.load(), isEmpty);
  });

  test('textoCompartir respeta la estructura y limpia marcadores', () {
    final hymn = Hymn.fromJson({
      'numero': 42,
      'titulo': 'SUBLIME GRACIA',
      'secciones': [
        {'tipo': 'estrofa', 'texto': 'Sublime gracia\nDel Señor'},
        {'tipo': 'coro', 'texto': '//Fui salvo// por su amor.'},
        {'tipo': 'estrofa', 'texto': 'La fe se afirmará'},
      ],
    });

    final texto = hymn.textoCompartir;

    expect(texto, startsWith('Himnos de Gloria y Triunfo'));
    expect(texto, contains('Himno #42'));
    expect(texto, contains('SUBLIME GRACIA'));
    expect(texto, contains('Estrofa 1:'));
    expect(texto, contains('Estrofa 2:'));
    expect(texto, contains('CORO:'));
    expect(texto, contains('Sublime gracia\nDel Señor'));
    expect(texto, contains('Fui salvo por su amor.'));
    expect(texto, isNot(contains('//')));
  });
}
