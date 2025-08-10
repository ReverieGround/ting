import 'package:flutter/material.dart';

class StickyNoteModel {
  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatarUrl;
  final DateTime createdAt;
  final bool pinned;
  final String text;
  final Color color;
  

  StickyNoteModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.createdAt,
    required this.text,
    required this.color,
    this.pinned = false,
    
  });

  StickyNoteModel copyWith({
    String? text,
    Color? color,
    bool? pinned,
  }) {
    return StickyNoteModel(
      id: id,
      authorId: authorId,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      createdAt: createdAt,
      text: text ?? this.text,
      color: color ?? this.color,
      pinned: pinned ?? this.pinned,
      
    );
  }
}
