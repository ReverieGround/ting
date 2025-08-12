// widgets/FilterBar.dart

import 'package:flutter/material.dart';

class FilterBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onFilterSelected;

  const FilterBar({
    super.key,
    required this.selectedIndex,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white),
      child:Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildFilterButton(
          context,
          icon: Image.asset('assets/thunder.png', width: 20, height: 20),
          text: '실시간',
          index: 0,
          isSelected: selectedIndex == 0,
          selectedColor: const Color.fromRGBO(225, 251, 169, 1),
          unselectedColor: const Color.fromRGBO(240, 240, 240, 1),
          selectedTextColor: Colors.black,
          unselectedTextColor: Colors.black,
        ),
        const SizedBox(width: 8),
        _buildFilterButton(
          context,
          icon: Image.asset('assets/fire.png', width: 20, height: 20),
          text: 'Hot Feed',
          index: 1,
          isSelected: selectedIndex == 1,
          selectedColor: const Color.fromRGBO(225, 251, 169, 1),
          unselectedColor: const Color.fromRGBO(240, 240, 240, 1),
          selectedTextColor: Colors.black,
          unselectedTextColor: Colors.black,
        ),
        const SizedBox(width: 8),
        _buildFilterButton(
          context,
          icon: Image.asset('assets/wack.png', width: 20, height: 20),
          text: 'Wack Feed',
          index: 2,
          isSelected: selectedIndex == 2,
          selectedColor: const Color.fromRGBO(225, 251, 169, 1),
          unselectedColor: const Color.fromRGBO(240, 240, 240, 1),
          selectedTextColor: Colors.black,
          unselectedTextColor: Colors.black,
        ),
      ],
      ),
    );
  }

  Widget _buildFilterButton(
    BuildContext context, {
    required Image icon,
    required String text,
    required int index,
    required bool isSelected,
    required Color selectedColor,
    required Color unselectedColor,
    required Color selectedTextColor,
    required Color unselectedTextColor,
  }) {
    final bg = isSelected ? selectedColor : unselectedColor;
    final fg = isSelected ? selectedTextColor : unselectedTextColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onFilterSelected(index),
        borderRadius: BorderRadius.circular(30),
        child: AnimatedContainer( // 선택 시 폭 변화도 부드럽게
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min, // ← 내용만큼만
            children: [
              SizedBox(width: 20, height: 20, child: icon),
              const SizedBox(width: 6),
              Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: fg,
                  fontWeight: FontWeight.w500,
                  height: 1.0,
                ),
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

}