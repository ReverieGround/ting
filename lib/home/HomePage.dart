import 'package:flutter/material.dart';
import '../feeds/FeedPage.dart';
import '../profile/ProfilePage.dart';
import '../nearby/NearbyPage.dart';
import 'dart:ui';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // lazy 캐시 (처음엔 FeedPage만 생성)
  final List<Widget?> _pages = [
    const FeedPage(key: PageStorageKey('feed')),
    null, // NearbyPage는 처음 탭할 때 생성
    null, // ProfilePage도 처음 탭할 때 생성
  ];

  final _bucket = PageStorageBucket();

  void _ensurePage(int index) {
    if (_pages[index] != null) return;
    switch (index) {
      case 1:
        _pages[1] = const NearbyPage(key: PageStorageKey('nearby'));
        break;
      case 2:
        _pages[2] = const ProfilePage(key: PageStorageKey('profile'));
        break;
    }
  }

  void _onItemTapped(int index) {
    if (!mounted) return;
    setState(() {
      _selectedIndex = index;
      _ensurePage(index); // 처음 탭할 때 생성
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuerySize = MediaQuery.of(context).size;
    final double bottomMargin = 10.0 + MediaQuery.of(context).padding.bottom;
    final double horizontalPadding = 20;
    final double navigatorWidth = mediaQuerySize.width - 2 * horizontalPadding;
    const double navigatorHeight = 50.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: PageStorage(
              bucket: _bucket,
              // IndexedStack은 children을 모두 렌더하려고 해서,
              // 아직 생성 안 된 페이지는 SizedBox로 채워둠 (빌드 비용 거의 0)
              child: IndexedStack(
                index: _selectedIndex,
                children: List.generate(3, (i) => _pages[i] ?? const SizedBox.shrink()),
              ),
            ),
          ),
          Positioned(
            bottom: bottomMargin,
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(60),
                  child: BackdropFilter(
                    // 블러가 GPU/합성비용이 좀 있으므로 살짝 낮추면 초기 체감 개선
                    filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
                    child: Container(
                      width: navigatorWidth,
                      height: navigatorHeight,
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(255, 255, 255, 0.4),
                        borderRadius: BorderRadius.circular(60),
                        border: Border.all(color: Colors.black87, width: 1.0),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildCustomNavItem('home', 0),
                          _buildCustomNavItem('nearby', 1),
                          _buildCustomNavItem('profile', 2),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomNavItem(String label, int index) {
    final bool isSelected = _selectedIndex == index;
    final String color = isSelected ? "pink" : "black";
    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.all(0.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/navi_${label}_${color}.png',
              fit: BoxFit.contain,
              alignment: Alignment.center,
              height: 22,
            ),
          ],
        ),
      ),
    );
  }
}
