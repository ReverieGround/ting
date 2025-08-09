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

  FeedData._internal({
    required this.post,
    required this.user,
    required this.isPinned,
    required this.isLikedByUser,
  });

  static Future<FeedData> create({
    required PostData post,
    UserData? user,
    bool? isPinned,
    bool? isLikedByUser,
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

    bool fetchedIsLikedByUser = isLikedByUser ?? false;
    if (isLikedByUser == null) {
      try {
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        if (currentUserId != null) {
          final likeDoc = await FirebaseFirestore.instance
              .collection('posts')
              .doc(post.postId)
              .collection('likes')
              .doc(currentUserId)
              .get();
          fetchedIsLikedByUser = likeDoc.exists;
        }
      } catch (e) {
        debugPrint('Error fetching like status for post ${post.postId}: $e');
      }
    }

    return FeedData._internal(
      post: post,
      user: fetchedUser,
      isPinned: fetchedIsPinned,
      isLikedByUser: fetchedIsLikedByUser,
    );
  }
}