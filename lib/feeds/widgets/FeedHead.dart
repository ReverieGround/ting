import 'package:flutter/material.dart';
import '../../widgets/utils/profile_avatar.dart'; 
import '../../widgets/utils/time_ago_text.dart'; 

class FeedHead extends StatelessWidget { 
  final String profileImageUrl;
  final String userName;
  final String? userTitle;
  final String createdAt;

  const FeedHead({
    Key? key,
    required this.profileImageUrl,
    required this.userName,
    required this.createdAt,
    this.userTitle,
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
                        color: Colors.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      userTitle ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
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