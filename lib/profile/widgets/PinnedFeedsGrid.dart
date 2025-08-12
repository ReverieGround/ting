// lib/profile/widgets/PinnedFeedsGrid.dart
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/FeedData.dart';
import '../../feeds/widgets/FeedCard.dart';

class PinnedFeedsGrid extends StatefulWidget {
  final List<FeedData> pinnedFeeds;
  final bool isLoading;
  final void Function(FeedData feed)? onUnpin;

  const PinnedFeedsGrid({
    super.key,
    required this.pinnedFeeds,
    this.onUnpin,
    this.isLoading = false,
  });

  @override
  State<PinnedFeedsGrid> createState() => _PinnedFeedsGridState();
}

class _PinnedFeedsGridState extends State<PinnedFeedsGrid> {
  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) return _buildShimmerSliver();

    if (widget.pinnedFeeds.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: Text('고정된 게시물이 없습니다.')),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childCount: widget.pinnedFeeds.length,
        itemBuilder: (context, index) {
          final feed = widget.pinnedFeeds[index];
          return FeedCard(
            key: ValueKey('pinned_${feed.post.postId}'),
            feed: feed,
            isPinned: true,
            onTogglePin: widget.onUnpin == null ? null : () => widget.onUnpin!(feed), 
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

  SliverPadding _buildShimmerSliver() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFD9D9D9);
    final highlight = isDark ? const Color(0xFF4C4C4C) : const Color(0xFFF2F2F2);
    final ratios = <double>[4 / 5, 1.0, 3 / 4, 4 / 5, 1.0, 3 / 4];

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childCount: ratios.length,
        itemBuilder: (_, i) {
          final ar = ratios[i % ratios.length];
          return Shimmer.fromColors(
            period: const Duration(milliseconds: 1200),
            baseColor: base,
            highlightColor: highlight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: ar,
                child: Container(color: base),
              ),
            ),
          );
        },
      ),
    );
  }
}
