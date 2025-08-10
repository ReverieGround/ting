// feeds/widgets/FeedHead.dart 
import 'package:flutter/material.dart';
import '../../common/widgets/ProfileAvatar.dart'; 
import '../../common/widgets/TimeAgoText.dart'; 

class FeedHead extends StatelessWidget { 
  final String profileImageUrl;
  final String userName;
  final String? userTitle;
  final String createdAt;
  final Color fontColor; 

  const FeedHead({
    Key? key,
    required this.profileImageUrl,
    required this.userName,
    required this.createdAt,
    this.userTitle,
    this.fontColor = Colors.black,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,  
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ProfileAvatar(
                profileUrl: profileImageUrl,
                size: 40,
              ),
              SizedBox(width: 12),
              Container(
                padding: EdgeInsets.symmetric(vertical: 1),
                margin: EdgeInsets.zero,
                height: 40,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: fontColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      userTitle ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: fontColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        TimeAgoText(
          createdAt: createdAt,
          fontSize: 12,
          fontColor: Colors.grey,
        ),
      ])
    );
  }
}