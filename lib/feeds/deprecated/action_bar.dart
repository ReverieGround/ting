import 'package:flutter/material.dart';

class FeedActionBar extends StatelessWidget {
  final VoidCallback? onForkPressed;
  final VoidCallback? onCommentPressed;

  const FeedActionBar({
    Key? key,
    this.onForkPressed,
    this.onCommentPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: onForkPressed,
            child: Image.asset('assets/fork.png', height: 24, width: 24),
          ),
          SizedBox(width: 20),
          GestureDetector(
            onTap: onCommentPressed,
            child: Image.asset('assets/comment.png', height: 20, width: 20),
          ),
        ],
      ),
    );
  }
}