// helpers/ImagePickerFlow.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../EditPage.dart';
import 'ExifHelper.dart';

class ImagePickerFlow {
  final ImagePicker _picker = ImagePicker();

  /// 이미지를 고르고(복수 가능), 2장 이상이면 편집 페이지로 이동.
  /// 반환: (files: List<File>, takenAt: DateTime?)
  Future<({List<File> files, DateTime? takenAt})?> pickAndEdit(
    BuildContext context,
  ) async {
    try {
      // 메타데이터(EXIF)까지 요청해야 촬영 시각을 안정적으로 읽을 수 있음
      final picks = await _picker.pickMultiImage(
        requestFullMetadata: true, // iOS/Android에서 EXIF 접근에 도움
        // imageQuality: 90,       // 필요 시 압축
        // maxWidth: 2048, maxHeight: 2048,
      );

      if (picks.isEmpty) return null;

      // 1장만 선택한 경우: 편집 없이 바로 반환
      if (picks.length == 1) {
        final file = File(picks.first.path);
        final takenAt = await ExifHelper.extractTakenAt(file); // File 기준
        return (files: [file], takenAt: takenAt);
      }

      // 2장 이상: 편집 페이지로 이동
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
    } catch (e) {
      // 사용자가 권한 거부/취소했거나, picker 에러가 난 경우
      debugPrint('[ImagePickerFlow] pickAndEdit error: $e');
      return null;
    }
  }
}
