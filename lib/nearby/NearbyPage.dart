// NearbyPage.dart
import 'package:flutter/material.dart';
import 'widgets/MainHeader.dart';
import 'widgets/FeedGrid.dart';
import '../models/FeedData.dart';
import '../../services/FeedService.dart';
import '../../services/UserService.dart';

class NearbyPage extends StatefulWidget {
  const NearbyPage({super.key});

  @override
  State<NearbyPage> createState() => _NearbyPageState();
}

class _NearbyPageState extends State<NearbyPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  List<FeedData> realtimeFeeds = [];
  List<FeedData> hotFeeds = [];
  List<FeedData> wackFeeds = [];
  bool isLoading = true;
  String region = '서울시';

  final FeedService _feedService = FeedService();
  final UserService _userService = UserService();
  late TabController _tabController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
        _handleTabSelection();
      }
    });
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);
    await fetchRegion();
    await _loadFeeds(tabIndex: 0);
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _handleTabSelection() async {
    if (!_tabController.indexIsChanging) {
      await _loadFeeds(tabIndex: _tabController.index);
    }
  }

  Future<void> _loadFeeds({required int tabIndex}) async {
    if (tabIndex == 0 && realtimeFeeds.isNotEmpty) return;
    if (tabIndex == 1 && hotFeeds.isNotEmpty) return;
    if (tabIndex == 2 && wackFeeds.isNotEmpty) return;

    if (mounted) setState(() => isLoading = true);

    try {
      if (tabIndex == 0) {
        final fetchedFeeds = await _feedService.fetchRealtimeFeeds(region: region, limit: 20);
        if (mounted) setState(() => realtimeFeeds = fetchedFeeds);
      } else if (tabIndex == 1) {
        final fetchedFeeds = await _feedService.fetchHotFeeds(region: region, date: DateTime.now(), limit: 20);
        if (mounted) setState(() => hotFeeds = fetchedFeeds);
      } else if (tabIndex == 2) {
        final fetchedFeeds = await _feedService.fetchWackFeeds(region: region, limit: 20);
        if (mounted) setState(() => wackFeeds = fetchedFeeds);
      }
    } catch (e) {
      debugPrint('피드 로딩 실패: $e');
      if (mounted) {
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('피드 로딩 중 오류가 발생했습니다: $e', style: TextStyle(color: theme.colorScheme.onPrimary)),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> fetchRegion() async {
    try {
      final fetchedRegion = await _userService.fetchUserRegion();
      if (fetchedRegion != null && mounted) {
        setState(() => region = fetchedRegion);
      }
    } catch (e) {
      if (mounted) {
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('지역 정보를 불러오는 데 실패했습니다.'),
            backgroundColor: theme.colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(94),
        child: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          toolbarHeight: 100,
          automaticallyImplyLeading: false,
          leadingWidth: 0,
          titleSpacing: 0,
          title: null,
          flexibleSpace: SafeArea(
            top: true,
            bottom: false,
            left: false,
            right: false,
            child: MainHeader(
              region: region,
              currentFilterIndex: _tabController.index,
              onFilterSelected: (index) => _tabController.animateTo(index),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          isLoading && _tabController.index == 0
              ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
              : _buildFeedGrid(realtimeFeeds, theme),
          isLoading && _tabController.index == 1
              ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
              : _buildFeedGrid(hotFeeds, theme),
          isLoading && _tabController.index == 2
              ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
              : _buildFeedGrid(wackFeeds, theme),
        ],
      ),
    );
  }

  Widget _buildFeedGrid(List<FeedData> feeds, ThemeData theme) {
    if (feeds.isEmpty) {
      return Center(child: Text("게시물이 없습니다.", style: theme.textTheme.bodyMedium));
    }
    return RefreshIndicator(
      color: theme.colorScheme.primary,
      onRefresh: () => _loadFeeds(tabIndex: _tabController.index),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
            sliver: FeedGrid(
              feeds: feeds,
              onDeleted: (postId) {
                setState(() {
                  feeds.removeWhere((f) => f.post.postId == postId);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('삭제되었습니다.', style: TextStyle(color: theme.colorScheme.onPrimary)),
                    backgroundColor: theme.colorScheme.primary,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
