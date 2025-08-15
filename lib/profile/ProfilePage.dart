// lib/pages/profile/profile_page.dart
import 'package:flutter/material.dart';

// Firebase
import 'package:firebase_auth/firebase_auth.dart';

// Common widgets
import '../AppHeader.dart';
import '../../common/widgets/ProfileAvatar.dart';

// Models & widgets
import '../models/ProfileInfo.dart';
import '../models/FeedData.dart';
import 'widgets/UserStatsRow.dart';
import 'widgets/PinnedFeedsGrid.dart';
import 'widgets/StatusMessage.dart';
import 'widgets/FollowButton.dart';
import 'tabs/YumTab.dart';
import 'tabs/GuestBookTab.dart';

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

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late ProfileInfo profileInfo = ProfileInfo.empty();
  bool isLoading = true;
  bool isFeedsLoading = false;
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

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    userId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid ?? "";
    _stagedFirstLoad();
  }

  @override
  void dispose() {
    _tabController.dispose();
    statusMessageController.dispose();
    super.dispose();
  }

  Future<bool> _saveStatusMessage(String text) async {
    final ok = await userService.updateStatusMessage(text.trim());
    if (!mounted) return ok;
    if (ok) {
      _safeSetState(() {
        profileInfo = profileInfo.copyWith(statusMessage: text.trim());
      });
    }
    return ok;
  }

  Future<void> _stagedFirstLoad() async {
    if (!mounted) return;
    _safeSetState(() => isLoading = true);

    try {
      final info = await userService.fetchUserForViewer(userId);
      if (!mounted) return;

      if (info != null) {
        _safeSetState(() {
          profileInfo = info;
          statusMessageController.text = info.statusMessage ?? '';
          isLoading = false;
        });
      } else {
        _safeSetState(() => isLoading = false);
      }

      if (!mounted) return;
      _safeSetState(() => isFeedsLoading = true);

      final result = await profileService.loadProfile(targetUserId: userId);
      if (!mounted) return;

      if (result == null) {
        _safeSetState(() => isFeedsLoading = false);
        return;
      }

      final allFeedsBuilt = await Future.wait(result.posts.map((p) => FeedData.create(post: p)));
      final pinnedFeedsBuilt = await Future.wait(result.pinned.map((p) => FeedData.create(post: p)));
      if (!mounted) return;

      _safeSetState(() {
        allFeeds = allFeedsBuilt;
        pinnedFeeds = pinnedFeedsBuilt;
        isFeedsLoading = false;
      });
    } catch (e) {
      debugPrint('stagedFirstLoad error: $e');
      if (!mounted) return;
      _safeSetState(() {
        isLoading = false;
        isFeedsLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final me = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = me != null && me == userId;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppHeader(
        showBackButton: false,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        titleWidget: Container(
          margin: const EdgeInsets.only(top: 5),
          child: Row(
            children: [
              ProfileAvatar(profileUrl: profileInfo.profileImage, size: 43),
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
                  _safeSetState(() {
                    profileInfo = profileInfo.copyWith(followerCount: next < 0 ? 0 : next);
                  });
                },
              ),
            ),

          if (pinnedFeeds.isNotEmpty)
            PinnedFeedsGrid(
              isLoading: isFeedsLoading,
              pinnedFeeds: pinnedFeeds,
              onUnpin: (feed) async {
                if (!mounted) return;
                try {
                  await postService.unpinPost(feed.post.postId); // ✅ DB 해제
                  if (!mounted) return;
                  _safeSetState(() {
                    pinnedFeeds = pinnedFeeds.where((f) => f.post.postId != feed.post.postId).toList();
                  });
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                    const SnackBar(content: Text('해제 실패. 잠시 후 다시 시도해 주세요')),
                  );
                }
              },
            )
          else
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
          SliverAppBar(
            pinned: true,
            backgroundColor: const Color.fromARGB(255, 255, 255, 255),
            toolbarHeight: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(36),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.centerLeft,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.black,
                  indicatorWeight: 2,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 10),
                  indicatorPadding: EdgeInsets.zero,
                  indicatorSize: TabBarIndicatorSize.tab, 
                  indicator: const UnderlineTabIndicator( // ← 여백 없이 꽉 차게
                    borderSide: BorderSide(width: 2, color: Colors.black),
                    insets: EdgeInsets.zero,
                  ),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(height: 30, text: 'Yum'),
                    Tab(height: 30, text: 'Recipe'),
                    Tab(height: 30, text: 'Guestbook'),
                  ],
                ),
              ),
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                YumTab(
                  feeds: allFeeds,
                  isLoading: isFeedsLoading,
                  onPin: (feed) async {
                    if (!mounted) return;

                    try {
                      await postService.pinPost(feed.post.postId); // ✅ DB 기록

                      if (!mounted) return;
                      final already = pinnedFeeds.any((f) => f.post.postId == feed.post.postId);
                      if (!already) {
                        _safeSetState(() {
                          pinnedFeeds = [feed, ...pinnedFeeds];
                        });
                      }

                      if (!mounted) return;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                          const SnackBar(content: Text('상단에 고정했습니다')),
                        );
                      });
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                        const SnackBar(content: Text('고정 실패. 잠시 후 다시 시도해 주세요')),
                      );
                    }
                  },
                ),
                const Center(child: Text('Recipe Content (e.g., filtered posts for Recipe)')),
                GuestBookTab(
                  heroNamespace: 'guestbook_tab_1',
                  targetUserId: userId,
                  currentUserId: FirebaseAuth.instance.currentUser?.uid ?? 'guest',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
