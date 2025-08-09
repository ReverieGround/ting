// lib/pages/profile/status.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firestore update
import 'package:firebase_auth/firebase_auth.dart'; // For FirebaseAuth

class StatusWidget extends StatefulWidget {
  final String initialMessage;
  // isEditable property from previous iteration is implied by existence of onSave,
  // and we'll use userId == null check in profile_page for editability logic.
  final Function(String) onSave; // Callback when message is saved

  const StatusWidget({
    super.key,
    required this.initialMessage,
    required this.onSave, // onSave is always required for potential updates
  });

  @override
  State<StatusWidget> createState() => _StatusWidgetState();
}

class _StatusWidgetState extends State<StatusWidget> {
  late TextEditingController _controller;
  bool _isEditing = false;
  bool _isSaving = false; // Renamed to avoid conflict with ProfilePage's isSaving

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialMessage);
  }

  @override
  void didUpdateWidget(covariant StatusWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controller text if initialMessage changes from outside
    if (widget.initialMessage != oldWidget.initialMessage) {
      _controller.text = widget.initialMessage;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Handle saving the status message to Firestore
  Future<void> _handleSave() async {
    final String newMessage = _controller.text.trim();

    // Only save if the message has actually changed
    if (newMessage == widget.initialMessage.trim() && newMessage.isNotEmpty) {
      // No change and not empty, just exit editing mode
      setState(() {
        _isEditing = false;
        _isSaving = false;
      });
      return;
    }

    // Call the parent's onSave callback for external logic (e.g., ProfilePage state update)
    widget.onSave(newMessage);

    // This widget now handles its own Firestore update as well
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint("❌ 로그인된 사용자 없음 (StatusWidget)");
      return;
    }

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'status_message': newMessage});

      debugPrint("✅ Firestore에 상태 메시지 저장 완료 (StatusWidget)");

      setState(() {
        _isSaving = false;
        _isEditing = false;
      });
      FocusScope.of(context).unfocus(); // Dismiss keyboard
    } catch (e) {
      debugPrint("❌ Firestore 상태 메시지 저장 실패 (StatusWidget): $e");
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine if the status message should be editable based on the current user
    // This assumes ProfilePage passes a `widget.userId == null` check to StatusWidget's constructor
    // Or, you can pass `isEditable` explicitly from ProfilePage.
    // For now, let's assume this widget is always editable if `onSave` is provided.
    final bool canEdit = widget.onSave != null; // Simplified, assuming onSave being present means it's editable

    return GestureDetector(
      onTap: canEdit && !_isEditing ? () => setState(() => _isEditing = true) : null,
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 0, bottom: 0), // Match image padding
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center, // Vertically center content
          children: [
            // ✅ Left two circles
            Container(
              alignment: Alignment.center, // Center small circle
              height: 30, // To align with the input field's height
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255,245,245,245),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 2),
            Container(
              alignment: Alignment.center, // Center larger circle
              height: 30, // To align with the input field's height
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255,245,245,245),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 7),

            // ✅ Message Input/Display Area
            Expanded(
              child: Container(
                height: 30, // Fixed height as per image
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Color.fromARGB(255,245,245,245),
                  borderRadius: BorderRadius.circular(10), // Rounded corners
                ),
                child: _isEditing
                    ? TextField(
                        controller: _controller,
                        autofocus: true, // Auto-focus when editing starts
                        onTapOutside: (event) { // New: Close editing on tap outside
                          if (_isEditing) {
                            _handleSave(); // Attempt to save when tapping outside
                          }
                        },
                        onSubmitted: (value) => _handleSave(), // Save on keyboard submit
                        maxLines: 1, // Single line input as per image
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero, // Minimal padding
                          border: InputBorder.none, // No border
                          hintText: '상태 메시지', // Hint text from image
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
                    : Align(
                        alignment: Alignment.centerLeft, // Align text to left
                        child: Text(
                          widget.initialMessage.isNotEmpty ? widget.initialMessage : '상태 메시지', // Default to hint text if empty
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: widget.initialMessage.isNotEmpty
                                ? Colors.black
                                : const Color.fromARGB(255, 147, 147, 147), // Hint text color
                            fontWeight: FontWeight.w400,
                            fontStyle: widget.initialMessage.isNotEmpty ? FontStyle.normal : FontStyle.normal, // No italic for hint
                          ),
                        ),
                      ),
              ),
            ),
            // Removed explicit edit/save buttons as per image
            // Editing now starts on tap, and saves on unfocus/submit
            // if (_isSaving)
            //   const Padding(
            //     padding: EdgeInsets.only(left: 8, right: 2),
            //     child: SizedBox(
            //       width: 15,
            //       height: 15,
            //       child: CircularProgressIndicator(
            //         color: Colors.black,
            //         strokeWidth: 2,
            //       ),
            //     ),
            //   )
            // else if (_isEditing)
            //   IconButton(
            //     icon: const Icon(Icons.check),
            //     onPressed: _handleSave,
            //     tooltip: "저장",
            //   )
            // else if (canEdit) // Only show edit icon if it's editable and not editing
            //   IconButton(
            //     icon: const Icon(Icons.edit, size: 18),
            //     onPressed: () {
            //       setState(() {
            //         _isEditing = true;
            //         _controller.text = widget.initialMessage; // Ensure correct initial text
            //       });
            //     },
            //     tooltip: "수정",
            //   ),
          ],
        ),
      ),
    );
  }
}