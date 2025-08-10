// FollowButton.dart
import 'package:flutter/material.dart';
import '../../services/FollowService.dart';

class FollowButton extends StatefulWidget {
  const FollowButton({
    super.key,
    required this.targetUid,
    this.width = 343,
    this.height = 40,
    this.onChanged,
  });

  final String targetUid;
  final double width;
  final double height;
  final ValueChanged<bool>? onChanged;

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  static const _pink = Color.fromRGBO(255, 110, 199, 1);
  final _follow = FollowService();
  bool _busy = false;

  Future<void> _toggle(bool isFollowing) async {
    if (_busy) return;
    setState(() => _busy = true);

    final me = _follow.me;
    if (me == null || me == widget.targetUid) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 상태를 확인해주세요.')),
      );
      return;
    }

    bool ok = false;
    try {
      ok = isFollowing
          ? await _follow.unfollow(widget.targetUid)
          : await _follow.follow(widget.targetUid);
    } catch (_) {
      ok = false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('처리할 수 없어요. 차단/권한을 확인하세요.')),
      );
      return;
    }

    widget.onChanged?.call(!isFollowing);
  }

  @override
  Widget build(BuildContext context) {
    final me = _follow.me;
    if (me != null && me == widget.targetUid) {
      return const SizedBox.shrink(); // 본인 프로필이면 숨김
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: StreamBuilder<bool>(
        stream: _follow.isFollowingStream(widget.targetUid),
        initialData: false,
        builder: (context, snap) {
          final isFollowing = snap.data ?? false;
          final bg = isFollowing ? Colors.white : _pink;
          final fg = isFollowing ? _pink : Colors.white;

          return Material(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: _busy ? null : () => _toggle(isFollowing),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: widget.width,
                height: widget.height,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _pink, width: 1),
                ),
                child: _busy
                    ? const SizedBox(
                        width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        isFollowing ? '팔로우 중' : '팔로우',
                        style: TextStyle(
                          color: fg,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
