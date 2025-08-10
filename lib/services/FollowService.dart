// lib/services/FollowService.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FollowEntry {
  final String uid;
  final Timestamp? createdAt;
  FollowEntry({required this.uid, this.createdAt});
}

class FollowService {
  final _fs = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get me => _auth.currentUser?.uid;

  Future<bool> follow(String targetUid) async {
    final uid = me;
    if (uid == null || uid == targetUid) return false;

    // 내 blocks만 체크(허용됨). 상대방 blocks는 규칙이 막아줌.
    try {
      final blockedByMe = await _fs
          .collection('users').doc(uid)
          .collection('blocks').doc(targetUid)
          .get();
      if (blockedByMe.exists) return false;
    } catch (_) {
      // 읽기 실패해도 규칙에서 최종 차단됨 → 계속 진행 후 commit에서 걸러짐
    }

    final batch = _fs.batch();
    batch.set(
      _fs.collection('users').doc(targetUid).collection('followers').doc(uid),
      {'created_at': FieldValue.serverTimestamp()},
    );
    batch.set(
      _fs.collection('users').doc(uid).collection('following').doc(targetUid),
      {'created_at': FieldValue.serverTimestamp()},
    );

    try {
      await batch.commit();
      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        // 상대가 나를 차단했거나 규칙 조건 불만족
        return false;
      }
      rethrow;
    }
  }

  Future<bool> unfollow(String targetUid) async {
    final uid = me;
    if (uid == null || uid == targetUid) return false;

    final batch = _fs.batch();
    batch.delete(_fs.collection('users').doc(targetUid).collection('followers').doc(uid));
    batch.delete(_fs.collection('users').doc(uid).collection('following').doc(targetUid));
    await batch.commit();
    return true;
  }

  Future<bool> block(String targetUid) async {
    final uid = me;
    if (uid == null || uid == targetUid) return false;

    final batch = _fs.batch();
    batch.set(
      _fs.collection('users').doc(uid).collection('blocks').doc(targetUid),
      {'created_at': FieldValue.serverTimestamp()},
    );
    batch.delete(_fs.collection('users').doc(uid).collection('following').doc(targetUid));
    batch.delete(_fs.collection('users').doc(targetUid).collection('followers').doc(uid));
    batch.delete(_fs.collection('users').doc(targetUid).collection('following').doc(uid));
    batch.delete(_fs.collection('users').doc(uid).collection('followers').doc(targetUid));
    await batch.commit();
    return true;
  }

  Future<bool> unblock(String targetUid) async {
    final uid = me;
    if (uid == null || uid == targetUid) return false;
    await _fs.collection('users').doc(uid).collection('blocks').doc(targetUid).delete();
    return true;
  }

  Future<int> followerCount(String userId) async {
    final agg = await _fs.collection('users').doc(userId).collection('followers').count().get();
    return agg.count ?? 0;
  }

  Future<int> followingCount(String userId) async {
    final agg = await _fs.collection('users').doc(userId).collection('following').count().get();
    return agg.count ?? 0;
  }

  Future<int> blockedCount(String userId) async {
    final agg = await _fs.collection('users').doc(userId).collection('blocks').count().get();
    return agg.count ?? 0;
  }

  Stream<bool> isFollowingStream(String targetUid) {
    final uid = me;
    if (uid == null) return const Stream<bool>.empty();
    return _fs
        .collection('users').doc(uid)
        .collection('following').doc(targetUid)
        .snapshots()
        .map((d) => d.exists);
  }

  Stream<bool> isFollowedByStream(String targetUid) {
    final uid = me;
    if (uid == null) return const Stream<bool>.empty();
    return _fs
        .collection('users').doc(uid)
        .collection('followers').doc(targetUid)
        .snapshots()
        .map((d) => d.exists);
  }

  Stream<bool> isBlockedStream(String targetUid) {
    final uid = me;
    if (uid == null) return const Stream<bool>.empty();
    return _fs
        .collection('users').doc(uid)
        .collection('blocks').doc(targetUid)
        .snapshots()
        .map((d) => d.exists);
  }

  Future<List<FollowEntry>> fetchFollowersPage({
    required String userId,
    int limit = 30,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    Query<Map<String, dynamic>> q = _fs
        .collection('users').doc(userId)
        .collection('followers')
        .orderBy('created_at', descending: true)
        .limit(limit);
    if (startAfter != null) q = q.startAfterDocument(startAfter);

    final snap = await q.get();
    return snap.docs.map((d) {
      final data = d.data();
      return FollowEntry(uid: d.id, createdAt: data['created_at'] as Timestamp?);
    }).toList();
  }

  Future<List<FollowEntry>> fetchFollowingPage({
    required String userId,
    int limit = 30,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    Query<Map<String, dynamic>> q = _fs
        .collection('users').doc(userId)
        .collection('following')
        .orderBy('created_at', descending: true)
        .limit(limit);
    if (startAfter != null) q = q.startAfterDocument(startAfter);

    final snap = await q.get();
    return snap.docs.map((d) {
      final data = d.data();
      return FollowEntry(uid: d.id, createdAt: data['created_at'] as Timestamp?);
    }).toList();
  }

  Future<List<FollowEntry>> fetchBlockedPage({
    required String userId,
    int limit = 30,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    Query<Map<String, dynamic>> q = _fs
        .collection('users').doc(userId)
        .collection('blocks')
        .orderBy('created_at', descending: true)
        .limit(limit);
    if (startAfter != null) q = q.startAfterDocument(startAfter);

    final snap = await q.get();
    return snap.docs.map((d) {
      final data = d.data();
      return FollowEntry(uid: d.id, createdAt: data['created_at'] as Timestamp?);
    }).toList();
  }

  Stream<List<String>> followersUidsStream(String userId, {int limit = 100}) {
    return _fs
        .collection('users').doc(userId)
        .collection('followers')
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => d.id).toList());
  }

  Stream<List<String>> followingUidsStream(String userId, {int limit = 100}) {
    return _fs
        .collection('users').doc(userId)
        .collection('following')
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => d.id).toList());
  }

  Stream<List<String>> blockedUidsStream(String userId, {int limit = 100}) {
    return _fs
        .collection('users').doc(userId)
        .collection('blocks')
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => d.id).toList());
  }
}
