// feeds/widgets/ReplyIcon.dart 
import 'package:flutter/material.dart';

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

class ReplyIcon extends StatefulWidget {
  final String postId;
  final int initialCommentCount;
  final Function(int newCommentCount)? onCommentPosted;

  final double fontSize;
  final double iconSize;

  final Color fontColor;

  const ReplyIcon({
    super.key,
    required this.postId,
    required this.initialCommentCount,
    this.onCommentPosted,
    this.fontSize = 14.0,
    this.iconSize = 20.0,
    this.fontColor = Colors.black,
  });

  @override
  State<ReplyIcon> createState() => _ReplyIconState();
}

class _ReplyIconState extends State<ReplyIcon> {
  late int _currentCommentCount;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentCommentCount = widget.initialCommentCount;
  }

  @override
  void didUpdateWidget(covariant ReplyIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCommentCount != oldWidget.initialCommentCount) {
      _currentCommentCount = widget.initialCommentCount;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String iconPath = 'assets/chat.png';

    return GestureDetector(
      // onTap: _isPostingComment ? null : () => _showCommentInputBottomSheet(context),
      onTap: null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(2.0),
            child: Image.asset(
              iconPath,
              width: widget.iconSize,
              height: widget.iconSize,
              color: widget.fontColor,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            formatNumber(_currentCommentCount),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: widget.fontSize,
              color: widget.fontColor,
            ),
            textHeightBehavior: const TextHeightBehavior(
              applyHeightToFirstAscent: false,
              applyHeightToLastDescent: false,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}