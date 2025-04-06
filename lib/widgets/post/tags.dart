import 'package:flutter/material.dart';

class PostTags extends StatelessWidget {
  final Map<String, dynamic> post;

  const PostTags({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    List<dynamic> tags = post['tags'] as List<dynamic>? ?? [];
    
    return Wrap(
      spacing: 6,
      children: tags.map((tag) => Chip(label: Text(tag.toString()))).toList(),
    );
  }
}
