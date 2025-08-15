// feeds/widgets/FeedCard.dart
import 'package:flutter/material.dart';
import 'FeedHead.dart';
import 'FeedImages.dart';
import 'FeedContent.dart';
import '../../posts/PostPage.dart';
import 'FeedLikeIcon.dart';
import 'FeedReplyIcon.dart';
import '../../models/PostData.dart';
import '../../models/FeedData.dart';
import '../../profile/ProfilePage.dart';

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
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<dynamic> comments = feed.post.comments ?? [];
    final List<dynamic> imageUrls = (feed.post.imageUrls as List<dynamic>);

    return Container(
      decoration: BoxDecoration(color: backgroundColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTopWriter)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfilePage(userId: feed.user.userId),
                  ),
                );
              },
              child: FeedHead(
                profileImageUrl: feed.user.profileImage!,
                userName: feed.user.userName,
                userId: feed.user.userId,
                userTitle: feed.user.title,
                createdAt: formatTimestamp(feed.post.createdAt),
                fontColor: fontColor,
              ),
            ),
          if (imageUrls.isNotEmpty)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PostPage(feed: feed)),
                );
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

  Widget _buildAutoImageArea(BuildContext context, List<dynamic> imageUrls) {
    // 고정 높이 모드
    if (imageHeight != null) {
      // 단일 이미지면 직접 다운스케일 디코딩
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

      // 2장 이상은 기존 FeedImages 유지
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

    // 자동 비율 모드
    final aspect = _autoAspectByCount(imageUrls.length);
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = w / aspect;
        final dpr = MediaQuery.of(context).devicePixelRatio;

        // 단일 이미지면 직접 다운스케일 디코딩
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

        // 2장 이상은 기존 FeedImages 유지
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

  // 우상단 핀 버튼
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

  // 하단 작성자 영역(아바타 다운스케일)
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
