import 'package:flutter/material.dart';
import 'dart:io';

class ProfileAvatar extends StatelessWidget {
  final File? profileImage; // ✅ 사용자 프로필 (로컬 파일)
  final String? profileUrl; // ✅ 사용자 프로필 (네트워크 URL)
  final double size; // ✅ 동적으로 크기 조절 가능 (기본값: 40)

  const ProfileAvatar({Key? key, this.profileImage, this.profileUrl, this.size = 40}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, // ✅ 사이즈 조정 (원형 유지)
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle, // ✅ 원형 아바타
        color: Colors.white, // ✅ 배경색 설정
        border: Border.all(color: Colors.black, width: 0.5), // ✅ 검은색 테두리 추가
        image: DecorationImage(
          image: profileImage != null
              ? FileImage(profileImage!) // ✅ 로컬 파일
              : (profileUrl != null && profileUrl!.isNotEmpty)
                  ? NetworkImage(profileUrl!) // ✅ 네트워크 이미지
                  : AssetImage('assets/default_profile.png') as ImageProvider, // ✅ 기본 이미지
          fit: BoxFit.cover, // ✅ 원형 아바타 꽉 채우기
        ),
      ),
    );
  }
}
