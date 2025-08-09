// lib/pages/nearby/widgets/feed_grid.dart
import 'package:flutter/material.dart';
import '../../models/FeedData.dart';
import 'FeedCard.dart';             

class FeedGrid extends StatelessWidget {
  final List<FeedData> feeds; 

  const FeedGrid({
    super.key, 
    required this.feeds
  });

  @override
  Widget build(BuildContext context) {
    if (feeds.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: Text('게시물이 없습니다.')),
      );
    }

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 0.75,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final feed = feeds[index];
          return FeedCard(
            imageUrl: feed.post.imageUrls != null ? feed.post.imageUrls![0] : 'https://placehold.co/200x260/E0E0E0/000000?text=No+Image',
            nickname: feed.user.userName,
            profileUrl: feed.user.profileImage!,
            postId: feed.post.postId,
          );
        },
        childCount: feeds.length,
      ),
    );
  }
}