// feeds/widgets/Tag.dart 
import 'package:flutter/material.dart';

final Map<String, String> assetMap = {
  'Fire': 'assets/fire.png',
  'Tasty': 'assets/tasty.png',
  'Soso': 'assets/soso.png',
  'Woops': 'assets/woops.png',
  'Wack': 'assets/wack.png',
};

class Tag extends StatelessWidget {
  final String? label;
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;
  final FontWeight fontWeight;
  final double horizontalPadding;
  final double verticalPadding;
  final double borderRadius;

  const Tag({
    Key? key,
    required this.label,
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
    final String? iconAssetPath = assetMap[label]; 

    final Widget labelContent = Row(
      mainAxisSize: MainAxisSize.min, 
      children: [
        if (iconAssetPath != null) ...[
          Image.asset(
            iconAssetPath,
            height: fontSize * 1.2, 
            width: fontSize * 1.2, 
          ),
          const SizedBox(width: 4), 
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
        border: Border.all(
          color: Colors.black,
          width: 0.5,
        ),
      ),
      child: labelContent,
    );
  }
}