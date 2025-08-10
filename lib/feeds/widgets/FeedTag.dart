// feeds/widgets/FeedTag.dart 
import 'package:flutter/material.dart';

final Map<String, String> assetMap = {
  'Fire': 'assets/fire.png',
  'Tasty': 'assets/tasty.png',
  'Soso': 'assets/soso.png',
  'Woops': 'assets/woops.png',
  'Wack': 'assets/wack.png',
};

class FeedTag extends StatelessWidget {
  final String? label; // 텍스트 라벨

  final Color backgroundColor; // 태그 배경색
  final Color textColor; // 태그 텍스트 색상
  final double fontSize; // 태그 폰트 크기 (아이콘 크기에도 사용)
  final FontWeight fontWeight; // 태그 폰트 굵기
  final double horizontalPadding; // 좌우 패딩
  final double verticalPadding; // 상하 패딩
  final double borderRadius; // 모서리 둥글기

  const FeedTag({
    Key? key,
    required this.label, // 라벨은 필수
    this.backgroundColor = const Color.fromRGBO(255, 255, 255, 0.8),
    this.textColor = Colors.black,
    this.fontSize = 14,
    this.fontWeight = FontWeight.w500,
    this.horizontalPadding = 10,
    this.verticalPadding = 4,
    this.borderRadius = 16,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (label == null){
      return SizedBox.shrink();
    }
    if (label == ''){
      return SizedBox.shrink();
    }
    // label에 해당하는 이미지 에셋 경로를 assetMap에서 찾습니다.
    final String? iconAssetPath = assetMap[label]; // 'label' 변수 사용

    // 아이콘과 텍스트를 포함할 Row 위젯
    final Widget labelContent = Row(
      mainAxisSize: MainAxisSize.min, // Row의 크기를 자식 위젯에 맞춥니다.
      children: [
        // iconAssetPath가 null이 아닐 때만 Image.asset을 표시합니다.
        if (iconAssetPath != null) ...[
          Image.asset(
            iconAssetPath,
            height: fontSize * 1.2, // 폰트 크기와 동일하게 아이콘 크기 설정
            width: fontSize * 1.2, // 폰트 크기와 동일하게 아이콘 크기 설정
          ),
          const SizedBox(width: 4), // 아이콘과 텍스트 사이 간격
        ],
        Text(
          label!,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: fontWeight,
          ),
        ),
      ],
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: labelContent,
    );
  }
}