import 'package:flutter/material.dart';
import '../../models/FeedData.dart'; 
import '../../feeds/widgets/FeedCard.dart'; 

class PinnedFeedsGrid extends StatelessWidget {
  final List<FeedData> pinnedFeeds;
  final void Function(FeedData feed)? onUnpin; // 추가

  const PinnedFeedsGrid({
    super.key,
    required this.pinnedFeeds,
    this.onUnpin,
  });

  @override
  Widget build(BuildContext context) {
    if (pinnedFeeds.isEmpty) {
      return const SliverFillRemaining(child: Center(child: Text('고정된 게시물이 없습니다.')));
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childCount: pinnedFeeds.length,
        itemBuilder: (context, index) {
          final feed = pinnedFeeds[index];
          return FeedCard(
            key: ValueKey('pinned_${feed.post.postId}'),
            feed: feed,
            isPinned: true,                         // ← 우상단 핀 아이콘 표시
            onTogglePin: onUnpin == null ? null : () => onUnpin!(feed),
            showTags: false,
            showContent: false,
            showBottomWriter: false,
            showTopWriter: false,
            showIcons: false,
            imageHeight: null,
            borderRadius: 12,
          );
        },
      ),
    );
  }
}
