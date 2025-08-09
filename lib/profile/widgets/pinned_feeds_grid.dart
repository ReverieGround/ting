import 'package:flutter/material.dart';
import '../../models/feed_data.dart'; 
import '../../nearby/widgets/feed_card.dart'; 

class PinnedFeedsGrid extends StatelessWidget {
  final List<FeedData> pinnedFeeds;

  const PinnedFeedsGrid({
    super.key,
    required this.pinnedFeeds,
  });

  @override
  Widget build(BuildContext context) {
    if (pinnedFeeds.isEmpty) {
      return const SliverFillRemaining( // SliverGrid 대신 SliverFillRemaining 사용
        child: Center(child: Text('고정된 게시물이 없습니다.')),
      );
    }

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2열 그리드
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 0.75, // FeedCard와 동일한 비율 유지
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final feed = pinnedFeeds[index];
          return FeedCard(
            imageUrl: feed.post.imageUrls != null ? feed.post.imageUrls![0] : 'https://placehold.co/200x260/E0E0E0/000000?text=No+Image',
            nickname: feed.user.userName,
            profileUrl: feed.user.profileImage!,
            postId: feed.post.postId,
          );
        },
        childCount: pinnedFeeds.length,
      ),
    );
  }
}
