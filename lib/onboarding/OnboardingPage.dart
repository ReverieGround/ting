// lib/onboarding/OnboardingPage.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/AuthService.dart';
import '../services/UserService.dart';
import '../main.dart' show AppStatus, AppState; // 또는 별도 app_state.dart로 분리 권장
import 'package:image_picker/image_picker.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.appState});
  final AppState appState; // 👈 주입

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nickCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  String _countryCode = 'KR';
  String _countryName = '대한민국';

  bool _saving = false;

  final _auth = AuthService();
  final _userService = UserService();
  final _picker = ImagePicker();
  File? _pickedImage;

  @override
  void dispose() {
    _nickCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
      if (x == null) return;
      setState(() => _pickedImage = File(x.path));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 선택 실패: $e')),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      await _auth.saveIdToken();

      await _auth.registerUser(
        userName: _nickCtrl.text.trim(),
        countryCode: _countryCode,
        countryName: _countryName,
        profileImageUrl: '',
        bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
      );

      if (_pickedImage != null) {
        await _userService.uploadProfileImage(_pickedImage!);
      }

      await _auth.markHasLoginBefore();

      // ✅ refreshListenable 쓰지 말고, 주입된 appState 사용
      widget.appState.status = AppStatus.authenticated;
      widget.appState.notifyListeners(); // redirect 트리거
      if (mounted) context.go('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 중 오류가 발생했어요: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _skip() {
    widget.appState.status = AppStatus.authenticated;
    widget.appState.notifyListeners();
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('첫 설정')),
      body: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text('T!ng을 시작하려면 몇 가지만 설정해요. (1분)'),
              const SizedBox(height: 16),

              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundImage:
                          _pickedImage != null ? FileImage(_pickedImage!) : null,
                      child: _pickedImage == null
                          ? Icon(Icons.person, size: 44, color: theme.colorScheme.outline)
                          : null,
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: IconButton.filledTonal(
                        onPressed: _saving ? null : _pickImage,
                        icon: const Icon(Icons.camera_alt, size: 20),
                        tooltip: '프로필 이미지 선택',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nickCtrl,
                decoration: const InputDecoration(
                  labelText: '닉네임 *',
                  hintText: '예: 맛잘알, 초보쿡',
                ),
                maxLength: 20,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '닉네임을 입력해 주세요.' : null,
              ),
              const SizedBox(height: 8),

              InputDecorator(
                decoration: const InputDecoration(labelText: '지역(국가) *'),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _countryCode,
                    items: const [
                      DropdownMenuItem(value: 'KR', child: Text('대한민국')),
                      DropdownMenuItem(value: 'US', child: Text('미국')),
                      DropdownMenuItem(value: 'JP', child: Text('일본')),
                    ],
                    onChanged: _saving
                        ? null
                        : (val) {
                            if (val == null) return;
                            setState(() {
                              _countryCode = val;
                              _countryName = switch (val) {
                                'KR' => '대한민국',
                                'US' => '미국',
                                'JP' => '일본',
                                _ => '대한민국',
                              };
                            });
                          },
                  ),
                ),
              ),
              const SizedBox(height: 8),

              TextFormField(
                controller: _bioCtrl,
                decoration: const InputDecoration(
                  labelText: '한 줄 소개',
                  hintText: '예: 자취생 3년차, 다이어트 레시피 수집가',
                ),
                maxLength: 80,
              ),

              const SizedBox(height: 24),

              FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(
                        width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check),
                label: Text(_saving ? '저장 중…' : '시작하기'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _saving ? null : _skip,
                child: Text('나중에 할래요', style: TextStyle(color: theme.colorScheme.outline)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
