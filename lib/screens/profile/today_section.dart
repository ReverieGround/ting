import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart';
import '../../services/auth_service.dart';

class TodaySection extends StatefulWidget {
  const TodaySection({super.key});

  @override
  State<TodaySection> createState() => _TodaySectionState();
}

class _TodaySectionState extends State<TodaySection> {
  int? selectedIndex;
  List<dynamic> posts = [];
  final ScrollController _scrollController = ScrollController(); // ✅ 추가

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    try {
      final String? token = await AuthService.getToken();

      if (token == null) {
        print('토큰 없음');
        return;
      }

      final response = await http.get(
        Uri.parse('${Config.baseUrl}/post/myposts'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // final data = json.decode(response.body);
        final Map<String, dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            posts = data["posts"];
            selectedIndex = posts.length - 1;
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
      } else {
        print('포스트 불러오기 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('예외 발생: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: posts.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  controller: _scrollController, // ✅ 반드시 연결해야 작동함!
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.only(
                    left: posts.length == 1 ? 20 : 0,
                    right: 24,
                  ),
                  itemCount: posts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, index) {
                    final isSelected = selectedIndex == index;
                    final size = isSelected ? 110.0 : 80.0;

                    final post = posts[index];
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
