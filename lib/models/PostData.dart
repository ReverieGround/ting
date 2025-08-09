// lib/models/post_data.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

String formatTimestamp(Timestamp timestamp) {
  // Convert Timestamp to DateTime
  DateTime dateTime = timestamp.toDate();
  // Format the DateTime into the desired format
  String formattedDate = DateFormat('yyyy. MM. dd HH:mm').format(dateTime);
  return formattedDate;
}

class PostData {

  final String userId;
  final String postId;
  final String title;
  final String content;
  final List<dynamic>? comments;
  final List<dynamic>? imageUrls;
  final int likesCount;
  final int commentsCount;
  final String category;
  final String? value;
  final String? recipeId;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final String visibility;
  final bool archived;
  
  PostData({
    required this.userId,
    required this.postId,
    required this.title,
    required this.content,
    this.comments,
    this.imageUrls,
    required this.likesCount,
    required this.commentsCount,
    required this.category,
    this.value,
    this.recipeId,
    required this.createdAt,
    required this.updatedAt,
    required this.visibility,
    required this.archived,
  });

  factory PostData.fromMap(Map<String, dynamic> data) {
    
    return PostData(
      userId: data['user_id'],
      postId: data['post_id'],
      title: data['title'],
      content: data['content'],
      comments: data['comments'] ?? [],
      imageUrls: data['image_urls'],
      likesCount: data['likes_count'],
      commentsCount: data['comments_count'],
      category: data['category'],
      value: data['value'],
      recipeId: data['recipe_id'],
      createdAt: data['created_at'],
      updatedAt: data['updated_at'],
      visibility: data['visibility'],
      archived: data['archived'],
    );
  }
}
