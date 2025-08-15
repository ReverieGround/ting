// widgets/ChipsCategory.dart
import 'package:flutter/material.dart';

class CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelect;

  /// 에러/하이라이트용 테두리 표시 여부
  final bool showBorder;

  /// 테두리 색/두께/라운드
  final Color borderColor;
  final double borderWidth;
  final BorderRadius borderRadius;

  const CategoryChips({
    super.key,
    required this.categories,
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
        // 칩들 (타이트한 높이, 가로 스크롤)
        Align(
          alignment: Alignment.centerLeft,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            child: Row(
              children: [
                for (int i = 0; i < categories.length; i++) ...[
                  _chip(categories[i], selected == categories[i]),
                  if (i != categories.length - 1) const SizedBox(width: 6),
                ],
              ],
            ),
          ),
        ),

        // 테두리 오버레이 (자식 위에 그림 → 칩이 가릴 수 없음)
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

  Widget _chip(String label, bool isSelected) {
    return ChoiceChip(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      showCheckmark: false,
      labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      label: Text(
        label,
        style: const TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w500),
      ),
      selected: isSelected,
      onSelected: (_) => onSelect(label),
      selectedColor: const Color.fromRGBO(199, 244, 100, 1),
      backgroundColor: Colors.grey.shade200,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide.none,
      ),
    );
  }
}
