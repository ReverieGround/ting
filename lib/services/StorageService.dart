// lib/services/StorageService.dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'AuthService.dart';

class StorageService {
  final _storage = FirebaseStorage.instance;
  final _auth = AuthService();
  final _uuid = const Uuid();

  Future<String?> uploadPostImage(File file) async {
    try {
      final ownerId = _auth.currentUser?.uid;
      if (ownerId == null) return null;

      final ext = _ext(file.path);
      final path = 'posts/$ownerId/${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4()}.$ext';
      final ref = _storage.ref().child(path);

      final meta = SettableMetadata(contentType: _contentType(ext));
      await ref.putFile(file, meta);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('uploadPostImage error: $e');
      return null;
    }
  }

  Future<List<String>> uploadPostImages(List<File> files, {String? uid}) async {
    final urls = <String>[];
    for (final f in files) {
      final u = await uploadPostImage(f);
      if (u != null) urls.add(u);
    }
    return urls;
    // 병렬 업로드 원하면:
    // final tasks = files.map((f) => uploadPostImage(f, uid: uid)).toList();
    // return (await Future.wait(tasks)).whereType<String>().toList();
  }

  Future<void> deleteByUrl(String url) async {
    try {
      await _storage.refFromURL(url).delete();
    } catch (e) {
      debugPrint('deleteByUrl error: $e');
    }
  }

  String _ext(String path) {
    final i = path.lastIndexOf('.');
    return (i >= 0 && i < path.length - 1) ? path.substring(i + 1).toLowerCase() : 'jpg';
  }

  String _contentType(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'application/octet-stream';
    }
  }
}
