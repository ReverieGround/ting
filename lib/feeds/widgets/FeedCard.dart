// feeds/widgets/FeedCard.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'FeedHead.dart';
import 'FeedImages.dart';
import 'FeedContent.dart';
import '../../posts/PostPage.dart';
import 'FeedLikeIcon.dart';
import 'FeedReplyIcon.dart';
import '../../models/PostData.dart';
import '../../models/FeedData.dart';
import '../../services/PostService.dart';

class FeedCard extends StatefulWidget {
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
  final double iconHGap;
  final double iconVGap;
  final MainAxisAlignment iconAlignment;
  final bool isPinned;
  final VoidCallback? onTogglePin;
  final bool blockNavPost;
  final VoidCallback? onDeleted;

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
    this.iconHGap = 4.0,
    this.iconVGap = 4.0,
    this.iconAlignment = MainAxisAlignment.start,
    this.blockNavPost = false,
    this.onDeleted,
  }) : super(key: key);

  @override
  State<FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<FeedCard> {
  final _postService = PostService();

  String? _visOverride;
  String? _catOverride;
  String? _valOverride;

  FeedData get feed => widget.feed;
  Color get fontColor => widget.fontColor;
  Color get backgroundColor => widget.backgroundColor;
  bool get showTopWriter => widget.showTopWriter;
  bool get showBottomWriter => widget.showBottomWriter;
  bool get showTags => widget.showTags;
  bool get showIcons => widget.showIcons;
  bool get showContent => widget.showContent;
  double? get imageHeight => widget.imageHeight;
  BoxFit get fit => widget.fit;
  double get borderRadius => widget.borderRadius;
  double get iconSize => widget.iconSize;
  double get iconHGap => widget.iconHGap;
  double get iconVGap => widget.iconVGap;
  MainAxisAlignment get iconAlignment => widget.iconAlignment;
  bool get isPinned => widget.isPinned;
  VoidCallback? get onTogglePin => widget.onTogglePin;
  bool get blockNavPost => widget.blockNavPost;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color effectiveFont =
        fontColor == Colors.black ? theme.colorScheme.onSurface : fontColor;
    final Color effectiveBg =
        backgroundColor == Colors.white ? theme.cardColor : backgroundColor;

    final comments = feed.post.comments ?? [];
    final imageUrls = (feed.post.imageUrls as List<dynamic>);
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    final currCategory = _catOverride ?? feed.post.category;
    final currValue = _valOverride ?? feed.post.value;

    return Container(
      decoration: BoxDecoration(color: effectiveBg),
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
              fontColor: effectiveFont,
              isMine: feed.user.userId == myUid,
              onEdit: () => _openEditSheet(context),
            ),
          if (imageUrls.isNotEmpty)
            GestureDetector(
              onTap: () async {
                if (!blockNavPost) {
                  final deleted = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PostPage(feed: feed)),
                  );
                  if (deleted == true) {
                    if (widget.onDeleted != null) {
                      widget.onDeleted!.call();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '삭제되었습니다.',
                            style: TextStyle(color: theme.colorScheme.onPrimary),
                          ),
                          backgroundColor: theme.colorScheme.primary,
                        ),
                      );
                    }
                  }
                }
              },
              child: _buildAutoImageArea(context, imageUrls, currCategory, currValue),
            ),
          if (showIcons)
            Padding(
              padding: EdgeInsets.symmetric(vertical: iconVGap, horizontal: iconHGap),
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
                      fontColor: effectiveFont,
                    ),
                    const SizedBox(width: 12),
                    FeedReplyIcon(
                      postId: feed.post.postId,
                      initialCommentCount: feed.numComments,
                      fontSize: iconSize - 3,
                      iconSize: iconSize,
                      fontColor: effectiveFont,
                    ),
                  ],
                ),
              ),
            ),
          if (showContent)
            FeedContent(
              content: feed.post.content,
              comments: comments,
              fontColor: effectiveFont,
            ),
        ],
      ),
    );
  }

  Future<void> _openEditSheet(BuildContext context) async {
    final theme = Theme.of(context);

    final visibilityInit = _visOverride ?? (feed.post.visibility ?? 'PUBLIC');
    final categoryInit   = _catOverride ?? feed.post.category;
    final valueInit      = _valOverride ?? feed.post.value;

    String vis = visibilityInit;
    String? cat = categoryInit;
    String? val = valueInit;

    final categories = const ['요리', '밀키트', '식당', '배달'];
    final reviewValues = const [
      {'label': 'Fire',  'image': 'assets/fire.png'},
      {'label': 'Tasty', 'image': 'assets/tasty.png'},
      {'label': 'Soso',  'image': 'assets/soso.png'},
      {'label': 'Woops', 'image': 'assets/woops.png'},
      {'label': 'Wack',  'image': 'assets/wack.png'},
    ];

    final result = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: theme.dividerColor.withOpacity(.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('게시물 편집', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        TextButton.icon(
                          onPressed: () => Navigator.pop(context, 'delete'),
                          icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                          label: Text('삭제', style: TextStyle(color: theme.colorScheme.error)),
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
                      onChanged: (v) => setModalState(() => vis = v ?? vis),
                      decoration: const InputDecoration(labelText: '공개 범위', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: cat,
                      items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setModalState(() => cat = v),
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
                            onSelected: (_) => setModalState(() => val = v['label']),
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
          await _postService.softDelete(feed.post.postId);
          if (!mounted) return;

          if (widget.onDeleted != null) {
            widget.onDeleted!.call();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('삭제되었습니다.', style: TextStyle(color: theme.colorScheme.onPrimary)),
                backgroundColor: theme.colorScheme.primary,
              ),
            );
          } else {
            Navigator.of(context).pop(true);
          }
          return;
        }
        return;
      }

      final map = result as Map<String, dynamic>;
      await _postService.updateFields(
        postId: feed.post.postId,
        visibility: map['visibility'] as String?,
        category: map['category'] as String?,
        value: map['value'] as String?,
      );

      setState(() {
        _visOverride = map['visibility'] as String? ?? _visOverride;
        _catOverride = map['category'] as String? ?? _catOverride;
        _valOverride = map['value'] as String? ?? _valOverride;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('수정되었습니다.', style: TextStyle(color: theme.colorScheme.onPrimary)),
          backgroundColor: theme.colorScheme.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('실패: $e', style: TextStyle(color: theme.colorScheme.onError)),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    }
  }

  Widget _buildAutoImageArea(
    BuildContext context,
    List<dynamic> imageUrls,
    String? currCategory,
    String? currValue,
  ) {
    if (imageHeight != null) {
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
                category: currCategory ?? feed.post.category,
                value: currValue ?? feed.post.value ?? '',
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
                  category: currCategory ?? feed.post.category,
                  value: currValue ?? feed.post.value ?? '',
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
    final theme = Theme.of(context);
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final avatarPx = (24 * dpr).round();

    final overlay = theme.colorScheme.inverseSurface.withOpacity(0.78);
    final fg = theme.colorScheme.onInverseSurface;

    return Positioned(
      left: 0, right: 0, bottom: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              theme.colorScheme.inverseSurface.withOpacity(0.85),
              theme.colorScheme.inverseSurface.withOpacity(0.0),
            ],
          ),
        ),
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
              style: theme.textTheme.bodyMedium?.copyWith(
                color: fg,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1))],
              ),
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
