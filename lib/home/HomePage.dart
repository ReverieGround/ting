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

  final List<Widget?> _pages = [
    const FeedPage(key: PageStorageKey('feed')),
    null,
    null,
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
      _ensurePage(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuerySize = MediaQuery.of(context).size;
    final double bottomMargin = 10.0 + MediaQuery.of(context).padding.bottom;
    const double horizontalPadding = 20;
    final double navigatorWidth = mediaQuerySize.width - 2 * horizontalPadding;
    const double navigatorHeight = 50.0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, 
      body: Stack(
        children: [
          Positioned.fill(
            child: PageStorage(
              bucket: _bucket,
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
                padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(60),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
                    child: Container(
                      width: navigatorWidth,
                      height: navigatorHeight,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withOpacity(0.4), 
                        borderRadius: BorderRadius.circular(60),
                        border: Border.all(
                          color: theme.dividerColor, 
                          width: 1.0,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildCustomNavItem(context, 'home', 0),
                          _buildCustomNavItem(context, 'nearby', 1),
                          _buildCustomNavItem(context, 'profile', 2),
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

  Widget _buildCustomNavItem(BuildContext context, String label, int index) {
    final theme = Theme.of(context);
    final bool isSelected = _selectedIndex == index;

    
    final Color iconColor = isSelected 
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface;

    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.all(0.0),
        child: Icon( // PNG 대신 Theme 색상을 입힌 Icon 사용 권장
          _mapLabelToIcon(label),
          color: iconColor,
          size: 24,
        ),
      ),
    );
  }

  
  IconData _mapLabelToIcon(String label) {
    switch (label) {
      case 'home':
        return Icons.home_rounded;
      case 'nearby':
        return Icons.location_on_rounded;
      case 'profile':
        return Icons.person_rounded;
      default:
        return Icons.circle;
    }
  }
}
