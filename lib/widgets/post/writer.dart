import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:vibe_yum/widgets/utils/profile_avatar.dart';
import 'dart:convert';
import '../../config.dart'; // ✅ API Base URL 가져오기
import '../utils/time_ago_text.dart';

class UserInfoRow extends StatefulWidget {
  final Map<String, dynamic> post;

  const UserInfoRow({super.key, required this.post});

  @override
  _UserInfoRowState createState() => _UserInfoRowState();
}

class _UserInfoRowState extends State<UserInfoRow> {
  String? username;
  String? userProfile;
  bool isLoading = true; // ✅ 로딩 상태 추가

  @override
  void initState() {
    super.initState();
    fetchUserInfo(); // ✅ API 호출
  }

  Future<void> fetchUserInfo() async {
    String userId = widget.post['user_id'] ?? '';

    if (userId.isEmpty) return; // ✅ user_id가 없으면 API 호출하지 않음

    try {
      final response = await http.get(Uri.parse('${Config.baseUrl}/user/$userId'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          username = data['username']; // ✅ API에서 받은 username
          userProfile = data['profile_image']; // ✅ API에서 받은 프로필 이미지
          isLoading = false; // ✅ 로딩 상태 업데이트
        });
      } else {
        setState(() {
          isLoading = false; // ✅ 로딩 종료
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false; // ✅ 오류 발생 시 로딩 종료
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, // ✅ 전체 공간을 양쪽으로 정렬
      children: [
        Row( // ✅ 프로필 이미지, 이름, 국가를 왼쪽 정렬
          children: [
            ProfileAvatar(
              profileUrl: userProfile,
              size: 36,
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLoading ? '' : username ?? 'Unknown User',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(widget.post['country'] ?? 'South Korea', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ],
        ),
        TimeAgoText(
          createdAt: widget.post['created_at'], 
          fontColor: Colors.grey, 
          fontSize: 12),
      ],
    );

  }
}
