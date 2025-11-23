class ProfileInfo {
  final String userId; 
  final String userName;
  final String location;
  final int recipeCount;
  final int postCount;
  final int receivedLikeCount;
  final int followerCount;
  final int followingCount;
  final String? profileImage;
  final String? statusMessage;
  final String userTitle;

  ProfileInfo({
    required this.userId,            
    required this.userName,
    required this.location,
    required this.statusMessage,
    required this.recipeCount,
    required this.postCount,
    required this.receivedLikeCount,
    required this.followerCount,
    required this.followingCount,
    required this.profileImage,
    required this.userTitle,
  });

  factory ProfileInfo.empty() {
    return ProfileInfo(
      userId: '',                    
      userName: '',
      userTitle: '',
      profileImage: '',
      statusMessage: '',
      postCount: 0,
      recipeCount: 0,
      followerCount: 0,
      followingCount: 0,
      location: '',
      receivedLikeCount: 0,
    );
  }

  factory ProfileInfo.fromJson(Map<String, dynamic> json) {
    return ProfileInfo(
      userId: json['user_id'] ?? '',               
      userName: json['user_name'] ?? '',
      location: json['location'] ?? '서울시',
      statusMessage: json['status_message'] ?? '',
      recipeCount: json['recipe_count'] ?? 0,
      postCount: json['post_count'] ?? 0,
      receivedLikeCount: json['received_like_count'] ?? 0,
      followerCount: json['follower_count'] ?? 0,
      followingCount: json['following_count'] ?? 0,
      profileImage: json['profile_image'] ?? '',
      userTitle: json['user_title'] ?? '',
    );
  }

  ProfileInfo copyWith({
    String? userId,
    String? userName,
    String? location,
    String? statusMessage,
    int? recipeCount,
    int? postCount,
    int? receivedLikeCount,
    int? followerCount,
    int? followingCount,
    String? profileImage,
    String? userTitle,
  }) {
    return ProfileInfo(
      userId: userId ?? this.userId,               
      userName: userName ?? this.userName,
      location: location ?? this.location,
      statusMessage: statusMessage ?? this.statusMessage,
      recipeCount: recipeCount ?? this.recipeCount,
      postCount: postCount ?? this.postCount,
      receivedLikeCount: receivedLikeCount ?? this.receivedLikeCount,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
      profileImage: profileImage ?? this.profileImage,
      userTitle: userTitle ?? this.userTitle,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,                          
      'user_name': userName,
      'location': location,
      'status_message': statusMessage,
      'recipe_count': recipeCount,
      'post_count': postCount,
      'received_like_count': receivedLikeCount,
      'follower_count': followerCount,
      'following_count': followingCount,
      'profile_image': profileImage,
      'user_title': userTitle,
    };
  }
}
