// widgets/PostTextField.dart
import 'package:flutter/material.dart';

class PostTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const PostTextField({
    super.key,
    required this.controller,
    this.hint = '내용을 입력하세요',
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 4,
      onSubmitted: (_) => FocusScope.of(context).unfocus(), // ✅ 엔터 누르면 키보드 닫힘
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        fillColor: Colors.grey.shade100,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
