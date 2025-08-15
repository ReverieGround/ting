import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ 현재 로그인 유저 확인용
import '../../common/widgets/TimeAgoText.dart';
import '../../services/PostService.dart'; // ✅ 댓글 삭제 서비스

class CommentTile extends StatelessWidget {
  final String commentId; // ✅ 댓글 문서 ID
  final String postId;    // ✅ 부모 포스트 ID
  final String userId;    
  final dynamic createdAt; 
  final String content;
  final bool dark;

  const CommentTile({
    required this.commentId,
    required this.postId,
    required this.userId,
    required this.createdAt,
    required this.content,
    this.dark = true,
  });

  @override
  Widget build(BuildContext context) {
    final bg = dark ? const Color(0xFF1E1E1E) : Colors.grey[100]!;
    final nameColor = dark ? Colors.white : Colors.black;
    final textColor = dark ? Colors.white : Colors.black87;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return _buildSkeleton(bg);
        }
        final userData = snap.data!.data();
        final userName = userData?['user_name'] ?? 'Anonymous';
        final userProfile = userData?['profile_image'];

        return Container(
          margin: const EdgeInsets.only(bottom: 7),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: (userProfile != null && userProfile.isNotEmpty)
                            ? NetworkImage(userProfile)
                            : null,
                        backgroundColor: Colors.grey[700],
                      ),
                      const SizedBox(width: 6),
                      Text(userName, style: TextStyle(color: nameColor, fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      TimeAgoText(
                      createdAt: createdAt,
                      fontSize: 14, 
                      fontColor: nameColor,
                    ),
                    if (currentUserId == userId) 
                    IconButton(
                      icon: const Icon(Icons.delete, size: 18, color: Colors.redAccent),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (dialogCtx) => AlertDialog(
                            backgroundColor: const Color(0xFF1E1E1E),
                            title: const Text("댓글 삭제", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            content: const Text("정말 이 댓글을 삭제하시겠습니까?", style: TextStyle(color: Colors.white70)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(dialogCtx).pop(false), // ✅ dialogCtx 사용
                                child: const Text("취소", style: TextStyle(color: Colors.white70)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(dialogCtx).pop(true),  // ✅ dialogCtx 사용
                                child: const Text("삭제", style: TextStyle(color: Colors.redAccent)),
                              ),
                            ],
                          ),
                        );

                        if (confirmed != true) return;

                        // 삭제 실행
                        await PostService().deleteComment(
                          postId: postId,
                          commentId: commentId,
                        );

                        // 이 아래에서 context를 쓸 거면(스낵바 등) mounted 체크
                        if (!context.mounted) return;

                        // 예: 스낵바
                        // ScaffoldMessenger.of(context).showSnackBar(
                        //   const SnackBar(content: Text('댓글을 삭제했어요.')),
                        // );
                      }
                    ),
                  ],)
                ],
              ),
              Text(content, style: TextStyle(color: textColor, fontSize: 16)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSkeleton(Color bg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(8),
      child: const SizedBox(
        height: 40,
        child: Center(child: CircularProgressIndicator(strokeWidth: 1)),
      ),
    );
  }
}
