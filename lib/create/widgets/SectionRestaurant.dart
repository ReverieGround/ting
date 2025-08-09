// widgets/SectionRestaurant.dart
import 'package:flutter/material.dart';
import 'LinkInputRow.dart';

class SectionRestaurant extends StatelessWidget {
  final String value;
  final ValueChanged<String> onSubmitted;

  const SectionRestaurant({
    super.key,
    required this.value,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LinkInputRow(
        initialText: value,
        hint: '식당명을 검색해 보세요',
        trailingAsset: 'assets/search.png',
        onSubmitted: onSubmitted,
      ),
    );
  }
}
