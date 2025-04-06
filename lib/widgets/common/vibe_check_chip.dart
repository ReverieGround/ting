import 'package:flutter/material.dart';

class VibeCheckChip extends StatelessWidget {
  final String label;
  final VoidCallback? onDeleted;

  const VibeCheckChip({
    super.key,
    required this.label,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      backgroundColor: Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      deleteIcon: onDeleted != null ? const Icon(Icons.close) : null,
      onDeleted: onDeleted,
    );
  }
}
