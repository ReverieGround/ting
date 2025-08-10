import 'package:flutter/material.dart';
import '../../models/PostData.dart';

class PostTags extends StatelessWidget {
  final PostData post;

  const PostTags({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    // List<dynamic> tags = post.tags as List<dynamic>? ?? [];
    List<dynamic> tags =  [];
    
    return Wrap(
      spacing: 6,
      children: tags.map((tag) => Chip(label: Text(tag.toString()))).toList(),
    );
  }
}
