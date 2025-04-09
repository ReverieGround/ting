import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../widgets/utils/profile_avatar.dart';
import '../widgets/utils/time_ago_text.dart';
import '../widgets/common/vibe_header.dart';
import '../services/auth_service.dart'; 
import '../config.dart'; 
import 'post_page.dart';
import 'recipe_example/recipe_list_page.dart';


class FeedUnfoldPage extends StatefulWidget {
  const FeedUnfoldPage({super.key});

  @override
  State<FeedUnfoldPage> createState() => _FeedUnfoldPageState();
}

class _FeedUnfoldPageState extends State<FeedUnfoldPage> {
  List<dynamic> allPosts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAllFeeds();
  }

  Future<void> fetchAllFeeds() async {
    setState(() => isLoading = true);

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

      // posts.sort((a, b) => b['created_at'].compareTo(a['created_at']));

      setState(() {
        allPosts = posts;
        isLoading = false;
      });
      
    } catch (e) {
      print('피드 로딩 실패: $e');
      setState(() => isLoading = false);
    }
  }
  Widget _buildOverlayButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: Colors.white),
      label: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black.withOpacity(0.4), // 반투명
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 0,
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
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: ProfileAvatar(
                    profileUrl: post['profile_image'],
                    size: 30,
                  ),
                  title: Text(post['username'] ?? 'Unknown'),
                ),
                if (imageUrls.isNotEmpty)
                  SizedBox(
                    height: 250,
                    child: Stack(
                      children: [
                        PageView.builder(
                          controller: pageController,
                          itemCount: imageUrls.length,
                          onPageChanged: (index) {
                            setInnerState(() => currentPage = index);
                          },
                          itemBuilder: (context, index) {
                            return Image.network(
                              imageUrls[index],
                              width: double.infinity,
                              height: 250,
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                        if (post['recipe_id'] != null && post['recipe_title'] != null)
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: _buildOverlayButton(
                              text: '> ${post['recipe_title']}',
                              icon: Icons.restaurant_menu,
                              onPressed: () {
                                // 레시피 페이지 이동
                              },
                            ),
                          )
                        else
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: _buildOverlayButton(
                              text: '레시피 요청',
                              icon: Icons.soup_kitchen,
                              onPressed: () {
                                // 레시피 요청 처리
                              },
                            ),
                          ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(post['content'] ?? '', style: const TextStyle(fontSize: 16)),
                ),
                if (comments.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Text(
                      '${comments[0]['username'] ?? '익명'}: ${comments[0]['content'] ?? ''}',
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VibeHeader(
        titleWidget: const Text(
          'VibeYum 피드',
          style: TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold),
        ),
        navigateType: VibeHeaderNavType.profilePage,
        showBackButton: false,
      ),
      body: isLoading
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RecipeListPage()),
          );
        },
        label: const Text("요리하기", style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.restaurant_menu),
        backgroundColor: Colors.deepOrangeAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
      ),
    );
  }
}
