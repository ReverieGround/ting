import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart';
import '../../services/AuthService.dart'; // ✅ JWT 토큰 가져오기
import 'dart:developer'; 

class LikeButton extends StatefulWidget {
  final String postId;
  final Color initialColor; // ✅ 기본 색상 (회색)
  final Color fontColor; // ✅ 기본 색상 (회색)

  const LikeButton({
    super.key,
    required this.postId,
    this.initialColor = Colors.white, // ✅ 기본값
    this.fontColor = Colors.white, // ✅ 기본값
  });

  @override
  _LikeButtonState createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> with SingleTickerProviderStateMixin {
  int likesCount = 0;
  bool isLiked = false;
  bool isProcessing = false;

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
      lowerBound: 0.8,
      upperBound: 1.2,
    );

    _fetchLikeData(); // ✅ 좋아요 상태 & 개수 API 호출
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// ✅ 좋아요 개수 & 현재 사용자가 좋아요 눌렀는지 확인
  Future<void> _fetchLikeData() async {
    String? token = await AuthService.getToken();
    if (token == null) return;

    String url = '${Config.baseUrl}/post/${widget.postId}/likes';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<String> likedUsers = List<String>.from(data['likes'] ?? []);

        String? currentUser = await AuthService.getUserId();
        setState(() {
          likesCount = likedUsers.length;
          isLiked = currentUser != null && likedUsers.contains(currentUser);
        });
      }
    } catch (e) {
      log("Error fetching like data: $e");
    }
  }

  /// ✅ 좋아요 API 호출 (POST or DELETE)
  Future<void> _toggleLike() async {
    if (isProcessing) return;
    setState(() => isProcessing = true);

    setState(() {
      isLiked = !isLiked;
      likesCount += isLiked ? 1 : -1;
    });

    try {
      String? token = await AuthService.getToken();
      if (token == null) {
        log("Error: User token not found");
        return;
      }

      String url = '${Config.baseUrl}/post/${widget.postId}/like';
      http.Response response;

      Map<String, String> headers = {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json"
      };

      if (isLiked) {
        _controller.forward().then((_) => _controller.reverse());
        response = await http.post(Uri.parse(url), headers: headers);
      } else {
        response = await http.delete(Uri.parse(url), headers: headers);
      }

      if (!(response.statusCode == 200 || response.statusCode == 201)) {
        setState(() {
          isLiked = !isLiked;
          likesCount += isLiked ? 1 : -1;
        });
      }
    } catch (e) {
      log('Exception: $e');
      setState(() {
        isLiked = !isLiked;
        likesCount += isLiked ? 1 : -1;
      });
    } finally {
      setState(() => isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleLike,
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: Icon(
              Icons.favorite,
              key: ValueKey<bool>(isLiked),
              color: isLiked ? Colors.red : widget.initialColor, // ✅ 초기 색상 적용
              size: 24,
            ),
          ),
          SizedBox(width: 4),
          Text('$likesCount', style: TextStyle(color: widget.fontColor)),
        ],
      ),
    );
  }
}
