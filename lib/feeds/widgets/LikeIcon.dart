// feeds/widgets/LikeIcon.dart 
import 'package:flutter/material.dart';
import '../../services/PostService.dart'; 

// 숫자 단위 축약 함수 (변동 없음)
String formatNumber(int count) {
  if (count < 1000) {
    return count.toString();
  } else if (count < 1000000) {
    double result = count / 1000.0;
    return '${result.toStringAsFixed(result.truncateToDouble() == result ? 0 : 1)}k';
  } else {
    double result = count / 1000000.0;
    return '${result.toStringAsFixed(result.truncateToDouble() == result ? 0 : 1)}m';
  }
}

class LikeIcon extends StatefulWidget {
  final String postId;
  final String userId;
  final int initialLikeCount;
  final bool hasLiked;
  final Function(int newLikeCount, bool newIsLiked)? onToggleCompleted;
  final double fontSize;
  final double iconSize;
  final Color fontColor;

  const LikeIcon({
    super.key,
    required this.postId,
    required this.userId,
    required this.initialLikeCount,
    required this.hasLiked,
    this.onToggleCompleted,
    this.fontSize = 14.0,
    this.iconSize = 20.0,
    this.fontColor = Colors.black,
  });

  @override
  State<LikeIcon> createState() => _LikeWidgetState();
}

class _LikeWidgetState extends State<LikeIcon> {
  late int _currentLikeCount;
  late bool _currentHasLiked; 
  bool _isToggling = false;

  // PostService 인스턴스 생성
  final PostService _postService = PostService(); 

  @override
  void initState() {
    super.initState();
    _currentLikeCount = widget.initialLikeCount;
    _currentHasLiked = widget.hasLiked;
  }

  @override
  void didUpdateWidget(covariant LikeIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 좋아요 수와 좋아요 여부가 외부에서 변경될 때만 업데이트
    if (widget.initialLikeCount != oldWidget.initialLikeCount) {
      _currentLikeCount = widget.initialLikeCount;
    }
    if (widget.hasLiked != oldWidget.hasLiked) {
      _currentHasLiked = widget.hasLiked;
    }
  }

  Future<void> _toggleLike() async {
    if (widget.userId == _postService.getCurrentUserId()) return;
    if (_isToggling) return;
    
    setState(() {
      _isToggling = true;
    });

    // UI를 먼저 업데이트하여 즉각적인 피드백 제공
    final bool optimisticNewHasLiked = !_currentHasLiked;
    final int optimisticNewLikeCount = optimisticNewHasLiked ? _currentLikeCount + 1 : _currentLikeCount - 1;

    setState(() {
      _currentHasLiked = optimisticNewHasLiked;
      _currentLikeCount = optimisticNewLikeCount;
    });

    try {
      await _postService.toggleLike(
        postId: widget.postId,
        userId: widget.userId,
        isCurrentlyLiked: !optimisticNewHasLiked, // PostService는 현재 상태의 반대를 토글하므로
      );

      // Firestore 업데이트 성공 후, 부모 위젯에 변경된 상태 알림
      widget.onToggleCompleted?.call(_currentLikeCount, _currentHasLiked);
      debugPrint("✅ 좋아요 토글 성공 (Firestore 반영)");

    } catch (e) {
      debugPrint("❌ 좋아요 토글 중 오류: $e");
      // 오류 발생 시 UI 롤백
      if (mounted) {
        setState(() {
          _currentHasLiked = !optimisticNewHasLiked; // 원래 상태로 롤백
          _currentLikeCount = !optimisticNewHasLiked ? _currentLikeCount - 1 : _currentLikeCount + 1; // 원래 좋아요 수로 롤백
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('좋아요 토글 실패: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isToggling = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isToggling ? null : _toggleLike,
      child: Container(
        padding: EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Color.fromARGB(100, 255, 255, 255),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.black,
            width: 0.5,
          ),
        ),
        child: Icon(
          Icons.favorite,
          size: widget.iconSize,
          color: _currentHasLiked ? Colors.redAccent : Colors.black38,
        ),
      ),
    );
  }
}