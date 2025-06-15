import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'today_section.dart';
import 'tab_section.dart';
import 'status_message.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../widgets/common/vibe_header.dart';
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
    _loadUserInfo();
    _fetchPostsFromFirestore();
  }

  Future<void> _loadUserInfo() async {
    try {
      String? targetUserId = widget.userId;

      // 현재 로그인한 사용자 UID 가져오기
      if (targetUserId == null) {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          debugPrint('❌ 로그인한 유저 없음');
          return;
        }
        targetUserId = currentUser.uid;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .get();

      if (!doc.exists) {
        debugPrint('❌ 사용자 문서가 존재하지 않음');
        return;
      }

      final data = doc.data();
      if (mounted) {
        setState(() {
          userInfo = UserInfo.fromJson(data!);
          statusMessageController.text = userInfo?.statusMessage ?? '';
          // isEditable = widget.userId == null; // ✅ 필요 시 복원
        });
      }
    } catch (e) {
      debugPrint('❌ Firestore에서 사용자 정보 불러오기 실패: $e');
    }
  }

  Future<void> _uploadProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint("❌ 로그인된 사용자 없음");
        return;
      }

      final fileName =
          'profile_images/${user.uid}_${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
      final ref = FirebaseStorage.instance.ref().child(fileName);

      await ref.putFile(File(picked.path));
      final downloadUrl = await ref.getDownloadURL();

      // ✅ Firestore의 사용자 문서 업데이트
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'profile_image': downloadUrl});

      debugPrint('✅ 프로필 이미지 업로드 및 Firestore 업데이트 성공');
      _loadUserInfo(); // Firestore에서 바로 다시 불러오기
    } catch (e) {
      debugPrint('❌ 이미지 업로드 실패: $e');
    }
  }

  Future<void> _fetchPostsFromFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint("❌ 로그인된 유저가 없습니다.");
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection("posts")
          .where("user_id", isEqualTo: user.uid)
          .where("archived", isEqualTo: false)
          .orderBy("created_at", descending: true)
          .limit(50)
          .get();

      final postList = snapshot.docs.map((doc) => doc.data()).toList();
      print(postList);
      if (mounted) {
        setState(() {
          posts = postList;
        });
      }
    } catch (e) {
      debugPrint("❌ Firestore에서 포스트 불러오기 실패: $e");
    }
  }
  
  void _fetchPostsWithLoading() async {
    setState(() => isLoading = true);
    await _fetchPostsFromFirestore();
    setState(() => isLoading = false);
  }
  
  @override
  Widget build(BuildContext context) {
    if (userInfo == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: VibeHeader(
        backgroundColor: Color.fromARGB(255, 245, 245, 245),
        titleWidget: Container(
          margin: EdgeInsets.only(top: 5),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.zero,
                        bottomRight: Radius.zero,
                      ),
                    ),
                    backgroundColor: Colors.white,
                    builder: (_) => _buildProfileImagePicker(context));
                },
                child: ProfileAvatar(
                    profileUrl: userInfo!.profileImage!,
                    size: 43,
                ),
              ),
              SizedBox(width: 12),
              Container(
                padding: EdgeInsets.zero,
                margin: EdgeInsets.zero,
                height: 45,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:[
                    Text(userInfo!.nickname, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    Text(userInfo!.userTitle ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.black)),
                  ]
                ),
              ),
              // SizedBox(width: 12),
              // Text(userInfo!.location,
              //     style: TextStyle(fontSize: 12, color: Color(0xFF9B9B9B))),
            ],
          ),
        ),
        navigateType: VibeHeaderNavType.createPost,
        showBackButton: widget.userId != null,
        headerCallback: _fetchPostsFromFirestore,
      ),
      body: Container(
        color: Color.fromARGB(255, 245, 245, 245),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusMessage(),
              // _buildStats(),
              // _buildFollowInfo(),
              Container(
                color: const Color.fromARGB(255, 245, 245, 245),
                child: TodaySection(posts: posts)),
              // PickSection(),
              Expanded(child: TabSection(posts: posts)),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildProfileImagePicker(BuildContext context) {
    
    const avatarList = [
      'https://firebasestorage.googleapis.com/v0/b/vibeyum-alpha.firebasestorage.app/o/profile_images%2Favatar-design.png?alt=media&token=f34a16cd-689d-464f-9c45-3859c66be0c0',
      'https://firebasestorage.googleapis.com/v0/b/vibeyum-alpha.firebasestorage.app/o/profile_images%2Fbusinesswoman.png?alt=media&token=6fa85751-6fff-42e2-91d9-32d114167352',
      'https://firebasestorage.googleapis.com/v0/b/vibeyum-alpha.firebasestorage.app/o/profile_images%2Fprogrammer.png?alt=media&token=ed21ed93-f845-42b9-8ec4-6d47f6e2650c',
      'https://firebasestorage.googleapis.com/v0/b/vibeyum-alpha.firebasestorage.app/o/profile_images%2Fwoman%20(1).png?alt=media&token=4494aa07-e112-489e-b053-7555d483c02c',
      'https://firebasestorage.googleapis.com/v0/b/vibeyum-alpha.firebasestorage.app/o/profile_images%2Fwoman.png?alt=media&token=4acd3f2f-3a19-4289-858e-e9fe929b5e91',
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('프로필 사진 선택', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.black)),
                InkWell(
                  onTap: () async {
                    Navigator.pop(context);
                    await _uploadProfileImage();
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.photo_library, color: Colors.black87),
                  ),
                )
              ]
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: avatarList.map((url) {
                return GestureDetector(
                  onTap: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .update({'profile_image': url});
                      Navigator.pop(context);
                      _loadUserInfo(); // 사용자 정보 갱신
                    }
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      url,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
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
