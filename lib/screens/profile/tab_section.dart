import 'package:flutter/material.dart';
import 'content_grid.dart';

class TabSection extends StatefulWidget {
  const TabSection({super.key});

  @override
  State<TabSection> createState() => _TabSectionState();
}

class _TabSectionState extends State<TabSection> with TickerProviderStateMixin {
  late TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        children: [
          Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TabBar(
                controller: _controller,
                labelColor: Colors.black,
                unselectedLabelColor: Color.fromARGB(100, 62, 62, 62),
                labelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                indicator: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.black, // 원하는 색상
                      width: 1,                 // 굵기
                    ),
                  ),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
                  if (states.contains(WidgetState.pressed)) {
                    return Colors.grey.withOpacity(0.1); // 눌렀을 때 효과 색상
                  }
                  return null;
                }),
                tabs: const [
                  Tab(text: 'Yum'),
                  Tab(text: 'Recipe'),
                  Tab(text: 'Guestbook'),
                ],
              ),
          ),
          
          Expanded(
            child: TabBarView(
              controller: _controller,
              children: const [
                ContentGrid(type: 'yum'),
                ContentGrid(type: 'recipe'),
                ContentGrid(type: 'guestbook'),
              ],
            ),
          ),
        ],
    );
  }
}
