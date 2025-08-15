import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'FeedHead.dart';
import 'FeedImages.dart';
import 'FeedContent.dart';
import '../../posts/PostPage.dart';
import 'FeedLikeIcon.dart';
import 'FeedReplyIcon.dart';
import '../../models/PostData.dart';
import '../../models/FeedData.dart';
import '../../services/PostService.dart';

class FeedCard extends StatelessWidget {
  final FeedData feed;
  final Color fontColor;
  final Color backgroundColor;
  final bool showTopWriter;
  final bool showBottomWriter;
  final bool showTags;
  final bool showIcons;
  final bool showContent;
  final double? imageHeight;
  final BoxFit fit;
  final double borderRadius;
  final double iconSize;
  final double iconGap;
  final MainAxisAlignment iconAlignment;
  final bool isPinned;
  final VoidCallback? onTogglePin;
  final bool blockNavPost;

  const FeedCard({
    Key? key,
    required this.feed,
    this.fontColor = Colors.black,
    this.backgroundColor = Colors.white,
    this.showTopWriter = true,
    this.showBottomWriter = false,
    this.showTags = true,
    this.showContent = true,
    this.showIcons = true,
    this.imageHeight = 350,
    this.fit = BoxFit.cover,
    this.borderRadius = 0.0,
    this.isPinned = false,
    this.onTogglePin,
    this.iconSize = 22.0,
    this.iconGap = 4.0,
    this.iconAlignment = MainAxisAlignment.start,
    this.blockNavPost = false,
  }) : super(key: key);

  final _postService = PostService();

  @override
  Widget build(BuildContext context) {
    final comments = feed.post.comments ?? [];
    final imageUrls = (feed.post.imageUrls as List<dynamic>);
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return Container(
      decoration: BoxDecoration(color: backgroundColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTopWriter)
            FeedHead(
              profileImageUrl: feed.user.profileImage!,
              userName: feed.user.userName,
              userId: feed.user.userId,
              userTitle: feed.user.title,
              createdAt: formatTimestamp(feed.post.createdAt),
              fontColor: fontColor,
              isMine: feed.user.userId == myUid,
              onEdit: () => _openEditSheet(context),
            ),
          if (imageUrls.isNotEmpty)
            GestureDetector(
              onTap: () {
                if (!blockNavPost) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => PostPage(feed: feed)));
                }
              },
              child: _buildAutoImageArea(context, imageUrls),
            ),
          if (showIcons)
            Padding(
              padding: EdgeInsets.symmetric(vertical: iconGap, horizontal: iconGap),
              child: SizedBox(
                height: iconSize,
                child: Row(
                  mainAxisAlignment: iconAlignment,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    FeedLikeIcon(
                      postId: feed.post.postId,
                      userId: feed.user.userId,
                      initialLikeCount: feed.numLikes,
                      hasLiked: feed.isLikedByUser,
                      onToggleCompleted: null,
                      fontSize: iconSize - 3,
                      iconSize: iconSize,
                      fontColor: fontColor,
                    ),
                    const SizedBox(width: 12),
                    FeedReplyIcon(
                      postId: feed.post.postId,
                      initialCommentCount: feed.numComments,
                      fontSize: iconSize - 3,
                      iconSize: iconSize,
                      fontColor: fontColor,
                    ),
                  ],
                ),
              ),
            ),
          if (showContent)
            FeedContent(
              content: feed.post.content,
              comments: comments,
              fontColor: fontColor,
            ),
        ],
      ),
    );
  }

  Future<void> _openEditSheet(BuildContext context) async {
    final visibilityInit = feed.post.visibility ?? 'PUBLIC';
    final categoryInit = feed.post.category;
    final valueInit = feed.post.value;

    String vis = visibilityInit;
    String? cat = categoryInit;
    String? val = valueInit;

    final List<String> categories = ['요리', '밀키트', '식당', '배달'];
    final List<Map<String, String>> reviewValues = [
      {'label': 'Fire', 'image': 'assets/fire.png'},
      {'label': 'Tasty', 'image': 'assets/tasty.png'},
      {'label': 'Soso', 'image': 'assets/soso.png'},
      {'label': 'Woops', 'image': 'assets/woops.png'},
      {'label': 'Wack', 'image': 'assets/wack.png'},
    ];

    final result = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('게시물 편집', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    TextButton.icon(
                      onPressed: () => Navigator.pop(context, 'delete'),
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      label: const Text('삭제', style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: vis,
                  items: const [
                    DropdownMenuItem(value: 'PUBLIC', child: Text('전체 공개')),
                    DropdownMenuItem(value: 'FOLLOWERS', child: Text('팔로워만')),
                    DropdownMenuItem(value: 'PRIVATE', child: Text('비공개')),
                  ],
                  onChanged: (v) => vis = v ?? vis,
                  decoration: const InputDecoration(labelText: '공개 범위', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: cat,
                  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => cat = v,
                  decoration: const InputDecoration(labelText: '카테고리', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: reviewValues.map((v) {
                      final selected = val == v['label'];
                      return ChoiceChip(
                        label: Text(v['label']!),
                        selected: selected,
                        onSelected: (_) => val = v['label'],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, {
                      'visibility': vis,
                      'category': cat,
                      'value': val,
                    }),
                    child: const Text('저장'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result == null) return;

    try {
      if (result == 'delete') {
        final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('삭제할까요?'),
            content: const Text('이 게시물을 삭제합니다.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('삭제')),
            ],
          ),
        );
        if (ok == true) {
          _postService.softDelete(feed.post.postId);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('삭제되었습니다.')));
          }
        }
        return;
      }

      final map = result as Map<String, dynamic>;
      _postService.updateFields(
        postId: feed.post.postId,
        visibility: map['visibility'],
        category: map['category'],
        value: map['value'],
      );
      setState() {
        if (map['visibility'] != null ){
          feed.post.visibility = map['visibility'];
        }
        if (map['category'] != null ){
          feed.post.category = map['category'];
        }
        if (map['value'] != null ){
          feed.post.value = map['value'];
        }
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('수정되었습니다.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('실패: $e')));
      }
    }
  }

  String _visLabel(String v) {
    switch (v) {
      case 'PUBLIC': return '전체 공개';
      case 'FOLLOWERS': return '팔로워만';
      case 'PRIVATE': return '비공개';
      default: return v;
    }
  }

  Widget _buildAutoImageArea(BuildContext context, List<dynamic> imageUrls) {
    if (imageHeight != null) {
      if (imageUrls.length == 1) {
        final String url = imageUrls.first as String? ?? '';
        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: imageHeight,
            child: LayoutBuilder(
              builder: (context, c) {
                final dpr = MediaQuery.of(context).devicePixelRatio;
                final wPx = (c.maxWidth * dpr).round();
                final hPx = ((imageHeight ?? 0) * dpr).round();
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      url,
                      fit: fit,
                      cacheWidth: wPx,
                      cacheHeight: hPx,
                      filterQuality: FilterQuality.low,
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                    ),
                    if (isPinned) _buildPinButton(),
                    if (showBottomWriter) _buildBottomWriterOverlay(context),
                  ],
                );
              },
            ),
          ),
        );
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: imageHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              FeedImages(
                imageUrls: imageUrls,
                category: feed.post.category,
                value: feed.post.value ?? '',
                recipeId: feed.post.recipeId,
                recipeTitle: "",
                showTags: showTags,
                height: imageHeight,
                fit: fit,
                onRecipeButtonPressed: () {},
              ),
              if (isPinned) _buildPinButton(),
              if (showBottomWriter) _buildBottomWriterOverlay(context),
            ],
          ),
        ),
      );
    }

    final aspect = _autoAspectByCount(imageUrls.length);
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = w / aspect;
        final dpr = MediaQuery.of(context).devicePixelRatio;

        if (imageUrls.length == 1) {
          final String url = imageUrls.first as String? ?? '';
          final wPx = (w * dpr).round();
          final hPx = (h * dpr).round();
          return ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              height: h,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    url,
                    fit: fit,
                    cacheWidth: wPx,
                    cacheHeight: hPx,
                    filterQuality: FilterQuality.low,
                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                  ),
                  if (isPinned) _buildPinButton(),
                  if (showBottomWriter) _buildBottomWriterOverlay(context),
                ],
              ),
            ),
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: h,
            child: Stack(
              fit: StackFit.expand,
              children: [
                FeedImages(
                  imageUrls: imageUrls,
                  category: feed.post.category,
                  value: feed.post.value ?? '',
                  recipeId: feed.post.recipeId,
                  recipeTitle: "",
                  showTags: showTags,
                  height: h,
                  fit: fit,
                  onRecipeButtonPressed: () {},
                ),
                if (isPinned) _buildPinButton(),
                if (showBottomWriter) _buildBottomWriterOverlay(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPinButton() {
    if (onTogglePin == null && !isPinned) return const SizedBox.shrink();
    return Positioned(
      right: 4,
      top: 4,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: InkWell(
          onTap: onTogglePin,
          borderRadius: BorderRadius.circular(10),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Icon(Icons.push_pin_outlined, size: 20, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomWriterOverlay(BuildContext context) {
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final avatarPx = (24 * dpr).round();
    return Positioned(
      left: 0, right: 0, bottom: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        color: const Color.fromRGBO(0, 0, 0, 0.6),
        child: Row(
          children: [
            ClipOval(
              child: Image.network(
                feed.user.profileImage ?? '',
                width: 24, height: 24,
                fit: BoxFit.cover,
                cacheWidth: avatarPx,
                cacheHeight: avatarPx,
                errorBuilder: (_, __, ___) => const SizedBox(width: 24, height: 24),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              feed.user.userName,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  double _autoAspectByCount(int count) {
    if (count <= 1) return 4 / 5;
    if (count == 2) return 1.0;
    return 3 / 4;
  }
}
