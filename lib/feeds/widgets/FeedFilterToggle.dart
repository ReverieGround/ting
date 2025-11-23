import 'package:flutter/material.dart';

class FeedFilterToggle extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const FeedFilterToggle({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  State<FeedFilterToggle> createState() => _FeedFilterToggleState();
}

class _FeedFilterToggleState extends State<FeedFilterToggle> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final text = _searchController.text.trim();
    if (text.isEmpty) return;
    debugPrint("Search: $text");
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topInset = MediaQuery.of(context).padding.top;
    const labels = ['전체', '요리', '식당'];

    return Container(
      padding: EdgeInsets.only(top: topInset, left: 8, right: 12),
      height: 52 + topInset,
      color: theme.scaffoldBackgroundColor.withOpacity(0.95),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 왼쪽 토글
          Row(
            children: List.generate(labels.length, (index) {
              final bool isSelected = widget.selectedIndex == index;
              return GestureDetector(
                onTap: () => widget.onSelected(index),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                  ),
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : Colors.white70,
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              );
            }),
          ),

          // 여유공간 확보
          const Spacer(),

          // 검색창
          Container(
            padding: EdgeInsets.symmetric(vertical: 10),
            width: 150,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: TextField(
                controller: _searchController,
                cursorColor: Colors.white,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _handleSubmit(),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[900],
                  hintText: "검색",
                  hintStyle: const TextStyle(color: Colors.white54),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: _handleSubmit,
                    icon: const Icon(Icons.search, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
