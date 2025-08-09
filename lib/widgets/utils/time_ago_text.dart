import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // DateFormat을 사용하기 위해 필요
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ Firestore 임포트

class TimeAgoText extends StatefulWidget {
  final dynamic createdAt; // Input is a String (e.g., "2025-07-10T01:42:55.181000+00:00")
  final double fontSize;
  final Color fontColor;

  const TimeAgoText({
    Key? key,
    required this.createdAt,
    this.fontSize = 12,
    this.fontColor = Colors.grey,
  }) : super(key: key);

  @override
  State<TimeAgoText> createState() => _TimeAgoTextState();
}

class _TimeAgoTextState extends State<TimeAgoText> {
  String _displayTime = ''; // This variable will store the formatted String to be displayed

  @override
  void initState() {
    super.initState();
    _updateDisplayTime();
  }

  @override
  void didUpdateWidget(covariant TimeAgoText oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update if createdAt string has changed
    if (oldWidget.createdAt != widget.createdAt) {
      _updateDisplayTime();
    }
  }

  void _updateDisplayTime() {
    DateTime? dateTime;

    try {
      // Step 1: Handle Timestamp directly. This is the preferred method.
      if (widget.createdAt is Timestamp) {
        dateTime = (widget.createdAt as Timestamp).toDate();
      } else if (widget.createdAt is String) {
        // Step 2: If the data is a String, use DateFormat to parse it.
        dateTime = DateFormat('yyyy. MM. dd HH:mm').parse(widget.createdAt);
        
      } else {
        throw Exception('날짜 형식이 올바르지 않습니다.');
      }

      if (dateTime != null) {
        _displayTime = _getTimeAgo(dateTime);
      } else {
        _displayTime = '날짜 오류';
      }
    } catch (e) {
      _displayTime = '날짜 오류';
    }

    if (mounted) {
      setState(() {});
    }
  }
  
  // Helper function to format time as "X ago" or "YYYY. MM. DD"
  String _getTimeAgo(DateTime dateTime) {
    final Duration diff = DateTime.now().difference(dateTime.toLocal()); // Convert to local time before calculating difference

    if (diff.inSeconds < 60) {
      return '방금 전';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}분 전';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}시간 전';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}일 전';
    } else if (diff.inDays < 30) {
      // Using floor() to get whole weeks
      return '${(diff.inDays / 7).floor()}주 전';
    } else if (diff.inDays < 365) {
      // Using floor() to get whole months
      return '${(diff.inDays / 30).floor()}개월 전';
    } else {
      // For more than a year, display full date
      return DateFormat('yyyy. MM. dd').format(dateTime.toLocal());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayTime, // Display the formatted string
      style: TextStyle(
        fontSize: widget.fontSize,
        color: widget.fontColor,
      ),
    );
  }
}