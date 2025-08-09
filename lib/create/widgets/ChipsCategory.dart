// widgets/ChipsCategory.dart
import 'package:flutter/material.dart';

class CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelect;

  const CategoryChips({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final e = categories[i];
          final isSelected = selected == e;
          return ChoiceChip(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            label: Text(e),
            selected: isSelected,
            onSelected: (_) => onSelect(e),
            selectedColor: const Color.fromRGBO(199, 244, 100, 1),
            backgroundColor: Colors.grey.shade200,
            labelStyle: const TextStyle(
              fontSize: 14,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide.none,
            ),
            showCheckmark: false,
            labelPadding: const EdgeInsets.symmetric(horizontal: 10),
          );
        },
      ),
    );
  }
}
