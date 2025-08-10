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
import '../models/ProfileInfo.dart';
import '../models/FeedData.dart';
import 'widgets/UserStatsRow.dart';
import 'widgets/PinnedFeedsGrid.dart';
import 'widgets/StatusMessage.dart';
import 'widgets/YumTab.dart';
import 'widgets/FollowButton.dart';
import 'GuestBookPage.dart';

// Services
import '../services/UserService.dart';
import '../services/PostService.dart';
import '../services/ProfileService.dart';

class ProfilePage extends StatefulWidget {
  final String? userId;

  const ProfilePage({
    super.key,
    this.userId,
  });
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late ProfileInfo profileInfo = ProfileInfo.empty();
  bool isLoading = true;          // 전체 페이지 스피너(초기 1회)
  bool isFeedsLoading = false;    // 탭(피드) 영역 스피너
  String userId = '';
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
    userId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid ?? "";
    _stagedFirstLoad(); // <= 변경: 단계적 초기 로딩
  }

  Future<bool> _saveStatusMessage(String text) async {
    final ok = await userService.updateStatusMessage(text.trim());
    if (!mounted) return ok;
    if (ok) {
      setState(() {
        profileInfo = profileInfo.copyWith(statusMessage: text.trim());
      });
    }
    return ok;
  }

  // 1단계: 프로필만 먼저
  // 2단계: 피드/고정피드
  Future<void> _stagedFirstLoad() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      // 1) 프로필 먼저
      final info = await userService.fetchUserForViewer(userId);
      if (mounted && info != null) {
        setState(() {
          profileInfo = info;
          statusMessageController.text = info.statusMessage ?? '';
          isLoading = false;
        });
      } else {
        if (mounted) setState(() => isLoading = false);
      }

      // 2) 피드
      if (!mounted) return;
      setState(() => isFeedsLoading = true);

      final result = await profileService.loadProfile(targetUserId: userId);
      if (!mounted || result == null) {
        if (mounted) setState(() => isFeedsLoading = false);
        return;
      }

      final allFeedsBuilt = await Future.wait(
        result.posts.map((p) => FeedData.create(post: p)),
      );
      final pinnedFeedsBuilt = await Future.wait(
        result.pinned.map((p) => FeedData.create(post: p)),
      );

      if (!mounted) return;
      setState(() {
        allFeeds = allFeedsBuilt;
        pinnedFeeds = pinnedFeedsBuilt;
        isFeedsLoading = false;
      });
    } catch (e) {
      debugPrint('stagedFirstLoad error: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          isFeedsLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final me = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = me != null && me == userId; // 내가 보는 내 프로필?

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppHeader(
        showBackButton: false,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        titleWidget: Container(
          margin: const EdgeInsets.only(top: 5),
          child: Row(
            children: [
              ProfileAvatar(
                profileUrl: profileInfo.profileImage,
                size: 43,
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 45,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profileInfo.userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    Text(profileInfo.userTitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.black)),
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
              yumCount: profileInfo.postCount,
              recipeCount: profileInfo.recipeCount,
              followerCount: profileInfo.followerCount,
              followingCount: profileInfo.followingCount,
            ),
          ),
          SliverToBoxAdapter(
            child: StatusMessage(
              initialMessage: profileInfo.statusMessage ?? '',
              onSave: isOwner ? _saveStatusMessage : (_) async => false,
              readOnly: !isOwner,
            ),
          ),
          if (!isOwner)
            SliverToBoxAdapter(
              child: FollowButton(
                targetUid: userId,
                onChanged: (isNowFollowing) {
                  if (!mounted) return;
                  final next = profileInfo.followerCount + (isNowFollowing ? 1 : -1);
                  setState(() {
                    profileInfo = profileInfo.copyWith(
                      followerCount: next < 0 ? 0 : next,
                    );
                  });
                },
              ),
            ),
          // 핀 영역: 로딩 중엔 얇은 placeholder
          if (pinnedFeeds.isNotEmpty)
            PinnedFeedsGrid(pinnedFeeds: pinnedFeeds)
          else
            const SliverToBoxAdapter(child: SizedBox(height: 8)),

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
                // 피드 탭: 로딩 스피너만 따로
                if (isFeedsLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  YumTab(feeds: allFeeds),

                const Center(child: Text('Recipe Content (e.g., filtered posts for Recipe)')),
                // const Center(child: Text('Guestbook Content')),
                // GuestBookPage(),
                GuestBookPage(
                  heroNamespace: 'guestbook_tab_1',
                  targetUserId: userId,
                  currentUserId: FirebaseAuth.instance.currentUser?.uid ?? 'guest', // 뷰어
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
