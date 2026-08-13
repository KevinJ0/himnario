class HymnSection {
  final String type;
  final String text;

  const HymnSection({required this.type, required this.text});

  bool get isChorus => type == 'coro';

  factory HymnSection.fromJson(Map<String, dynamic> json) {
    return HymnSection(
      type: json['tipo'] as String,
      text: json['texto'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'tipo': type, 'texto': text};
}

class Hymn {
  final int numero;
  final String titulo;
  final List<HymnSection> secciones;

  const Hymn({
    required this.numero,
    required this.titulo,
    required this.secciones,
  });

  String get tituloCompleto => '$numero. $titulo';

  int get numEstrofas => secciones.where((s) => s.type == 'estrofa').length;

  String get descripcionEstrofas {
    final n = numEstrofas;
    final base = n == 1 ? '1 estrofa' : '$n estrofas';
    return secciones.any((s) => s.isChorus) ? '$base, con coro' : base;
  }

  /// Texto en texto plano preparado para compartir: encabezado con el nombre
  /// del himnario, número y título, seguido de cada sección respetando su
  /// orden real. Los coros se etiquetan como «CORO» y se les quita el
  /// marcador técnico `//...//` de repetición.
  String get textoCompartir {
    final buffer = StringBuffer()
      ..writeln('Himnos de Gloria y Triunfo')
      ..writeln()
      ..writeln('Himno #$numero')
      ..writeln(titulo);
    var nEstrofa = 0;
    for (final seccion in secciones) {
      final textoLimpio = seccion.isChorus
          ? seccion.text.replaceAll('//', '')
          : seccion.text;
      buffer
        ..writeln()
        ..writeln()
        ..writeln(seccion.isChorus ? 'CORO:' : 'Estrofa ${++nEstrofa}:')
        ..writeln(textoLimpio);
    }
    return buffer.toString();
  }

  factory Hymn.fromJson(Map<String, dynamic> json) {
    return Hymn(
      numero: json['numero'] as int,
      titulo: json['titulo'] as String,
      secciones: (json['secciones'] as List<dynamic>)
          .map((e) => HymnSection.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'numero': numero,
    'titulo': titulo,
    'secciones': secciones.map((e) => e.toJson()).toList(),
  };
}
