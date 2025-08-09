// lib/pages/nearby/page.dart

import 'package:flutter/material.dart';

import 'widgets/main_header.dart';
import 'widgets/feed_grid.dart';  
import '../models/feed_data.dart'; 
import '../../services/feed_service.dart';
import '../../services/user_service.dart';

class NearbyPage extends StatefulWidget {
  const NearbyPage({super.key});

  @override
  State<NearbyPage> createState() => _NearbyPageState();
}

class _NearbyPageState extends State<NearbyPage> with SingleTickerProviderStateMixin {
  List<FeedData> realtimeFeeds = [];
  List<FeedData> hotFeeds = [];
  List<FeedData> wackFeeds = [];
  bool isLoading = true;
  String region = '서울시';
  
  final FeedService _feedService = FeedService();
  final UserService _userService = UserService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
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

    if(mounted) setState(() => isLoading = true);
    
    try {
      if (tabIndex == 0) {
        final fetchedFeeds = await _feedService.fetchRealtimeFeeds(
          region: region,
          limit: 20, // ✅ limit 값 전달
        );
        if(mounted) {
          setState(() {
            realtimeFeeds = fetchedFeeds;
          });
        }
      } else if (tabIndex == 1) {
        final fetchedFeeds = await _feedService.fetchHotFeeds(
          region: region,
          date: DateTime.now(),
          limit: 20,
        );
        if(mounted) {
          setState(() {
            hotFeeds = fetchedFeeds;
          });
        }
      } else if (tabIndex == 2) {
        final fetchedFeeds = await _feedService.fetchWackFeeds(
          region: region,
          limit: 20,
        );
        if(mounted) {
          setState(() {
            wackFeeds = fetchedFeeds;
          });
        }
      }
    } catch (e) {
      debugPrint('피드 로딩 실패: $e');
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('피드 로딩 중 오류가 발생했습니다: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> fetchRegion() async {
    try {
      final fetchedRegion = await _userService.fetchUserRegion();
      
      // ✅ 디버깅을 위해 콘솔에 출력
      if (fetchedRegion != null) {
        if (mounted) {
          setState(() {
            region = fetchedRegion;
          });
        }
      } else {
      }
    } catch (e) {
      // ✅ 오류 발생 시 콘솔에 출력
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('지역 정보를 불러오는 데 실패했습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 100, 
        title: MainHeader(
          region: region,
          currentFilterIndex: _tabController.index,
          onFilterSelected: (index) {            
            _tabController.animateTo(index);
          },
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          isLoading && _tabController.index == 0
              ? const Center(child: CircularProgressIndicator())
              : _buildFeedGrid(realtimeFeeds),
          isLoading && _tabController.index == 1
              ? const Center(child: CircularProgressIndicator())
              : _buildFeedGrid(hotFeeds),
          isLoading && _tabController.index == 1
              ? const Center(child: CircularProgressIndicator())
              : _buildFeedGrid(wackFeeds),
        ],
      ),
    );
  }

  Widget _buildFeedGrid(List<FeedData> feeds) {
    if (feeds.isEmpty) {
      return const Center(child: Text("게시물이 없습니다."));
    }
    return RefreshIndicator(
      onRefresh: () => _loadFeeds(tabIndex: _tabController.index),
      child: CustomScrollView(
        slivers: [
          SliverPadding( // ✅ Padding 대신 SliverPadding 사용
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            sliver: FeedGrid(feeds: feeds), // FeedGrid는 이미 SliverGrid를 포함하고 있습니다.
          ),
        ],
      ),
    );
  }
}