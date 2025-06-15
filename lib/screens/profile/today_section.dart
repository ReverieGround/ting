import 'package:flutter/material.dart';
import '../../screens/create_post_page.dart';

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
          padding: EdgeInsets.fromLTRB(20, 5, 20, 5),
          child: Text(
            "Today",
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(
          height: 110,
          child: sortedPosts.isEmpty
              ? Padding(
                padding: const EdgeInsets.only(left:20.0),
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CreatePostPage()),
                        );
                      },
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 250, 250, 250),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black54, width: 0.5),
                        ),
                        child: const Center(
                          child: Icon(Icons.add, size: 40, color: Colors.black54),
                        ),
                      ),
                    ),
                  ),
              )
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
                            color: Colors.black26,
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
