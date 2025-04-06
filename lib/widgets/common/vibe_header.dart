import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../screens/create_post_page.dart';
import '../../screens/register_page.dart';
import '../../screens/profile/profile_page.dart';
import '../../screens/recipe/recipe_register_page.dart';
import '../../screens/recipe/recipe_form_provider.dart';
import '../../screens/login_page.dart';

/// 액션 버튼 타입 정의
enum VibeHeaderNavType {
  createPost,
  createRecipe,
  profilePage,
  registerPage,
  loginPage,
}

/// AppBar 대체 커스텀 헤더
class VibeHeader extends StatelessWidget implements PreferredSizeWidget {
  final Widget titleWidget;
  final bool showBackButton;
  final VibeHeaderNavType? navigateType; // nullable

  const VibeHeader({
    super.key,
    required this.titleWidget,
    this.navigateType,
    this.showBackButton = true,
  });

  /// 액션 아이콘 반환
  IconData _iconFor(VibeHeaderNavType type) {
    switch (type) {
      case VibeHeaderNavType.createPost:
        return Icons.camera_alt_rounded;
      case VibeHeaderNavType.createRecipe:
        return Icons.ramen_dining_rounded;
      case VibeHeaderNavType.profilePage:
        return Icons.person_rounded;
      case VibeHeaderNavType.registerPage:
        return Icons.app_registration_rounded;
      case VibeHeaderNavType.loginPage:
        return Icons.login_rounded;
    }
  }

  /// 이동 대상 위젯 반환
  Widget _buildPageForNavigation() {
    switch (navigateType) {
      case VibeHeaderNavType.createPost:
        return const CreatePostPage();
      case VibeHeaderNavType.createRecipe:
        return ChangeNotifierProvider(
          create: (_) => RecipeFormProvider(),
          child: const RecipeRegisterPage(),
        );
      case VibeHeaderNavType.profilePage:
        return const ProfilePage();
      case VibeHeaderNavType.registerPage:
        return const RegisterPage();
      case VibeHeaderNavType.loginPage:
        return const LoginPage();
      case null:
        return const SizedBox.shrink(); // 아무것도 안 함
    }
  }

  /// 액션 버튼 클릭 시 이동 처리
  Future<void> _navigate(BuildContext context) async {
    if (navigateType == null) return;
    final page = _buildPageForNavigation();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      leadingWidth: 20,           // ← leading 영역 너비 제거
      titleSpacing: 0,           // ← title 왼쪽 패딩 제거
      backgroundColor: Colors.white,
      automaticallyImplyLeading: false,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      title: Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: titleWidget,
      ),
      centerTitle: false,
      actions: (navigateType != null)
          ? [
              Container(
                // margin: const EdgeInsets.only(right: 8),
                width: 60,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    _iconFor(navigateType!),
                    color: Colors.white,
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
