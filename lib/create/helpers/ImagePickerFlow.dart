// helpers/ImagePickerFlow.dart
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../EditPage.dart';
import 'ExifHelper.dart';
import 'package:flutter/material.dart';

class ImagePickerFlow {
  final ImagePicker _picker = ImagePicker();

  Future<({List<File> files, DateTime? takenAt})?> pickAndEdit(
    BuildContext context,
  ) async {
    final picks = await _picker.pickMultiImage();
    if (picks.isEmpty) return null;

    final edited = await Navigator.push<List<XFile>?>(
      context,
      MaterialPageRoute(builder: (_) => EditPage(initialFiles: picks)),
    );
    if (edited == null || edited.isEmpty) return null;

    final files = edited.map((e) => File(e.path)).toList();
    DateTime? takenAt;
    if (files.isNotEmpty) {
      takenAt = await ExifHelper.extractTakenAt(files.first);
    }
    return (files: files, takenAt: takenAt);
  }
}
