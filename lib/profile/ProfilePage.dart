// lib/pages/profile/profile_page.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// Firebase
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Common widgets
import '../AppHeader.dart';
import '../../common/widgets/ProfileAvatar.dart';

// Models & widgets
import '../models/MyInfo.dart';
import '../models/FeedData.dart';
import 'widgets/UserStatsRow.dart';
import 'widgets/PinnedFeedsGrid.dart';
import 'widgets/StatusMessage.dart';
import 'widgets/YumTab.dart';

// Services
import '../services/UserService.dart';
import '../services/PostService.dart';
import '../services/ProfileService.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late MyInfo myInfo = MyInfo.empty();
  bool isSaving = false;
  bool isLoading = true;
  List<FeedData> allFeeds = [];
  List<FeedData> pinnedFeeds = [];

  late TabController _tabController;
  final TextEditingController statusMessageController = TextEditingController();

  final userService = UserService();
  final postService = PostService();
  late final profileService = ProfileService(
    userService: userService,
    postService: postService,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        if (mounted) setState(() => isLoading = false);
        return;
      }

      final result = await profileService.loadProfile(targetUserId: uid);
      if (!mounted) return;
      if (result == null) {
        setState(() => isLoading = false);
        return;
      }

      // 비동기 변환은 setState 밖에서 전부 끝내기
      final allFeedsBuilt = await Future.wait(
        result.posts.map((p) => FeedData.create(post: p)),
      );
      
      final pinnedFeedsBuilt = await Future.wait(
        result.pinned.map((p) => FeedData.create(post: p)),
      );

      if (!mounted) return;
      setState(() {
        myInfo = result.myInfo;
        statusMessageController.text = result.myInfo.statusMessage ?? '';
        allFeeds = allFeedsBuilt;
        pinnedFeeds = pinnedFeedsBuilt;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('loadProfile error: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }


  Future<void> _uploadProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    try {
      final url = await userService.uploadProfileImage(File(picked.path));
      debugPrint(url != null ? '✅ Uploaded' : 'upload failed');
      await _loadProfileData();
    } catch (e) {
      debugPrint('uploadProfileImage error: $e');
    }
  }

  Future<bool> _uploadStatusMessage(String modified) async {
    final ok = await userService.updateStatusMessage(modified);
    if (ok) await _loadProfileData();
    return ok;
  }

  @override
  void dispose() {
    _tabController.dispose();
    statusMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppHeader(
        showBackButton: false,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        titleWidget: Container(
          margin: const EdgeInsets.only(top: 5),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  _showProfileImagePickerBottomSheet(context);
                },
                child: ProfileAvatar(
                  profileUrl: myInfo.profileImage,
                  size: 43,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 45,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(myInfo.userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    Text(myInfo.userTitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.black)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [

          SliverToBoxAdapter(
            child: UserStatsRow(
              yumCount: myInfo.postCount,
              recipeCount: myInfo.recipeCount,
              followerCount: myInfo.followerCount,
            ),
          ),
          SliverToBoxAdapter(
            child: StatusMessage(
              initialMessage: myInfo.statusMessage ?? '',
              onSave: _uploadStatusMessage,
            ),
          ),
          pinnedFeeds.isNotEmpty
              ? PinnedFeedsGrid(pinnedFeeds: pinnedFeeds)
              : const SliverToBoxAdapter(child: SizedBox.shrink()),
          SliverAppBar(
            pinned: true,
            backgroundColor: const Color.fromARGB(255, 255, 255, 255),
            toolbarHeight: 0,
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.black,
              tabs: const [
                Tab(text: 'Yum'),
                Tab(text: 'Recipe'),
                Tab(text: 'Guestbook'),
              ],
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                YumTab(feeds: allFeeds),
                const Center(child: Text('Recipe Content (e.g., filtered posts for Recipe)')),
                const Center(child: Text('Guestbook Content')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileImagePickerBottomSheet(BuildContext context) {
    const avatarList = [
      'https://firebasestorage.googleapis.com/v0/b/vibeyum-alpha.firebasestorage.app/o/profile_images%2Favatar-design.png?alt=media&token=f34a16cd-689d-464f-9c45-3859c66be0c0',
      'https://firebasestorage.googleapis.com/v0/b/vibeyum-alpha.firebasestorage.app/o/profile_images%2Fbusinesswoman.png?alt=media&token=6fa85751-6fff-42e2-91d9-32d114167352',
      'https://firebasestorage.googleapis.com/v0/b/vibeyum-alpha.firebasestorage.app/o/profile_images%2Fprogrammer.png?alt=media&token=ed21ed93-f845-42b9-8ec4-6d47f6e2650c',
      'https://firebasestorage.googleapis.com/v0/b/vibeyum-alpha.firebasestorage.app/o/profile_images%2Fwoman%20(1).png?alt=media&token=4494aa07-e112-489e-b053-7555d483c02c',
      'https://firebasestorage.googleapis.com/v0/b/vibeyum-alpha.firebasestorage.app/o/profile_images%2Fwoman.png?alt=media&token=4acd3f2f-3a19-4289-858e-e9fe929b5e91',
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
      ),
      backgroundColor: Colors.white,
      builder: (innerContext) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('프로필 사진 선택', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.black)),
                  InkWell(
                    onTap: () async {
                      Navigator.pop(innerContext);
                      await _uploadProfileImage();
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
                      child: const Icon(Icons.photo_library, color: Colors.black87),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: avatarList.map((url) {
                  return GestureDetector(
                    onTap: () async {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'profile_image': url});
                        Navigator.pop(innerContext);
                        _loadProfileData();
                      }
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(url, width: 60, height: 60, fit: BoxFit.cover),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
