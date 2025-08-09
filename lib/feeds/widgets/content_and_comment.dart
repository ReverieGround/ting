import 'package:flutter/material.dart';

class FeedContentAndComment extends StatelessWidget {
  final String? content;
  final List<dynamic> comments;

  const FeedContentAndComment({
    Key? key,
    this.content,
    required this.comments,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (content != null && content!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(
              content!,
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
        if (comments.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(
              '${comments[0]['user_name'] ?? '익명'}: ${comments[0]['content'] ?? ''}',
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}