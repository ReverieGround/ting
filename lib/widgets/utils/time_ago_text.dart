import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimeAgoText extends StatelessWidget {
  final String? createdAt;
  final double? fontSize; // ✅ 폰트 크기 (선택적)
  final Color? fontColor; // ✅ 폰트 색상 (선택적)

  const TimeAgoText({
    super.key,
    required this.createdAt,
    this.fontSize = 12.0, // ✅ 기본값 설정
    this.fontColor = Colors.grey, // ✅ 기본값 설정
  });

  /// ✅ "몇 시간 전" 또는 "yyyy년 MM월 dd일"로 변환
  String timeAgo(DateTime date) {
    final Duration difference = DateTime.now().difference(date);

    if (difference.inDays < 1) {
      if (difference.inHours < 1) {
        return "${difference.inMinutes}분 전";
      }
      return "${difference.inHours}시간 전";
    } else if (difference.inDays < 30) {
      return "${difference.inDays}일 전";
    } else {
      return DateFormat('yyyy년 MM월 dd일').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    
    String relativeCreatedAt = '';
    if (createdAt != null){
      DateTime formattedCreatedAt;
      try {
        // 🔥 Firestore에서 ISO 8601 or GMT 형식으로 저장된 문자열 변환
        formattedCreatedAt = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'").parseUtc(createdAt!).toLocal();
      } catch (e) {
        formattedCreatedAt = DateTime.now(); // 변환 실패 시 현재 시간 사용
      }
      relativeCreatedAt = timeAgo(formattedCreatedAt);
    }


    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5),
      child: Text(
        relativeCreatedAt,
        style: TextStyle(
          fontSize: fontSize, // ✅ 커스텀 폰트 크기 적용
          color: fontColor, // ✅ 커스텀 색상 적용
        ),
      ),
    );
  }
}
