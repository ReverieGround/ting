import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../common/widgets/ProfileAvatar.dart';
import '../../models/ProfileInfo.dart';
import '../../users/UserListPage.dart';

class ProfileHeader extends StatelessWidget {
  final ProfileInfo profileInfo;

  const ProfileHeader({super.key, required this.profileInfo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 👤 프로필 정보 (좌)
          Flexible(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // ✅ 높이 제약
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ProfileAvatar(profileUrl: profileInfo.profileImage, size: 45),
                    const SizedBox(width: 12),
                    // ✅ Expanded → Flexible로 교체
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            profileInfo.userName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            profileInfo.userTitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if ((profileInfo.statusMessage ?? '').isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      profileInfo.statusMessage!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // 📊 통계 (우)
          Flexible(
            flex: 1,
            child: Column(
              mainAxisSize: MainAxisSize.min, // ✅ 높이 고정
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Stat(icon: Icons.restaurant_menu_rounded, value: profileInfo.postCount),
                    const SizedBox(width: 16),
                    _HeaderStatIcon(
                      assetPath: 'assets/notebook.svg',
                      label: '${profileInfo.recipeCount}',
                      onTap: () => {},
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _HeaderStatIcon(
                      assetPath: 'assets/users-round.svg',
                      label: '${profileInfo.followerCount}',
                      onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserListPage(initialTabIndex: 0, targetUserId: profileInfo.userId),
                            ),
                          );
                        },
                    ),
                    const SizedBox(width: 16),
                    _HeaderStatIcon(
                      assetPath: 'assets/user-round-plus.svg',
                      label: '${profileInfo.followingCount}',
                      onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserListPage(initialTabIndex: 1, targetUserId: profileInfo.userId),
                            ),
                          );
                        },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final int value;

  const _Stat({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min, // ✅ 추가
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 28, color: theme.colorScheme.onSurface),
        const SizedBox(width: 6),
        Text(
          '$value',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w400,
            fontSize: 17,
          ),
        ),
      ],
    );
  }
}


class _HeaderStatIcon extends StatelessWidget {
  const _HeaderStatIcon({
    required this.assetPath,
    required this.label,
    required this.onTap,
  });

  final String assetPath;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        scale: 1.0,
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: Row(
            children: [
              Container(
                child: SvgPicture.asset(
                  assetPath,
                  height: 28,
                  colorFilter: ColorFilter.mode(
                    theme.colorScheme.onSurface,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w400,
                  fontSize: 17,
                ),
              ),
            ]
          ),
        ),
      ),
    );
  }
}