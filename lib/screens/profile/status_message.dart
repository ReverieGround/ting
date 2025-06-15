import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StatusMessage extends StatefulWidget {
  final String message;
  final void Function(String)? onMessageUpdated; // UI 갱신용 콜백

  const StatusMessage({
    super.key,
    required this.message,
    this.onMessageUpdated,
  });

  @override
  State<StatusMessage> createState() => _StatusMessageState();
}

class _StatusMessageState extends State<StatusMessage> {
  bool isEditing = false;
  bool isSaving = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.message);
  }

  Future<void> _handleSave() async {
    final String newMessage = _controller.text.trim();

    if (newMessage == widget.message.trim()) {
      // 변경 없음 → 그냥 닫기
      setState(() {
        isEditing = false;
        isSaving = false;
      });
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint("❌ 로그인된 사용자 없음");
      return;
    }

    setState(() => isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'status_message': newMessage});

      debugPrint("✅ Firestore에 상태 메시지 저장 완료");

      if (widget.onMessageUpdated != null) {
        widget.onMessageUpdated!(newMessage);
      }

      setState(() {
        isSaving = false;
        isEditing = false;
      });
    } catch (e) {
      debugPrint("❌ Firestore 상태 메시지 저장 실패: $e");
      setState(() => isSaving = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 0, top: 0 , bottom: 0),
      child: Row(children: [
        // ✅ 왼쪽 동그라미 2개
        Container(
          height: 30,
          padding: EdgeInsets.zero,
          margin: EdgeInsets.zero,
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                // border: Border.all(
                //   color: Colors.black38,
                //   width: 0.5,
                // ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 2),
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            // border: Border.all(
            //   color: Colors.black38,
            //   width: 0.5,
            // ),
          ),
        ),
        const SizedBox(width: 7),

        // ✅ 메시지 영역
        Expanded(
          child: Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              // border: Border.all(
              //     color: Colors.black38,
              //     width: 0.5,
              //   ),
            ),
            child: isEditing
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: TextField(
                    controller: _controller,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF3E3E3E),
                      fontWeight: FontWeight.w400,
                    ),
                    cursorColor: const Color(0xFF3E3E3E),
                    cursorHeight: 14,
                    showCursor: true,
                    textAlignVertical: TextAlignVertical.center, // ✅ 핵심!
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 7), // ✅ 핵심 포인트!
                      fillColor: Colors.white,
                      border: InputBorder.none,
                      hintText: '상태 메시지를 입력하세요',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: Color.fromARGB(255, 147, 147, 147),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  )
                )
                : Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.message.isNotEmpty ? widget.message : "첫 상태 메시지를 입력하세요.",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: widget.message.isNotEmpty ? Colors.black : Color.fromARGB(255, 112, 112, 112),
                        fontWeight: FontWeight.w400,
                        fontStyle: widget.message.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                      ),
                    ),
                  ),
          ),
        ),

        // ✅ 버튼
        isEditing
            ? isSaving
                ? const Padding(
                    padding: EdgeInsets.only(left: 8, right: 2),
                    child: SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: _handleSave,
                    tooltip: "저장",
                  )
            : IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: () {
                  setState(() {
                    isEditing = true;
                    _controller.text = widget.message;
                  });
                },
                tooltip: "수정",
              ),
      ]),
    );
  }
}
