import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart'; // Timestamp를 위해 추가
import '../../services/auth_service.dart';
import '../../config.dart';

// Post 모델 정의 (Timestamp 처리 포함)
class Post {
  final String postId;
  final String userId;
  final String title;
  final String content;
  final String visibility;
  final List<String> imageUrls;
  final String? recipeId;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final bool archived;
  final String userName; // 사용자 이름 필드 추가

  Post({
    required this.postId,
    required this.userId,
    required this.title,
    required this.content,
    required this.visibility,
    required this.imageUrls,
    this.recipeId,
    required this.createdAt,
    required this.updatedAt,
    required this.archived,
    required this.userName, // 생성자에 추가
  });

  factory Post.fromMap(Map<String, dynamic> data) {
    List<String> urls = [];
    if (data['image_urls'] != null) {
      if (data['image_urls'] is List) {
        urls = List<String>.from(data['image_urls']);
      } else if (data['image_urls'] is String) {
        try {
          urls = List<String>.from(json.decode(data['image_urls']));
        } catch (e) {
          print("Error parsing image_urls string: $e");
          urls = [];
        }
      }
    }

    Timestamp createdAtTimestamp;
    Timestamp updatedAtTimestamp;

    if (data['created_at'] is Map && data['created_at']['_seconds'] != null) {
      createdAtTimestamp = Timestamp(data['created_at']['_seconds'], data['created_at']['_nanoseconds']);
    } else if (data['created_at'] is int) {
      createdAtTimestamp = Timestamp(data['created_at'], 0);
    } else {
      try {
        final dateTime = DateTime.tryParse(data['created_at'] as String);
        createdAtTimestamp = dateTime != null ? Timestamp.fromDate(dateTime) : Timestamp.now();
      } catch (e) {
        createdAtTimestamp = Timestamp.now();
      }
    }

    if (data['updated_at'] is Map && data['updated_at']['_seconds'] != null) {
      updatedAtTimestamp = Timestamp(data['updated_at']['_seconds'], data['updated_at']['_nanoseconds']);
    } else if (data['updated_at'] is int) {
      updatedAtTimestamp = Timestamp(data['updated_at'], 0);
    } else {
      try {
        final dateTime = DateTime.tryParse(data['updated_at'] as String);
        updatedAtTimestamp = dateTime != null ? Timestamp.fromDate(dateTime) : Timestamp.now();
      } catch (e) {
        updatedAtTimestamp = Timestamp.now();
      }
    }

    return Post(
      postId: data['post_id'] as String,
      userId: data['user_id'] as String,
      title: data['title'] as String,
      content: data['content'] as String? ?? '',
      visibility: data['visibility'] as String,
      imageUrls: urls,
      recipeId: data['recipe_id'] as String?,
      createdAt: createdAtTimestamp,
      updatedAt: updatedAtTimestamp,
      archived: data['archived'] as bool? ?? false,
      userName: data['user_name'] as String? ?? 'Unknown',
    );
  }
}


class NearbyPage extends StatefulWidget {
  const NearbyPage({super.key});

  @override
  State<NearbyPage> createState() => _NearbyPageState();
}

class _NearbyPageState extends State<NearbyPage> {
  int _currentFilterIndex = 0; // 필터 바 선택 인덱스
  // int _selectedBottomNavIndex = 0; // 하단 내비게이션 바가 제거되었으므로 필요 없음
  List<Post> allPosts = []; // Post 모델 리스트로 변경
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAllFeeds(); // 페이지 로드 시 피드 가져오기
  }

  Future<void> fetchAllFeeds() async {
    if (mounted) setState(() => isLoading = true);

    final myUserId = await AuthService.getUserId();
    final token = await AuthService.getToken();

    if (myUserId == null || token == null) {
      print("로그인 정보 없음");
      if (mounted) setState(() => isLoading = false);
      return;
    }

    try {
      final userRes = await http.get(
        Uri.parse('${Config.baseUrl}/user/ids'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (userRes.statusCode != 200) {
        throw Exception('유저 목록 조회 실패: ${userRes.statusCode} ${userRes.body}');
      }
      List<dynamic> userIds = json.decode(userRes.body)['user_ids'];
      userIds.remove(myUserId);

      List<Post> fetchedPosts = [];

      for (String userId in userIds) {
        final postRes = await http.get(
          Uri.parse('${Config.baseUrl}/user/$userId/posts'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (postRes.statusCode == 200) {
          List<dynamic> userPostsData = json.decode(postRes.body);
          for (var postData in userPostsData) {
            try {
              fetchedPosts.add(Post.fromMap(postData));
            } catch (e) {
              print("Error parsing post data from user $userId: $e, Data: $postData");
            }
          }
        } else {
          print("Failed to fetch posts for user $userId: ${postRes.statusCode} ${postRes.body}");
        }
      }
      if (mounted) { 
        setState(() {
          allPosts = fetchedPosts;
          isLoading = false;
        });
      }
    } catch (e) {
      print('피드 로딩 실패: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    // final mediaQuery = MediaQuery.of(context).size; // 하단 바 제거로 필요 없음
    // final double bottomNavHeight = 60.0; // 하단 바 제거로 필요 없음
    // final double bottomNavWidth = 343.0; // 하단 바 제거로 필요 없음
    // final double bottomNavMargin = 20.0 + MediaQuery.of(context).padding.bottom; // 하단 바 제거로 필요 없음

    // _bottomNavPages 리스트는 이제 FeedGrid만 포함하도록 간소화
    final List<Widget> _pages = <Widget>[
      FeedGrid(posts: allPosts), // 홈 페이지에 피드 그리드 표시, 데이터 전달
      // 다른 탭 페이지들은 하단 내비게이션 바가 없으므로 제거됩니다.
      // const Center(child: Text('Search Page Content', style: TextStyle(fontSize: 24))),
      // const Center(child: Text('Profile Page Content', style: TextStyle(fontSize: 24))),
    ];

    return Scaffold(
      backgroundColor: Colors.white, // 전체 배경색
      body: CustomScrollView( // Stack 대신 CustomScrollView만 사용 (하단 바가 없으므로)
        slivers: [
          SliverAppBar(
            expandedHeight: 140.0,
            floating: true,
            pinned: true,
            backgroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Column(
                children: [
                  const SizedBox(height: 50),
                  const MainHeader(),
                  const SizedBox(height: 20),
                  FilterBar(
                    selectedIndex: _currentFilterIndex,
                    onFilterSelected: (index) {
                      setState(() {
                        _currentFilterIndex = index;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  sliver: _pages.elementAt(0) is FeedGrid // 이제 항상 첫 번째 페이지(FeedGrid)를 보여줍니다.
                      ? _pages.elementAt(0)
                      : SliverToBoxAdapter(
                          child: _pages.elementAt(0),
                        ),
                ),
        ],
      ),
      // 하단 내비게이션 바 관련 위젯 제거
      // bottomNavigationBar: CustomBottomNavigationBar(...)
    );
  }
}

// 1. 상단 헤더 위젯
class MainHeader extends StatelessWidget {
  const MainHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '이 시간 우리 동네',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          Row(
            children: [
              const Text(
                '대한민국, 서울시',
                style: TextStyle(
                  fontSize: 14,
                  color: Color.fromRGBO(124, 124, 124, 1),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 20,
                height: 20,
                child: Image.asset(
                  'assets/navi.png',
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.location_on, size: 20, color: Colors.grey),
                ),
              ),

            ],
          ),
        ],
      ),
    );
  }
}

// 2. 필터 바 위젯
class FilterBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onFilterSelected;

  const FilterBar({
    super.key,
    required this.selectedIndex,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        children: [
          _buildFilterButton(
            context,
            icon: Image.asset('assets/thunder.png', width: 20, height: 20),
            text: '실시간',
            index: 0,
            isSelected: selectedIndex == 0,
            selectedColor: const Color.fromRGBO(225, 251, 169, 1),
            unselectedColor: const Color.fromRGBO(240, 240, 240, 1),
            selectedTextColor: Colors.black,
            unselectedTextColor: Colors.black,
          ),
          const SizedBox(width: 8),
          _buildFilterButton(
            context,
            icon: Image.asset('assets/fire.png', width: 20, height: 20),
            text: 'Hot Feed',
            index: 1,
            isSelected: selectedIndex == 1,
            selectedColor: const Color.fromRGBO(240, 240, 240, 1),
            unselectedColor: const Color.fromRGBO(240, 240, 240, 1),
            selectedTextColor: Colors.black,
            unselectedTextColor: Colors.black,
          ),
          const SizedBox(width: 8),
          _buildFilterButton(
            context,
            icon: Image.asset('assets/wack.png', width: 20, height: 20),
            text: 'Wack Feed',
            index: 2,
            isSelected: selectedIndex == 2,
            selectedColor: const Color.fromRGBO(240, 240, 240, 1),
            unselectedColor: const Color.fromRGBO(240, 240, 240, 1),
            selectedTextColor: Colors.black,
            unselectedTextColor: Colors.black,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(
    BuildContext context, {
    required Image icon,
    required String text,
    required int index,
    required bool isSelected,
    required Color selectedColor,
    required Color unselectedColor,
    required Color selectedTextColor,
    required Color unselectedTextColor,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () => onFilterSelected(index),
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? selectedColor : unselectedColor,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 20, height: 20, child: icon),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    color: isSelected ? selectedTextColor : unselectedTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 3. 피드 그리드 위젯
class FeedGrid extends StatelessWidget {
  final List<Post> posts;

  const FeedGrid({super.key, required this.posts});

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: Text('게시물이 없습니다.')),
      );
    }

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 0.75,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final post = posts[index];

          return FeedCard(
            imageUrl: post.imageUrls.isNotEmpty ? post.imageUrls[0] : 'https://placehold.co/200x260/E0E0E0/000000?text=No+Image',
            nickname: post.userName,
            likeCount: 100 + index,
            commentCount: post.content.length,
          );
        },
        childCount: posts.length,
      ),
    );
  }
}

// 4. 피드 카드 위젯 (제공해주신 코드 그대로 유지)
class FeedCard extends StatelessWidget {
  final String imageUrl;
  final String nickname;
  final int likeCount;
  final int commentCount;

  const FeedCard({
    super.key,
    required this.imageUrl,
    required this.nickname,
    required this.likeCount,
    required this.commentCount,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0), // 둥근 모서리
      child: Container(
        color: Colors.white, // 카드 배경색
        child: Stack(
          children: [
            // 이미지
            Positioned.fill(
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[300],
                  child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 50)),
                ),
              ),
            ),
            // 하단 그라데이션 오버레이
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7), // 아래쪽은 불투명하게
                      Colors.transparent, // 위쪽은 투명하게
                    ],
                    stops: const [0.0, 0.5], // 그라데이션 범위 조정
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 닉네임 섹션
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.grey,
                          // backgroundImage: NetworkImage('URL_TO_AVATAR'), // 아바타 이미지
                        ),
                        const SizedBox(width: 8),
                        Text(
                          nickname,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // 좋아요 및 댓글 섹션
                    Row(
                      children: [
                        Icon(
                          Icons.rocket_launch, // 로켓 아이콘 (이미지에서 보이는 아이콘과 유사한 것으로 대체)
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$likeCount+',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.chat_bubble_outline, // 말풍선 아이콘
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$commentCount',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// CustomBottomNavigationBar 클래스는 완전히 제거되었습니다.