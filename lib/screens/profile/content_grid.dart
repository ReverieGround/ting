import 'package:flutter/material.dart';

class ContentGrid extends StatelessWidget {
  final String type;

  const ContentGrid({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 20,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemBuilder: (_, index) => Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(30, 60, 60, 60),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
