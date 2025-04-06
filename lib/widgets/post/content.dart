import 'package:flutter/material.dart';

class PostContent extends StatelessWidget {
  final Map<String, dynamic> post;

  const PostContent({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Text(
      post['content'] ?? '내용이 없습니다.',
      style: TextStyle(fontSize: 16),
    );
  }
}
