import 'package:flutter/material.dart';
import 'FeedTag.dart';

class FeedImages extends StatefulWidget {
  final List<dynamic> imageUrls;
  final String category;
  final String value;
  final String? recipeId;
  final String? recipeTitle;
  final VoidCallback? onRecipeButtonPressed;

  const FeedImages({ 
    Key? key,
    required this.imageUrls,
    required this.category,
    required this.value,
    this.recipeId,
    this.recipeTitle,
    this.onRecipeButtonPressed,
  }) : super(key: key);

  @override
  State<FeedImages> createState() => _FeedImageCarouselState(); 
}

class _FeedImageCarouselState extends State<FeedImages> { 
  final PageController _pageController = PageController();
  int _currentPage = 0;

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
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return SizedBox.shrink();
    }

    return SizedBox(
      height: 350,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              return ClipRRect(
                child: Image.network(
                  widget.imageUrls[index],
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Row(
              children: [
                
                FeedTag(
                  label: widget.category,
                  backgroundColor: Color.fromRGBO(255, 255, 255, 0.7),
                  textColor: Colors.black,
                  borderRadius: 16,
                  horizontalPadding: 10,
                ),
                SizedBox(width: 5),
                FeedTag(
                  label: widget.value,
                  backgroundColor: Color.fromRGBO(255, 255, 255, 0.7),
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
                  bool isActive = index == _currentPage;
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: 3,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.white : Colors.white30,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}