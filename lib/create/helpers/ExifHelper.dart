// helpers/ExifHelper.dart
import 'dart:io';
import 'package:exif/exif.dart';

class ExifHelper {
  static Future<DateTime?> extractTakenAt(File file) async {
    try {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return null;

      final tags = await readExifFromBytes(bytes);
      if (tags.containsKey('Image DateTime')) {
        final raw = tags['Image DateTime']!.printable; // e.g. 2023:10:02 14:33:22
        final parts = raw.split(' ');
        if (parts.length == 2) {
          final date = parts[0].replaceAll(':', '-');
          final time = parts[1];
          final parsed = DateTime.tryParse('$date $time');
          if (parsed != null) return parsed;
        }
      }
    } catch (_) {}
    return null;
  }
}
