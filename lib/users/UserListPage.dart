import 'package:flutter/material.dart';
import '../models/UserData.dart';
import '../services/UserService.dart';
import '../profile/ProfilePage.dart';

class UserListPage extends StatefulWidget {
  final int initialTabIndex; // 0: 팔로워, 1: 팔로잉, 2: 차단
  final String targetUserId;

  const UserListPage({
    super.key,
    required this.targetUserId,
    this.initialTabIndex = 0,
  });

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  late int selectedIndex;
  bool isLoading = false;

  final userService = UserService();

  // 캐시 리스트
  List<UserData> users = [];
  List<UserData> followers = [];
  List<UserData> following = [];
  List<UserData> blocks = [];

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialTabIndex;
    _loadUsers(); // 첫 진입 시 1회 호출
  }

  Future<void> _loadUsers({bool forceRefresh = false}) async {
    setState(() => isLoading = true);

    String field;
    List<UserData> cachedList;

    switch (selectedIndex) {
      case 0:
        field = 'followers';
        cachedList = followers;
        break;
      case 1:
        field = 'following';
        cachedList = following;
        break;
      default:
        field = 'blocks';
        cachedList = blocks;
    }

    // ✅ 이미 캐시되어 있으면 Firestore 호출 생략
    if (!forceRefresh && cachedList.isNotEmpty) {
      setState(() {
        users = cachedList;
        isLoading = false;
      });
      return;
    }

    // 🟢 처음 불러올 때만 Firestore 요청
    final result =
        await userService.fetchUserList(widget.targetUserId, field);

    setState(() {
      users = result;
      isLoading = false;
    });

    // ✅ 캐시에 저장
    switch (selectedIndex) {
      case 0:
        followers = result;
        break;
      case 1:
        following = result;
        break;
      default:
        blocks = result;
    }
  }

  void _toggleTab(int index) {
    if (index == selectedIndex) return;
    setState(() => selectedIndex = index);
    // 캐시 여부 확인 후 로드
    switch (index) {
      case 0:
        users = followers.isNotEmpty ? followers : [];
        break;
      case 1:
        users = following.isNotEmpty ? following : [];
        break;
      case 2:
        users = blocks.isNotEmpty ? blocks : [];
        break;
    }
    if (users.isEmpty) _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titles = ['팔로워', '팔로잉', '차단'];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        centerTitle: true,
        title: Text(
          titles[selectedIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // 🔘 상단 토글 버튼
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 0),
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(30),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(titles.length, (i) {
                  return Expanded(
                    child: _TabButton(
                      label: titles[i],
                      selected: selectedIndex == i,
                      onTap: () => _toggleTab(i),
                    ),
                  );
                }),
              ),
            ),
          ),

          // 📋 유저 리스트
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : users.isEmpty
                    ? const Center(
                        child: Text(
                          "사용자가 없습니다.",
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 6,
                          crossAxisSpacing: 6,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => ProfilePage(userId: user.userId)),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: EdgeInsets.all(5),
                                color: Colors.grey[900],
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 32,
                                      backgroundImage: user.profileImage != null
                                          ? NetworkImage(user.profileImage!)
                                          : null,
                                      backgroundColor: Colors.grey[800],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      user.userName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      user.title,
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withOpacity(0.9)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
