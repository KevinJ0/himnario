import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:himnario/data/favorites_controller.dart';
import 'package:himnario/models/hymn.dart';
import 'package:himnario/screens/hymn_detail_screen.dart';

Hymn _hymn() => Hymn.fromJson({
      'numero': 42,
      'titulo': 'SUBLIME GRACIA',
      'secciones': [
        {
          'tipo': 'estrofa',
          'texto': 'Sublime gracia del Señor,\nque a un pecador salvó.',
        },
        {'tipo': 'coro', 'texto': '//Gracia admirable//'},
        {'tipo': 'estrofa', 'texto': 'La fe se afirmará.'},
      ],
    });

double _controlsOpacity(WidgetTester tester) {
  final finder = find.ancestor(
    of: find.byTooltip('Salir del modo lectura'),
    matching: find.byType(AnimatedOpacity),
  );
  expect(finder, findsWidgets);
  return tester.widget<AnimatedOpacity>(finder.first).opacity;
}

void main() {
  testWidgets('modo lectura: entrada, toggle de controles y salida',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final favorites = FavoritesController();

    await tester.pumpWidget(
      MaterialApp(home: HymnDetailScreen(hymn: _hymn(), favorites: favorites)),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Modo lectura'), findsOneWidget);

    await tester.tap(find.byTooltip('Modo lectura'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Salir del modo lectura'), findsOneWidget);
    expect(find.text('Modo lectura'), findsOneWidget);
    expect(find.byTooltip('Aumentar letra'), findsOneWidget);
    expect(find.byTooltip('Reducir letra'), findsOneWidget);
    expect(find.byTooltip('Compartir'), findsOneWidget);
    expect(find.byTooltip('Agregar a favoritos'), findsOneWidget);
    expect(_controlsOpacity(tester), 1);

    await tester.tap(find.byType(SingleChildScrollView));
    await tester.pumpAndSettle();
    expect(_controlsOpacity(tester), 0);

    await tester.tap(find.byType(SingleChildScrollView));
    await tester.pumpAndSettle();
    expect(_controlsOpacity(tester), 1);

    await tester.tap(find.byTooltip('Aumentar letra'));
    await tester.pumpAndSettle();
    expect(find.text('20'), findsOneWidget);

    await tester.tap(find.byTooltip('Salir del modo lectura'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Salir del modo lectura'), findsNothing);
    expect(find.byTooltip('Modo lectura'), findsOneWidget);
  });
}
