import 'package:flutter/material.dart';
import '../utils/like_button.dart'; // ✅ LikeButton 추가
import '../../models/post_data.dart';

class PostStatsRow extends StatelessWidget {
  final PostData post;

  const PostStatsRow({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        /// ✅ LikeButton 추가 (좋아요 수 직접 관리)
        LikeButton(
          postId: post.postId,
          initialColor: Colors.grey,
          fontColor: Colors.black,
        ),
        SizedBox(width: 16),
        Icon(Icons.local_dining, color: Colors.orange),
        SizedBox(width: 4),
        // Text('${post['recipe_requests'] ?? 0}'),
      ],
    );
  }
}
