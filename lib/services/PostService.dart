// lib/services/post_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // print 대신 debugPrint 사용

class PostService {
  // 핀 상태를 토글하는 메서드
  Future<void> togglePin({
    required String postId,
    required bool isCurrentlyPinned,
  }) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;
    
    final pinDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('pinnedPosts')
        .doc(postId);
    
    try {
      if (isCurrentlyPinned) {
        await pinDocRef.delete();
      } else {
        await pinDocRef.set({'createdAt': FieldValue.serverTimestamp()});
      }
    } catch (e) {
      debugPrint('Failed to toggle pin state: $e');
    }
  }

  // 좋아요 상태를 토글하는 메서드
  Future<void> toggleLike({
    required String postId,
    required bool isCurrentlyLiked,
  }) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    final likeDocRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .doc(currentUserId);

    // likes_count 필드에 접근하기 위한 post 문서 참조
    final postDocRef = FirebaseFirestore.instance.collection('posts').doc(postId);

    try {
      if (isCurrentlyLiked) {
        // 좋아요 취소 (문서 삭제)
        await likeDocRef.delete();
        // 원자적으로 좋아요 수 감소
        await postDocRef.update({
          'likes_count': FieldValue.increment(-1),
        });
      } else {
        // 좋아요 추가 (문서 생성)
        await likeDocRef.set({
          'createdAt': FieldValue.serverTimestamp(),
        });
        // 원자적으로 좋아요 수 증가
        await postDocRef.update({
          'likes_count': FieldValue.increment(1),
        });
      }
    } catch (e) {
      debugPrint('Failed to toggle like state: $e');
      throw Exception('Failed to toggle like state: $e');
    }
  }
}