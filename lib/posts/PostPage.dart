// posts/PostPage.dart
import 'package:flutter/material.dart';
import 'dart:developer';

// feeds
import '../../feeds/widgets/FeedCard.dart';
import '../../models/FeedData.dart';

// 기존 comments 위젯
import 'widgets/CommentTile.dart';

// 서비스 
import '../../services/PostService.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class PostPage extends StatefulWidget {
  final FeedData feed;
  final Color fontColor;
  final Color backgroundColor;

  const PostPage({
    super.key,
    required this.feed,
    this.fontColor=Colors.white,
    this.backgroundColor=const Color.fromARGB(255, 30, 30, 30),
    
  });

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final TextEditingController _commentController = TextEditingController();
  bool _isPosting = false;

  final _postService = PostService();
  void refreshComments() => setState(() {});

  @override
  Widget build(BuildContext context) {
    const inputHeight = 60.0;
    final kb = MediaQuery.of(context).viewInsets.bottom; // 키보드 높이

    return Scaffold(
      backgroundColor: widget.backgroundColor,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: inputHeight + 24 + kb), // ⬅️ 변경
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AbsorbPointer(
                      absorbing: false,
                      child: FeedCard(
                        feed: widget.feed,
                        fontColor: widget.fontColor,
                        backgroundColor: widget.backgroundColor,
                        iconAlignment: MainAxisAlignment.start,
                        blockNavPost: true, 
                      ),
                    ),
                    const Divider(
                      indent: 0, endIndent: 0, thickness: 1, color: Colors.grey,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>( // ⬅️ 제네릭
                        stream: PostService().commentsStream(postId: widget.feed.post.postId),
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          if (snap.hasError) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Text('댓글을 불러오지 못했습니다.', style: TextStyle(color: Colors.grey)),
                            );
                          }
                          final docs = snap.data?.docs ?? [];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...docs.map((d) {
                                final c = d.data();
                                return CommentTile(
                                  postId: widget.feed.post.postId,
                                  commentId: c['comment_id'],
                                  userId: c['user_id'],
                                  createdAt: c['created_at'],
                                  content: (c['content'] ?? '') as String,
                                  dark: true,
                                );
                              }),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // _buildAppNav(),
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: _buildCommentInputPanel(inputHeight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppNav() {
    return Positioned(
      top: 8,
      left: 12,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2), // 반투명 밝은 톤
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
          ),
        ),
      ),
    );
  }

  // 클래스 안에 추가
  Future<void> _handleSubmit() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isPosting) return;

    setState(() => _isPosting = true);
    FocusScope.of(context).unfocus();

    try {
      final id = await _postService.addComment(
        postId: widget.feed.post.postId,
        content: text,
      );
      if (id != null) {
        _commentController.clear();
        refreshComments();
      }
    } catch (e) {
      log('addComment error: $e');
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  Widget _buildCommentInputPanel(double height) {
    final kb = MediaQuery.of(context).viewInsets.bottom;   // 키보드 높이
    final safeBottom = MediaQuery.of(context).padding.bottom;
    const double kCommentBarHeight = 48;
    
    return SafeArea(
      top: false,
      child: Container(
        height: height,
        width: height,
        color: const Color.fromARGB(255, 15, 15, 15),
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: (kb > 0 ? kb : safeBottom) + 8, // ⬅️ 키보드/세이프 적용
          top: 6,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset('assets/fork_white.png', height: 32, width: 32),
            const SizedBox(width: 8),
            Expanded(
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _commentController,
                builder: (context, value, _) {
                  final canSend = value.text.trim().isNotEmpty && !_isPosting;
                  return TextField(
                    controller: _commentController,
                    cursorColor: Colors.white,
                    style: const TextStyle(color: Colors.white),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _handleSubmit(),
                    textAlignVertical: TextAlignVertical.center, // ✅ 세로 중앙 정렬
                    decoration: InputDecoration(
                      constraints: const BoxConstraints(minHeight: kCommentBarHeight),
                      filled: true,
                      fillColor: Colors.grey[900],
                      hintText: "댓글을 작성해 보세요",
                      hintStyle: const TextStyle(color: Colors.white70),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(width: 1.0, color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(width: 1.0, color: Colors.white),
                      ),
                      suffixIcon: _isPosting
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : IconButton(
                              onPressed: canSend ? _handleSubmit : null,
                              icon: const Icon(Icons.send, color: Colors.white),
                            ),
                    ),
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
