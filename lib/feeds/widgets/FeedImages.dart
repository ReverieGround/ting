// feeds/widgets/FeedImages.dart
import 'package:flutter/material.dart';
import 'FeedTag.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FeedImages extends StatefulWidget {
  final List<dynamic> imageUrls;
  final String category;
  final String value;
  final String? recipeId;
  final String? recipeTitle;
  final VoidCallback? onRecipeButtonPressed;
  final bool showTags;

  final double? height;
  final double? maxHeight;
  final double aspectRatio;
  final BoxFit fit;

  const FeedImages({
    Key? key,
    required this.imageUrls,
    required this.category,
    required this.value,
    this.recipeId,
    this.recipeTitle,
    this.onRecipeButtonPressed,
    this.showTags = true,
    this.height,
    this.maxHeight = 350,
    this.aspectRatio = 4 / 3,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  State<FeedImages> createState() => _FeedImageCarouselState();
}

class _FeedImageCarouselState extends State<FeedImages> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  (int wPx, int hPx) _targetPx(double w, double h, double dpr) {
    final wi = (w * dpr).round().clamp(1, 4096);
    final hi = (h * dpr).round().clamp(1, 4096);
    return (wi, hi);
  }

  Widget _buildOverlayButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenW = MediaQuery.of(context).size.width;
        final dpr = MediaQuery.of(context).devicePixelRatio;
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : screenW;

        double effectiveHeight;
        if (widget.height != null) {
          effectiveHeight = widget.height!;
        } else {
          effectiveHeight = width / widget.aspectRatio;
          if (widget.maxHeight != null) {
            effectiveHeight = effectiveHeight > widget.maxHeight!
                ? widget.maxHeight!
                : effectiveHeight;
          }
        }

        final (wPx, hPx) = _targetPx(width, effectiveHeight, dpr);

        return SizedBox(
          height: effectiveHeight,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: widget.imageUrls.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  final url = widget.imageUrls[index] as String? ?? '';
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(0),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.black,
                      child: CachedNetworkImage(
                        imageUrl: url,
                        fit: widget.fit,
                        // 메모리 디코딩 크기 ↓
                        memCacheWidth: wPx,
                        memCacheHeight: hPx,
                        // 디스크에도 축소본 저장 ↓
                        maxWidthDiskCache: wPx,
                        maxHeightDiskCache: hPx,
                        fadeInDuration: Duration.zero,
                        placeholderFadeInDuration: Duration.zero,
                        progressIndicatorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white54),
                        useOldImageOnUrlChange: true,
                        alignment: Alignment.center,
                      ),
                    ),
                  );
                },
              ),

              if (widget.showTags)
                Positioned(
                  top: 10,
                  left: 6,
                  child: Row(
                    children: [
                      FeedTag(
                        label: widget.category,
                        backgroundColor: const Color.fromRGBO(255, 255, 255, 0.7),
                        textColor: Colors.black,
                        borderRadius: 16,
                        horizontalPadding: 10,
                      ),
                      const SizedBox(width: 5),
                      FeedTag(
                        label: widget.value,
                        backgroundColor: const Color.fromRGBO(255, 255, 255, 0.7),
                        textColor: Colors.black,
                        borderRadius: 16,
                        horizontalPadding: 10,
                      ),
                    ],
                  ),
                ),

              if (widget.category == '요리')
                Positioned(
                  bottom: 12,
                  right: 8,
                  child: (widget.recipeId != null && widget.recipeTitle != null)
                      ? _buildOverlayButton(
                          text: '> ${widget.recipeTitle}',
                          icon: Icons.restaurant_menu,
                          onPressed: widget.onRecipeButtonPressed ?? () {},
                        )
                      : _buildOverlayButton(
                          text: '레시피 요청',
                          icon: Icons.soup_kitchen,
                          onPressed: widget.onRecipeButtonPressed ?? () {},
                        ),
                ),

              if (widget.imageUrls.length > 1)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Row(
                    children: List.generate(widget.imageUrls.length, (index) {
                      final isActive = index == _currentPage;
                      return Expanded(
                        child: Container(
                          height: 5,
                          decoration: BoxDecoration(
                            color: isActive ? const Color.fromRGBO(255, 110, 199, 1) : Colors.white30,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
