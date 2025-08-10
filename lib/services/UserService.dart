// lib/services/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/MyInfo.dart';

class UserService {
  final _fs = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;

  Future<String?> getCurrentUserId() async => _auth.currentUser?.uid;
  
  Future<MyInfo?> fetchUserRaw(String uid) async {
    try {
      // 1. 유저 기본 정보
      final doc = await _fs.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      final data = Map<String, dynamic>.from(doc.data()!);

      // 2. 팔로워 수
      final followersSnap = await _fs
          .collection('users')
          .doc(uid)
          .collection('followers')
          .get();
      final followerCount = followersSnap.size;

      // 3. 게시물 수 (archived 제외)
      final postsSnap = await _fs
          .collection('posts')
          .where('user_id', isEqualTo: uid)
          .where('archived', isEqualTo: false)
          .get();
      final postCount = postsSnap.size;

      // 4. 레시피 수 (아직 기록 안 함 → 0)
      final recipeCount = 0;

      // 5. 데이터에 추가
      data['follower_count'] = followerCount;
      data['post_count'] = postCount;
      data['recipe_count'] = recipeCount;

      final myInfo = MyInfo.fromJson(data);
      return myInfo;
    } catch (e) {
      debugPrint('fetchUserRaw error: $e');
      return null;
    }
  }

  Future<String?> fetchUserRegion() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    try {
      final data = await fetchUserRaw(uid);
      if (data == null) return null;
      return data.location as String?;
    } catch (e) {
      debugPrint('fetchUserRegion error: $e');
      return null;
    }
  }

  Future<String?> uploadProfileImage(File file) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    try {
      final name = 'profile_images/${uid}_${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final ref = _storage.ref().child(name);
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      await _fs.collection('users').doc(uid).update({'profile_image': url});
      return url;
    } catch (e) {
      debugPrint('uploadProfileImage error: $e');
      return null;
    }
  }

  Future<bool> updateStatusMessage(String message) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    try {
      await _fs.collection('users').doc(uid).update({'status_message': message});
      return true;
    } catch (e) {
      debugPrint('updateStatusMessage error: $e');
      return false;
    }
  }
}
