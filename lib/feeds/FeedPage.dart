// lib/pages/feed/feed_page.dart
import 'package:flutter/material.dart';
import 'widgets/FeedCard.dart';
import '../create/CreatePostPage.dart';
import '../models/FeedData.dart';
import '../../services/feed_service.dart'; // ✅ FeedService 임포트

class FeedPage extends StatefulWidget {
  const FeedPage({
    super.key,
  });

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  List<FeedData> allFeeds = [];
  bool isLoading = true;
  
  // ✅ FeedService 인스턴스 생성
  final FeedService _feedService = FeedService();

  @override
  void initState() {
    super.initState();
    fetchAllFeeds();
  }

  Future<void> fetchAllFeeds() async {
    if (mounted) setState(() => isLoading = true);

    try {
      // ✅ 서비스의 메서드를 호출하여 데이터를 가져옵니다.
      final fetchedFeeds = await _feedService.fetchPersonalFeed();
      if (mounted) {
        setState(() {
          allFeeds = fetchedFeeds;
        });
      }
    }
    catch (e) {
      debugPrint('피드 로딩 중 오류 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('피드 로딩 중 오류가 발생했습니다.')),
      );
    }
    finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _navigate(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreatePostPage()),
    );
    // 새 글 작성 후 피드를 갱신합니다.
    fetchAllFeeds();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            color: Colors.white,
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : allFeeds.isNotEmpty
                    ? RefreshIndicator(
                        onRefresh: fetchAllFeeds,
                        child: ListView.builder(
                          itemCount: allFeeds.length,
                          itemBuilder: (context, index) {
                            return FeedCard(feed: allFeeds[index]);
                          },
                        ),
                      )
                    : const Center(child: Text("No posts")),
          ),
          Positioned(
            top: 40,
            right: 0,
            child: Container(
              width: 55,
              height: 45,
              decoration: BoxDecoration(
                color: Color.fromRGBO(199, 244, 100, 1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 25,
                ),
                onPressed: () => _navigate(context),
              ),
            ),
          )
        ],
      ),
    );
  }
}