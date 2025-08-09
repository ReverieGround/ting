import 'package:flutter/material.dart';
import '../../models/post_data.dart';

class PostContent extends StatelessWidget {
  final PostData post;

  const PostContent({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Text(
      post.content,
      style: TextStyle(fontSize: 16),
    );
  }
}
