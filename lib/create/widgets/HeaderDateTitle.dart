// widgets/HeaderDateTitle.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HeaderDateTitle extends StatelessWidget {
  final String capturedDate;
  final VoidCallback onTap;

  const HeaderDateTitle({
    super.key,
    required this.capturedDate,
    required this.onTap,
  });

  String _dateOnly(String input) {
    try {
      final dt = DateFormat('yyyy. MM. dd HH:mm').parse(input);
      return DateFormat('yyyy. MM. dd').format(dt);
    } catch (_) {
      return input.split(' ').take(2).join(' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(
            left: 0,
            child: Icon(Icons.calendar_today, size: 18, color: Color.fromRGBO(255, 110, 199, 1)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _dateOnly(capturedDate),
              style: const TextStyle(fontSize: 16, color: Colors.black, letterSpacing: -0.5),
            ),
          ),
        ],
      ),
    );
  }
}
