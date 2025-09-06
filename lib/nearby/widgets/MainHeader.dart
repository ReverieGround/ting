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
    final theme = Theme.of(context);

    return Container(
      color: theme.scaffoldBackgroundColor, // ✅ 배경색 테마
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SafeArea(
        left: false, right: false, top: true, bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '이 시간 우리 동네',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface, // ✅ 글자색 테마
                    ),
                  ),
                  LocationSelector(region: widget.region),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10.0, top: 5.0),
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
