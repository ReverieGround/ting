// lib/models/ProfileData.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'ProfileInfo.dart';
import 'PostData.dart'; 

class ProfileData {
  final ProfileInfo profileInfo;
  final List<PostData> posts;
  final List<PostData> pinned;
  ProfileData({
    required this.profileInfo,
    required this.posts,
    required this.pinned,
  });
}