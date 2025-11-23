// lib/services/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/ProfileInfo.dart';
import '../models/UserData.dart'; 

class UserService {
  final _fs = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;

  Future<String?> getCurrentUserId() async => _auth.currentUser?.uid;

  Future<int> _subcolCount(String uid, String sub) async {
    final agg = await _fs.collection('users').doc(uid).collection(sub).count().get();
    return agg.count ?? 0;
  }

  Future<int> _postCount(String ownerUid, String viewerUid) async {
    final isOwner = ownerUid == viewerUid;

    // 오너면 팔로우 조회 불필요
    List<String> visibilities;
    if (isOwner) {
      visibilities = ['PUBLIC', 'FOLLOWER', 'PRIVATE'];
    } else {
      final isFollower = await isFollowing(viewerUid, ownerUid);
      visibilities = isFollower ? ['PUBLIC', 'FOLLOWER'] : ['PUBLIC'];
    }
    
    try {
      final agg = await _fs
          .collection('posts')
          .where('user_id', isEqualTo: ownerUid)
          .where('archived', isEqualTo: false)
          .where('visibility', whereIn: visibilities)
          .count()
          .get();
      return agg.count ?? 0;
    } on FirebaseException catch (e) {
      // 혹시 permission-denied가 떠도 프로필 자체가 안 죽게 방어
      if (e.code == 'permission-denied') return 0;
      rethrow;
    }
  }
  

  // 내가 target을 팔로잉 중?
  Future<bool> isFollowing(String viewerUid, String targetUid) async {
    final d = await _fs.collection('users').doc(viewerUid).collection('following').doc(targetUid).get();
    return d.exists;
  }

  // 내가 target을 차단했나?
  Future<bool> isBlocked(String viewerUid, String targetUid) async {
    final d = await _fs.collection('users').doc(viewerUid).collection('blocks').doc(targetUid).get();
    return d.exists;

  }
  Future<ProfileInfo?> fetchUserForViewer(String targetUid, {String? viewerUid}) async {

    try {
      viewerUid ??= _auth.currentUser?.uid;
      if (viewerUid == null) return null;

      // 사전 차단 조회 제거: 규칙에서 get 시점에 차단 판단
      DocumentSnapshot<Map<String, dynamic>> doc;
      try {
        doc = await _fs.collection('users').doc(targetUid).get();
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied') {
          // 상호 차단 등으로 규칙에서 거절됨
          return null;
        }
        rethrow;
      }
      
      if (!doc.exists) return null;
      final data = Map<String, dynamic>.from(doc.data()!);

      data.remove('email');
      data.remove('phone');
  
      final followerCount  = await _subcolCount(targetUid, 'followers');
      final followingCount = await _subcolCount(targetUid, 'following');

      // 타인의 blocks는 비공개: 본인일 때만 카운트
      int? blockCount;
      if (viewerUid == targetUid) {
        blockCount = await _subcolCount(targetUid, 'blocks');
      }

      final postCount = await _postCount(targetUid, viewerUid);

      data['follower_count']  = followerCount;
      data['following_count'] = followingCount;
      data['post_count']      = postCount;
      data['recipe_count']    = 0;
      if (blockCount != null) data['block_count'] = blockCount;
      
      if (viewerUid == targetUid) {
        // 뷰어 관점 플래그
        data['viewer_is_following'] = await isFollowing(viewerUid, targetUid);
        // 이 플래그는 뷰어의 blocks만 조회하므로 허용됨
        data['viewer_blocked']      = await isBlocked(viewerUid, targetUid);
      }

      return ProfileInfo.fromJson(data);
    } catch (e) {
      debugPrint('fetchUserForViewer error: $e');
      return null;
    }
  }

  // 필요 시 유지(호출부 점진 교체 가능)
  Future<ProfileInfo?> fetchUserRaw(String uid) async {
    final me = _auth.currentUser?.uid;
    if (me == null) return null;
    if (uid == me) {
      return fetchUserForViewer(uid, viewerUid: me);                   // 내 프로필: 오너 권한/카운트까지 안전
    } else {
      return fetchUserForViewer(uid, viewerUid: me); // 타인 프로필: 차단/가시성 기준
    }
  }

  Future<String?> fetchUserRegion({String? targetUid}) async {
    final uid = targetUid ?? _auth.currentUser?.uid;
    if (uid == null) return null;
    try {
      final info = await fetchUserForViewer(uid);
      return info?.location;
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

  Future<List<UserData>> fetchUserList(String targetUserId, String type) async {
    try {
      // 🔹 followers / following / blocks = 서브컬렉션 구조
      final snapshot = await _fs
          .collection('users')
          .doc(targetUserId)
          .collection(type)
          .get();

      if (snapshot.docs.isEmpty) return [];

      // 🔹 각 문서의 ID가 userId 역할
      final List<UserData> result = [];

      // 병렬 요청 (성능 최적화)
      final futures = snapshot.docs.map((doc) async {
        final uid = doc.id;
        final userSnap = await _fs.collection('users').doc(uid).get();

        if (userSnap.exists) {
          final d = userSnap.data()!;
          return UserData(
            userId: uid,
            userName: d['user_name'] ?? '',
            location: d['location'] ?? '',
            title: d['user_title'] ?? '',
            statusMessage: d['status_message'],
            profileImage: d['profile_image'],
          );
        }
        return null;
      });

      final loaded = await Future.wait(futures);
      result.addAll(loaded.whereType<UserData>());

      return result;
    } catch (e) {
      debugPrint('🔥 fetchUserList error: $e');
      return [];
    }
  }

}
