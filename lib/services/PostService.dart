// lib/services/PostService.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/PostData.dart'; 

class PostService {
  final _fs = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<List<PostData>> fetchUserPosts({
    required String userId,
    int limit = 50,
    bool excludeArchived = true,
  }) async {
    final viewerUid = _auth.currentUser?.uid;
    if (viewerUid == null) return [];

    // 뷰어 기준 가시성 결정
    final bool isOwner = viewerUid == userId;
    final bool isFollower = await _isFollowing(viewerUid, userId); // 아래 보조 함수

    final List<String> canSee = isOwner
        ? ['PUBLIC', 'FOLLOWER', 'PRIVATE']
        : (isFollower ? ['PUBLIC', 'FOLLOWER'] : ['PUBLIC']);

    Query<Map<String, dynamic>> q = _fs
        .collection('posts')
        .where('user_id', isEqualTo: userId)
        .where('visibility', whereIn: canSee) // ★ 핵심
        .orderBy('created_at', descending: true)
        .limit(limit);

    if (excludeArchived) {
      q = q.where('archived', isEqualTo: false);
    }

    final snap = await q.get();

    return snap.docs.map((d) {
      final map = Map<String, dynamic>.from(d.data());
      map['post_id'] = d.id;
      return PostData.fromMap(map);
    }).toList();
  }

  // 내부용 팔로우 체크(이미 있으면 그거 쓰세요)
  Future<bool> _isFollowing(String viewerUid, String ownerUid) async {
    final doc = await _fs
        .collection('users')
        .doc(ownerUid)
        .collection('followers')
        .doc(viewerUid)
        .get();
    return doc.exists;
  }

  Future<List<PostData>> fetchPinnedPosts({
    String? ownerUserId,
    int limit = 20,
  }) async {
    final uid = ownerUserId ?? _auth.currentUser?.uid;
    if (uid == null) return [];

    final pinnedSnap = await _fs
        .collection('users')
        .doc(uid)
        .collection('pinnedPosts')
        .orderBy('created_at', descending: true)
        .limit(limit)
        .get();

    final ids = pinnedSnap.docs.map((d) => d.id).toList();
    if (ids.isEmpty) return [];

    final order = <String, int>{ for (var i = 0; i < ids.length; i++) ids[i]: i };
    final chunks = _chunk(ids, 10);

    final snaps = await Future.wait(
      chunks.map((g) => _fs.collection('posts')
          .where(FieldPath.documentId, whereIn: g)
          .get()),
    );

    final List<PostData> out = [];
    for (final s in snaps) {
      for (final d in s.docs) {
        final m = Map<String, dynamic>.from(d.data());
        m['post_id'] = d.id; // PostData.fromMap 호환
        // 필요 시만 안정성 보강
        m['comments'] ??= [];
        m['image_urls'] ??= [];
        m['likes_count'] ??= 0;
        m['comments_count'] ??= 0;
        out.add(PostData.fromMap(m));
      }
    }

    out.sort((a, b) => (order[a.postId] ?? 1 << 30).compareTo(order[b.postId] ?? 1 << 30));
    return out;
  }

  List<List<String>> _chunk(List<String> list, int size) {
    final List<List<String>> out = [];
    for (int i = 0; i < list.length; i += size) {
      out.add(list.sublist(i, i + size > list.length ? list.length : i + size));
    }
    return out;
  }

  Future<void> togglePin({
    required String postId,
    required bool isCurrentlyPinned,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final ref = _fs.collection('users').doc(uid).collection('pinnedPosts').doc(postId);
    try {
      if (isCurrentlyPinned) {
        await ref.delete();
      } else {
        await ref.set({'createdAt': FieldValue.serverTimestamp()});
      }
    } catch (e) {
      debugPrint('togglePin error: $e');
    }
  }

  Future<void> toggleLike({
    required String postId,
    required bool isCurrentlyLiked,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final likeRef = _fs.collection('posts').doc(postId).collection('likes').doc(uid);
    final postRef = _fs.collection('posts').doc(postId);

    try {
      await _fs.runTransaction((tx) async {
        if (isCurrentlyLiked) {
          tx.delete(likeRef);
          tx.update(postRef, {'likes_count': FieldValue.increment(-1)});
        } else {
          tx.set(likeRef, {'createdAt': FieldValue.serverTimestamp()});
          tx.update(postRef, {'likes_count': FieldValue.increment(1)});
        }
      });
    } catch (e) {
      debugPrint('toggleLike error: $e');
      rethrow;
    }
  }

  // 댓글 작성
  Future<String?> addComment({
    required String postId,
    required String content,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final postRef = _fs.collection('posts').doc(postId);
    final commentRef = postRef.collection('comments').doc();

    try {
      await _fs.runTransaction((tx) async {
        tx.set(commentRef, {
          'comment_id': commentRef.id,
          'post_id': postId,
          'user_id': uid,
          'content': content.trim(),
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
        tx.update(postRef, {
          'comments_count': FieldValue.increment(1),
          'updated_at': FieldValue.serverTimestamp(),
        });
      });
      return commentRef.id;
    } catch (e) {
      debugPrint('addComment error: $e');
      return null;
    }
  }

  // 댓글 수정
  Future<void> editComment({
    required String postId,
    required String commentId,
    required String content,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final ref = _fs.collection('posts').doc(postId).collection('comments').doc(commentId);
    try {
      await ref.update({
        'content': content.trim(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('editComment error: $e');
    }
  }

  // 댓글 삭제
  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    final postRef = _fs.collection('posts').doc(postId);
    final commentRef = postRef.collection('comments').doc(commentId);
    try {
      await _fs.runTransaction((tx) async {
        tx.delete(commentRef);
        tx.update(postRef, {'comments_count': FieldValue.increment(-1)});
      });
    } catch (e) {
      debugPrint('deleteComment error: $e');
    }
  }

  // 댓글 스트림 (최신순)
  Stream<QuerySnapshot<Map<String, dynamic>>> commentsStream({
    required String postId,
    int? limit,
  }) {
    Query<Map<String, dynamic>> q = _fs
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('created_at', descending: true);
    if (limit != null) q = q.limit(limit);
    return q.snapshots();
  }

  // 좋아요 여부 스트림
  Stream<bool> isLikedStream(String postId) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream<bool>.empty();
    return _fs
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists);
  }

  // 핀 여부 스트림
  Stream<bool> isPinnedStream(String postId) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream<bool>.empty();
    return _fs
        .collection('users')
        .doc(uid)
        .collection('pinnedPosts')
        .doc(postId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  // 좋아요 수 스트림
  Stream<int> likeCountStream(String postId) {
    return _fs.collection('posts').doc(postId).snapshots().map((doc) {
      final data = doc.data();
      return (data?['likes_count'] ?? 0) as int;
    });
  }

  // 댓글 수 스트림
  Stream<int> commentCountStream(String postId) {
    return _fs.collection('posts').doc(postId).snapshots().map((doc) {
      final data = doc.data();
      return (data?['comments_count'] ?? 0) as int;
    });
  }

}
