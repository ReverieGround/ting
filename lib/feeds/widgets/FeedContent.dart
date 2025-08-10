// feeds/widgets/FeedContent.dart 
import 'package:flutter/material.dart';

class FeedContent extends StatelessWidget {
  final String? content;
  final List<dynamic> comments;
  final Color fontColor;

  const FeedContent({
    Key? key,
    this.content,
    required this.comments,
    this.fontColor=Colors.black,
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
              style: TextStyle(fontSize: 16, color: fontColor),
            ),
          ),
        if (comments.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(
              '${comments[0]['user_name'] ?? '익명'}: ${comments[0]['content'] ?? ''}',
              style: TextStyle(fontSize: 14, color: fontColor),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}