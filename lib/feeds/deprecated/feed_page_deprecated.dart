import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart';
import '../../services/auth_service.dart';
import '../../widgets/feed/user_card.dart';
import '../../widgets/common/vibe_header.dart'; 

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  _FeedPageState createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  List<String> userIds = [];
  bool isLoading = true;

  Future<void> fetchUsers() async {
    if (!mounted) return; // ✅ 위젯이 Unmounted 상태이면 실행 중지
    setState(() {
      isLoading = true; // ✅ 새 데이터 로딩 중임을 표시
    });

    String? token = await AuthService.getToken();
    if (token == null) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/user/ids'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            userIds = List<String>.from(data['user_ids'] ?? []);
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사용자 목록을 불러오지 못했습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('네트워크 오류가 발생했습니다. 다시 시도하세요.')),
      );
    }
  }


  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VibeHeader(
        titleWidget: Text(
          'VibeYum 피드',
          style:TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold),
        ),
        navigateType: VibeHeaderNavType.createPost,
      ),
      body: RefreshIndicator(
        onRefresh: fetchUsers, // ✅ 당겨서 새로고침
        child: isLoading
            ? Center(child: CircularProgressIndicator(
              color: Colors.white,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black), 
            ))
            : ListView.builder(
                itemCount: userIds.length,
                itemBuilder: (context, index) {
                  return UserCard(userId: userIds[index]);
                },
              ),
      ),
    );
  }
}
