import 'package:flutter/material.dart';
import 'dart:io'; 

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
      if (hasImages){
        final createdAt = HttpDate.parse(post['created_at']);
        final dateKey = '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
        if (!grouped.containsKey(dateKey)) {
          grouped[dateKey] = [];
        }
        grouped[dateKey]!.add(post);
      }
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final sortedKeys = groupedPosts.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    
    return ListView.builder(
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
              child: Text(date, style: const TextStyle(fontSize: 16, color: Color(0xFF3E3E3E), fontWeight: FontWeight.bold)),
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
