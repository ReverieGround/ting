import 'package:flutter/material.dart';
import 'header.dart';
import 'image_carousel.dart';
import 'content_and_comment.dart';
import '../../posts/page.dart';
import 'like_widget.dart';
import 'comment_widget.dart';
import '../../models/post_data.dart';
import '../../models/feed_data.dart';

class FeedCard extends StatelessWidget {
  final FeedData feed;

  const FeedCard({
    Key? key,
    required this.feed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<dynamic> comments = feed.post.comments ?? [];
    final List<dynamic> imageUrls = (feed.post.imageUrls as List<dynamic>);
    final String value = feed.post.value ?? '';  
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostPage(post: feed.post), // PostPage도 경로 확인 필요
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FeedHeader(
              profileImageUrl: feed.user.profileImage!,
              userName: feed.user.userName,
              userTitle: feed.user.title,
              createdAt: formatTimestamp(feed.post.createdAt),
            ),
            if (imageUrls.isNotEmpty)
              FeedImageCarousel(
                imageUrls: imageUrls,
                category: feed.post.category,
                value: value,
                recipeId: feed.post.recipeId,
                recipeTitle: "", // TODO
                onRecipeButtonPressed: () {
                  debugPrint('Recipe button pressed for ');
                },
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(children: [
                LikeWidget(
                  postId: feed.post.postId,
                  initialLikeCount: feed.post.likesCount,
                  hasLiked: feed.isLikedByUser,
                  onToggleCompleted: null,
                  fontSize: 18.0,
                  iconSize: 22.0,
                ),
                SizedBox(width: 12),
                CommentWidget(
                  postId: feed.post.postId,
                  initialCommentCount: (feed.post.comments == null) ? feed.post.comments!.length : 0,
                  fontSize: 18.0,
                  iconSize: 18.0,
                ),
              ]),
            ),
            FeedContentAndComment(
              content: feed.post.content,
              comments: comments,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}