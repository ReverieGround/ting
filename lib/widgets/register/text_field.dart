import 'package:flutter/material.dart';

class RegisterTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator; // ✅ 추가: 검증 함수

  const RegisterTextField({
    Key? key,
    required this.controller,
    required this.label,
    this.icon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator, // ✅ 추가
  }) : super(key: key);

  @override
  _RegisterTextFieldState createState() => _RegisterTextFieldState();
}

class _RegisterTextFieldState extends State<RegisterTextField> {
  String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          cursorColor: Colors.black,
          style: TextStyle(height: 1.2), // ✅ 텍스트 높이 조절
          controller: widget.controller,
          obscureText: widget.isPassword,
          keyboardType: widget.keyboardType,
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.white,
            prefixIcon: widget.icon != null ? Icon(widget.icon, color: Colors.black) : null,
            floatingLabelBehavior: FloatingLabelBehavior.never,
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 2.0),
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
            errorText: errorText, // ✅ 오류 메시지 표시
          ),
          onChanged: (value) {
            if (widget.validator != null) {
              setState(() {
                errorText = widget.validator!(value);
              });
            }
          },
        ),
        if (errorText != null) SizedBox(height: 8),
      ],
    );
  }
}
