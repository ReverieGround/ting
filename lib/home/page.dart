import 'package:flutter/material.dart';
import '../feeds/page.dart';
import '../profile/page.dart';
import '../nearby/page.dart';
import 'dart:ui';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0; // 현재 선택된 내비게이션 인덱스

  static const List<Widget> _widgetOptions = <Widget>[
    FeedPage(),
    NearbyPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    if (mounted) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    final mediaQuerySize = MediaQuery.of(context).size;
    final double bottomMargin = 10.0 + MediaQuery.of(context).padding.bottom;
    final double horizontalPadding = 15;
    final double navigatorWidth = mediaQuerySize.width - 2 * horizontalPadding;
    const double navigatorHeight = 60.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill( 
            child:  _widgetOptions.elementAt(_selectedIndex),
          ),
          Positioned(
            bottom: bottomMargin,
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: ClipRRect( // 블러 효과가 border radius를 따르도록 ClipRRect로 감싸줍니다.
                  borderRadius: BorderRadius.circular(60),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), // sigmaX, sigmaY 값을 조절하여 블러 강도 변경
                    child: Container(
                      width: navigatorWidth,
                      height: navigatorHeight,
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(255, 255, 255, 0.4),
                        borderRadius: BorderRadius.circular(60),
                        border: Border.all(color: Colors.black12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                        children: [
                          _buildCustomNavItem('home', 0),
                          _buildCustomNavItem('place', 1),
                          _buildCustomNavItem('me', 2),
                        ],
                      ),
                    ),
                  )
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
              height: 22
            )
          ],
        ),
      ),
    );
  }
}
