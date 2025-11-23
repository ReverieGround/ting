import 'package:flutter/material.dart';
import '../../common/widgets/ProfileAvatar.dart';
import '../../common/widgets/TimeAgoText.dart';
import '../../profile/ProfilePage.dart';

class Head extends StatelessWidget {
  final String profileImageUrl;
  final String userName;
  final String userId;
  final String? userTitle;
  final String createdAt;
  final Color fontColor;

  // 내 글이면 우측에 편집 아이콘 노출
  final bool isMine;
  final VoidCallback? onEdit;

  const Head({
    Key? key,
    required this.profileImageUrl,
    required this.userName,
    required this.userId,
    required this.createdAt,
    this.userTitle,
    this.fontColor = Colors.black,
    this.isMine = false,
    this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 10, 5, 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfilePage(userId: userId)),
              );
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ProfileAvatar(profileUrl: profileImageUrl, size: 40),
                const SizedBox(width: 12),
                SizedBox(
                  height: 40,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: fontColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        userTitle ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: fontColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              TimeAgoText(createdAt: createdAt, fontSize: 12, fontColor: Colors.grey),
              if (isMine) const SizedBox(width: 4),
              if (isMine)
                IconButton(
                  tooltip: '편집',
                  icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                  onPressed: onEdit,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
