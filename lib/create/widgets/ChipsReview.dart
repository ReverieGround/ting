// widgets/ChipsReview.dart
import 'package:flutter/material.dart';

class ReviewChips extends StatelessWidget {
  final List<Map<String, String>> items;
  final String selected;
  final ValueChanged<String> onSelect;

  const ReviewChips({
    super.key,
    required this.items,
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
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final label = items[i]['label']!;
          final path = items[i]['image']!;
          final isSelected = selected == label;
          return ChoiceChip(
            label: Row(
              children: [
                Image.asset(path, width: 15, height: 15),
                const SizedBox(width: 4),
                Text(label, style: const TextStyle(color: Colors.black)),
              ],
            ),
            selected: isSelected,
            onSelected: (_) => onSelect(label),
            selectedColor: const Color.fromRGBO(199, 244, 100, 1),
            backgroundColor: Colors.grey.shade200,
            labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide.none),
            labelPadding: const EdgeInsets.symmetric(horizontal: 10),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            showCheckmark: false,
            padding: EdgeInsets.zero,
          );
        },
      ),
    );
  }
}
