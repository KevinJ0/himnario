import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../models/hymn.dart';
import '../widgets/hymn_share_card.dart';

/// Genera una (o varias, si el himno es muy largo) imágenes PNG del himno y
/// devuelve los archivos temporales listos para compartir.
class HymnShareService {
  /// Altura máxima (px) de cada imagen resultante. Si el himno la supera, se
  /// parte automáticamente en varias páginas, evitando imágenes gigantes que
  /// agoten la memoria al compartirlas.
  static const int _maxPageHeight = 3200;

  /// Factor de escala de captura para nitidez (2x = doble resolución).
  static const double _pixelRatio = 2.0;

  static Future<List<XFile>> buildFiles(BuildContext context, Hymn hymn) async {
    final controller = ScreenshotController();
    final bytes = await controller.captureFromLongWidget(
      HymnShareCard(hymn: hymn),
      context: context,
      constraints: const BoxConstraints(maxWidth: kShareCardWidth),
      pixelRatio: _pixelRatio,
    );

    final pages = await _splitIntoPages(bytes);

    final dir = await getTemporaryDirectory();
    final files = <XFile>[];
    for (var i = 0; i < pages.length; i++) {
      final name = pages.length == 1
          ? 'himno_${hymn.numero}.png'
          : 'himno_${hymn.numero}_p${i + 1}.png';
      final file = File('${dir.path}${Platform.pathSeparator}$name');
      await file.writeAsBytes(pages[i]);
      files.add(XFile(file.path, mimeType: 'image/png'));
    }
    return files;
  }

  static Future<void> share(BuildContext context, Hymn hymn) async {
    final files = await buildFiles(context, hymn);
    await SharePlus.instance.share(
      ShareParams(
        files: files,
        subject: '${hymn.titulo} · Himno ${hymn.numero}',
        text:
            'Himno ${hymn.numero} · ${hymn.titulo}\n'
            'Himnos de Gloria y Triunfo',
      ),
    );
  }

  /// Divide el PNG del himno completo en páginas de [maxPageHeight] px.
  static Future<List<Uint8List>> _splitIntoPages(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    codec.dispose();
    final src = frame.image;
    final width = src.width;
    final height = src.height;

    if (height <= _maxPageHeight) {
      final single = await _encodeImage(src);
      src.dispose();
      return [single];
    }

    final pages = <Uint8List>[];
    var y = 0;
    while (y < height) {
      final sliceHeight = math.min(_maxPageHeight, height - y);
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawImageRect(
        src,
        ui.Rect.fromLTWH(
          0,
          y.toDouble(),
          width.toDouble(),
          sliceHeight.toDouble(),
        ),
        ui.Rect.fromLTWH(0, 0, width.toDouble(), sliceHeight.toDouble()),
        ui.Paint(),
      );
      final picture = recorder.endRecording();
      final pageImage = await picture.toImage(width, sliceHeight);
      picture.dispose();
      pages.add(await _encodeImage(pageImage));
      pageImage.dispose();
      y += sliceHeight;
    }
    src.dispose();
    return pages;
  }

  static Future<Uint8List> _encodeImage(ui.Image image) async {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }
}
