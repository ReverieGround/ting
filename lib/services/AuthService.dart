// lib/services/AuthService.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:flutter_naver_login/flutter_naver_login.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _fs;
  final FlutterSecureStorage _storage;

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? fs,
    FlutterSecureStorage? storage,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _fs = fs ?? FirebaseFirestore.instance,
        _storage = storage ?? const FlutterSecureStorage();

  // 상태
  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  Future<bool> isLoggedIn() async => currentUser != null;

  // 토큰
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    final u = _auth.currentUser;
    if (u == null) return null;
    return await u.getIdToken(forceRefresh);
  }

  Future<void> saveIdToken() async {
    final t = await getIdToken(forceRefresh: true);
    if (t != null) await _storage.write(key: 'auth_token', value: t);
  }

  Future<bool> verifyStoredIdToken() async {
    final stored = await _storage.read(key: 'auth_token');
    if (stored == null || currentUser == null) return false;
    try {
      final now = await getIdToken();
      return stored == now;
    } catch (e) {
      debugPrint('verifyStoredIdToken error: $e');
      return false;
    }
  }

  // Firestore 사용자 문서 생성(최초 로그인 1회)
  Future<void> registerUser({
    required String userName,
    required String countryCode,
    required String countryName,
    String? profileImageUrl,
    String? bio,
  }) async {
    final uid = currentUserId;
    if (uid == null) return;

    final ref = _fs.collection('users').doc(uid);
    final snap = await ref.get();
    if (snap.exists) return;

    final providerId = currentUser?.providerData.isNotEmpty == true
        ? currentUser!.providerData.first.providerId
        : 'password';

    await ref.set({
      'user_id': uid,
      'email': currentUser?.email ?? '',
      'user_name': userName,
      'profile_image': profileImageUrl ?? '',
      'bio': bio ?? '',
      'country_code': countryCode,
      'country_name': countryName,
      'provider': providerId,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  // 로그아웃
  Future<void> signOut() async {
    try { await GoogleSignIn().signOut(); } catch (_) {}
    try { await FacebookAuth.instance.logOut(); } catch (_) {}
    try { await FlutterNaverLogin.logOut(); } catch (_) {}
    try { await kakao.UserApi.instance.logout(); } catch (_) {}
    await _auth.signOut();
    await _storage.delete(key: 'auth_token');
  }

  // ── Providers ─────────────────────────────────

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final gUser = await GoogleSignIn().signIn();
      if (gUser == null) return null;
      final gAuth = await gUser.authentication;
      final cred = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );
      return await _auth.signInWithCredential(cred);
    } catch (e) {
      debugPrint('signInWithGoogle error: $e');
      return null;
    }
  }

  Future<UserCredential?> signInWithFacebook() async {
    try {
      final res = await FacebookAuth.instance.login();
      if (res.status != LoginStatus.success || res.accessToken == null) return null;
      final cred = FacebookAuthProvider.credential(res.accessToken!.token);
      return await _auth.signInWithCredential(cred);
    } catch (e) {
      debugPrint('signInWithFacebook error: $e');
      return null;
    }
  }

  // Kakao/Naver는 백엔드에서 Firebase Custom Token 발급 필요
  Future<UserCredential?> signInWithKakao({
    Future<String> Function(String kakaoAccessToken)? fetchFirebaseCustomToken,
  }) async {
    try {
      final token = await (await kakao.isKakaoTalkInstalled()
          ? kakao.UserApi.instance.loginWithKakaoTalk()
          : kakao.UserApi.instance.loginWithKakaoAccount());

      if (fetchFirebaseCustomToken == null) {
        debugPrint('Kakao accessToken=${token.accessToken}');
        return null;
      }
      final customToken = await fetchFirebaseCustomToken(token.accessToken);
      return await _auth.signInWithCustomToken(customToken);
    } catch (e) {
      debugPrint('signInWithKakao error: $e');
      return null;
    }
  }

  Future<UserCredential?> signInWithNaver({
    Future<String> Function(String naverAccessToken)? fetchFirebaseCustomToken,
  }) async {
    try {
      final res = await FlutterNaverLogin.logIn();
      if (res.status != NaverLoginStatus.loggedIn) return null;

      if (fetchFirebaseCustomToken == null) {
        debugPrint('Naver accessToken=${res.accessToken.accessToken}');
        return null;
      }
      final customToken = await fetchFirebaseCustomToken(res.accessToken.accessToken);
      return await _auth.signInWithCustomToken(customToken);
    } catch (e) {
      debugPrint('signInWithNaver error: $e');
      return null;
    }
  }
  
  Future<UserCredential?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('signInWithEmailPassword error: $e');
      rethrow;
    }
  }

  Future<bool> sendEmailVerification() async {
    final u = _auth.currentUser;
    if (u == null) return false;
    await u.reload();
    if (u.emailVerified) return true; // 이미 인증됨
    await u.sendEmailVerification();
    return true;
  }
}
