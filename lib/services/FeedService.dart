// lib/services/feed_service.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore 임포트
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuth 임포트

import '../models/PostData.dart';
import '../models/FeedData.dart';

class FeedService {

  // 실시간 피드: 최신순으로 정렬 (limit 파라미터 추가)
  Future<List<FeedData>> fetchRealtimeFeeds({
    String? region,
    required int limit, // limit 파라미터 추가
  }) async {
    try {
      // Firebase 쿼리 작성
      Query query = FirebaseFirestore.instance
          .collection('posts')
          .where('archived', isEqualTo: false)
          .where('visibility', isEqualTo: 'PUBLIC')
          .orderBy('created_at', descending: true)
          .limit(limit); // 파라미터로 받은 limit 사용

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

  // Hot Feed를 가져오는 메서드
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

  // Wack Feed를 가져오는 메서드
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

  // 개인 피드: 팔로워들의 피드 가져오기
  Future<List<FeedData>> fetchPersonalFeed({int limit = 50}) async {
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (me == null) throw Exception('User not logged in');

    try {
      // following uids
      final followingSnap = await FirebaseFirestore.instance
          .collection('users').doc(me)
          .collection('following')
          .orderBy('created_at', descending: true)
          .get();
      var following = followingSnap.docs.map((d) => d.id).toList();

      if (following.isEmpty) return [];

      // blocks: 내가 차단한 유저 제외
      final blocksSnap = await FirebaseFirestore.instance
          .collection('users').doc(me)
          .collection('blocks')
          .get();
      final blocked = blocksSnap.docs.map((d) => d.id).toSet();
      following = following.where((u) => !blocked.contains(u)).toList();
      if (following.isEmpty) return [];

      // whereIn 10개 제한 → 청크
      final chunks = _chunk(following, 10);
      final List<QueryDocumentSnapshot<Map<String, dynamic>>> postDocs = [];

      for (final group in chunks) {
        final q = FirebaseFirestore.instance
            .collection('posts')
            .where('archived', isEqualTo: false)
            // 공개만 보일지 여부는 정책에 맞게. 필요 시 visibility 조건 제거
            .where('visibility', isEqualTo: 'PUBLIC')
            .where('user_id', whereIn: group)
            .orderBy('created_at', descending: true)
            .limit(limit);
        final snap = await q.get();
        postDocs.addAll(snap.docs);
      }

      if (postDocs.isEmpty) return [];

      // 합치고 정렬 후 상한 제한
      postDocs.sort((a, b) {
        final aa = a.data()['created_at'] as Timestamp?;
        final bb = b.data()['created_at'] as Timestamp?;
        final ad = aa?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = bb?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });
      final trimmed = postDocs.take(limit).toList();

      final futures = trimmed.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['post_id'] = doc.id; // PostData.fromMap 호환
        return FeedData.create(post: PostData.fromMap(data));
      }).toList();

      return await Future.wait(futures);
    } catch (e) {
      debugPrint('Error fetching personal feed: $e');
      rethrow;
    }
  }

  List<List<T>> _chunk<T>(List<T> list, int size) {
    if (list.isEmpty) return const [];
    final r = <List<T>>[];
    for (var i = 0; i < list.length; i += size) {
      r.add(list.sublist(i, i + size > list.length ? list.length : i + size));
    }
    return r;
  }
}
