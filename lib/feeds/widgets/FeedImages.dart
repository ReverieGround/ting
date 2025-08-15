// feeds/widgets/FeedImages.dart
import 'package:flutter/material.dart';
import 'FeedTag.dart';

class FeedImages extends StatefulWidget {
  final List<dynamic> imageUrls;
  final String category;
  final String value;
  final String? recipeId;
  final String? recipeTitle;
  final VoidCallback? onRecipeButtonPressed;
  final bool showTags;

  // 높이 제어
  final double? height;        // 고정 높이(지정 시 우선)
  final double? maxHeight;     // 자동 계산 시 최대 높이
  final double aspectRatio;    // 자동 계산용 가로:세로 비율
  final BoxFit fit;            // BoxFit.contain => 크롭 없음

  const FeedImages({
    Key? key,
    required this.imageUrls,
    required this.category,
    required this.value,
    this.recipeId,
    this.recipeTitle,
    this.onRecipeButtonPressed,
    this.showTags = true,
    this.height,                 // null이면 자동 계산
    this.maxHeight = 350,              // null이면 제한 없음
    this.aspectRatio = 4 / 3,    // 기본 비율
    this.fit = BoxFit.cover,     // 필요 시 BoxFit.contain
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
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : MediaQuery.of(context).size.width;
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

        return SizedBox(
          height: effectiveHeight,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: widget.imageUrls.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(0),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.black, // contain일 때 레터박스 배경
                      child: Image.network(
                        widget.imageUrls[index],
                        fit: widget.fit, // cover/contain 선택
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  );
                },
              ),

              if (widget.showTags)
                Positioned(
                  top: 6,
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
                          // margin: const EdgeInsets.symmetric(horizontal: 2),
                          height: 5,
                          decoration: BoxDecoration(
                            color: isActive ? Color.fromRGBO(255, 110, 199, 1) : Colors.white30,
                            // borderRadius: BorderRadius.circular(3),
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
