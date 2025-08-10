// lib/models/ProfileData.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'MyInfo.dart';
import 'PostData.dart'; 

class ProfileData {
  final MyInfo myInfo;
  final List<PostData> posts;
  final List<PostData> pinned;
  ProfileData({
    required this.myInfo,
    required this.posts,
    required this.pinned,
  });
}