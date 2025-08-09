import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../widgets/utils/profile_avatar.dart';
import '../../widgets/utils/time_ago_text.dart';
import '../../services/auth_service.dart'; 
import '../../config.dart'; 
import '../../pages/posts/create_post_page.dart';
import '../../pages/posts/post_page.dart';
import '../../pages/feeds/tag.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  List<dynamic> allPosts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAllFeeds();
  }

  Future<void> fetchAllFeeds() async {
    if (mounted) setState(() => isLoading = true);

    final myUserId = await AuthService.getUserId();
    final token = await AuthService.getToken();

    if (myUserId == null || token == null) {
      print("로그인 정보 없음");
      return;
    }

    try {
      final userRes = await http.get(
        Uri.parse('${Config.baseUrl}/user/ids'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (userRes.statusCode != 200) throw Exception('유저 목록 조회 실패');
      List<dynamic> userIds = json.decode(userRes.body)['user_ids'];
      userIds.remove(myUserId); // 나 자신 제외
      List<dynamic> posts = [];

      for (String userId in userIds) {
        final postRes = await http.get(
          Uri.parse('${Config.baseUrl}/user/$userId/posts'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (postRes.statusCode == 200) {
          List<dynamic> userPosts = json.decode(postRes.body);
          posts.addAll(userPosts);
        }
      }
      if (mounted) {
        setState(() {
          allPosts = posts;
          isLoading = false;
        });
      }
    } catch (e) {
      print('피드 로딩 실패: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget _buildOverlayButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 36,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: Colors.white),
        label: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black.withOpacity(0.6), // 반투명
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 0,
        ),
      ),
    );
  }

  Widget buildPostCard(dynamic post) {
    final List<String> tags = (post['tags'] as List<dynamic>?)?.cast<String>() ?? [];
    final List<dynamic> comments = (post['comments'] as List<dynamic>?) ?? [];
    final List<dynamic> imageUrls = (post['image_urls'] as List<dynamic>?) ?? [];
    final PageController pageController = PageController();
    int currentPage = 0;

    return StatefulBuilder(
      builder: (context, setInnerState) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PostPage(post: post),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      ProfileAvatar(
                            profileUrl: post['profile_image'],
                            size: 40,
                      ),
                      SizedBox(width: 12),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 1),
                        margin: EdgeInsets.zero,
                        height: 40,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children:[
                            Text(post['user_name'], 
                            style: TextStyle(
                              fontSize: 14, 
                              fontWeight: FontWeight.w600, 
                              color: Colors.black,
                              letterSpacing: -0.5,
                            )),
                            Text(post['user_title'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.black)),
                          ]
                        ),
                      ),
                    ],
                  ),
                ),
                if (imageUrls.isNotEmpty)
                  SizedBox(
                    height: 350,
                    child: Stack(
                      children: [
                        PageView.builder(
                          controller: pageController,
                          itemCount: imageUrls.length,
                          onPageChanged: (index) {
                            setInnerState(() => currentPage = index);
                          },
                          itemBuilder: (context, index) {
                            return ClipRRect(
                              child: Image.network(
                                imageUrls[index],
                                width: double.infinity,
                                height: 250,
                                fit: BoxFit.cover,
                            ));
                          },
                        ),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Row(children: [FeedTag(label: post['category']), SizedBox(width: 5),  FeedTag(label: post['value'])]),
                        ),
                        (post['category'] == '요리') ? (
                          (post['recipe_id'] != null && post['recipe_title'] != null) ?
                            Positioned(
                              bottom: 12,
                              right: 8,
                              child: _buildOverlayButton(
                                text: '> ${post['recipe_title']}',
                                icon: Icons.restaurant_menu,
                                onPressed: () {
                                  // 레시피 페이지 이동
                                },
                              ),
                            )
                          : Positioned(
                              bottom: 8,
                              right: 8,
                              child: _buildOverlayButton(
                                text: '레시피 요청',
                                icon: Icons.soup_kitchen,
                                onPressed: () {
                                  // 레시피 요청 처리
                                },
                              ),
                            )
                        )
                        : (SizedBox.shrink()),
                        // 라인 인디케이터 (아래쪽에 가느다란 줄)
                        if(imageUrls.length > 1)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Row(
                              children: List.generate(imageUrls.length, (index) {
                                bool isActive = index == currentPage;
                                return Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 2),
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: isActive ? Colors.white : Colors.white30,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                      ],
                    ),
                  ),
                
                if (tags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: -8,
                            children: tags.map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '#$tag',
                                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        TimeAgoText(
                          createdAt: post['created_at'],
                          fontSize: 12,
                          fontColor: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  child: Row(children:[Image.asset('assets/fork.png', height: 24, width: 24), SizedBox(width: 20), Image.asset('assets/comment.png', height:20, width: 20)]),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(post['content'] ?? '', style: const TextStyle(fontSize: 16, color: Colors.black)),
                ),
                if (comments.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Text(
                      '${comments[0]['user_name'] ?? '익명'}: ${comments[0]['content'] ?? ''}',
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                    ),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 액션 버튼 클릭 시 이동 처리
  Future<void> _navigate(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreatePostPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: const Color.fromARGB(255, 245, 245, 245),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : allPosts.isNotEmpty
                    ? RefreshIndicator(
                        onRefresh: fetchAllFeeds,
                        child: ListView.builder(
                          itemCount: allPosts.length,
                          itemBuilder: (context, index) => buildPostCard(allPosts[index]),
                        ),
                      )
                    : const Center(child: Text("No posts")),
          ),
          Positioned(
            top: 40,
            right: 0,
            child: Container(
                // margin: const EdgeInsets.only(right: 8),
              width: 55,
              height: 45,
              decoration: BoxDecoration(
              color: Color.fromRGBO(199, 244, 100, 1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                // border: const Border(
                //   top: BorderSide(color: Colors.black, width: 0.5),
                //   left: BorderSide(color: Colors.black, width: 0.5),
                //   bottom: BorderSide(color: Colors.black, width: 0.5),
                //   right: BorderSide.none, // ✅ 오른쪽 테두리 제거
                // ),
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
      ]),
      // floatingActionButton: SizedBox(
      //   height: 36,
      //   child: FloatingActionButton.extended(
      //     onPressed: () {
      //       Navigator.push(
      //         context,
      //         MaterialPageRoute(builder: (_) => const RecipeListPage()),
      //       );
      //     },
      //     label: const Text(
      //       "요리하기", 
      //       style: TextStyle(
      //         fontSize: 12,
      //         fontWeight: FontWeight.bold, 
      //         color: Colors.white)),
      //     icon: const Icon(Icons.restaurant_menu, size: 16),
      //     backgroundColor: Colors.black,
      //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
      //     extendedPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), // ✅ 좌우 공간 줄이기
      //   ),
      // ),
    );
  }
}

