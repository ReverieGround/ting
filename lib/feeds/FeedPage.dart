// feeds/FeedPage.dart
import 'package:flutter/material.dart';
import 'widgets/FeedCard.dart';
import '../create/CreatePostPage.dart';
import '../models/FeedData.dart';
import '../services/FeedService.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> with AutomaticKeepAliveClientMixin {
  final FeedService _feedService = FeedService();

  List<FeedData> _feeds = [];
  bool _loading = false;

  int _initialLimit = 8;
  static const _columns = 1;
  static const _spacing = 6.0;
  static const _aspect = 3 / 4;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calcInitialLimit();
      _loadInitial();
    });
  }

  void _calcInitialLimit() {
    final size = MediaQuery.of(context).size;
    final cellW = (size.width - _spacing * (_columns - 1)) / _columns;
    final cellH = cellW / _aspect;
    final availableH = size.height - 120;
    final rows = (availableH / (cellH + _spacing)).ceil().clamp(1, 8);
    _initialLimit = rows * _columns + 6;
  }

  Future<void> _loadInitial() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final first = await _feedService.fetchPersonalFeed(limit: _initialLimit);
      if (!mounted) return;
      setState(() => _feeds = first);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('피드 로딩 중 오류가 발생했습니다.')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
      _prefetchMore();
    }
  }

  Future<void> _prefetchMore() async {
    if (_loading) return;
    _loading = true;
    try {
      // 더 큰 limit로 다시 가져와서 통째로 교체 (중복 문제 회피)
      final more = await _feedService.fetchPersonalFeed(limit: _initialLimit + 10);
      if (!mounted) return;
      setState(() => _feeds = more);
    } catch (_) {
    } finally {
      _loading = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _refresh() async {
    await _loadInitial();
  }

  Future<void> _navigate(BuildContext context) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePostPage()));
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final bool initialLoading = _feeds.isEmpty && _loading;

    final Widget listView = _feeds.isEmpty
        ? ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 160),
              Center(child: Text('No posts')),
            ],
          )
        : ListView.builder(
            padding: EdgeInsets.zero,
            cacheExtent: 800,
            itemCount: _feeds.length,
            itemBuilder: (context, index) {
              final item = _feeds[index];
              return FeedCard(
              feed: item,
              onDeleted: () {
                setState(() {
                  _feeds.removeWhere((f) => f.post.postId == item.post.postId);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('삭제되었습니다.')),
                );
              },
            );
          }
        );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          if (initialLoading)
            const Center(child: CircularProgressIndicator())
          else
            RefreshIndicator(onRefresh: _refresh, child: listView),
          Positioned(
            top: 40,
            right: 0,
            child: Container(
              width: 55,
              height: 45,
              decoration: const BoxDecoration(
                color: Color.fromRGBO(199, 244, 100, 1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: IconButton(
                icon: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 25),
                onPressed: () => _navigate(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
