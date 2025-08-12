// widgets/MainHeader.dart
import 'package:flutter/material.dart';
import 'FilterBar.dart';
import 'LocationSelector.dart';

class MainHeader extends StatefulWidget implements PreferredSizeWidget {
  final String region;
  final int currentFilterIndex;
  final Function(int) onFilterSelected;

  const MainHeader({
    super.key,
    required this.region,
    required this.currentFilterIndex,
    required this.onFilterSelected,
  });

  @override
  State<MainHeader> createState() => _MainHeaderState();

  @override
  Size get preferredSize {
    const double headerHeight = 40.0;
    const double filterBarHeight = 40.0;
    const double padding = 20.0;
    return const Size.fromHeight(headerHeight + filterBarHeight + padding);
  }
}

class _MainHeaderState extends State<MainHeader> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 10), // 좌우 패딩 제거
      child: SafeArea(
        left: false, right: false, top: true, bottom: false, // 좌우 인셋 제거
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 좌우 패딩 없이 화면 끝에 맞춤
                  Text(
                    '이 시간 우리 동네',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),SizedBox(width: 0), // 왼쪽 끝 붙임
                  LocationSelector(region: widget.region),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10.0, top: 12.0),
              child: FilterBar(
                selectedIndex: widget.currentFilterIndex,
                onFilterSelected: widget.onFilterSelected,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
