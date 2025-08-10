import 'package:flutter/material.dart';
import 'create/CreatePostPage.dart';
import 'login/LoginPage.dart';
import 'profile/ProfilePage.dart';

/// 액션 버튼 타입 정의
enum VibeHeaderNavType {
  createPost,
  profilePage,
  loginPage,
  none, 
}

/// AppBar 대체 커스텀 헤더
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final Widget titleWidget;
  final bool showBackButton;
  final VibeHeaderNavType? navigateType; // nullable
  final Function? headerCallback; 
  final Color backgroundColor;
  final Color leadingColor;
  final bool centerTitle;
  const AppHeader ({
    super.key,
    required this.titleWidget,
    this.navigateType,
    this.showBackButton = true,
    this.headerCallback, 
    this.backgroundColor = Colors.white,
    this.leadingColor = Colors.black,
    this.centerTitle = false,
  });

  /// 액션 아이콘 반환
  IconData? _iconFor(VibeHeaderNavType type) {
    switch (type) {
      case VibeHeaderNavType.createPost:
        return Icons.local_dining_rounded; // camera_alt_rounded;
      case VibeHeaderNavType.profilePage:
        return Icons.person_rounded;
      case VibeHeaderNavType.loginPage:
        return Icons.login_rounded;
      case VibeHeaderNavType.none:
        return null;
    }
  }

  /// 이동 대상 위젯 반환
  Widget? _buildPageForNavigation() {
    switch (navigateType) {
      case VibeHeaderNavType.createPost:
        return const CreatePostPage();
      case VibeHeaderNavType.profilePage:
        return const ProfilePage();
      case VibeHeaderNavType.loginPage:
        return const LoginPage();
      case VibeHeaderNavType.none:
        return null;
      case null:
        return const SizedBox.shrink(); // 아무것도 안 함
    }
  }

  /// 액션 버튼 클릭 시 이동 처리
  Future<void> _navigate(BuildContext context) async {
    if (navigateType == null) return;
    final page = _buildPageForNavigation();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page!),
    );
    if (result == true && headerCallback != null) {
      headerCallback!(); // ✅ 이렇게 함수처럼 호출해야 실행됨!
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      leadingWidth: 20,           // ← leading 영역 너비 제거
      titleSpacing: 0,           // ← title 왼쪽 패딩 제거
      backgroundColor: this.backgroundColor,
      automaticallyImplyLeading: false,
      leading: showBackButton
          ? IconButton(
              iconSize: 20,
              icon: Icon(
                Icons.arrow_back_ios, color: this.leadingColor
               ),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      title: this.centerTitle ? titleWidget :Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: titleWidget,
      ),
      centerTitle: this.centerTitle,
      actions: (navigateType != null)
          ? [
              Container(
                // margin: const EdgeInsets.only(right: 8),
                width: 50,
                height: 40,
                decoration: BoxDecoration(
                  color: this.backgroundColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  border: const Border(
                    top: BorderSide(color: Colors.black, width: 0.5),
                    left: BorderSide(color: Colors.black, width: 0.5),
                    bottom: BorderSide(color: Colors.black, width: 0.5),
                    right: BorderSide.none, // ✅ 오른쪽 테두리 제거
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    _iconFor(navigateType!),
                    color: Colors.black54,
                    size: 26,
                  ),
                  onPressed: () => _navigate(context),
                ),
              ),
            ]
          : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
