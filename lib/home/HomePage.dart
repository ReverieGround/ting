import 'package:flutter/material.dart';
import '../feeds/FeedPage.dart';
import '../profile/ProfilePage.dart';
import '../create/CreatePostPage.dart';

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
    null, // FAB 액션
    null, // Profile (lazy)
  ];

  final _bucket = PageStorageBucket();

  void _ensurePage(int index) {
    if (_pages[index] != null) return;
    switch (index) {
      case 2:
        _pages[2] = const ProfilePage(key: PageStorageKey('profile'));
        break;
    }
  }

  void _onItemTapped(int index) {
    if (!mounted) return;
    if (index == 1) { _openCook(); return; } // FAB 위치는 탭 이동 X
    setState(() {
      _selectedIndex = index;
      _ensurePage(index);
    });
  }

  Future<void> _openCook() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreatePostPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: PageStorage(
        bucket: _bucket,
        child: IndexedStack(
          index: _selectedIndex,
          children: List.generate(3, (i) => _pages[i] ?? const SizedBox.shrink()),
        ),
      ),

      // FAB: 더 크게 + 완전 동그라미
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        width: kFabSize,
        height: kFabSize,
        child: FloatingActionButton(
          backgroundColor: theme.colorScheme.onSurface,
          onPressed: _openCook,
          tooltip: '요리하기',
          elevation: 5,
          shape: CircleBorder(
            side: BorderSide(
              color:theme.colorScheme.surface,
              width: 5.0,
             )
          ),
          child: Icon(
            Icons.restaurant_menu_rounded, size: 40,
            color: theme.colorScheme.surface,
          ),
        ),
      ),

      // 낮은 BottomAppBar (적응형 배치)
      bottomNavigationBar: BottomAppBar(
        // 노치 없음(동그란 FAB가 위에 살짝 겹치는 형태)
        height: kNavBarHeight,
        elevation: 6,
        color: theme.colorScheme.surface.withOpacity(0.9),
        child: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double w = constraints.maxWidth;

              // 화면 너비 기반 동적 여백
              final double sidePadding = (w * 0.1).clamp(12.0, 28.0); // 좌우 패딩
              final double centerMargin = (w * 0.02).clamp(8.0, 16.0);  // FAB 좌우 여유
              final double spacerWidth = kFabSize + centerMargin * 2;   // FAB 지름 + 여유

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: sidePadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _NavIconButton(
                      icon: Icons.supervisor_account_rounded,
                      label: '커뮤니티',
                      selected: _selectedIndex == 0,
                      onTap: () => _onItemTapped(0),
                    ),

                    // 가운데 FAB 영역 확보 (화면 크기에 따라 자동 조절)
                    SizedBox(width: spacerWidth),

                    _NavIconButton(
                      icon: Icons.person_rounded,
                      label: '프로필',
                      selected: _selectedIndex == 2,
                      onTap: () => _onItemTapped(2),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),


    );
  }
}

class _NavIconButton extends StatelessWidget {
  const _NavIconButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color color =
        selected ? theme.colorScheme.primary : theme.colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      child: Icon(icon, color: color, size: 32),
    );
  }
}
