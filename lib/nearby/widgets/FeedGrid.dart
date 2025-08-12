import 'package:flutter/material.dart';
import '../../models/FeedData.dart';
import '../../feeds/widgets/FeedCard.dart';

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

    final screenWidth = MediaQuery.of(context).size.width;
    const columns = 2;
    const spacing = 6.0;
    const horizontalPadding = 0.0; // 바깥 여백이 있으면 값 수정
    final cellWidth = (screenWidth - horizontalPadding * 2 - spacing * (columns - 1)) / columns;

    const imageAspect = 3 / 4;                 // 가로:세로 비율
    final imageHeight = cellWidth / imageAspect; // 자동 계산된 높이
    const iconSize = 22.0;
    const iconGap = 4.0;

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        mainAxisExtent: imageHeight + iconSize + iconGap * 2, // 셀 높이 = 이미지 높이
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
            imageHeight: imageHeight, // 카드에도 동일 적용
            fit: BoxFit.cover,
            borderRadius: 12,
            iconSize: iconSize,
            iconGap: iconGap,
          );
        },
        childCount: feeds.length,
      ),
    );

    
  }
}