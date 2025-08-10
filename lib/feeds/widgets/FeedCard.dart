
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

class FeedCard extends StatelessWidget {
  final FeedData feed;
  final Color fontColor;
  final Color backgroundColor;
  final bool showTopWriter;
  final bool showBottomWriter;
  final bool showTags;
  final bool showContent;
  final double? imageHeight;
  final BoxFit fit;
  final double borderRadius;

  const FeedCard({
    Key? key,
    required this.feed,
    this.fontColor=Colors.black,
    this.backgroundColor=Colors.white,
    this.showTopWriter=true,
    this.showBottomWriter=false,
    this.showTags=true,
    this.showContent=true,
    this.imageHeight=350,
    this.fit = BoxFit.cover,
    this.borderRadius=0,

  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<dynamic> comments = feed.post.comments ?? [];
    final List<dynamic> imageUrls = (feed.post.imageUrls as List<dynamic>);
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostPage(
              feed: feed,
            ), // PostPage도 경로 확인 필요
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: backgroundColor,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTopWriter)
              FeedHead(
                profileImageUrl: feed.user.profileImage!,
                userName: feed.user.userName,
                userTitle: feed.user.title,
                createdAt: formatTimestamp(feed.post.createdAt),
                fontColor: fontColor,
              ),
            if (imageUrls.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius), // 원하는 둥글기
                child: Stack(
                  children: [
                  FeedImages(
                    imageUrls: imageUrls,
                    category: feed.post.category,
                    value: feed.post.value ?? '',
                    recipeId: feed.post.recipeId,
                    recipeTitle: "", // TODO
                    showTags: showTags,
                    height: imageHeight,
                    fit: fit,
                    onRecipeButtonPressed: () {
                      debugPrint('Recipe button pressed for ');
                    },
                  ),
                  if (showBottomWriter)
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
                                  backgroundImage: NetworkImage(feed.user.profileImage!),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  feed.user.userName,
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
             ]),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(children: [
                FeedLikeIcon(
                  postId: feed.post.postId,
                  initialLikeCount: feed.numLikes,
                  hasLiked: feed.isLikedByUser,
                  onToggleCompleted: null,
                  fontSize: 18.0,
                  iconSize: 22.0,
                  fontColor: fontColor,
                ),
                SizedBox(width: 12),
                FeedReplyIcon(
                  postId: feed.post.postId,
                  initialCommentCount: feed.numComments,
                  fontSize: 18.0,
                  iconSize: 18.0,
                  fontColor: fontColor,
                ),
              ]),
            ),
            if (showContent)
              FeedContent(
                content: feed.post.content,
                comments: comments,
                fontColor: fontColor,
              ),
              const SizedBox(height: 8),  
          ],
        ),
      ),
    );
  }
}