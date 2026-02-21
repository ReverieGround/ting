# 프론트엔드 아키텍처

## 디렉토리 구조

```
lib/
├── main.dart                          # 엔트리포인트, AppState, GoRouter
├── SplashPage.dart                    # 스플래시 화면
├── AppHeader.dart                     # 공통 커스텀 AppBar
├── firebase_options.dart              # Firebase 설정 (자동 생성)
│
├── theme/
│   └── AppTheme.dart                  # 테마 정의 (라이트/다크)
│
├── models/
│   ├── PostData.dart                  # 포스트 모델
│   ├── FeedData.dart                  # 피드 복합 모델 (Post + User + 메트릭스)
│   ├── UserData.dart                  # 사용자 기본 정보
│   ├── ProfileInfo.dart               # 프로필 상세 정보
│   ├── ProfileData.dart               # 프로필 페이지 데이터 (Info + Posts + Pinned)
│   ├── Recipe.dart                    # 레시피 모델 (+ Ingredient, Method, Nutrition)
│   ├── PostInputData.dart             # 포스트 작성 입력 데이터
│   └── StickyNoteModel.dart           # 게스트북 스티키 노트
│
├── services/
│   ├── AuthService.dart               # 인증 (소셜 로그인, 토큰 관리)
│   ├── FeedService.dart               # 피드 조회 (실시간, 인기, Wack, 개인)
│   ├── PostService.dart               # 포스트 CRUD, 좋아요, 댓글, 핀
│   ├── UserService.dart               # 사용자 프로필, 팔로우 확인
│   ├── FollowService.dart             # 팔로우/언팔로우/차단
│   ├── ProfileService.dart            # 프로필 데이터 로딩 (조합 서비스)
│   ├── RecipeService.dart             # Firestore 레시피 조회
│   ├── StorageService.dart            # Firebase Storage 이미지 업로드
│   └── GuestBookService.dart          # 게스트북 CRUD
│
├── login/
│   └── LoginPage.dart                 # 로그인 (소셜 + 바이오메트릭)
│
├── onboarding/
│   └── OnboardingPage.dart            # 온보딩 (닉네임, 국가, 이미지)
│
├── home/
│   └── HomePage.dart                  # 홈 (4탭 네비게이션)
│
├── feeds/
│   ├── FeedPage.dart                  # 피드 메인 페이지
│   └── widgets/
│       ├── FeedCard.dart              # 피드 카드 (메인 위젯)
│       ├── Head.dart                  # 포스트 헤더 (작성자 정보)
│       ├── Images.dart                # 이미지 캐러셀
│       ├── Content.dart               # 포스트 텍스트
│       ├── Tag.dart                   # 카테고리/리뷰 태그
│       ├── CookingIcon.dart           # 좋아요 아이콘
│       ├── LikeIcon.dart              # 하트 아이콘
│       ├── ReplyIcon.dart             # 댓글 아이콘
│       ├── CitationIcon.dart          # 카테고리 아이콘
│       ├── FeedFilterToggle.dart      # 피드 필터 토글
│       └── PostMetaEditSheet.dart     # 포스트 메타 편집 시트
│
├── posts/
│   ├── PostPage.dart                  # 포스트 상세 (댓글 포함)
│   └── widgets/
│       └── CommentTile.dart           # 댓글 타일
│
├── create/
│   ├── CreatePostPage.dart            # 포스트 작성 메인
│   ├── ConfirmPage.dart               # 작성 확인 + 업로드
│   ├── EditPage.dart                  # 이미지 편집 (정렬, 크롭)
│   ├── helpers/
│   │   ├── ImagePickerFlow.dart       # 이미지 선택 플로우
│   │   └── ExifHelper.dart            # EXIF 메타데이터 추출
│   └── widgets/
│       ├── ImageCarousel.dart         # 이미지 캐러셀
│       ├── ChipsCategory.dart         # 카테고리 칩
│       ├── ChipsReview.dart           # 리뷰 칩
│       ├── PostTextField.dart         # 텍스트 입력
│       ├── DateTimePickerDialog.dart  # 날짜/시간 선택
│       ├── HeaderDateTitle.dart       # 헤더 날짜 제목
│       ├── BottomNextButton.dart      # 하단 다음 버튼
│       ├── RecommendRecipeToggle.dart # 레시피 추천 토글
│       ├── SectionMealKit.dart        # 밀키트 섹션
│       ├── SectionRestaurant.dart     # 식당 섹션
│       ├── SectionDelivery.dart       # 배달 섹션
│       └── LinkInputRow.dart          # URL 입력 컴포넌트
│
├── recipe/
│   ├── RecipeListPage.dart            # 레시피 목록
│   ├── RecipeDetailPage.dart          # 레시피 상세
│   └── RecipeEditPage.dart            # 레시피 편집 (음성+GPT)
│
├── profile/
│   ├── ProfilePage.dart               # 프로필 메인 (3탭)
│   ├── tabs/
│   │   ├── YumTab.dart                # 포스트 그리드 탭
│   │   └── GuestBookTab.dart          # 게스트북 탭
│   └── widgets/
│       ├── ProfileHeader.dart         # 프로필 헤더
│       ├── FollowButton.dart          # 팔로우 버튼
│       ├── UserStatsRow.dart          # 통계 행
│       ├── StatusMessage.dart         # 상태 메시지 버블
│       ├── ContentGrid.dart           # 콘텐츠 그리드
│       ├── PinnedFeedsGrid.dart       # 핀 포스트 그리드
│       ├── StickyNoteCard.dart        # 스티키 노트 카드
│       ├── StickyNoteEditSheet.dart   # 노트 편집 시트
│       ├── NoteColorPalette.dart      # 노트 색상 팔레트
│       └── GuestNoteRepository.dart   # 데모 노트 데이터
│
├── users/
│   └── UserListPage.dart              # 사용자 목록 (팔로워/팔로잉/차단)
│
├── nearby/                            # 위치 기반 (미사용)
│   ├── NearbyPage.dart
│   └── widgets/
│       ├── MainHeader.dart
│       ├── FilterBar.dart
│       ├── LocationSelector.dart
│       └── FeedGrid.dart
│
└── common/
    └── widgets/
        ├── ProfileAvatar.dart         # 공통 프로필 아바타
        └── TimeAgoText.dart           # 상대 시간 텍스트
```

---

## AppState 상태 머신

`lib/main.dart`에 정의된 `AppState`는 `ChangeNotifier`를 상속하며, 앱 전체의 인증/온보딩 상태를 관리합니다.

### 상태 흐름

```
┌──────────────┐
│ initializing │  ← 앱 시작
└──────┬───────┘
       │ bootstrap()
       ▼
  ┌────────────┐     user == null     ┌─────────────────┐
  │  Firebase   │ ──────────────────→ │ unauthenticated │
  │ Auth 확인   │                     └─────────────────┘
  └────┬───────┘
       │ user != null
       ▼
  ┌──────────────────┐
  │ Firestore 문서    │
  │ 확인              │
  └────┬─────────────┘
       ├── user_name/country_code 미설정
       │        ↓
       │   ┌──────────────────┐
       │   │ needsOnboarding  │
       │   └──────────────────┘
       │
       └── 설정 완료
                ↓
           ┌───────────────┐
           │ authenticated │
           └───────────────┘
```

### 핵심 코드

```dart
enum AppStatus { initializing, unauthenticated, needsOnboarding, authenticated }

class AppState extends ChangeNotifier {
  AppStatus status = AppStatus.initializing;
  String? userId;
  final AuthService auth;
  final bool forceOnboarding;  // FORCE_ONBOARDING dart-define으로 제어

  Future<void> bootstrap() async {
    // 1. Firebase Auth 현재 사용자 확인
    // 2. ID 토큰 저장
    // 3. Firestore 사용자 문서에서 온보딩 완료 여부 확인
    // 4. 상태 전환 + notifyListeners()
  }
}
```

---

## GoRouter 라우팅 시스템

### 라우트 정의

| 경로 | 페이지 | 설명 |
|------|--------|------|
| `/splash` | `SplashPage` | 초기 로딩 |
| `/login` | `LoginPage` | 소셜 로그인 |
| `/onboarding` | `OnboardingPage` | 프로필 초기 설정 |
| `/home` | `HomePage` | 메인 앱 (4탭) |

### 리다이렉트 로직

`GoRouter`의 `redirect` 콜백에서 `AppState.status`에 따라 자동 리다이렉트:

```dart
redirect: (context, state) {
  final here = state.matchedLocation;
  switch (appState.status) {
    case AppStatus.initializing:
      return (here == '/splash') ? null : '/splash';
    case AppStatus.unauthenticated:
      return (here == '/login' || here == '/splash') ? null : '/login';
    case AppStatus.needsOnboarding:
      return (here == '/onboarding') ? null : '/onboarding';
    case AppStatus.authenticated:
      if (here == '/splash' || here == '/login' || here == '/onboarding') {
        return '/home';
      }
      return null;
  }
}
```

`refreshListenable: appState`로 상태 변경 시 자동 리다이렉트가 트리거됩니다.

---

## 상태 관리 패턴

### 기본 패턴: StatefulWidget + setState

프로젝트는 전용 상태 관리 라이브러리(Provider, Riverpod, Bloc 등)를 사용하지 않습니다. 각 페이지는 `StatefulWidget`과 `setState()`로 로컬 상태를 관리합니다.

### PageStorageBucket

`HomePage`에서 탭 전환 시 스크롤 위치를 보존하기 위해 사용:

```dart
final _bucket = PageStorageBucket();

// ...
PageStorage(
  bucket: _bucket,
  child: IndexedStack(
    index: _selectedIndex,
    children: [...],
  ),
)
```

### 실시간 데이터: StreamBuilder

Firestore 실시간 업데이트가 필요한 곳에서 사용:

- 댓글 목록 (`PostService.commentsStream`)
- 좋아요 여부 (`PostService.isLikedStream`)
- 핀 여부 (`PostService.isPinnedStream`)
- 팔로우 여부 (`FollowService.isFollowingStream`)

### 비동기 데이터: FutureBuilder / async-await

대부분의 서비스는 `Future`를 반환하며, UI에서는 직접 async/await 패턴으로 로딩:

```dart
// 일반적인 패턴
bool _loading = true;
List<FeedData> _feeds = [];

Future<void> _load() async {
  setState(() => _loading = true);
  final feeds = await feedService.fetchRealtimeFeeds(limit: 20);
  setState(() { _feeds = feeds; _loading = false; });
}
```

---

## 테마 시스템

### 구조

`lib/theme/AppTheme.dart`에서 중앙 관리됩니다.

### 색상 체계

| 상수 | 값 | 용도 |
|------|-----|------|
| `kBgLight` | `#0F1115` | 라이트 모드 배경 (어두운 배경) |
| `kBgDark` | `#0B0D10` | 다크 모드 배경 |
| `kPrimary` | `#EAECEF` | 주 색상 (밝은 회백색) |
| `kFontLight` | `#EAECEF` | 라이트 모드 글자색 |
| `kFontDark` | `#EAECEF` | 다크 모드 글자색 |

### 투명도 상수

| 상수 | 값 | 용도 |
|------|-----|------|
| `kHintOpacity` | `0.6` | 힌트 텍스트 |
| `kBorderOpacity` | `0.15` | 테두리 |
| `kDividerOpacity` | `0.12` | 구분선 |

### 현재 설정

```dart
// main.dart
themeMode: ThemeMode.light,  // 라이트 모드 강제
theme: AppTheme.lightTheme,
```

> 실제로는 "다크 색상 + 밝은 brightness 설정"으로 다크 UI를 구현하고 있습니다. `ColorScheme.fromSeed()`로 일관된 색상 파생을 사용합니다.

### 커스터마이즈된 컴포넌트

- `AppBarTheme`: 배경색 = backgroundColor, 글자색 = fontColor, elevation = 0
- `ElevatedButtonTheme`: StadiumBorder, primary 배경 + 검정 글자
- `InputDecorationTheme`: filled, borderRadius 14, 커스텀 border 색상
- `TextTheme`: bodyLarge/bodyMedium에 fontColor 적용

---

## 위젯 구성: 주요 페이지별 계층 구조

### HomePage

```
HomePage (StatefulWidget)
├── IndexedStack
│   ├── [0] FeedPage (PageStorageKey)
│   ├── [1] RecipeListPage (lazy)
│   ├── [2] RecipeEditPage (lazy)
│   └── [3] ProfilePage (PageStorageKey, lazy)
└── BottomNavBar (커스텀 오버레이)
    ├── _NavIconButton (커뮤니티)
    ├── _NavIconButton (요리하기)
    ├── _NavIconButton (기록)
    └── _NavIconButton (프로필)
```

### FeedPage → FeedCard

```
FeedCard
├── Head (작성자 아바타, 이름, 시간, 편집 아이콘)
├── Images (PageView, CachedNetworkImage, 태그 오버레이)
│   └── Tag (카테고리 + 리뷰 값)
├── Content (포스트 텍스트, 첫 댓글 미리보기)
└── IconsRow
    ├── CookingIcon (좋아요 수)
    ├── ReplyIcon (댓글 수)
    └── CitationIcon (카테고리 아이콘)
```

### ProfilePage

```
ProfilePage
├── ProfileHeader
│   ├── ProfileAvatar
│   ├── Username + Title
│   ├── StatusMessage (커스텀 버블 shape)
│   ├── FollowButton (타인 프로필만)
│   └── UserStatsRow (포스트/레시피/팔로워/팔로잉)
├── PinnedFeedsGrid (Masonry 2열)
└── TabBarView
    ├── YumTab (3열 이미지 그리드)
    ├── RecipeTab
    └── GuestBookTab (Masonry 스티키 노트)
        └── StickyNoteCard (Hero 애니메이션)
```

---

## 공통 패턴

### 에러 처리

서비스 레이어에서 `debugPrint()`로 에러를 출력하고, 실패 시 `null` 또는 빈 리스트를 반환합니다:

```dart
// 일반적 패턴
try {
  // Firestore 호출
} catch (e) {
  debugPrint('methodName error: $e');
  return null;  // 또는 return []
}
```

### Firestore whereIn 제한 처리

Firestore `whereIn`은 최대 10개로 제한되므로 chunking 패턴을 사용합니다:

```dart
List<List<T>> _chunk<T>(List<T> list, int size) {
  final r = <List<T>>[];
  for (var i = 0; i < list.length; i += size) {
    r.add(list.sublist(i, min(i + size, list.length)));
  }
  return r;
}
```

### 낙관적 UI 업데이트

좋아요 등의 인터랙션에서 서버 응답을 기다리지 않고 즉시 UI를 업데이트한 후, 실패 시 롤백합니다.

---

## 관련 문서

- [기능 및 사용자 플로우](./FEATURES.md)
- [백엔드 통합](./BACKEND.md)
- [데이터 모델](./DATA_MODELS.md)
- [개발 환경 설정](./SETUP.md)
