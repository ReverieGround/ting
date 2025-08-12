
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
    this.fontColor=Colors.black,
    this.backgroundColor=Colors.white,
    this.showTopWriter=true,
    this.showBottomWriter=false,
    this.showTags=true,
    this.showContent=true,
    this.showIcons=true,
    this.imageHeight=350,
    this.fit = BoxFit.cover,
    this.borderRadius=0.0,
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
      decoration: BoxDecoration(
        color: backgroundColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTopWriter)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfilePage(
                      userId: feed.user.userId,
                    ),
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
                  MaterialPageRoute(
                    builder: (_) => PostPage(
                      feed: feed,
                    ),
                  ),
                );
              },
              child: _buildAutoImageArea(context, imageUrls),
            ),
          if (showIcons)
            Padding(
              padding: EdgeInsets.symmetric(vertical: iconGap, horizontal: iconGap),
              child: Container(
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
                  SizedBox(width: 12),
                  FeedReplyIcon(
                    postId: feed.post.postId,
                    initialCommentCount: feed.numComments,
                    fontSize: iconSize - 3,
                    iconSize: iconSize,
                    fontColor: fontColor,
                  ),
                ]),
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
  
  // // FeedCard 클래스 하단에 추가
  // Widget _buildAutoImageArea(BuildContext context, List<dynamic> imageUrls) {
  //   // imageHeight가 있으면 그대로 사용
  //   if (imageHeight != null) {
  //     return ClipRRect(
  //       borderRadius: BorderRadius.circular(borderRadius),
  //       child: FeedImages(
  //         imageUrls: imageUrls,
  //         category: feed.post.category,
  //         value: feed.post.value ?? '',
  //         recipeId: feed.post.recipeId,
  //         recipeTitle: "",
  //         showTags: showTags,
  //         height: imageHeight,        // 고정 높이
  //         fit: fit,
  //         onRecipeButtonPressed: () {},
  //       ),
  //     );
  //   }

  //   // 없으면 폭 기반으로 비율 계산 → 높이 산출
  //   final aspect = _autoAspectByCount(imageUrls.length); // width / height
  //   return LayoutBuilder(
  //     builder: (context, c) {
  //       final w = c.maxWidth;
  //       final h = w / aspect; // height = width / (w/h)
  //       return ClipRRect(
  //         borderRadius: BorderRadius.circular(borderRadius),
  //         child: SizedBox(
  //           height: h,
  //           child: FeedImages(
  //             imageUrls: imageUrls,
  //             category: feed.post.category,
  //             value: feed.post.value ?? '',
  //             recipeId: feed.post.recipeId,
  //             recipeTitle: "",
  //             showTags: showTags,
  //             height: h,             // 계산된 높이 주입
  //             fit: fit,
  //             onRecipeButtonPressed: () {},
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }
  // FeedCard 클래스 하단 교체
  Widget _buildAutoImageArea(BuildContext context, List<dynamic> imageUrls) {
    if (imageHeight != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        clipBehavior: Clip.antiAlias,
        child: Container(
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
              if (isPinned)
                _buildPinButton(), // 우상단 핀
              if (showBottomWriter)
                Positioned(
                  left: 0, right: 0, bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    color: const Color.fromRGBO(0, 0, 0, 0.6),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundImage: NetworkImage(feed.user.profileImage!),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          feed.user.userName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
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
                  category: feed.post.category,
                  value: feed.post.value ?? '',
                  recipeId: feed.post.recipeId,
                  recipeTitle: "",
                  showTags: showTags,
                  height: h,
                  fit: fit,
                  onRecipeButtonPressed: () {},
                ),
                if (isPinned)
                  _buildPinButton(), // 우상단 핀
                if (showBottomWriter)
                  Positioned(
                    left: 0, right: 0, bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      color: const Color.fromRGBO(0, 0, 0, 0.6),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundImage: NetworkImage(feed.user.profileImage!),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            feed.user.userName,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
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

    final icon = Icons.push_pin_outlined;

    return Positioned(
      right: 4,
      top: 4,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: InkWell(
          onTap: onTogglePin,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
        ),
      ),
    );
  }

  double _autoAspectByCount(int count) {
    if (count <= 1) return 4 / 5;  // 단일 이미지: 약간 세로형
    if (count == 2) return 1.0;    // 두 장: 정사각
    return 3 / 4;                  // 세 장 이상: 살짝 세로형
  }

}