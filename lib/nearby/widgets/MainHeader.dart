// lib/pages/nearby/widgets/main_header.dart

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
    // Column 위젯의 높이(header + filter bar)를 계산해서 반환합니다.
    const double headerHeight = 40.0; // "이 시간 우리 동네" Row의 대략적인 높이
    const double filterBarHeight = 40.0; // FilterBar의 대략적인 높이
    const double padding = 20.0; // 상하 패딩과 여백
    return const Size.fromHeight(headerHeight + filterBarHeight + padding);
  }
}

class _MainHeaderState extends State<MainHeader> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0, left: 8.0, right: 8.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '이 시간 우리 동네',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                LocationSelector(region: widget.region),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: FilterBar(
              selectedIndex: widget.currentFilterIndex,
              onFilterSelected: widget.onFilterSelected,
            ),
          ),
        ],
      ),
    );
  }
}