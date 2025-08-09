class UserData {
  final String userId;
  final String userName;
  final String location;
  final String title;
  final String? statusMessage;
  final String? profileImage;

  UserData({
    required this.userId,
    required this.userName,
    required this.location,
    required this.title,
    required this.statusMessage,
    required this.profileImage,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? '',
      location: json['location'] ?? 'Seoul',
      title: json['user_title'] ?? '',
      statusMessage: json['status_message'] ?? '',
      profileImage: json['profile_image'] ?? '',
    );
  }

  UserData copyWith({
    String? userId,
    String? userName,
    String? location,
    String? statusMessage,
    String? profileImage,
    String? title,
  }) {
    return UserData(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      location: location ?? this.location,
      title: title ?? this.title,
      statusMessage: statusMessage ?? this.statusMessage,
      profileImage: profileImage ?? this.profileImage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'location': location,
      'user_title': title,
      'status_message': statusMessage,
      'profile_image': profileImage,
    };
  }
}
