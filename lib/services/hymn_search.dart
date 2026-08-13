import '../models/hymn.dart';

/// Orden canónico del abecedario para agrupar/sidebar. Los títulos se agrupan
/// por la primera letra normalizada; se usa `#` como comodín para títulos que
/// no comienzan con A-Z.
const List<String> kAlphabetOrder = [
  'A',
  'B',
  'C',
  'D',
  'E',
  'F',
  'G',
  'H',
  'I',
  'J',
  'K',
  'L',
  'M',
  'N',
  'Ñ',
  'O',
  'P',
  'Q',
  'R',
  'S',
  'T',
  'U',
  'V',
  'W',
  'X',
  'Y',
  'Z',
];

/// Lógica pura de búsqueda, filtrado, ordenamiento y agrupación alfabética de
/// himnos. Sin estado: los métodos son estáticos y la pantalla conserva solo
/// su caché de resultados.
abstract final class HymnSearch {
  HymnSearch._();

  /// Normaliza un texto para comparación: mayúsculas y sin acentos.
  static String normalize(String s) {
    const withAccents = 'ÁÉÍÓÚÜÑ';
    const withoutAccents = 'AEIOUUN';
    var result = s.toUpperCase();
    for (var i = 0; i < withAccents.length; i++) {
      result = result.replaceAll(withAccents[i], withoutAccents[i]);
    }
    return result;
  }

  /// Títulos normalizados por número, calculados una sola vez.
  static Map<int, String> buildNormMap(List<Hymn> himnos) {
    return {for (final h in himnos) h.numero: normalize(h.titulo)};
  }

  /// Filtra por favoritos y consulta y ordena según [sortAlphabetically].
  /// Devuelve una nueva lista sin modificar el origen.
  static List<Hymn> filter({
    required List<Hymn> source,
    required Map<int, String> normMap,
    required String query,
    required bool showFavoritesOnly,
    required Set<int> favoriteIds,
    required bool sortAlphabetically,
  }) {
    final q = query.trim().toLowerCase();
    final normQuery = normalize(q);
    final filtered = source.where((h) {
      if (showFavoritesOnly && !favoriteIds.contains(h.numero)) return false;
      if (normQuery.isEmpty) return true;
      if ('${h.numero}'.contains(q)) return true;
      return matchesTitle(normMap[h.numero]!, normQuery);
    }).toList();
    filtered.sort(
      sortAlphabetically
          ? (a, b) => normMap[a.numero]!.compareTo(normMap[b.numero]!)
          : (a, b) => a.numero.compareTo(b.numero),
    );
    return filtered;
  }

  /// Búsqueda tolerante sobre el título ya normalizado (mayúsculas, sin
  /// acentos). Coincide por subcadena y, cuando la subcadena no basta, compara
  /// palabra por palabra tolerando errores de escritura con distancia de
  /// Levenshtein.
  static bool matchesTitle(String title, String query) {
    if (title.contains(query)) return true;
    final queryWords = query
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (queryWords.isEmpty) return false;
    final titleWords = title
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    return queryWords.every((q) => titleWords.any((t) => _fuzzyWord(t, q)));
  }

  /// Primera letra (A-Z) del título normalizado. Los títulos que empiezan con
  /// signos de exclamación o interrogación invertidos («¡...», «¿...») saltan
  /// esos caracteres y se agrupan por su primera letra real.
  static String groupLetter(String normalized) {
    for (final rune in normalized.runes) {
      final ch = String.fromCharCode(rune);
      if (RegExp(r'[A-Z]').hasMatch(ch)) return ch;
    }
    return '#';
  }

  /// Coincidencia difusa de una palabra: subcadena o distancia de Levenshtein
  /// dentro de un umbral razonable según la longitud de la consulta.
  static bool _fuzzyWord(String titleWord, String queryWord) {
    if (titleWord.contains(queryWord)) return true;
    final maxDist = switch (queryWord.length) {
      <= 3 => 0,
      <= 6 => 1,
      _ => 2,
    };
    return _levenshtein(titleWord, queryWord) <= maxDist;
  }

  /// Distancia de Levenshtein (inserciones/borrados/sustituciones mínimas).
  static int _levenshtein(String a, String b) {
    if (a.length < b.length) return _levenshtein(b, a);
    var prev = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 1; i <= a.length; i++) {
      final curr = List<int>.filled(b.length + 1, 0)..[0] = i;
      for (var j = 1; j <= b.length; j++) {
        curr[j] = _min(
          _min(curr[j - 1] + 1, prev[j] + 1),
          prev[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1),
        );
      }
      prev = curr;
    }
    return prev[b.length];
  }

  static int _min(int a, int b) => a < b ? a : b;
}
