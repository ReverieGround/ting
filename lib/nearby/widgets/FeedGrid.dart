// feeds/widgets/FeedGrid.dart
import 'package:flutter/material.dart';
import '../../models/FeedData.dart';
import '../../feeds/widgets/FeedCard.dart';

class FeedGrid extends StatelessWidget {
  final List<FeedData> feeds;
  final ValueChanged<String>? onDeleted; // postId 전달

  const FeedGrid({
    super.key,
    required this.feeds,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    if (feeds.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: Text('게시물이 없습니다.')),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    const columns = 2;
    const spacing = 6.0;
    const horizontalPadding = 0.0;
    final cellWidth = (screenWidth - horizontalPadding * 2 - spacing * (columns - 1)) / columns;

    const imageAspect = 3 / 4;
    final imageHeight = cellWidth / imageAspect;
    const iconSize = 22.0;
    const iconGap = 4.0;

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        mainAxisExtent: imageHeight + iconSize + iconGap * 2,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final feed = feeds[index];
          return FeedCard(
            feed: feed,
            showTags: false,
            showContent: false,
            showTopWriter: false,
            showBottomWriter: true,
            imageHeight: imageHeight,
            fit: BoxFit.cover,
            borderRadius: 12,
            iconSize: iconSize,
            iconGap: iconGap,
            onDeleted: () {
              onDeleted?.call(feed.post.postId);
            },
          );
        },
        childCount: feeds.length,
      ),
    );
  }
}
