// posts/widgets/CommentTile.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../common/widgets/TimeAgoText.dart';
import '../../services/PostService.dart';
import '../../profile/ProfilePage.dart';

class CommentTile extends StatelessWidget {
  final String commentId;
  final String postId;
  final String userId;
  final dynamic createdAt;
  final String content;

  const CommentTile({
    super.key,
    required this.commentId,
    required this.postId,
    required this.userId,
    required this.createdAt,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return _buildSkeleton(theme);

        final user = snap.data!.data();
        final userName = user?['user_name'] ?? 'Anonymous';
        final userProfile = user?['profile_image'];

        return Container(
          margin: const EdgeInsets.only(bottom: 7),
          // decoration: BoxDecoration(
          //   color: Colors.transparent, // 투명
          //   borderRadius: BorderRadius.circular(8),
          //   border: Border.all(color: theme.dividerColor.withOpacity(.3)),
          // ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 22,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ProfilePage(userId: userId)),
                        );
                      },
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundImage: (userProfile != null && userProfile.isNotEmpty)
                                ? NetworkImage(userProfile)
                                : null,
                            backgroundColor: theme.colorScheme.surfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            userName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          child: TimeAgoText(
                            createdAt: createdAt,
                            fontSize: 13,
                            fontColor: theme.colorScheme.onSurface.withOpacity(.7),
                          ),
                          margin: EdgeInsets.only(right: 4),
                        ),
                        if (currentUserId == userId)
                          SizedBox(
                            height: 18,
                            width: 18,
                            child: IconButton(
                              icon: Icon(Icons.delete, size: 18, color: theme.colorScheme.error),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (dCtx) => AlertDialog(
                                    backgroundColor: theme.colorScheme.surface,
                                    title: Text(
                                      "댓글 삭제",
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: theme.colorScheme.onSurface,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    content: Text(
                                      "정말 이 댓글을 삭제하시겠습니까?",
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(.7),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(dCtx).pop(false),
                                        child: Text("취소", style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(.7))),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(dCtx).pop(true),
                                        child: Text("삭제", style: TextStyle(color: theme.colorScheme.error)),
                                      ),
                                    ],
                                  ),
                                );
                                if (ok != true) return;
                                await PostService().deleteComment(postId: postId, commentId: commentId);
                              },
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                content,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSkeleton(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(.3)),
      ),
      padding: const EdgeInsets.all(8),
      child: SizedBox(
        height: 40,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
