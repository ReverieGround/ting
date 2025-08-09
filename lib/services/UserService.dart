// lib/services/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // debugPrint를 위해 임포트

class UserService {
  Future<String?> fetchUserRegion() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return null;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists && userDoc.data()!.containsKey('region')) {
        return userDoc.data()!['region'] as String;
      }
      return null; // 문서가 없거나 region 필드가 없을 경우
    } catch (e) {
      debugPrint("Failed to fetch region from Firestore: $e");
      return null; // 오류 발생 시
    }
  }
}