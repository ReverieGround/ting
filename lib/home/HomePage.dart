import 'package:flutter/material.dart';
import '../feeds/FeedPage.dart';
import '../profile/ProfilePage.dart';
import '../create/CreatePostPage.dart';
import '../recipe/RecipeListPage.dart'; 
import '../recipe/RecipeEditPage.dart'; 
import 'package:flutter_svg/flutter_svg.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 0: 커뮤니티(피드), 1: FAB 액션, 2: 프로필
  int _selectedIndex = 0;

  // 사이즈 튜닝 포인트 👇
  static const double kNavBarHeight = 50.0; // 더 낮은 바
  static const double kFabSize = 78.0;      // 더 큰 원형 FAB (ex. 64~72 권장)
  static const double kFabSpacerMargin = 12.0; // FAB 좌우 여유

  final List<Widget?> _pages = [
    const FeedPage(key: PageStorageKey('community')),
    null, // 2nd page
    null, // 3rd page
    null, // 4rd page
  ];

  final _bucket = PageStorageBucket();

  void _ensurePage(int index) {
    if (_pages[index] != null) return;
    switch (index) {
      case 1:
        _pages[1] = const RecipeListPage();
        break;
      case 2:
        _pages[2] = const RecipeEditPage(recipe: null);
        break;
      case 3:
        _pages[3] = const ProfilePage(key: PageStorageKey('profile'));
        break;
    }
  }

  void _onItemTapped(int index) {
    if (!mounted) return;
    // if (index == 1) { _openCook(); return; } // FAB 위치는 탭 이동 X
    setState(() {
      _selectedIndex = index;
      _ensurePage(index);
    });
  }

  Future<void> _openCook() async {
    await Navigator.of(context).push(
      // MaterialPageRoute(builder: (_) => const CreatePostPage()),
      MaterialPageRoute(builder: (_) => const RecipeListPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBody: true, // ✅ body를 FAB/Bottom 위까지 확장시켜줌
      body: Stack(
        children: [
          PageStorage(
            bucket: _bucket,
            child: IndexedStack(
              index: _selectedIndex,
              children: List.generate(3, (i) => _pages[i] ?? const SizedBox.shrink()),
            ),
          ),

          // ✅ 반투명 네비게이션바 오버레이
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: kNavBarHeight + MediaQuery.of(context).padding.bottom,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double w = constraints.maxWidth;
                    final double sidePadding = (w * 0.1).clamp(12.0, 28.0);
                    final double centerMargin = (w * 0.02).clamp(8.0, 16.0);
                    final double spacerWidth = kFabSize + centerMargin * 2;

                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: sidePadding),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _NavIconButton(
                            assetPath: 'assets/feeds.svg',
                            label: '커뮤니티',
                            selected: _selectedIndex == 0,
                            onTap: () => _onItemTapped(0),
                          ),
                          // SizedBox(width: spacerWidth),
                          _NavIconButton(
                            assetPath: 'assets/cooking-book.svg',
                            label: '요리하기',
                            selected: _selectedIndex == 1,
                            onTap: () => _onItemTapped(1),
                          ),
                          // SizedBox(width: spacerWidth),
                          _NavIconButton(
                            assetPath: 'assets/note2.svg',
                            label: '기록',
                            selected: _selectedIndex == 2,
                            onTap: () => _onItemTapped(2),
                          ),
                          // SizedBox(width: spacerWidth),
                          _NavIconButton(
                            assetPath: 'assets/profile.svg',
                            label: '프로필',
                            selected: _selectedIndex == 3,
                            onTap: () => _onItemTapped(3),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),

      // ✅ FloatingActionButton 유지
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // floatingActionButton: SizedBox(
      //   width: kFabSize,
      //   height: kFabSize,
      //   child: FloatingActionButton(
      //     backgroundColor: theme.colorScheme.onSurface,
      //     onPressed: _openCook,
      //     tooltip: '요리하기',
      //     elevation: 5,
      //     shape: CircleBorder(
      //       side: BorderSide(
      //         color: theme.colorScheme.surface,
      //         width: 5.0,
      //       ),
      //     ),
      //     child: Icon(
      //       Icons.restaurant_menu_rounded,
      //       size: 40,
      //       color: theme.colorScheme.surface,
      //     ),
      //   ),
      // ),
    );
  }

}

class _NavIconButton extends StatelessWidget {
  const _NavIconButton({
    required this.assetPath,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String assetPath;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected ? theme.colorScheme.primary : Colors.white70;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        scale: selected ? 1.2 : 1.0,
        child: Padding(
          padding: const EdgeInsets.all(0.0),
          child: Container(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                      assetPath,
                      height: 25,
                      colorFilter: ColorFilter.mode(
                        selected ? theme.colorScheme.onSurface : const Color.fromARGB(198, 255, 255, 255),
                        BlendMode.srcIn,
                      ),
                    ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: selected ? theme.colorScheme.onSurface : const Color.fromARGB(198, 255, 255, 255),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        ),
      ),
    );
  }
}