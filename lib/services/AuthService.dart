import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // 이건 필수!

import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';

class AuthService {
  static final _secureStorage = FlutterSecureStorage();

  // ─── 인증 상태 및 토큰 ─────────────────────────

  static Future<bool> isLoggedIn() async {
    return FirebaseAuth.instance.currentUser != null;
  }

  static Future<String?> getToken() async {
    return await FirebaseAuth.instance.currentUser?.getIdToken();
  }

  static Future<bool> verifyAuthToken() async {
    final storedToken = await _secureStorage.read(key: 'auth_token');
    final user = FirebaseAuth.instance.currentUser;
    if (storedToken == null || user == null) return false;
    try {
      final currentToken = await user.getIdToken();
      return storedToken == currentToken;
    } catch (e) {
      debugPrint(" Firebase 토큰 확인 실패: $e");
      return false;
    }
  }

  static Future<void> storeAuthToken() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken(true);
    if (token != null) {
      await _secureStorage.write(key: 'auth_token', value: token);
      debugPrint("auth_token 저장됨 (bio login)");
    }
  }

  static Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    await FacebookAuth.instance.logOut();
    await _secureStorage.delete(key: 'auth_token');
    debugPrint("로그아웃 완료");
  }

  static Future<String?> getUserId() async {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  // ─── Firestore 사용자 정보 등록 ─────────────────────────

  static Future<void> registerUserInFirestore({
    required String userName,
    required String countryCode,
    required String countryName,
    String? profileImageUrl,
    String? bio,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint(" Firebase 사용자 정보 없음. Firestore 등록 실패.");
      return;
    }

    final uid = user.uid;
    final email = user.email;

    final usersRef = FirebaseFirestore.instance.collection('users');
    final doc = await usersRef.doc(uid).get();
    if (doc.exists) {
      // debugPrint("이미 Firestore에 등록된 사용자입니다.");
      return;
    }

    await usersRef.doc(uid).set({
      'user_id': uid,
      'email': email,
      'user_name': userName,
      'profile_image': profileImageUrl ?? "",
      'bio': bio ?? "",
      'country_code': countryCode,
      'country_name': countryName,
      'provider': user.providerData.first.providerId,
      'created_at': FieldValue.serverTimestamp(),
    });

    debugPrint("Firestore에 사용자 정보 등록 완료.");
  }

  // ─── SNS 로그인 ─────────────────────────

  static Future<UserCredential?> signInWithGoogle(BuildContext context) async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Google 로그인이 취소되었습니다.")),
        );
        return null;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await FirebaseAuth.instance.signInWithCredential(credential);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("로그인 성공: ${result.user?.email ?? '알 수 없음'}")),
      );

      return result;
    } catch (e) {
      debugPrint("Google 로그인 실패: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Google 로그인 실패")),
      );
      return null;
    }
  }


  // static Future<UserCredential?> signInWithGoogle() async {
  //   try {
  //     final googleUser = await GoogleSignIn().signIn();
  //     if (googleUser == null) return null;

  //     final googleAuth = await googleUser.authentication;
  //     final credential = GoogleAuthProvider.credential(
  //       accessToken: googleAuth.accessToken,
  //       idToken: googleAuth.idToken,
  //     );

  //     final result = await FirebaseAuth.instance.signInWithCredential(credential);
  //     debugPrint("Google 로그인 성공: ${result.user?.email}");
  //     return result;
  //   } catch (e) {
  //     debugPrint("❌ Google 로그인 실패: $e");
  //     return null;
  //   }
  // }

  static Future<UserCredential?> signInWithFacebook() async {
    try {
      final result = await FacebookAuth.instance.login();
      if (result.status != LoginStatus.success) return null;

      final credential = FacebookAuthProvider.credential(result.accessToken!.token);
      final resultUser = await FirebaseAuth.instance.signInWithCredential(credential);
      debugPrint("Facebook 로그인 성공: ${resultUser.user?.email}");
      return resultUser;
    } catch (e) {
      debugPrint("Facebook 로그인 실패: $e");
      return null;
    }
  }

  static Future<UserCredential?> signInWithKakao() async {
    try {
      OAuthToken token = await (await isKakaoTalkInstalled()
          ? UserApi.instance.loginWithKakaoTalk()
          : UserApi.instance.loginWithKakaoAccount());

      // TODO: token.accessToken → 백엔드로 전송 → Firebase Custom Token 발급
      debugPrint("⚠️ Kakao 로그인 성공(토큰): ${token.accessToken}");
      return null;
    } catch (e) {
      debugPrint(" Kakao 로그인 실패: $e");
      return null;
    }
  }

  static Future<UserCredential?> signInWithNaver() async {
    try {
      final result = await FlutterNaverLogin.logIn();
      if (result.status != NaverLoginStatus.loggedIn) return null;

      // TODO: result.accessToken.accessToken → 백엔드로 전송 → Firebase Custom Token 발급
      debugPrint("⚠️ Naver 로그인 성공(토큰): ${result.accessToken.accessToken}");
      return null;
    } catch (e) {
      debugPrint(" Naver 로그인 실패: $e");
      return null;
    }
  }
}
