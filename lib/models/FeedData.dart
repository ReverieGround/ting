// lib/models/FeedData.dart
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'UserData.dart';
import 'PostData.dart';

class FeedData {
  final UserData user;
  final PostData post;
  final bool isPinned;
  final bool isLikedByUser;
  final int numComments;
  final int numLikes;

  FeedData._internal({
    required this.post,
    required this.user,
    required this.isPinned,
    required this.isLikedByUser,
    required this.numComments,
    required this.numLikes,
  });

  static Future<FeedData> create({
    required PostData post,
    UserData? user,
    bool? isPinned,
    bool? isLikedByUser,
    int? numComments,
    int? numLikes,
  }) async {
    UserData fetchedUser;

    if (user != null) {
      fetchedUser = user;
    } else {
      try {
        final userInfoSnapshot = await FirebaseFirestore.instance
            .collection("users")
            .doc(post.userId)
            .get();

        if (userInfoSnapshot.exists && userInfoSnapshot.data() != null) {
          fetchedUser = UserData.fromJson(userInfoSnapshot.data()!);
        } else {
          debugPrint('User data not found for userId: ${post.userId}. Throwing error.');
          throw Exception('User data for post creator not found.'); // 사용자 데이터를 찾지 못하면 예외 발생
        }
      } catch (e) {
        debugPrint('Error fetching user data for ${post.userId}: $e');
        throw Exception('Failed to fetch user data: $e'); // 데이터 로딩 중 에러 발생 시 예외 던지기
      }
    }

    bool fetchedIsPinned = isPinned ?? false;
    if (isPinned == null) {
      try {
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        if (currentUserId != null) {
          final pinDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserId)
              .collection('pinnedPosts')
              .doc(post.postId)
              .get();
          fetchedIsPinned = pinDoc.exists;
        }
      } catch (e) {
        debugPrint('Error fetching pin status for post ${post.postId}: $e');
      }
    }

    int? fetchedNumLikes = numLikes ?? 0;
    int? fetchedNumComments = numComments ?? 0;
    bool? fetchedIsLikedByUser = isLikedByUser;

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final postRef = FirebaseFirestore.instance.collection('posts').doc(post.postId);
      final likesCol = postRef.collection('likes');
      final commentsCol = postRef.collection('comments');

      final futures = <Future>[];
      
      // 좋아요 수
      if (numLikes == null) {
        futures.add(
          likesCol.count().get().then((snap) => fetchedNumLikes = snap.count),
        );
      }

      // 내가 좋아요 눌렀는지
      if (uid != null && isLikedByUser == null) {
        futures.add(
          likesCol.doc(uid).get().then((doc) => fetchedIsLikedByUser = doc.exists),
        );
      }

      // 댓글 수
      if (numComments == null) {
        futures.add(
          commentsCol.count().get().then((snap) => fetchedNumComments = snap.count),
        );
      }

      await Future.wait(futures);
    } catch (e) {
      debugPrint('fetch meta failed for post ${post.postId}: $e');
    }

    return FeedData._internal(
      post: post,
      user: fetchedUser,
      isPinned: fetchedIsPinned,
      isLikedByUser: fetchedIsLikedByUser!,
      numComments: fetchedNumComments!,
      numLikes: fetchedNumLikes!,
    );
  }
}