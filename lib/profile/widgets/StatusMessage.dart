// lib/pages/profile/status.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:characters/characters.dart';

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
  final bool readOnly;

  const StatusMessage({
    super.key,
    required this.initialMessage,
    required this.onSave,
    this.readOnly=true,
  });

  @override
  State<StatusMessage> createState() => _StatusWidgetState();
}

class _StatusWidgetState extends State<StatusMessage> {
  static const int _maxChars = 100;
  static const int _collapsedLines = 2;

  late TextEditingController _controller;
  late final VoidCallback _ctrlListener;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialMessage);
    _ctrlListener = () { if (mounted && _isEditing) setState(() {}); };
    _controller.addListener(_ctrlListener);
  }

  @override
  void didUpdateWidget(covariant StatusMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialMessage != oldWidget.initialMessage && !_isEditing) {
      _controller.text = widget.initialMessage;
      _expanded = false; // 내용 바뀌면 접기
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_ctrlListener);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (widget.readOnly) { // 읽기 전용이면 저장 시도 안 함
      setState(() { _isEditing = false; _isSaving = false; });
      FocusManager.instance.primaryFocus?.unfocus();
      return;
    }
    final raw = _controller.text.trim();
    final newMessage = raw.length > _maxChars ? raw.substring(0, _maxChars) : raw;

    if (newMessage == widget.initialMessage.trim()) {
      setState(() {
        _isEditing = false;
        _isSaving = false;
      });
      FocusManager.instance.primaryFocus?.unfocus();
      return;
    }

    setState(() => _isSaving = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isSaving = false);
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'status_message': newMessage});

      widget.onSave(newMessage);

      setState(() {
        _isSaving = false;
        _isEditing = false;
        _expanded = false;
      });
      FocusManager.instance.primaryFocus?.unfocus();
    } catch (e) {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bubbleBg = Color.fromARGB(255, 245, 245, 245);
    const tailW = 10.0;
    const tailH = 15.0;
    const tailTop = 0.0;

    return GestureDetector(
      onTap: (!widget.readOnly && !_isEditing) ? () => setState(() => _isEditing = true) : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: CustomPaint(
                painter: _BubbleShapePainter(
                  bubbleColor: bubbleBg,
                  borderRadius: 10,
                  tailWidth: tailW,
                  tailHeight: tailH,
                  tailOffsetFromTop: tailTop,
                ),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12 + tailW, 6, 12, 6),
                  constraints: const BoxConstraints(minHeight: 30),
                  alignment: Alignment.centerLeft,
                  child: (_isEditing && !widget.readOnly)
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _controller,
                              autofocus: true,
                              inputFormatters: [LengthLimitingTextInputFormatter(_maxChars)],
                              onTapOutside: (_) => _handleSave(),
                              onSubmitted: (_) => _handleSave(),
                              maxLines: 1,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                                hintText: '상태 메시지',
                                hintStyle: TextStyle(
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
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (_isSaving)
                                  const SizedBox(
                                    width: 16, height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                else
                                  Text(
                                    '${_controller.text.characters.length}/$_maxChars',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF999999),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        )
                      : Stack(
                          children: [
                            Text(
                              widget.initialMessage.isNotEmpty
                                  ? widget.initialMessage
                                  : '상태 메시지',
                              maxLines: _expanded ? null : _collapsedLines,
                              overflow: _expanded
                                  ? TextOverflow.visible
                                  : TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: widget.initialMessage.isNotEmpty
                                    ? Colors.black
                                    : const Color.fromARGB(255, 147, 147, 147),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            if ((widget.initialMessage).trim().length > 30)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: GestureDetector(
                                  onTap: () => setState(() => _expanded = !_expanded),
                                  child: Text(
                                    _expanded ? '접기' : '더보기',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF556EE6),
                                      backgroundColor: bubbleBg,
                                    ),
                                  ),
                                ),
                              ),
                          ],
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
