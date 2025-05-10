import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart';
import '../../services/auth_service.dart';

class TodaySection extends StatefulWidget {
  final List<dynamic> posts;
  const TodaySection({
    super.key,
    required this.posts,
  });
  @override
  State<TodaySection> createState() => _TodaySectionState();
}

class _TodaySectionState extends State<TodaySection> {
  int? selectedIndex;
  final ScrollController _scrollController = ScrollController(); // ✅ 추가

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      selectedIndex = widget.posts.length - 1;
    });
    await Future.delayed(const Duration(milliseconds: 100)); // 빌드 대기
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedPosts = [...widget.posts]; // 원본 변경 방지
    sortedPosts.sort((a, b) {
      final aTime = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(2000);
      final bTime = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(2000);
      return aTime.compareTo(bTime); // 오래된 → 최신 순 (최신이 오른쪽에!)
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 15, 20, 10),
          child: Text(
            "Today",
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        SizedBox(
          height: 110,
          child: sortedPosts.isEmpty
              ? const Center(child: Text("No posts", style: TextStyle(color: Color.fromARGB(243, 150, 150, 150), fontSize: 14)))
              : ListView.separated(
                  controller: _scrollController, // ✅ 반드시 연결해야 작동함!
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.only(
                    left: sortedPosts.length == 1 ? 20 : 0,
                    right: 24,
                  ),
                  itemCount: sortedPosts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, index) {
                    final isSelected = selectedIndex == index;
                    final size = isSelected ? 110.0 : 80.0;

                    final post = sortedPosts[index];
                    final List imageList = post['image_urls'] ?? [];
                    
                    final String? imageUrl =
                        imageList.isNotEmpty ? imageList[0] : null;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIndex = index;
                        });
                      },
                      child: Align(
                        alignment: Alignment.center,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            image: imageUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(imageUrl),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: imageUrl == null
                              ? const Icon(Icons.image_not_supported, size: 40)
                              : null,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
