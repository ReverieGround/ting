// lib/pages/nearby/widgets/feed_card.dart
import 'package:http/http.dart' as http; // http 통신을 위해 import
import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../config.dart'; // API Base URL을 위해 import
import '../../../services/AuthService.dart'; // 인증 토큰을 위해 import
import '../../feeds/widgets/FeedLikeIcon.dart';
import '../../feeds/widgets/FeedReplyIcon.dart';


class FeedCard extends StatefulWidget {
  final String postId; // 좋아요/댓글 API 호출을 위한 postId 추가
  final String imageUrl;
  final String nickname;
  final String profileUrl;

  const FeedCard({
    super.key,
    required this.postId, // postId 추가
    required this.imageUrl,
    required this.nickname,
    required this.profileUrl,
  });

  @override
  State<FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<FeedCard> {
  int _currentLikeCount = 0;
  int _currentCommentCount = 0;
  bool _isLikedByUser = false;
  double _fontSize = 14;

  @override
  void initState() {
    super.initState();
    _fetchLikesAndComments(); // 위젯이 생성될 때 API 호출 시작
  }

  Future<void> _fetchLikesAndComments() async {
    final token = await AuthService.getToken(); // AuthService에서 토큰 가져오기

    if (token == null) {
      debugPrint("Error: No authentication token found for FeedCard API call.");
      return;
    }

    // 좋아요 수 조회 API 호출
    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/post/${widget.postId}/likes'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final int numLikes = data['num_likes'];
        final bool is_liked_by_user = data['is_liked_by_user'];
        if (mounted) {
          setState(() {
            _currentLikeCount = numLikes;
            _isLikedByUser = is_liked_by_user;
          });
        }
      } else if (response.statusCode == 404) {
        // 좋아요가 없거나 포스트를 찾을 수 없는 경우 (API 응답에 따라)
        if (mounted) {
          setState(() {
            _currentLikeCount = 0;
          });
        }
      } else {
        debugPrint('Failed to load likes: ${response.statusCode} ${response.body}');
        // 오류 발생 시 초기값 유지 또는 다른 처리
      }
    } catch (e) {
      debugPrint('Error fetching likes: $e');
      // 네트워크 오류 등 발생 시
    }

    // 댓글 수 조회 API 호출 (새로 만든 API 사용)
    try {
      final commentResponse = await http.get( // 변수명 변경: commentResponse
        Uri.parse('${Config.baseUrl}/post/${widget.postId}/num_comments'), // API 경로 변경
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (commentResponse.statusCode == 200) {
        final data = json.decode(commentResponse.body);
        if (mounted) {
          setState(() {
            _currentCommentCount = data['num_comments'] ?? 0; // num_comments 값으로 업데이트
          });
        }
      } else if (commentResponse.statusCode == 404) {
        // 포스트를 찾을 수 없는 경우 (API 응답에 따라)
        if (mounted)  {
          setState(() {
            _currentCommentCount = 0;
          });
        }
      } else {
        debugPrint('Failed to load comments count: ${commentResponse.statusCode} ${commentResponse.body}');
      }
    } catch (e) {
      debugPrint('Error fetching comments count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 4, 
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.0),
            child: Container(
              color: Colors.white, 
              width: double.infinity, 
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AspectRatio(
                      aspectRatio: 0.75, 
                      child: Image.network(
                        widget.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[300],
                          child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 50)),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(0, 0, 0, 0.6),
                      ),
                      child: Column( 
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.grey,
                                backgroundImage: NetworkImage(widget.profileUrl),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                widget.nickname,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  letterSpacing: -0.4,
                                ),
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
          ),
        ),
        Container(
          width: double.infinity, 
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0), // 좌우 및 상하 패딩 추가
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              FeedLikeIcon(
                  postId: widget.postId,
                  initialLikeCount: _currentLikeCount,
                  hasLiked: _isLikedByUser,
                  onToggleCompleted: null,
                  fontSize: 13.0,
                  iconSize: 20.0,
                ),
              SizedBox(width: 40),
              FeedReplyIcon(
                postId: widget.postId,
                initialCommentCount: _currentCommentCount,
                fontSize: 13.0,
                iconSize: 16.0,
              ),
            ],
          ),
        ),
      ],
    );
  }
}