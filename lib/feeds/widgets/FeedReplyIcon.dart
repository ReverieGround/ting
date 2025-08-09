// lib/widgets/comment_widget.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config.dart';

// 숫자 단위 축약 함수 (변동 없음)
String formatNumber(int count) {
  if (count < 1000) {
    return count.toString();
  } else if (count < 1000000) {
    double result = count / 1000.0;
    return '${result.toStringAsFixed(result.truncateToDouble() == result ? 0 : 1)}k';
  } else {
    double result = count / 1000000.0;
    return '${result.toStringAsFixed(result.truncateToDouble() == result ? 0 : 1)}m';
  }
}

class FeedReplyIcon extends StatefulWidget {
  final String postId;
  final int initialCommentCount;
  final Function(int newCommentCount)? onCommentPosted;

  final double fontSize;
  final double iconSize;

  const FeedReplyIcon({
    super.key,
    required this.postId,
    required this.initialCommentCount,
    this.onCommentPosted,
    this.fontSize = 14.0,
    this.iconSize = 20.0,
  });

  @override
  State<FeedReplyIcon> createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<FeedReplyIcon> {
  late int _currentCommentCount;
  bool _isPostingComment = false;
  final TextEditingController _commentController = TextEditingController();

  final String _apiBaseUrl = '${Config.baseUrl}/post';

  @override
  void initState() {
    super.initState();
    _currentCommentCount = widget.initialCommentCount;
  }

  @override
  void didUpdateWidget(covariant FeedReplyIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCommentCount != oldWidget.initialCommentCount) {
      _currentCommentCount = widget.initialCommentCount;
    }
  }

  Future<String?> _getIdToken() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint("❌ 로그인된 사용자 없음. 토큰을 가져올 수 없습니다.");
      return null;
    }
    try {
      final idTokenResult = await user.getIdTokenResult(true);
      return idTokenResult.token;
    } catch (e) {
      debugPrint("❌ ID 토큰 가져오기 실패: $e");
      return null;
    }
  }

  void _showCommentInputBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white, // ✅ 배경을 무조건 흰색으로 설정
      builder: (BuildContext bc) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(bc).viewInsets.bottom,
            left: 16.0,
            right: 16.0,
            top: 16.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: _commentController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '댓글을 입력하세요...',
                  // ✅ 기본 테두리
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(color: Colors.grey), // 기본 테두리 색상
                  ),
                  // ✅ 포커스 시 테두리 (하이라이트 색상)
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(
                      color: Color.fromRGBO(255, 110, 199, 1), // rgba(255, 110, 199, 1)
                      width: 1.0, // 1px solid
                    ),
                  ),
                  // ✅ 활성화된(입력 가능한) 상태의 테두리
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                  ),
                  suffixIcon: _isPostingComment
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: () {
                            _postComment(context);
                          },
                        ),
                ),
                maxLines: null,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    ).whenComplete(() {
      _commentController.clear();
      if (mounted) {
        setState(() {
          _isPostingComment = false;
        });
      }
    });
  }

  Future<void> _postComment(BuildContext context) async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글 내용을 입력해주세요.')),
      );
      return;
    }

    if (_isPostingComment) return;

    setState(() {
      _isPostingComment = true;
    });

    final String? token = await _getIdToken();
    if (token == null) {
      if (mounted) {
        setState(() {
          _isPostingComment = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글을 게시하려면 로그인해야 합니다.')),
      );
      return;
    }

    final String commentPostUrl = '$_apiBaseUrl/${widget.postId}/comment';
    final String commentContent = _commentController.text.trim();

    try {
      final response = await http.post(
        Uri.parse(commentPostUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'content': commentContent},
      );

      if (response.statusCode == 201) {
        debugPrint("✅ 댓글 게시 성공: ${response.body}");
        if (mounted) {
          setState(() {
            _currentCommentCount++;
            _isPostingComment = false;
          });
          _commentController.clear();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('댓글이 성공적으로 게시되었습니다.')),
          );
        }
        widget.onCommentPosted?.call(_currentCommentCount);
      } else {
        debugPrint("❌ 댓글 게시 실패 (${response.statusCode}): ${response.body}");
        if (mounted) {
          setState(() {
            _isPostingComment = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('댓글 게시 실패: ${json.decode(response.body)['detail'] ?? '알 수 없는 오류'}')),
          );
        }
      }
    } catch (e) {
      debugPrint("❌ 댓글 게시 중 네트워크 오류: $e");
      if (mounted) {
        setState(() {
          _isPostingComment = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('네트워크 오류: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String iconPath = 'assets/comment.png';

    return GestureDetector(
      onTap: _isPostingComment ? null : () => _showCommentInputBottomSheet(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            iconPath,
            width: widget.iconSize,
            height: widget.iconSize,
            color: Colors.black,
          ),
          const SizedBox(width: 6),
          Text(
            formatNumber(_currentCommentCount),
            style: TextStyle(
              fontSize: widget.fontSize,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}