// widgets/ChipsReview.dart
import 'package:flutter/material.dart';

class ReviewChips extends StatelessWidget {
  final List<Map<String, String>> items;
  final String selected;
  final ValueChanged<String> onSelect;

  /// 에러/하이라이트용 테두리
  final bool showBorder;
  final Color borderColor;
  final double borderWidth;
  final BorderRadius borderRadius;

  const ReviewChips({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelect,
    this.showBorder = false,
    this.borderColor = Colors.red,
    this.borderWidth = 1.5,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 원래 구조: 가로 스크롤 + Row
        Align(
          alignment: Alignment.centerLeft,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            child: Row(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  _chip(
                    label: items[i]['label']!,
                    assetPath: items[i]['image']!,
                    isSelected: selected == items[i]['label'],
                    onTap: onSelect,
                  ),
                  if (i != items.length - 1) const SizedBox(width: 6),
                ],
              ],
            ),
          ),
        ),

        // CategoryChips와 동일: 패딩 없이 위층에 테두리만 오버레이
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: ShapeDecoration(
                shape: RoundedRectangleBorder(
                  borderRadius: borderRadius,
                  side: BorderSide(
                    color: showBorder ? borderColor : Colors.transparent,
                    width: borderWidth,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _chip({
    required String label,
    required String assetPath,
    required bool isSelected,
    required ValueChanged<String> onTap,
  }) {
    return ChoiceChip(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      showCheckmark: false,
      labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(assetPath, width: 17, height: 17),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.black)),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onTap(label),
      selectedColor: const Color.fromRGBO(199, 244, 100, 1),
      backgroundColor: Colors.grey.shade200,
      labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide.none,
      ),
    );
  }
}
