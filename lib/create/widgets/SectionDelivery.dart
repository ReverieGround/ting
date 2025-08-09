// widgets/SectionDelivery.dart
import 'package:flutter/material.dart';
import 'LinkInputRow.dart';

class SectionDelivery extends StatelessWidget {
  final String value;
  final ValueChanged<String> onSubmitted;

  const SectionDelivery({
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
        hint: '배달음식점 링크를 공유해 보세요',
        trailingAsset: 'assets/link.png',
        onSubmitted: onSubmitted,
      ),
    );
  }
}
