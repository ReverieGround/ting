// widgets/ImageCarousel.dart
import 'dart:io';
import 'package:flutter/material.dart';

class ImageCarousel extends StatelessWidget {
  final PageController pageController;
  final List<File> images;
  final VoidCallback onTap;

  const ImageCarousel({
    super.key,
    required this.pageController,
    required this.images,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pageController,
      builder: (_, __) {
        double scale = 1.0;
        if (pageController.position.haveDimensions) {
          final page = pageController.page ?? 0.0;
          final delta = (page - (pageController.positions.isNotEmpty ? page : 0)).abs();
          scale = (1 - (delta * 0.2)).clamp(0.8, 1.0);
        }
        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              height: 220,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: images.isEmpty
                  ? const Center(
                      child: Icon(Icons.add_a_photo, size: 40, color: Colors.white),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: images.length == 1
                          ? Image.file(
                              images.first,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: images.length,
                              itemBuilder: (_, i) => Image.file(
                                images[i],
                                width: 220,
                                fit: BoxFit.cover,
                              ),
                            ),
                    ),
            ),
          ),
        );
      },
    );
  }
}
