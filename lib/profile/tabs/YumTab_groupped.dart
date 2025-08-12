import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/FeedData.dart';

class YumTab extends StatefulWidget {
  final List<FeedData> feeds;
  const YumTab({
    super.key,
    required this.feeds,
  });

  @override
  State<YumTab> createState() => _YumGridState();
}

class _YumGridState extends State<YumTab> {
  int? selectedIndex;
  Map<String, List<dynamic>> groupedPosts = {};

  @override
  void initState() {
    super.initState();
    _reformDataStructure();
  }

  Future<void> _reformDataStructure() async {
    if (widget.feeds.isNotEmpty){
      setState(() {
        groupedPosts = groupPostsByDay(widget.feeds);
        selectedIndex = groupedPosts.length - 1;
      });
    }
  }

  Map<String, List<dynamic>> groupPostsByDay(List<FeedData> feeds) {
    final Map<String, List<FeedData>> grouped = {};
    for (var feed in feeds) {
      final hasImages = feed.post.imageUrls is List && (feed.post.imageUrls as List).isNotEmpty;
      if (hasImages) {
        final rawCreatedAt = feed.post.createdAt;
        
        DateTime createdAt;

        // 🔐 타입 체크 후 안전하게 DateTime으로 변환
        if (rawCreatedAt is Timestamp) {
          createdAt = rawCreatedAt.toDate();
        } else {
          // 예외 처리 또는 continue
          debugPrint("❌ 알 수 없는 created_at 타입: $rawCreatedAt");
          continue;
        }

        final dateKey = '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
        grouped.putIfAbsent(dateKey, () => []).add(feed);
      }
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final sortedKeys = groupedPosts.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    
    return widget.feeds.isEmpty ? 
      const Center(child: Text("No feeds", style: TextStyle(color: Color.fromARGB(243, 150, 150, 150), fontSize: 14)))
      : ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final date = sortedKeys[index];
        final postsForDate = groupedPosts[date]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 2.0),
              child: Text(date, style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 4),
            buildGalleryCard(postsForDate),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Widget buildGalleryCard(List<dynamic> feeds) {
    final count = feeds.length;
    final displayedFeeds = count <= 3 ? feeds : feeds.sublist(0, 3);
    
    return  GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: displayedFeeds.length,
          itemBuilder: (context, index) {
            final feed = displayedFeeds[index];
            final imageUrls = feed.post.imageUrls; // 너의 post 모델에 따라 맞게 수정
            final imageUrl = imageUrls[0];
            // 마지막 셀에 +N 오버레이
            if (index == 2 && count > 3) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  buildImage(imageUrl),
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    alignment: Alignment.center,
                    child: Text(
                      '+${count - 3}',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              );
            }
            return buildImage(imageUrl);
          },
          shrinkWrap: true,
      );
  }

  Widget buildImage(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: Colors.grey), // 실패 시 회색 박스
      ),
    );
  }

}
