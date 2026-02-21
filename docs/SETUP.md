# 개발 환경 설정 및 의존성

## 필수 환경

| 항목 | 버전 | 비고 |
|------|------|------|
| Flutter SDK | 3.7.0+ | `sdk: ^3.7.0` (pubspec.yaml) |
| Dart SDK | 3.7.0+ | Flutter 내장 |
| Xcode | 15.0+ | iOS 빌드용 |
| CocoaPods | 최신 | iOS 네이티브 의존성 |
| Android Studio | 최신 | Android 빌드용 (선택) |
| Firebase CLI | 최신 | Firebase 설정 |
| FlutterFire CLI | 최신 | `firebase_options.dart` 생성 |

### Flutter SDK 설치 확인

```bash
flutter doctor
flutter --version
```

---

## 의존성 목록

### Firebase

| 패키지 | 버전 | 용도 |
|--------|------|------|
| `firebase_core` | ^3.13.0 | Firebase 초기화 |
| `firebase_auth` | ^5.5.3 | 인증 |
| `cloud_firestore` | ^5.6.7 | 데이터베이스 |
| `firebase_storage` | ^12.4.5 | 파일 스토리지 |

### 인증 / 소셜 로그인

| 패키지 | 버전 | 용도 |
|--------|------|------|
| `google_sign_in` | ^6.3.0 | Google OAuth |
| `flutter_facebook_auth` | ^6.0.3 | Facebook 로그인 |
| `kakao_flutter_sdk_user` | ^1.9.7+3 | Kakao 로그인 |
| `flutter_naver_login` | ^2.0.0 | Naver 로그인 |
| `local_auth` | ^2.1.6 | 바이오메트릭 인증 |
| `flutter_secure_storage` | ^9.0.0 | 보안 토큰 저장 |

### UI / 디자인

| 패키지 | 버전 | 용도 |
|--------|------|------|
| `cupertino_icons` | ^1.0.8 | iOS 스타일 아이콘 |
| `flutter_svg` | ^2.2.1 | SVG 렌더링 |
| `google_fonts` | ^6.3.0 | Google Fonts |
| `shimmer` | ^3.0.0 | 로딩 스켈레톤 |
| `country_flags` | ^3.2.0 | 국가 플래그 |
| `dropdown_button2` | ^2.3.9 | 드롭다운 버튼 |
| `flutter_staggered_grid_view` | ^0.7.0 | Masonry 그리드 |
| `reorderable_grid_view` | ^2.2.8 | 드래그 정렬 그리드 |

### 이미지 처리

| 패키지 | 버전 | 용도 |
|--------|------|------|
| `image_picker` | ^1.2.0 | 이미지 선택 |
| `image_cropper` | ^9.1.0 | 이미지 크롭 |
| `cached_network_image` | ^3.4.1 | 네트워크 이미지 캐싱 |
| `flutter_cache_manager` | ^3.4.1 | 캐시 관리 |
| `exif` | ^3.3.0 | EXIF 메타데이터 읽기 |
| `image` | ^4.5.4 | 이미지 처리 |

### 네비게이션 / 라우팅

| 패키지 | 버전 | 용도 |
|--------|------|------|
| `go_router` | ^16.2.1 | 선언적 라우팅 |

### 유틸리티

| 패키지 | 버전 | 용도 |
|--------|------|------|
| `http` | ^1.2.2 | HTTP 요청 |
| `uuid` | ^4.5.1 | UUID 생성 |
| `shared_preferences` | ^2.5.2 | 간단한 로컬 저장 |
| `path_provider` | ^2.1.1 | 파일 시스템 경로 |
| `characters` | ^1.4.0 | 문자열 처리 |
| `flutter_dotenv` | ^5.0.2 | 환경 변수 (.env) |

### 음성 / AI

| 패키지 | 버전 | 용도 |
|--------|------|------|
| `speech_to_text` | ^7.0.0 | 음성 인식 |
| `flutter_gemma` | ^0.11.13 | Gemma 모델 (온디바이스 AI) |

### 데스크탑 지원

| 패키지 | 버전 | 용도 |
|--------|------|------|
| `sqflite_common_ffi` | ^2.3.6 | 데스크탑 SQLite |

### dev_dependencies

| 패키지 | 버전 | 용도 |
|--------|------|------|
| `flutter_test` | SDK | 테스트 프레임워크 |
| `image_picker` | ^1.0.7 | (dev 중복) |
| `intl` | ^0.19.0 | 국제화/날짜 포맷 |
| `flutter_localization` | ^0.3.1 | 로컬라이제이션 |
| `provider` | ^6.1.0 | 상태 관리 (dev용) |
| `flutter_launcher_icons` | ^0.14.3 | 앱 아이콘 생성 |

---

## Firebase 설정 방법

### 1. Firebase 프로젝트 연결

```bash
# FlutterFire CLI 설치
dart pub global activate flutterfire_cli

# Firebase 프로젝트 연결 (firebase_options.dart 자동 생성)
flutterfire configure --project=vibeyum-alpha
```

### 2. Firebase 서비스 활성화

Firebase Console에서 다음 서비스를 활성화합니다:

- **Authentication**: Google, Facebook, Email/Password 프로바이더 활성화
- **Cloud Firestore**: 데이터베이스 생성 (아시아 리전 권장)
- **Firebase Storage**: 스토리지 버킷 생성

### 3. iOS 설정

`ios/Runner/GoogleService-Info.plist` 파일이 필요합니다 (FlutterFire configure 시 자동 생성).

---

## 소셜 로그인 설정

### Google

1. Firebase Console → Authentication → Sign-in providers → Google 활성화
2. iOS: `ios/Runner/Info.plist`에 `REVERSED_CLIENT_ID` URL scheme 추가
3. `google_sign_in` 패키지가 자동으로 처리

### Facebook

1. [Facebook Developers](https://developers.facebook.com/)에서 앱 생성
2. Firebase Console → Authentication → Facebook 프로바이더 활성화
3. `ios/Runner/Info.plist`에 Facebook App ID, Client Token 추가:
   ```xml
   <key>FacebookAppID</key>
   <string>YOUR_APP_ID</string>
   <key>FacebookClientToken</key>
   <string>YOUR_CLIENT_TOKEN</string>
   ```

### Kakao

1. [Kakao Developers](https://developers.kakao.com/)에서 앱 생성
2. `ios/Runner/Info.plist`에 Kakao SDK URL scheme 추가
3. **백엔드 필요**: Kakao accessToken → Firebase Custom Token 교환 서버
4. `kakao_flutter_sdk_user` 초기화 (현재 main.dart에서 미설정)

### Naver

1. [Naver Developers](https://developers.naver.com/)에서 앱 생성
2. iOS 네이티브 설정 필요
3. **백엔드 필요**: Naver accessToken → Firebase Custom Token 교환 서버

---

## 빌드 및 실행 명령어

### 기본 실행

```bash
# 의존성 설치
flutter pub get

# 디바이스 확인
flutter devices

# 기본 실행
flutter run

# 강제 온보딩 모드 (테스트용)
flutter run --dart-define=FORCE_ONBOARDING=true
```

### 빌드

```bash
# Android APK
flutter build apk

# Android App Bundle (Play Store용)
flutter build appbundle

# iOS
flutter build ios

# 클린 빌드
flutter clean && flutter pub get && flutter run
```

### 앱 아이콘 생성

```bash
flutter pub run flutter_launcher_icons
```

아이콘 설정 (pubspec.yaml):
```yaml
flutter_icons:
  ios: true
  image_path: "assets/icons/appstore.png"
```

---

## 환경 변수

### .env 파일

프로젝트 루트에 `.env` 파일이 필요합니다 (`.gitignore`에 포함):

```
OPENAI_API_KEY=sk-...
```

### dart-define

빌드 시 환경 변수를 주입할 수 있습니다:

| 변수 | 기본값 | 설명 |
|------|--------|------|
| `FORCE_ONBOARDING` | `false` | `true`로 설정 시 항상 온보딩 화면 표시 |

```bash
flutter run --dart-define=FORCE_ONBOARDING=true
```

---

## 플랫폼별 설정

### iOS

- **최소 버전**: Xcode에서 설정 (일반적으로 iOS 14.0+)
- **필수 설정**:
  - `GoogleService-Info.plist` (Firebase)
  - Info.plist URL schemes (Google, Facebook, Kakao)
  - 카메라/갤러리 접근 권한 (NSCameraUsageDescription, NSPhotoLibraryUsageDescription)
  - 바이오메트릭 권한 (NSFaceIDUsageDescription)
  - 마이크 접근 권한 (음성 인식용)
- **CocoaPods**:
  ```bash
  cd ios && pod install && cd ..
  ```

### Android (향후)

- `google-services.json` (Firebase)
- `android/app/build.gradle`에 minSdkVersion 설정
- 소셜 로그인 SHA-1 키 등록

### 데스크탑 (macOS/Windows/Linux)

- `sqflite_common_ffi` 초기화:
  ```dart
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  ```

---

## Assets 구조

> assets 디렉토리는 `.gitignore`에 포함되어 있으므로, 로컬에 직접 준비해야 합니다.

```
assets/
├── images/                     # 일반 이미지
│   ├── user-square.svg
│   └── note2.svg
├── icons/
│   └── appstore.png            # 앱 아이콘 원본
├── models/
│   └── gemma-2b-it-cpu-int8.bin  # Gemma 모델 (온디바이스 AI)
├── login_icons/                # 소셜 로그인 아이콘
│   ├── google_logo.png
│   ├── facebook_logo.png
│   ├── naver_logo.png
│   └── kakao_logo.png
├── logo_white.png              # 앱 로고
├── feeds.svg                   # 탭 아이콘: 커뮤니티
├── cooking-book.svg            # 탭 아이콘: 요리하기
├── note2.svg                   # 탭 아이콘: 기록
├── profile.svg                 # 탭 아이콘: 프로필
├── fire.png                    # 리뷰: Fire
├── tasty.png                   # 리뷰: Tasty
├── soso.png                    # 리뷰: Soso
├── woops.png                   # 리뷰: Woops
└── wack.png                    # 리뷰: Wack
```

---

## 알려진 제한사항 및 TODO

### 미구현

- [ ] Kakao/Naver 소셜 로그인 백엔드 (Custom Token 교환)
- [ ] 테스트 코드 (단위 테스트, 위젯 테스트, 통합 테스트 모두 없음)
- [ ] 국제화 (intl l10n 시스템 미사용, 대부분 하드코딩된 한국어)
- [ ] 에러 처리 고도화 (현재 debugPrint + null/빈 리스트 반환)
- [ ] 전용 상태 관리 라이브러리 도입 (Provider/Riverpod 등)
- [ ] Android/Web 플랫폼 최적화

### 알려진 이슈

- `nearby/` 디렉토리의 페이지들이 현재 사용되지 않음
- `RecipeEditPage copy.dart` 파일이 불필요하게 존재
- dev_dependencies에 `image_picker`가 중복 등록
- `provider` 패키지가 dev_dependencies에 있지만 코드에서 사용하지 않음
- assets 디렉토리가 gitignore되어 있어 클론 후 수동 준비 필요

### 보안 고려사항

- `.env` 파일에 API 키가 포함되므로 절대 커밋하지 말 것
- Firebase Security Rules이 프로덕션 수준으로 설정되어야 함
- `email`, `phone` 필드는 `UserService.fetchUserForViewer()`에서 제거됨

---

## 관련 문서

- [기능 및 사용자 플로우](./FEATURES.md)
- [아키텍처](./ARCHITECTURE.md)
- [백엔드 통합](./BACKEND.md)
- [데이터 모델](./DATA_MODELS.md)
