import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../widgets/register/text_field.dart';
import '../widgets/register/country_field.dart';
import '../widgets/utils/profile_avatar.dart';
import '../widgets/common/vibe_header.dart'; 
import '../services/auth_service.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController customCountryController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _profileImage;
  bool isRegistering = false;
  bool isCustomCountry = false;
  String? selectedCountryCode;
  String? selectedCountryName;

  Future<String?> uploadProfileImageToFirebase(File imageFile) async {
    try {
      final storageRef = FirebaseStorage.instance.ref();
      final fileName = 'profile/${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      final uploadRef = storageRef.child(fileName);

      await uploadRef.putFile(imageFile);
      return await uploadRef.getDownloadURL();
    } catch (e) {
      debugPrint("❌ 이미지 업로드 실패: $e");
      return null;
    }
  }

  bool isValidEmail(String email) {
    return email.contains("@");
  }

  bool isValidPassword(String password) {
    // return RegExp(r'^(?=.*[a-z])(?=.*[0-9])(?=.*[!@#\$&*~]).{8,}$').hasMatch(password);
    final lowercaseMatches = RegExp(r'[a-z]').allMatches(password).length;
    final numberMatches = RegExp(r'[0-9]').allMatches(password).length;
    return (lowercaseMatches + numberMatches) >= 4;
  }

  bool passwordsMatch() {
    return passwordController.text == confirmPasswordController.text;
  }

  Future<void> registerUser() async {
    if (isRegistering) return;
    setState(() => isRegistering = true);

    String email = emailController.text.trim();
    String userName = usernameController.text.trim();
    String password = passwordController.text.trim();
    String bio = bioController.text.trim();

    if (!isValidPassword(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('비밀번호는 소문자를 포함해야 합니다.')),
      );
      setState(() => isRegistering = false);
      return;
    }

    try {
      // 1. Firebase Auth로 가입
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // 2. 이메일 인증 메일 전송
      await userCredential.user?.sendEmailVerification();

      // 3. Firestore에 사용자 정보 저장
      String countryCode = selectedCountryCode ?? "CUSTOM";
      String countryName = isCustomCountry
          ? customCountryController.text.trim()
          : (selectedCountryName ?? "Unknown");

      String? profileImageUrl;
      if (_profileImage != null) {
        profileImageUrl = await uploadProfileImageToFirebase(_profileImage!);
      }
      if (profileImageUrl == null){
          const defaultList = [
            'https://firebasestorage.googleapis.com/v0/b/vibeyum-alpha.firebasestorage.app/o/profile_images%2Favatar-design.png?alt=media&token=f34a16cd-689d-464f-9c45-3859c66be0c0',
            'https://firebasestorage.googleapis.com/v0/b/vibeyum-alpha.firebasestorage.app/o/profile_images%2Fbusinesswoman.png?alt=media&token=6fa85751-6fff-42e2-91d9-32d114167352',
            'https://firebasestorage.googleapis.com/v0/b/vibeyum-alpha.firebasestorage.app/o/profile_images%2Fprogrammer.png?alt=media&token=ed21ed93-f845-42b9-8ec4-6d47f6e2650c',
            'https://firebasestorage.googleapis.com/v0/b/vibeyum-alpha.firebasestorage.app/o/profile_images%2Fwoman%20(1).png?alt=media&token=4494aa07-e112-489e-b053-7555d483c02c',
            'https://firebasestorage.googleapis.com/v0/b/vibeyum-alpha.firebasestorage.app/o/profile_images%2Fwoman.png?alt=media&token=4acd3f2f-3a19-4289-858e-e9fe929b5e91',
          ];
          defaultList.shuffle();
          profileImageUrl = defaultList.first;
      }
      await AuthService.registerUserInFirestore(
        userName: userName,
        countryCode: countryCode,
        countryName: countryName,
        profileImageUrl: profileImageUrl,
        bio: bio,
      );

      // 4. 안내 및 화면 전환
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('인증 메일을 보냈습니다.\n메일함을 확인해주세요.')),
      );
      Navigator.pop(context, true);
    } on FirebaseAuthException catch (e) {
      String errorMessage = '회원가입 실패';
      if (e.code == 'email-already-in-use') {
        errorMessage = '이미 존재하는 이메일입니다.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
    } catch (e) {
      debugPrint("회원가입 중 오류: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('회원가입 실패')));
    }

    setState(() => isRegistering = false);
  }

  /// 갤러리에서 프로필 이미지 선택
  Future<void> pickProfileImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: VibeHeader(
        titleWidget: Text(
          '회원가입',
          style:TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold),
      )),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: pickProfileImage,
                      child: ProfileAvatar(
                          profileImage: _profileImage,
                          size: 80,
                        )
                    ),
                    SizedBox(height: 12),
                    RegisterTextField(
                      controller: emailController,
                      label: '이메일',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "이메일을 입력하세요";
                        }
                        if (!isValidEmail(value)) {
                          return "올바른 이메일 주소를 입력하세요";
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12),
                    RegisterTextField(
                      controller: usernameController,
                      label: '닉네임',
                      icon: Icons.person_outline),
                    SizedBox(height: 12),
                    RegisterTextField(
                      controller: passwordController,
                      label: '비밀번호',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      validator: (value) {
                        if (value == null) {
                          return "비밀번호를 입력하세요";
                        }
                        if (value.isEmpty) {
                          return null ;
                        }
                        if (!isValidPassword(value)) {
                          // return "비밀번호는 최소 8자, 소문자, 숫자, 특수문자를 포함해야 합니다.";
                          return "비밀번호는 최소 8자, 소문자를 포함해야 합니다.";
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12),
                    RegisterTextField(
                      controller: confirmPasswordController,
                      label: '비밀번호 확인',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      validator: (value) {
                        if (value == null) {
                          return "비밀번호를 다시 입력하세요";
                        }
                        if (value.isEmpty) {
                          return null ;
                        }
                        if (!passwordsMatch()) {
                          return "비밀번호가 일치하지 않습니다";
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12),
                    RegisterTextField(
                      controller: bioController,
                      label: '소개',
                      icon: Icons.info_outline),
                    SizedBox(height: 12),
                    RegisterCountryField(
                      label: '국가 선택',
                      icon: Icons.public,
                      onCountrySelected: (code, name) {
                        selectedCountryCode = code;
                        selectedCountryName = name;
                        
                      },
                    ),
                  ],
                ),
              ),
            ),
            // ✅ 버튼을 하단에 고정하고 넓게 설정
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8), // ✅ 좌우 여백 추가
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: registerUser,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16), // 버튼 높이 키우기
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: isRegistering 
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text('회원가입', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
