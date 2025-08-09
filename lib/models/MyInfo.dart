
class MyInfo {
  final String userName;
  final String location;
  final int recipeCount; // 'Yum'에 매핑될 수 있음 (실제 앱에서는 'yumCount'나 'likedRecipeCount' 등으로 명확히 하는 것이 좋음)
  final int postCount; // 'Recipe'에 매핑될 수 있음 (실제 앱에서는 'recipeCount' 등으로 명확히 하는 것이 좋음)
  final int receivedLikeCount; // 이 필드는 현재 UserStatsRow에서 'Follower' 외에 사용되지 않음. 필요에 따라 활용
  final int followerCount;
  final int followingCount;
  final String? profileImage;
  final String? statusMessage;
  final String userTitle; // '생존형 자취 음식 전문가' 같은 필드 (API 필드명은 'user_title'로 가정)

  MyInfo({
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

  // JSON 데이터 (Map<String, dynamic>)로부터 MyInfo 객체를 생성하는 팩토리 생성자
  factory MyInfo.fromJson(Map<String, dynamic> json) {
    return MyInfo(
      userName: json['user_name'] ?? '',
      location: json['location'] ?? 'Seoul',
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

  // 기존 MyInfo 객체에서 특정 필드만 변경하여 새로운 MyInfo 객체를 반환하는 copyWith 메서드
  MyInfo copyWith({
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
    return MyInfo(
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

  // 선택 사항: MyInfo 객체를 JSON (Map<String, dynamic>)으로 변환하는 메서드
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
