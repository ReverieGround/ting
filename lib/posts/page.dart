import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:developer'; 
import '../../widgets/post/writer.dart';
import '../../widgets/post/content.dart';
import '../../widgets/post/tags.dart';
import '../../widgets/post/status.dart';
import '../../widgets/post/comments.dart';
import '../../services/auth_service.dart'; 
import '../../config.dart';
import '../models/post_data.dart';

class PostPage extends StatefulWidget {
  final PostData post;

  const PostPage({super.key, required this.post});

  @override
  _PostPageState createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final TextEditingController _commentController = TextEditingController(); // ✅ 댓글 입력 컨트롤러
  bool _isPosting = false; // ✅ 댓글 전송 중 여부
  
  void refreshComments() {
    setState(() {}); // ✅ 댓글 위젯을 다시 빌드하여 새 댓글 반영
  }

  /// ✅ 댓글 추가 API 호출 (query 방식)
  Future<void> postComment() async {
    if (_commentController.text.trim().isEmpty) return; // ✅ 빈 댓글 방지
    setState(() => _isPosting = true); // ✅ 전송 시작

    String postId = widget.post.postId; // ✅ 포스트 ID 가져오기
    String commentContent = _commentController.text.trim(); // ✅ 입력한 댓글 가져오기
    
    // ✅ JWT 토큰 가져오기
    String? token = await AuthService.getToken();
    if (token == null) {
      log("인증 토큰 없음");
      setState(() => _isPosting = false);
      return;
    }

    // ✅ content를 query 파라미터로 추가 (URL 인코딩 필수)
    final url = Uri.parse("${Config.baseUrl}/post/$postId/comment?content=${Uri.encodeComponent(commentContent)}");

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token', // ✅ JWT 인증 헤더
        },
      );

      log("댓글 전송 요청: $url");

      if (response.statusCode == 201) {
        log("✅ 댓글 추가 성공!");
        _commentController.clear(); // ✅ 입력 필드 초기화
        // 댓글 리스트 새로고침 (UI 갱신)
        refreshComments();
      } else {
        log("❌ 댓글 추가 실패: ${response.statusCode}");
        log("응답 내용: ${response.body}");
      }
    } catch (e) {
      log("❌ 댓글 전송 중 오류 발생: $e");
    }

    setState(() => _isPosting = false); // ✅ 전송 완료
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> imageUrls = widget.post.imageUrls as List<dynamic>? ?? [];
    double screenWidth = MediaQuery.of(context).size.width;    
    double imageHeight = MediaQuery.of(context).size.height / 2; 
    double postCommentHeight = 80.0;
    // double postContentHeight = MediaQuery.of(context).size.height- imageHeight - postCommentHeight ;
    
    return Scaffold(
      body: Stack(
          children: [
            Column(
              children: [
                _buildImagePannel(imageUrls, imageHeight, screenWidth),
                _buildContentPannel(),
                Divider(
                  indent: 12,
                  endIndent: 12,
                  thickness: 1, color: Colors.grey[300]), // ✅ 구분선
                _buildCommentPannel(),
                _buildCommentInputPannel(postCommentHeight),
            ]),
          _buildAppNav(),
        ]),
    );
  }
  
  Widget _buildImagePannel(List<dynamic> imageUrls, double height, double width) {
    bool hasMultipleImages = imageUrls.length > 1;
    // imageUrls가 비어있으면 빈 문자열을 thumbnailUrl로 사용합니다.
    String thumbnailUrl = imageUrls.isNotEmpty ? imageUrls[0] : '';

    return Stack(
      children: [
        ClipRRect(
          // borderRadius: BorderRadius.circular(12), // 주석 처리된 부분은 유지합니다.
          child: SizedBox(
            width: width,
            height: height,
            child: thumbnailUrl.isEmpty // thumbnailUrl이 비어있으면 (즉, imageUrls가 비어있으면)
                ? Container(
                    color: Colors.grey[300], // 회색 배경
                    child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.grey, size: 50), // 깨진 이미지 아이콘
                    ),
                  )
                : Image.network(
                    thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // 이미지 로드 실패 시 회색 배경의 빈 상자 표시
                      return Container(
                        color: Colors.grey[300], // 회색 배경
                        child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.grey, size: 50), // 깨진 이미지 아이콘
                        ),
                      );
                    },
                  ),
            ),
          ),
          if (hasMultipleImages)
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: Colors.black54,
                onPressed: () {
                  // TODO: 사진 갤러리 기능 추가
                },
                child: const Icon(Icons.collections, color: Colors.white),
              ),
            ),
        ],
      );
  }
  Widget _buildContentPannel(){
    return Container(
      decoration: BoxDecoration(color:Colors.white),
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserInfoRow(post: widget.post), // ✅ 유저 정보
          SizedBox(height: 8),
          PostContent(post: widget.post), // ✅ 포스트 내용
          SizedBox(height: 8),
          PostTags(post: widget.post), // ✅ 태그
          SizedBox(height: 8),
          PostStatsRow(post: widget.post), // ✅ 좋아요 & 레시피 요청 수
        ],
      ),
    );
  }

  Widget _buildCommentPannel(){
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(color:Colors.white),
        child: PostComments(postId: widget.post.postId, refreshCallback: refreshComments),
      ),
    );
  }
  
  Widget _buildAppNav() {
    return Positioned(
      top: 40,
      left: 16, // ✅ Keeps left padding consistent
      child: Material(
        color: Colors.transparent, // ✅ Ensures no background color interference
        child: InkWell(
          borderRadius: BorderRadius.circular(30), // ✅ More tap-friendly
          onTap: () {
            Navigator.pop(context); // ✅ Navigate back
          },
          child: Container(
            padding: EdgeInsets.all(8), // ✅ Ensures better touch area
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4), // ✅ Smoother opacity
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_back, color: Colors.white, size: 26),
          ),
        ),
      ),
    );
  }
  /// ✅ 댓글 입력창 UI (하단 고정)
  Widget _buildCommentInputPannel(height) {
    return  Container(
      height: height,
      decoration: BoxDecoration(color: Colors.white),
      padding: EdgeInsets.only(left: 12, right: 12, bottom: 24, top: 12), // ✅ 좌우 여백 추가
      child: TextField(
        cursorColor: Colors.black,
        controller: _commentController,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey[100],
          hintText: "댓글을 작성해 보세요", // ✅ 기본 텍스트
          hintStyle: TextStyle(color: Colors.grey), // ✅ 힌트 색상 회색
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25), // ✅ 둥근 모서리 추가
            borderSide: BorderSide(
              width: 1.0,
              color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(
              width: 1.0,
              color: Colors.black), // ✅ 포커스 시 검정색 테두리
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          suffixIcon: _isPosting // ✅ 전송 중이면 로딩 아이콘 표시
              ? Padding(
                  padding: EdgeInsets.all(10),
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black), 
                    strokeWidth: 2),
                )
              : IconButton(
                  icon: Icon(Icons.send, color: Colors.black),
                  onPressed: postComment, // ✅ API 호출 함수 연결
                ),
          ),
      ),
    );
  }
}
