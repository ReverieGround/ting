import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import '../../config.dart';
import '../../services/auth_service.dart';
import '../../widgets/common/vibe_header.dart';

import 'today_section.dart';
import 'pick_section.dart';
import 'tab_section.dart';
import 'status_message.dart';
import '../../widgets/utils/profile_avatar.dart';

class ProfilePage extends StatefulWidget {
  final String? userId;

  const ProfilePage({super.key, this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserInfo? userInfo;
  String? jwtToken;
  bool isEditable = false;
  bool isSaving = false; // 클래스 상단에 추가
  bool isLoading = false; 
  List<dynamic> posts = [];
  final TextEditingController statusMessageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initTokenAndUser();
    _fetchPosts();
  }

  Future<void> _initTokenAndUser() async {
    jwtToken = await AuthService.getToken();
    await _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    if (jwtToken == null) return;

    final url = widget.userId == null
        ? '${Config.baseUrl}/user/me'
        : '${Config.baseUrl}/user/${widget.userId}';

    final response = await http.get(
      Uri.parse(url),
      headers: {"Authorization": "Bearer $jwtToken"},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        userInfo = UserInfo.fromJson(data);
        // isEditable = widget.userId == null;
        statusMessageController.text = userInfo?.statusMessage ?? '';
      });
    } else {
      print('❌ 사용자 정보를 불러오는데 실패했습니다');
    }
  }

  Future<void> _uploadProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    var request = http.MultipartRequest(
        'POST', Uri.parse('${Config.baseUrl}/user/upload_image'));
    request.headers['Authorization'] = 'Bearer $jwtToken';
    request.files.add(await http.MultipartFile.fromPath('file', picked.path));

    final res = await request.send();

    if (res.statusCode == 200) {
      print('✅ 프로필 이미지 업로드 성공');
      _loadUserInfo();
    } else {
      print('❌ 프로필 이미지 업로드 실패');
    }
  }


  Future<void> _fetchPosts() async {
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
        final Map<String, dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            posts = data["posts"];
          });
        }
      } else {
        print('포스트 불러오기 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('예외 발생: $e');
    }
  }
  
  void _fetchPostsWithLoading() async {
    setState(() => isLoading = true);
    await _fetchPosts();
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (userInfo == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: VibeHeader(
        titleWidget: Row(
          children: [
            ProfileAvatar(
                profileUrl: userInfo!.profileImage!,
                size: 30,
            ),
            SizedBox(width: 12),
            Text(userInfo!.nickname,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            SizedBox(width: 12),
            Text(userInfo!.location,
                style: TextStyle(fontSize: 12, color: Color(0xFF9B9B9B))),
          ],
        ),
        navigateType: VibeHeaderNavType.createPost,
        showBackButton: widget.userId != null,
        headerCallback: _fetchPosts,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserTitle(),
            _buildStatusMessage(),
            // _buildStats(),
            // _buildFollowInfo(),
            TodaySection(posts: posts),
            // PickSection(),
            SizedBox(height: 12),
            Expanded(child: TabSection(posts: posts)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUserTitle() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 8, bottom: 4),
      child: Text(
        userInfo?.userTitle ?? '',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
      ),
    );
  }

  Widget _buildStatusMessage() {
    return StatusMessage(
      message: userInfo?.statusMessage ?? '',
      onMessageUpdated: (newMsg) {
        setState(() {
          userInfo = userInfo?.copyWith(statusMessage: newMsg);
        });
      },
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem("레시피", userInfo!.recipeCount),
          _buildStatItem("포스트", userInfo!.postCount),
          _buildStatItem("받은 좋아요", userInfo!.receivedLikeCount),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count) {
    return Column(
      children: [
        Text('$count',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildFollowInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          Text("팔로워 ${userInfo!.followerCount} · 팔로잉 ${userInfo!.followingCount}",
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
  // build 하위 위젯 함수 및 모델은 이전 코드와 동일
}

// ✅ 모델 정의
class UserInfo {
  final String nickname;
  final String location;
  final String statusMessage;
  final int recipeCount;
  final int postCount;
  final int receivedLikeCount;
  final int followerCount;
  final int followingCount;
  final String profileImage;
  final String userTitle;

  UserInfo({
    required this.nickname,
    required this.location,
    required this.statusMessage,
    required this.recipeCount,
    required this.postCount,
    required this.receivedLikeCount,
    required this.followerCount,
    required this.followingCount,
    required this.profileImage,
    required this.userTitle,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) => UserInfo(
        nickname: json['username'] ?? '',
        location: json['location'] ?? '🇰🇷 Seoul',
        statusMessage: json['status_message'] ?? '',
        recipeCount: json['recipe_count'] ?? 0,
        postCount: json['post_count'] ?? 0,
        receivedLikeCount: json['received_like_count'] ?? 0,
        followerCount: json['follower_count'] ?? 0,
        followingCount: json['following_count'] ?? 0,
        profileImage: json['profile_image'] ?? '',
        userTitle: json['user_title'] ?? '',
      );

  UserInfo copyWith({String? statusMessage}) {
    return UserInfo(
      nickname: nickname,
      location: location,
      statusMessage: statusMessage ?? this.statusMessage,
      recipeCount: recipeCount,
      postCount: postCount,
      receivedLikeCount: receivedLikeCount,
      followerCount: followerCount,
      followingCount: followingCount,
      profileImage: profileImage,
      userTitle: userTitle,
    );
  }
}