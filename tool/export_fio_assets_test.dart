import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

// Export the approved dragon artwork without redrawing or replacing the mascot.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Export Fio launcher and web assets', () async {
    final codec = await ui.instantiateImageCodec(
        await File('assets/mascot/app-icon.png').readAsBytes());
    final source = (await codec.getNextFrame()).image;
    final outputs = <String, int>{
      'android/app/src/main/res/mipmap-mdpi/ic_launcher.png': 48,
      'android/app/src/main/res/mipmap-hdpi/ic_launcher.png': 72,
      'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png': 96,
      'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png': 144,
      'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,
      'web/favicon.png': 64,
      'web/icons/Icon-192.png': 192,
      'web/icons/Icon-512.png': 512,
      'web/icons/Icon-maskable-192.png': 192,
      'web/icons/Icon-maskable-512.png': 512,
      'android/app/src/main/res/drawable-nodpi/finora_dragon_icon.png': 432,
      'artifacts/dragon-icon-20261030.png': 1024,
    };
    for (final entry in outputs.entries) {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final size = entry.value;
      final adaptive = entry.key.contains('drawable-nodpi');
      if (!adaptive) canvas.drawColor(const Color(0xFF00866A), BlendMode.src);
      final inset = adaptive ? size / 6 : 0.0;
      canvas.drawImageRect(
          source,
          Rect.fromLTWH(
              0, 0, source.width.toDouble(), source.height.toDouble()),
          Rect.fromLTWH(inset, inset, size - inset * 2, size - inset * 2),
          Paint()..filterQuality = FilterQuality.high);
      final picture = recorder.endRecording();
      final image = await picture.toImage(size, size);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      expect(data, isNotNull);
      final bytes = data!.buffer.asUint8List();
      final file = File(entry.key);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
      if (entry.key.contains('mipmap-')) {
        await File(entry.key
                .replaceAll('ic_launcher.png', 'ic_launcher_round.png'))
            .writeAsBytes(bytes);
      }
      image.dispose();
      picture.dispose();
    }
    source.dispose();
    codec.dispose();
  });
}
