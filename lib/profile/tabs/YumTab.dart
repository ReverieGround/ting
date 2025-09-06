// lib/pages/profile/tabs/YumTab.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/FeedData.dart';
import '../../posts/PostPage.dart';

class YumTab extends StatefulWidget {
  final List<FeedData> feeds;
  final bool isLoading;
  final void Function(FeedData feed) onPin;

  const YumTab({
    super.key,
    required this.feeds,
    required this.onPin,
    this.isLoading = false,
  });

  @override
  State<YumTab> createState() => _YumTabState();
}

class _YumTabState extends State<YumTab> {
  late List<FeedData> _visibleFeeds;

  @override
  void initState() {
    super.initState();
    _rebuild();
  }

  @override
  void didUpdateWidget(covariant YumTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.feeds != widget.feeds || oldWidget.isLoading != widget.isLoading) {
      _rebuild();
    }
  }

  void _rebuild() {
    _visibleFeeds = widget.feeds.where((f) {
      final imgs = f.post.imageUrls;
      return imgs is List && imgs.isNotEmpty;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.isLoading) return _buildShimmerGrid(theme);

    if (_visibleFeeds.isEmpty) {
      return Center(
        child: Text(
          "No feeds",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(.6),
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4,
      ),
      itemCount: _visibleFeeds.length,
      itemBuilder: (context, index) {
        final feed = _visibleFeeds[index];
        final List imgs = feed.post.imageUrls as List;
        final url = imgs.first as String;

        return GestureDetector(
          key: ValueKey('yum_${feed.post.postId}'),
          onLongPress: () => _openPreview(feed, theme),
          onTap: () async {
            final deleted = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PostPage(feed: feed)),
            );
            if (deleted == true) {
              if (!mounted) return;
              setState(() {
                _visibleFeeds.removeWhere((f) => f.post.postId == feed.post.postId);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('삭제되었습니다.', style: TextStyle(color: theme.colorScheme.onPrimary)),
                  backgroundColor: theme.colorScheme.primary,
                ),
              );
            }
          },
          child: _buildImage(context, url),
        );
      },
    );
  }

  Widget _buildImage(BuildContext context, String url) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: theme.colorScheme.surfaceVariant),
      ),
    );
  }

  Future<void> _openPreview(FeedData feed, ThemeData theme) async {
    if (!mounted) return;
    final List imgs = feed.post.imageUrls as List;
    final url = imgs.first as String;

    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: theme.colorScheme.scrim.withOpacity(.35),
      builder: (ctx) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 450),
            child: Material(
              clipBehavior: Clip.antiAlias,
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: theme.colorScheme.surfaceVariant),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            minimumSize: const Size(0, 36),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            backgroundColor: theme.colorScheme.secondaryContainer,
                            foregroundColor: theme.colorScheme.onSecondaryContainer,
                          ),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            if (!mounted) return;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              widget.onPin(feed);
                            });
                          },
                          icon: Icon(Icons.push_pin_outlined, size: 16, color: theme.colorScheme.onSecondaryContainer),
                          label: const Text('상단 고정하기', style: TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    if (!mounted) return;
  }

  Widget _buildShimmerGrid(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final base = theme.colorScheme.surfaceVariant.withOpacity(isDark ? .45 : .6);
    final highlight = theme.colorScheme.surface.withOpacity(isDark ? .35 : .9);

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4,
      ),
      itemCount: 9,
      itemBuilder: (_, __) {
        return Shimmer.fromColors(
          period: const Duration(milliseconds: 1200),
          baseColor: base,
          highlightColor: highlight,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(color: base),
          ),
        );
      },
    );
  }
}
