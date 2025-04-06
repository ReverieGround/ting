import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart';
import '../../services/auth_service.dart';
import 'post_card.dart';
import '../utils/profile_avatar.dart';

class UserCard extends StatefulWidget {
  final String userId;

  const UserCard({super.key, required this.userId});

  @override
  UserCardState createState() => UserCardState();
}

class UserCardState extends State<UserCard> {
  Map<String, dynamic>? user;
  List<String> postIds = [];
  bool isLoading = true;
  final ScrollController _scrollController = ScrollController();

  /// ✅ 사용자 정보 가져오기
  Future<void> fetchUserDetails() async {
    final response = await http.get(
      Uri.parse('${Config.baseUrl}/user/${widget.userId}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await AuthService.getToken()}',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        user = jsonDecode(response.body);
      });
      fetchUserPostIds(); // ✅ 새로운 API 사용
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// ✅ 사용자의 게시글 ID 목록 가져오기 (새 API 사용)
  Future<void> fetchUserPostIds() async {
    final response = await http.get(
      Uri.parse('${Config.baseUrl}/user/${widget.userId}/post_ids'), // ✅ 새로운 API
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await AuthService.getToken()}',
      },
    );

    if (response.statusCode == 200) {
      List<String> fetchedPostIds = List<String>.from(jsonDecode(response.body)['post_ids']);

      setState(() {
        postIds = fetchedPostIds;
        isLoading = false;
      });

      // ListView가 완전히 로드된 후 맨 처음으로 스크롤 이동
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToStart();
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _scrollToStart() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.minScrollExtent);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator(
        color: Colors.white,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.black), 
      ));
    }
    if (user == null) {
      return SizedBox();
    }
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ProfileAvatar(
                    profileUrl: user!['profile_image'],
                    size: 30,
                ),
                // CircleAvatar(
                //   backgroundColor: Colors.white,
                //   backgroundImage: user!['profile_image'] != null &&
                //           user!['profile_image'].isNotEmpty &&
                //           user!['profile_image'] != 'https://example.com/profile.jpg'
                //       ? NetworkImage(user!['profile_image'])
                //       : AssetImage('assets/default_profile.png') as ImageProvider,
                //   radius: 18,
                // ),
                SizedBox(width: 12),
                Text(
                  user!['username'] ?? '사용자',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            SizedBox(height: 10),
            SizedBox(
              height: 250,
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                reverse: true,
                itemCount: postIds.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 200,
                    margin: EdgeInsets.only(right: 8),
                    child: PostCard(postId: postIds[index]), // ✅ `post_id`만 전달
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
