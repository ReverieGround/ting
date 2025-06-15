import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class YumGrid extends StatefulWidget {
  final List<dynamic> posts;
  const YumGrid({
    super.key,
    required this.posts,
  });

  @override
  State<YumGrid> createState() => _YumGridState();
}

class _YumGridState extends State<YumGrid> {
  int? selectedIndex;
  Map<String, List<dynamic>> groupedPosts = {};

  @override
  void initState() {
    super.initState();
    _reformDataStructure();
  }

  Future<void> _reformDataStructure() async {
    if (widget.posts.isNotEmpty){
      setState(() {
        groupedPosts = groupPostsByDay(widget.posts);
        selectedIndex = groupedPosts.length - 1;
      });
    }
  }

  Map<String, List<dynamic>> groupPostsByDay(List<dynamic> posts) {
    final Map<String, List<dynamic>> grouped = {};
    for (var post in posts) {
      final hasImages = post['image_urls'] is List && (post['image_urls'] as List).isNotEmpty;
      if (hasImages) {
        final rawCreatedAt = post['created_at'];
        DateTime createdAt;

        // 🔐 타입 체크 후 안전하게 DateTime으로 변환
        if (rawCreatedAt is Timestamp) {
          createdAt = rawCreatedAt.toDate();
        } else if (rawCreatedAt is String) {
          createdAt = DateTime.parse(rawCreatedAt);
        } else {
          // 예외 처리 또는 continue
          debugPrint("❌ 알 수 없는 created_at 타입: $rawCreatedAt");
          continue;
        }

        final dateKey = '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
        grouped.putIfAbsent(dateKey, () => []).add(post);
      }
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final sortedKeys = groupedPosts.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    
    return widget.posts.isEmpty ? 
      const Center(child: Text("No posts", style: TextStyle(color: Color.fromARGB(243, 150, 150, 150), fontSize: 14)))
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
              padding: const EdgeInsets.only(left: 4.0),
              child: Text(date, style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            buildGalleryCard(postsForDate),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget buildGalleryCard(List<dynamic> posts) {
    final count = posts.length;
    final displayedPosts = count <= 3 ? posts : posts.sublist(0, 3);
    
    return  GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: displayedPosts.length,
          itemBuilder: (context, index) {
            final post = displayedPosts[index];
            final imageUrls = post['image_urls']; // 너의 post 모델에 따라 맞게 수정
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
