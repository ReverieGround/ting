
class ProfileInfo {
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

  // JSON 데이터 (Map<String, dynamic>)로부터 ProfileInfo 객체를 생성하는 팩토리 생성자
  factory ProfileInfo.fromJson(Map<String, dynamic> json) {
    return ProfileInfo(
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

  // 기존 ProfileInfo 객체에서 특정 필드만 변경하여 새로운 ProfileInfo 객체를 반환하는 copyWith 메서드
  ProfileInfo copyWith({
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

  // 선택 사항: ProfileInfo 객체를 JSON (Map<String, dynamic>)으로 변환하는 메서드
  Map<String, dynamic> toJson() {
    return {
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
