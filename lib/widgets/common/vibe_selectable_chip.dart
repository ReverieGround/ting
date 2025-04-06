import 'package:flutter/material.dart';

class VibeSelectableChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const VibeSelectableChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = selected ? Color.fromARGB(255, 155, 155, 155) : Color.fromARGB(255, 246, 246, 246);
    final textColor = Colors.black;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check, size: 16, color: textColor),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 14, color: textColor)),
          ],
        ),
      ),
    );
  }
}
