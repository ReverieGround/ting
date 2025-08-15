import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/FeedData.dart';
import '../../posts/PostPage.dart';

class YumTab extends StatefulWidget {
  final List<FeedData> feeds;
  final bool isLoading;
  final void Function(FeedData feed) onPin; // 추가

  const YumTab({
    super.key,
    required this.feeds,
    required this.onPin,           // 추가
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
    }).toList(); // 상위가 최신순으로 준다고 가정
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) return _buildShimmerGrid();

    if (_visibleFeeds.isEmpty) {
      return const Center(
        child: Text("No feeds",
          style: TextStyle(color: Color.fromARGB(243,150,150,150), fontSize: 14)),
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
          onLongPress: () => _openPreview(feed),
          onTap: () => {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PostPage(feed: feed)),
            )
          },
          child: _buildImage(url),
        );
      },
    );
  }

  Widget _buildImage(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: Colors.grey),
      ),
    );
  }

  Future<void> _openPreview(FeedData feed) async {
    if (!mounted) return; // 추가
    final List imgs = feed.post.imageUrls as List;
    final url = imgs.first as String;
    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(.35),
      builder: (ctx) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400+50,),
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
                          errorBuilder: (_, __, ___) => Container(color: Colors.grey),
                        ),
                      ),
                    ),
                    SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            minimumSize: const Size(0, 36),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            backgroundColor: const Color.fromARGB(255, 240, 240, 240),
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            if (!mounted) return;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              widget.onPin(feed);
                            });
                          },
                          icon: const Icon(Icons.push_pin_outlined, size: 16, color: Colors.black), // 아이콘도 축소
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
    if (!mounted) return; // 추가
  }

  Widget _buildShimmerGrid() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFD0D0D0);
    final highlight = isDark ? const Color(0xFF4C4C4C) : const Color(0xFFF1F1F1);

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
