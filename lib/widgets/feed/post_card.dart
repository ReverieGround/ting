import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart';
import '../../screens/post_page.dart';
import '../utils/like_button.dart';

class PostCard extends StatefulWidget {
  final String postId;

  const PostCard({super.key, required this.postId});

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  Map<String, dynamic>? post;
  bool isLoading = true;
  bool isError = false;

  @override
  void initState() {
    super.initState();
    _fetchPost();
  }

  /// ✅ `GET /post/{post_id}` API 호출하여 데이터 가져오기
  Future<void> _fetchPost() async {
    setState(() {
      isLoading = true;
      isError = false;
    });

    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/post/${widget.postId}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          post = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          isError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isError = true;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator(
        color: Colors.white,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.black), 
      ));
    }

    if (isError || post == null) {
      return Center(
        child: Text('포스트를 불러올 수 없습니다.', style: TextStyle(color: Colors.red)),
      );
    }

    List<dynamic> imageUrls = post!['image_urls'] is String
        ? jsonDecode(post!['image_urls']) as List<dynamic>
        : (post!['image_urls'] as List<dynamic>? ?? []);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PostPage(post: post!)),
        ).then((_) {
          _fetchPost(); // ✅ PostPage가 Pop되면 _fetchPost() 실행
        });
      },
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children:[
                _buildImageSection(imageUrls),
                Positioned(
                  bottom: 0, // ✅ 화면의 아래쪽에 배치
                  left: 0, 
                  right: 0, 
                  child: _buildOverlaySection(post!), // ✅ 오버레이 섹션
                ),
              ]
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text(
                post!['content'] ?? '내용 없음',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.black, fontSize: 12),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Wrap(
                spacing: 6,
                children: (post!['tags'] as List<dynamic>? ?? []).map((tag) {
                  return Chip(
                    label: Text(tag.toString(), style: TextStyle(fontSize: 12)),
                    backgroundColor: Colors.grey[200],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ 이미지 영역 (여러 이미지가 있을 경우 세로 슬라이드)
  Widget _buildImageSection(List<dynamic> imageUrls) {
    return SizedBox(
      height: 180,
      child: imageUrls.isNotEmpty
          ? PageView.builder(
              itemCount: imageUrls.length,
              scrollDirection: Axis.vertical,
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                  child: Image.network(
                    imageUrls[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                  ),
                );
              },
            )
          : _buildPlaceholder(),
    );
  }

  /// ✅ 이미지가 없을 경우 대체 UI
  Widget _buildPlaceholder() {
    return Container(
      height: 160,
      width: double.infinity,
      alignment: Alignment.center,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.2),
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Text(
        '이미지 없음',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// ✅ 좋아요 & 댓글 오버레이
  Widget _buildOverlaySection(Map<String, dynamic> post) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: Color.fromRGBO(0, 0, 0, 0.5), ), // ✅ 50% 투명한 블랙
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          LikeButton(
            postId: post['post_id'],
            initialColor: Color.fromARGB(200, 255, 94, 94),
            fontColor: Colors.white
          ),
          SizedBox(width: 10),
          Row(
            children: [
              Icon(Icons.chat_bubble, color: Color.fromARGB(200, 94, 183, 255)),
              SizedBox(width: 4),
              Text('${post['comments_count'] ?? 0}', style: TextStyle(color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }
}
