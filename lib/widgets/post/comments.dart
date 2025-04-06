import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../config.dart';
import '../utils/time_ago_text.dart';
import '../utils/profile_avatar.dart';
import 'dart:developer'; 

class PostComments extends StatefulWidget {
  final String postId; // ✅ post_id를 직접 받아옴
  final VoidCallback refreshCallback; // ✅ 새 댓글 추가 시 부모 위젯에서 호출할 콜백
  const PostComments({super.key, required this.postId, required this.refreshCallback});
  @override
  _PostCommentsState createState() => _PostCommentsState();
}

class _PostCommentsState extends State<PostComments> {
  List<dynamic> comments = [];
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    fetchComments();
  }

  /// ✅ 댓글 데이터 불러오기 (API 호출)
  Future<void> fetchComments() async {
    setState(() => isLoading = true); // ✅ 로딩 시작

    try {
      final url = Uri.parse("${Config.baseUrl}/post/${widget.postId}/comments");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          comments = data['comments'];
          isLoading = false;
        });
      } else {
        log("❌ 댓글 불러오기 실패: ${response.statusCode}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      log("❌ 네트워크 오류: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator(
        color: Colors.white,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.black), 
      )); // ✅ 로딩 표시
    }

    if (comments.isEmpty) {
      return Center(child: Text("댓글이 없습니다.", style: TextStyle(color: Colors.grey))); // ✅ 댓글 없을 때
    }
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('댓글 ${comments.length}', style: TextStyle(color: Colors.black, fontSize:16, fontWeight: FontWeight.bold)),
        SizedBox(height: 6),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero, // ✅ 자동 여백 제거
            itemCount: comments.length,
            itemBuilder: (context, index) {
              return Column(
                children: [
                  Container(
                    margin: EdgeInsets.only(bottom: 5),
                    decoration: BoxDecoration(color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: EdgeInsets.all(8),
                    child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              decoration: BoxDecoration(color: Colors.transparent),
                              width: double.infinity,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [ Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    ProfileAvatar(
                                      profileUrl: comments[index]['user_profile'],
                                      size: 24,
                                    ),
                                    SizedBox(width: 6),
                                    Text(comments[index]['username'] ?? 'Anonymous', 
                                      style: TextStyle(
                                        fontSize: 14, 
                                        fontWeight: 
                                        FontWeight.bold)),
                                  ]),       
                                TimeAgoText(
                                  createdAt: comments[index]['created_at'], 
                                  fontColor: Colors.grey, 
                                  fontSize: 12),
                              ]),
                            ),
                          Container(
                            decoration: BoxDecoration(color: Colors.transparent),
                            width: double.infinity,
                            padding: EdgeInsets.fromLTRB(0, 10, 0, 5),
                            child: Text(
                              comments[index]['content'] ?? '', 
                              style: TextStyle(fontSize: 16)
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Divider(thickness: 1, color: Colors.grey[100]), // ✅ 구분선
                ],
              );
            },
          ),
        ),
      ]);
  }
}
