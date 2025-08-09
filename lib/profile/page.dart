// lib/pages/profile/profile_page.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// Firebase related imports
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

// Common widgets
import '../widgets/common/vibe_header.dart';
import '../widgets/utils/profile_avatar.dart';

// Custom models and widgets
import '../models/my_info.dart';
import '../models/post_data.dart';
import '../models/feed_data.dart';
import 'widgets/user_stats_row.dart';
import 'widgets/pinned_feeds_grid.dart';
import 'widgets/status.dart';
import 'yum_tab.dart';
import '../services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  // Use the aliased to avoid conflict
  late MyInfo myInfo;
  bool isSaving = false; 
  bool isLoading = true; 
  List<PostData> allPosts = []; 
  List<FeedData> pinnedFeeds = []; 

  late TabController _tabController;
  final TextEditingController statusMessageController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // For 'Yum', 'Recipe', 'Guestbook'
    _loadProfileData(); // Load all necessary profile data
  }

  Future<void> _loadProfileData() async {
    setState(() {
      isLoading = true; // Start loading
    });

    try {
      String? targetUserId = await AuthService.getUserId();
      
      // Determine the user ID: if not provided, use current logged-in user
      if (targetUserId == null) {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          debugPrint('No logged-in user.');
          if (mounted) setState(() => isLoading = false);
          return;
        }
        targetUserId = currentUser.uid;
      }
      // 1. Fetch User Info
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .get();
      if (!userDoc.exists) {
        debugPrint('User document does not exist.');
        if (mounted) setState(() => isLoading = false);
        return;
      }
      final userData = userDoc.data();
      if (mounted) {
        setState(() {
          myInfo = MyInfo.fromJson(userData!);
          statusMessageController.text = myInfo.statusMessage ?? ''; // Initialize controller
        });
      }
      // 2. Fetch User Posts (including pinned posts)
      final postsSnapshot = await FirebaseFirestore.instance
          .collection("posts") // Assuming your posts are in "posts"
          .where("user_id", isEqualTo: targetUserId)
          .where("archived", isEqualTo: false) // Exclude archived posts
          .orderBy("created_at", descending: true)
          .limit(50) // Limit to a reasonable number
          .get();

      final List<PostData> fetchedPosts = postsSnapshot.docs.map((doc) { // Changed from PostData to PostData
        final data = doc.data();
        data['postId'] = doc.id; // Add document ID to the data map
        
        return PostData.fromMap(data); // Use your custom PostData.fromMap factory
      }).toList();
      // Filter pinned posts
      // final List<PostData> filteredPinnedFeeds = fetchedPosts.where((post) => post.isPinned).toList(); // Changed from PostData to PostData
      final List<FeedData> filteredPinnedFeeds =  [];

      if (mounted) {
        setState(() {
          allPosts = fetchedPosts;
          pinnedFeeds = filteredPinnedFeeds;
          isLoading = false; // Loading finished
        });
      }
    } catch (e) {
      debugPrint('Failed to load profile data: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  // Method to handle profile image upload
  Future<void> _uploadProfileImage() async {
    
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint("No logged-in user.");
        return;
      }
      final fileName =
          'profile_images/${user.uid}_${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
      final ref = FirebaseStorage.instance.ref().child(fileName);

      await ref.putFile(File(picked.path));
      final downloadUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'profile_image': downloadUrl});

      debugPrint('✅ Profile image uploaded and Firestore updated successfully.');
      _loadProfileData(); // Reload all data to update UI
    } catch (e) {
      debugPrint('Failed to upload image: $e');
    }
  }

  Future<dynamic> _uploadStatusMessage(String modified) async{
    return true;
  }
  // Disposable resources
  @override
  void dispose() {
    _tabController.dispose();
    statusMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading indicator if data is not ready
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: VibeHeader(
        showBackButton: false,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        titleWidget: Container(
          margin: const EdgeInsets.only(top: 5), // Adjust margin as needed
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  _showProfileImagePickerBottomSheet(context);
                },
                child: ProfileAvatar(
                  profileUrl: myInfo.profileImage, // Safe due to myInfo null check above
                  size: 43,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox( 
                height: 45, 
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribute space
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
      body: CustomScrollView( // Use CustomScrollView for flexible scrolling behavior
        slivers: [
          // User Stats Row (PostData, Recipe, Follower)
          SliverToBoxAdapter(
            child: UserStatsRow(
              yumCount: myInfo.postCount,   
              recipeCount: myInfo.recipeCount,
              followerCount: myInfo.followerCount,
            ),
          ),
          SliverToBoxAdapter(
            child: StatusWidget(
            initialMessage:  myInfo.statusMessage ?? '',
            onSave: _uploadStatusMessage,
            ),
          ),
          // Pinned Posts Grid
          pinnedFeeds.isNotEmpty 
          ? PinnedFeedsGrid(pinnedFeeds: pinnedFeeds)
          : const SliverToBoxAdapter(child: SizedBox.shrink()),

          // TabBar (Yum, Recipe, Guestbook) - Pinned to the top when scrolled
          SliverAppBar(
            pinned: true, // Makes the TabBar stick to the top
            backgroundColor: const Color.fromARGB(255, 255, 255, 255), // Match background
            toolbarHeight: 0, // No actual app bar content above the tabs
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

          // TabBarView content - Takes the remaining space
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                YumTab(posts: allPosts),
                Center(child: Text('Recipe Content (e.g., filtered posts for Recipe)')), // Placeholder
                Center(child: Text('Guestbook Content')), // Placeholder
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Extracted the bottom sheet logic into a separate method for clarity
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
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      backgroundColor: Colors.white,
      builder: (innerContext) { // Use innerContext to ensure correct navigator pop
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
                      Navigator.pop(innerContext); // Pop this bottom sheet
                      await _uploadProfileImage(); // Then upload new image
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
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
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .update({'profile_image': url});
                        Navigator.pop(innerContext); // Pop bottom sheet
                        _loadProfileData(); // Refresh user info
                      }
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        url,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
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