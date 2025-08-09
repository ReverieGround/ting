// lib/pages/profile/status.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


// ✅ Custom Painter for the bubble shape (다시 포함)
class _BubbleShapePainter extends CustomPainter {
  final Color bubbleColor;
  final double borderRadius;
  final double tailWidth;
  final double tailHeight; // Height of the tail along the bubble's side
  final double tailOffsetFromTop; // Y-offset from top of the bubble for the tail's top connection

  _BubbleShapePainter({
    required this.bubbleColor,
    this.borderRadius = 10.0,
    this.tailWidth = 10.0, // How much the tail sticks out horizontally
    this.tailHeight = 10.0, // Vertical extent of the tail's base on the bubble body
    this.tailOffsetFromTop = 10.0, // Y-coordinate of the tail's top connection point
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = bubbleColor;
    final Path path = Path();

    // The main body of the rounded rectangle starts after the tail's horizontal extent.
    final double bodyStartX = tailWidth;
    final double bodyEndX = size.width;
    final double bodyTopY = 0;
    final double bodyBottomY = size.height;

    // 1. Start drawing from the top-left corner of the main body (after the tail)
    // This ensures the top-left corner is rounded.
    path.moveTo(bodyStartX + borderRadius, bodyTopY);

    // 2. Draw top line
    path.lineTo(bodyEndX - borderRadius, bodyTopY);

    // 3. Draw top-right arc
    path.arcToPoint(
      Offset(bodyEndX, bodyTopY + borderRadius),
      radius: Radius.circular(borderRadius),
      clockwise: true,
    );

    // 4. Draw right line
    path.lineTo(bodyEndX, bodyBottomY - borderRadius);

    // 5. Draw bottom-right arc
    path.arcToPoint(
      Offset(bodyEndX - borderRadius, bodyBottomY),
      radius: Radius.circular(borderRadius),
      clockwise: true,
    );

    // 6. Draw bottom line
    path.lineTo(bodyStartX + borderRadius, bodyBottomY);

    // 7. Draw bottom-left arc
    path.arcToPoint(
      Offset(bodyStartX, bodyBottomY - borderRadius),
      radius: Radius.circular(borderRadius),
      clockwise: true,
    );

    // 8. Draw the left line of the main body up to the tail's bottom connection point
    path.lineTo(bodyStartX, bodyTopY + tailOffsetFromTop + tailHeight);

    // 9. Draw the tail itself
    // Connect to the tip of the tail (which is at x=0)
    path.lineTo(0, bodyTopY + tailOffsetFromTop ); // Tip of the tail

    // Connect to the top point of the tail on the body
    path.lineTo(bodyStartX, bodyTopY + tailOffsetFromTop);

    // 10. Close the path back to the starting point (top-left rounded corner)
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // Only repaint if properties change, otherwise it's efficient
    return oldDelegate is _BubbleShapePainter &&
        (oldDelegate.bubbleColor != bubbleColor ||
            oldDelegate.borderRadius != borderRadius ||
            oldDelegate.tailWidth != tailWidth ||
            oldDelegate.tailHeight != tailHeight ||
            oldDelegate.tailOffsetFromTop != tailOffsetFromTop);
  }
}


class StatusMessage extends StatefulWidget {
  final String initialMessage;
  final Function(String) onSave;

  const StatusMessage({
    super.key,
    required this.initialMessage,
    required this.onSave,
  });

  @override
  State<StatusMessage> createState() => _StatusWidgetState();
}

class _StatusWidgetState extends State<StatusMessage> {
  late TextEditingController _controller;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialMessage);
  }

  @override
  void didUpdateWidget(covariant StatusMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialMessage != oldWidget.initialMessage) {
      if (!_isEditing) {
        _controller.text = widget.initialMessage;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final String newMessage = _controller.text.trim();

    if (newMessage == widget.initialMessage.trim() && newMessage.isNotEmpty) {
      setState(() {
        _isEditing = false;
        _isSaving = false;
      });
      FocusScope.of(context).unfocus();
      return;
    }

    if (newMessage.isEmpty && widget.initialMessage.trim().isEmpty) {
        setState(() {
            _isEditing = false;
            _isSaving = false;
        });
        FocusScope.of(context).unfocus();
        return;
    }


    setState(() => _isSaving = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint("❌ 로그인된 사용자 없음 (StatusMessage)");
      setState(() => _isSaving = false);
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'status_message': newMessage});

      debugPrint("✅ Firestore에 상태 메시지 저장 완료 (StatusMessage)");
      widget.onSave(newMessage);

      setState(() {
        _isSaving = false;
        _isEditing = false;
      });
      FocusScope.of(context).unfocus();
    } catch (e) {
      debugPrint("❌ Firestore 상태 메시지 저장 실패 (StatusMessage): $e");
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canEdit = widget.onSave != null;
    const Color bubbleBackgroundColor = Color.fromARGB(255, 245, 245, 245);
    
    // ✅ 추천 시작점
    const double tailWidth = 10.0;    // 꼬리가 많이 튀어나오지 않도록 줄임
    const double tailHeight = 15.0;  // 꼬리 밑변 높이
    const double tailOffsetFromTop = 0.0;   // 꼬리 수직 위치 (위쪽에서 8픽셀 아래)

    return GestureDetector(
      onTap: canEdit && !_isEditing
          ? () => setState(() {
                _isEditing = true;
              })
          : null,
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 0, bottom: 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ✅ 기존의 두 개의 Container(원) 제거됨

            // ✅ Message Input/Display Area with CustomPainter for the bubble shape
            Expanded(
              child: CustomPaint(
                painter: _BubbleShapePainter(
                  bubbleColor: bubbleBackgroundColor,
                  borderRadius: 10.0,
                  tailWidth: tailWidth,
                  tailHeight: tailHeight,
                  tailOffsetFromTop: tailOffsetFromTop,
                ),
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    12.0 + tailWidth, // Add tailWidth to left padding for content
                    6.0,
                    12.0,
                    6.0,
                  ),
                  constraints: const BoxConstraints(minHeight: 30),
                  alignment: Alignment.centerLeft,
                  child: _isEditing
                      ? TextField(
                          controller: _controller,
                          autofocus: true,
                          onTapOutside: (event) {
                            if (_isEditing) {
                              _handleSave();
                            }
                          },
                          onSubmitted: (value) => _handleSave(),
                          maxLines: 1,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            hintText: '상태 메시지',
                            hintStyle: const TextStyle(
                              fontSize: 14,
                              color: Color.fromARGB(255, 147, 147, 147),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF3E3E3E),
                            fontWeight: FontWeight.w400,
                          ),
                        )
                      : Text(
                          widget.initialMessage.isNotEmpty ? widget.initialMessage : '상태 메시지',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: widget.initialMessage.isNotEmpty
                                ? Colors.black
                                : const Color.fromARGB(255, 147, 147, 147),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}