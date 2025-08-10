// ProfileService.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'UserService.dart';
import 'PostService.dart';
import '../models/ProfileData.dart';

class ProfileService {
  final _auth = FirebaseAuth.instance;
  final UserService userService;
  final PostService postService;

  ProfileService({
    required this.userService,
    required this.postService,
  });

  Future<ProfileData?> loadProfile({String? targetUserId}) async {
    String? uid = targetUserId ?? _auth.currentUser?.uid;
    if (uid == null) return null;

    final profileInfo = await userService.fetchUserRaw(uid);
    if (profileInfo == null) return null;

    final posts = await postService.fetchUserPosts(
      userId: uid,
      limit: 50,
      excludeArchived: true,
    );
    final pinned = await postService.fetchPinnedPosts(
      ownerUserId: uid,
      limit: 20,
    );

    return ProfileData(
      profileInfo: profileInfo,
      posts: posts,
      pinned: pinned,
    );
  }
}
