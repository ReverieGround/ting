// widgets/RecommendRecipeToggle.dart
import 'package:flutter/material.dart';

class RecommendRecipeToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const RecommendRecipeToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onChanged(!value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.thumb_up, size: 14, color: value ? Colors.amber : Colors.black54),
                const SizedBox(width: 4),
                const Text(
                  '이 레시피 추천',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
