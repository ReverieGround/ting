// lib/services/feed_service.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ Firestore 임포트
import 'package:firebase_auth/firebase_auth.dart'; // ✅ FirebaseAuth 임포트

import '../models/post_data.dart';
import '../models/feed_data.dart';

class FeedService {

  // ✅ 실시간 피드: 최신순으로 정렬 (limit 파라미터 추가)
  Future<List<FeedData>> fetchRealtimeFeeds({
    String? region,
    required int limit, // ✅ limit 파라미터 추가
  }) async {
    try {
      // Firebase 쿼리 작성
      Query query = FirebaseFirestore.instance
          .collection('posts')
          .where('archived', isEqualTo: false)
          .where('visibility', isEqualTo: 'PUBLIC')
          .orderBy('created_at', descending: true)
          .limit(limit); // ✅ 파라미터로 받은 limit 사용

      // 만약 region이 제공되면 쿼리에 추가
      if (region != null && region.isNotEmpty) {
        query = query.where('region', isEqualTo: region);
      }

      final postsSnapshot = await query.get();
      if (postsSnapshot.docs.isEmpty) {
        return [];
      }

      final List<Future<FeedData>> feedFutures = postsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return FeedData.create(post: PostData.fromMap(data));
      }).toList();
      
      final List<FeedData> fetchedFeeds = await Future.wait(feedFutures);
      
      return fetchedFeeds;

    } catch (e) {
      debugPrint('Error fetching nearby feeds: $e');
      rethrow;
    }
  }

  // ✅ Hot Feed를 가져오는 메서드
  Future<List<FeedData>> fetchHotFeeds({
    String? region,
    required DateTime date,
    required int limit,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      final startOfDay = Timestamp.fromDate(DateTime(date.year, date.month, date.day));
      final endOfDay = Timestamp.fromDate(DateTime(date.year, date.month, date.day, 23, 59, 59));
      
      Query query = FirebaseFirestore.instance
          .collection('posts')
          .where('archived', isEqualTo: false)
          .where('visibility', isEqualTo: 'PUBLIC')
          .where('likes_count', isGreaterThan: 0)
          .where('value', isNotEqualTo: 'Wack')
          // .where('created_at', isGreaterThanOrEqualTo: startOfDay)
          // .where('created_at', isLessThanOrEqualTo: endOfDay)
          .orderBy('likes_count', descending: true);

      if (region != null && region.isNotEmpty) {
        query = query.where('region', isEqualTo: region);
      }
      
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      query = query.limit(limit);

      final postsSnapshot = await query.get();

      if (postsSnapshot.docs.isEmpty) {
        return [];
      }

      final List<Future<FeedData>> feedFutures = postsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return FeedData.create(post: PostData.fromMap(data));
      }).toList();
      
      final List<FeedData> fetchedFeeds = await Future.wait(feedFutures);
      
      return fetchedFeeds;

    } catch (e) {
      debugPrint('Error fetching hot feeds: $e');
      rethrow;
    }
  }

  // ✅ Wack Feed를 가져오는 메서드
  Future<List<FeedData>> fetchWackFeeds({
    String? region,
    required int limit,
  }) async {
    try {
      Query query = FirebaseFirestore.instance
          .collection('posts')
          .where('archived', isEqualTo: false)
          .where('visibility', isEqualTo: 'PUBLIC')
          .where('value', isEqualTo: 'Wack')
          .orderBy('likes_count', descending: true)
          .limit(limit);

      if (region != null && region.isNotEmpty) {
        query = query.where('region', isEqualTo: region);
      }
      
      final postsSnapshot = await query.get();

      if (postsSnapshot.docs.isEmpty) {
        return [];
      }

      final List<Future<FeedData>> feedFutures = postsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return FeedData.create(post: PostData.fromMap(data));
      }).toList();
      
      return await Future.wait(feedFutures);
    } catch (e) {
      debugPrint('Error fetching wack feeds: $e');
      rethrow;
    }
  }

  // ✅ 개인 피드: 팔로워들의 피드 가져오기
  Future<List<FeedData>> fetchPersonalFeed() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('User not logged in');
    }
    final myUserId = currentUser.uid;

    try {
      // Fetch user information to get followers
      final userInfoSnapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(myUserId)
          .get();

      if (!userInfoSnapshot.exists) {
        return [];
      }

      Map<String, dynamic> userInfo = userInfoSnapshot.data()!;
      List<String> followers = List<String>.from(userInfo['followers'] ?? []);
      
      // 팔로워가 없으면 빈 리스트 반환
      if (followers.isEmpty) {
        return [];
      }
      
      // Fetch posts of the followers
      final postsSnapshot = await FirebaseFirestore.instance
        .collection("posts")
        .where("archived", isEqualTo: false)
        .where("user_id", whereIn: followers)
        .orderBy("created_at", descending: true)
        .limit(50)
        .get();
      
      if (postsSnapshot.docs.isEmpty) {
        return [];
      }

      // Map fetched posts to a list of FeedData objects
      final List<Future<FeedData>> feedFutures = postsSnapshot.docs.map((doc) {
        final data = doc.data();
        return FeedData.create(post: PostData.fromMap(data));
      }).toList();
      
      final List<FeedData> fetchedFeeds = await Future.wait(feedFutures);
      return fetchedFeeds;
    } catch (e) {
      debugPrint('Error fetching personal feed: $e');
      rethrow;
    }
  }
}
