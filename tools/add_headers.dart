import 'dart:io';
import 'package:path/path.dart' as p;

void main() async {
  final baseDir = Directory('lib');

  if (!baseDir.existsSync()) {
    print('lib/ klasörü bulunamadı.');
    return;
  }

  final projectRoot = Directory.current.path;

  await for (final entity
      in baseDir.list(recursive: true, followLinks: false)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final relativePath =
          p.relative(entity.path, from: projectRoot).replaceAll('\\', '/');
      final headerLine = '// $relativePath';

      final lines = await entity.readAsLines();
      if (lines.isNotEmpty && lines.first.trim() == headerLine) {
        // Zaten eklenmiş, geç
        continue;
      }

      print('⤴️  $relativePath → başlık ekleniyor');
      final newContent = [headerLine, ...lines].join('\n');
      await entity.writeAsString(newContent);
    }
  }

  print('\n✅ Tüm dosyalara başlık eklendi (varsa atlandı).');
}
