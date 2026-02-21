# Firebase 및 백엔드 통합

## Firebase 프로젝트 설정

- **프로젝트**: vibeyum-alpha
- **설정 파일**: `lib/firebase_options.dart` (FlutterFire CLI로 자동 생성)
- **사용 서비스**:
  - Firebase Authentication
  - Cloud Firestore
  - Firebase Storage

---

## Firestore 컬렉션 구조

### `users` 컬렉션

사용자 프로필 정보를 저장합니다.

```
users/{userId}
├── user_id: string
├── email: string
├── user_name: string
├── profile_image: string (URL)
├── bio: string
├── country_code: string ("KR", "US", "JP")
├── country_name: string
├── location: string
├── user_title: string
├── status_message: string
├── provider: string ("google.com", "facebook.com", "password" 등)
├── created_at: Timestamp (서버)
│
├── [서브컬렉션] followers/{followerUserId}
│   └── created_at: Timestamp
│
├── [서브컬렉션] following/{followingUserId}
│   └── created_at: Timestamp
│
├── [서브컬렉션] blocks/{blockedUserId}
│   └── created_at: Timestamp
│
├── [서브컬렉션] pinned_posts/{postId}
│   └── created_at: Timestamp
│
└── [서브컬렉션] guestbook/{noteId}
    ├── id: string
    ├── authorId: string
    ├── authorName: string
    ├── authorAvatarUrl: string
    ├── text: string
    ├── color: int (Color.value)
    ├── pinned: bool
    └── createdAt: Timestamp
```

### `posts` 컬렉션

사용자 포스트를 저장합니다.

```
posts/{postId}
├── post_id: string
├── user_id: string
├── title: string
├── content: string
├── image_urls: array<string>
├── category: string ("요리", "밀키트", "식당", "배달")
├── value: string ("Fire", "Tasty", "Soso", "Woops", "Wack")
├── visibility: string ("PUBLIC", "FOLLOWER", "PRIVATE")
├── archived: bool
├── recipe_id: string? (연결된 레시피)
├── region: string
├── likes_count: int
├── comments_count: int
├── created_at: Timestamp (서버)
├── updated_at: Timestamp (서버)
├── captured_at: Timestamp
│
├── [서브컬렉션] likes/{userId}
│   └── created_at: Timestamp
│
└── [서브컬렉션] comments/{commentId}
    ├── comment_id: string
    ├── post_id: string
    ├── user_id: string
    ├── content: string
    ├── created_at: Timestamp
    └── updated_at: Timestamp
```

### `recipes` 컬렉션

Firestore 기반 레시피 데이터입니다.

```
recipes/{recipeId}
├── _id: string
├── title: string
├── food_category: string
├── cooking_category: string
├── images: { original_url: string, local_path: string }
├── tags: string
├── tips: string
├── ingredients: array<{ name: string, quantity: string }>
├── methods: array<{ describe: string, image: { original_url: string, local_path: string } }>
├── nutrition: { calories: string, protein: string, carbohydrates: string, fat: string, sodium: string }
└── created_at: Timestamp
```

---

## 인증 플로우

### 지원 프로바이더

| 프로바이더 | 방식 | 상태 |
|-----------|------|------|
| Google | Firebase 네이티브 OAuth | 완전 구현 |
| Facebook | Firebase 네이티브 OAuth | 완전 구현 |
| Kakao | Custom Token (백엔드 필요) | 프론트엔드만 구현 |
| Naver | Custom Token (백엔드 필요) | 프론트엔드만 구현 |
| Email/Password | Firebase 네이티브 | 구현됨 |

### Google 로그인 플로우

```
1. GoogleSignIn().signIn()
2. gUser.authentication → accessToken, idToken
3. GoogleAuthProvider.credential(accessToken, idToken)
4. FirebaseAuth.signInWithCredential(credential)
5. registerUser() → Firestore 'users' 문서 생성 (없는 경우)
6. saveIdToken() → FlutterSecureStorage에 토큰 저장
7. markHasLoginBefore() → 자동 로그인 플래그 설정
```

### Facebook 로그인 플로우

```
1. FacebookAuth.instance.login()
2. result.accessToken.token
3. FacebookAuthProvider.credential(token)
4. FirebaseAuth.signInWithCredential(credential)
5. (이후 Google과 동일)
```

### Kakao / Naver 로그인

백엔드에서 Firebase Custom Token을 발급해야 합니다:

```
1. Kakao/Naver SDK로 OAuth → accessToken 획득
2. accessToken을 백엔드 서버로 전송 (미구현)
3. 백엔드에서 Firebase Admin SDK로 Custom Token 생성
4. FirebaseAuth.signInWithCustomToken(customToken)
```

> 현재 `fetchFirebaseCustomToken` 콜백이 null이면 accessToken만 출력하고 null을 반환합니다.

### 회원가입 (registerUser)

최초 로그인 시 Firestore에 사용자 문서를 생성합니다:

```dart
Future<void> registerUser({
  required String userName,
  required String countryCode,
  required String countryName,
  String? profileImageUrl,
  String? bio,
}) async {
  final ref = _fs.collection('users').doc(uid);
  final snap = await ref.get();
  if (snap.exists) return;  // 이미 등록됨

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
```

### 로그아웃

모든 소셜 프로바이더를 순차적으로 로그아웃합니다:

```dart
Future<void> signOut() async {
  try { await GoogleSignIn().signOut(); } catch (_) {}
  try { await FacebookAuth.instance.logOut(); } catch (_) {}
  try { await FlutterNaverLogin.logOut(); } catch (_) {}
  try { await kakao.UserApi.instance.logout(); } catch (_) {}
  await _auth.signOut();
  await _storage.delete(key: 'auth_token');
}
```

---

## 토큰 관리

### 저장소

`FlutterSecureStorage`를 사용하여 민감한 데이터를 안전하게 저장합니다.

| 키 | 값 | 설명 |
|---|---|------|
| `auth_token` | Firebase ID Token | 인증 토큰 |
| `has_logged_in_before` | `"true"` / null | 이전 로그인 여부 |

### 토큰 갱신

```dart
Future<void> saveIdToken() async {
  final t = await getIdToken(forceRefresh: true);
  if (t != null) await _storage.write(key: 'auth_token', value: t);
}
```

### 토큰 검증

```dart
Future<bool> verifyStoredIdToken() async {
  final stored = await _storage.read(key: 'auth_token');
  if (stored == null || currentUser == null) return false;
  final now = await getIdToken();
  return stored == now;
}
```

---

## Firebase Storage 사용

### 이미지 업로드 경로 구조

```
Firebase Storage
├── posts/{userId}/{timestamp}_{uuid}.{ext}     # 포스트 이미지
└── profile_images/{userId}_{timestamp}_{filename}  # 프로필 이미지
```

### StorageService 주요 메서드

| 메서드 | 설명 |
|--------|------|
| `uploadPostImage(File)` | 단일 포스트 이미지 업로드 → URL 반환 |
| `uploadPostImages(List<File>)` | 복수 이미지 순차 업로드 |
| `deleteByUrl(String)` | URL로 이미지 삭제 |

### Content-Type 매핑

| 확장자 | Content-Type |
|--------|-------------|
| jpg, jpeg | `image/jpeg` |
| png | `image/png` |
| webp | `image/webp` |
| gif | `image/gif` |
| 기타 | `application/octet-stream` |

---

## 서비스 레이어

### AuthService (`lib/services/AuthService.dart`)

인증 및 사용자 등록을 담당합니다.

| 메서드 | 반환 | 설명 |
|--------|------|------|
| `currentUser` | `User?` | 현재 Firebase 사용자 |
| `signInWithGoogle()` | `UserCredential?` | Google 로그인 |
| `signInWithFacebook()` | `UserCredential?` | Facebook 로그인 |
| `signInWithKakao()` | `UserCredential?` | Kakao 로그인 |
| `signInWithNaver()` | `UserCredential?` | Naver 로그인 |
| `signInWithEmailPassword()` | `UserCredential?` | 이메일 로그인 |
| `registerUser()` | `void` | Firestore 사용자 문서 생성 |
| `signOut()` | `void` | 전체 로그아웃 |
| `saveIdToken()` | `void` | 토큰 저장 |
| `verifyStoredIdToken()` | `bool` | 저장된 토큰 검증 |
| `hasLoginBefore()` | `bool` | 이전 로그인 여부 |

### FeedService (`lib/services/FeedService.dart`)

피드 데이터를 Firestore에서 조회합니다.

| 메서드 | 설명 |
|--------|------|
| `fetchRealtimeFeeds({region, limit})` | 최신순 공개 피드 |
| `fetchHotFeeds({region, date, limit, lastDocument})` | 좋아요순 인기 피드 (페이지네이션) |
| `fetchWackFeeds({region, limit})` | Wack 평가 피드 |
| `fetchPersonalFeed({limit})` | 팔로잉 사용자의 피드 (차단 제외) |

### PostService (`lib/services/PostService.dart`)

포스트 CRUD 및 인터랙션을 처리합니다.

| 메서드 | 설명 |
|--------|------|
| `createPost({...})` | 새 포스트 생성 |
| `fetchUserPosts({userId, limit})` | 사용자 포스트 조회 (가시성 필터) |
| `fetchPinnedPosts({ownerUserId})` | 핀 포스트 조회 |
| `toggleLike({postId, userId, isCurrentlyLiked})` | 좋아요 토글 (트랜잭션) |
| `addComment({postId, content})` | 댓글 추가 (트랜잭션) |
| `editComment({postId, commentId, content})` | 댓글 수정 |
| `deleteComment({postId, commentId})` | 댓글 삭제 (트랜잭션) |
| `togglePin({postId, isCurrentlyPinned})` | 핀 토글 |
| `updateFields({postId, visibility, category, value})` | 메타 필드 수정 |
| `softDelete(postId)` | 소프트 삭제 (archived=true) |
| `commentsStream({postId})` | 댓글 실시간 스트림 |
| `isLikedStream(postId)` | 좋아요 여부 스트림 |
| `isPinnedStream(postId)` | 핀 여부 스트림 |
| `likeCountStream(postId)` | 좋아요 수 스트림 |
| `commentCountStream(postId)` | 댓글 수 스트림 |

### UserService (`lib/services/UserService.dart`)

사용자 프로필 데이터를 관리합니다.

| 메서드 | 설명 |
|--------|------|
| `fetchUserForViewer(targetUid, {viewerUid})` | 뷰어 관점 프로필 조회 |
| `fetchUserRaw(uid)` | 프로필 조회 (내부용) |
| `fetchUserRegion({targetUid})` | 사용자 지역 조회 |
| `uploadProfileImage(File)` | 프로필 이미지 업로드 + Firestore 업데이트 |
| `updateStatusMessage(message)` | 상태 메시지 업데이트 |
| `fetchUserList(targetUserId, type)` | 팔로워/팔로잉/차단 목록 조회 |
| `isFollowing(viewerUid, targetUid)` | 팔로우 여부 확인 |
| `isBlocked(viewerUid, targetUid)` | 차단 여부 확인 |

### FollowService (`lib/services/FollowService.dart`)

팔로우/언팔로우/차단 관계를 관리합니다.

| 메서드 | 설명 |
|--------|------|
| `follow(targetUid)` | 팔로우 (batch write) |
| `unfollow(targetUid)` | 언팔로우 |
| `block(targetUid)` | 차단 (+ 상호 팔로우 해제) |
| `unblock(targetUid)` | 차단 해제 |
| `followerCount(userId)` | 팔로워 수 (AggregateQuery) |
| `followingCount(userId)` | 팔로잉 수 |
| `isFollowingStream(targetUid)` | 팔로우 여부 실시간 스트림 |
| `isFollowedByStream(targetUid)` | 역팔로우 여부 스트림 |
| `isBlockedStream(targetUid)` | 차단 여부 스트림 |
| `fetchFollowersPage({userId, limit, startAfter})` | 팔로워 페이지네이션 |
| `fetchFollowingPage({userId, limit, startAfter})` | 팔로잉 페이지네이션 |
| `fetchBlockedPage({userId, limit, startAfter})` | 차단 페이지네이션 |

### ProfileService (`lib/services/ProfileService.dart`)

UserService와 PostService를 조합하여 프로필 데이터를 한 번에 로딩합니다.

```dart
Future<ProfileData?> loadProfile({String? targetUserId}) async {
  final profileInfo = await userService.fetchUserRaw(uid);
  final posts = await postService.fetchUserPosts(userId: uid);
  final pinned = await postService.fetchPinnedPosts(ownerUserId: uid);
  return ProfileData(profileInfo: profileInfo, posts: posts, pinned: pinned);
}
```

### RecipeService (`lib/services/RecipeService.dart`)

Firestore에서 레시피를 조회합니다.

| 메서드 | 설명 |
|--------|------|
| `fetchLatestRecipes({limit})` | 최신 레시피 |
| `fetchRecipesByCategory({foodCategory, cookingCategory, limit})` | 카테고리별 레시피 |
| `searchRecipesByTag({tag, limit})` | 태그(재료)로 검색 |

### GuestBookService (`lib/services/GuestBookService.dart`)

프로필 게스트북(스티키 노트)을 관리합니다.

| 메서드 | 설명 |
|--------|------|
| `watchNotes(targetUserId)` | 노트 실시간 스트림 (핀→최신순) |
| `addNote(targetUserId, note)` | 노트 추가 |
| `updateNote(targetUserId, note)` | 노트 수정 |
| `deleteNote(targetUserId, noteId)` | 노트 삭제 |

---

## 보안 모델

### Post Visibility

`PostService.fetchUserPosts()`에서 뷰어 관점으로 가시성을 결정합니다:

```dart
final List<String> canSee = isOwner
    ? ['PUBLIC', 'FOLLOWER', 'PRIVATE']
    : (isFollower ? ['PUBLIC', 'FOLLOWER'] : ['PUBLIC']);
```

### Follow/Block 관계

- **팔로우**: `users/{uid}/following` + `users/{target}/followers` 양방향 기록 (batch write)
- **차단**: `users/{uid}/blocks`에 기록 + 상호 팔로우 관계 삭제
- **차단 시 규칙**: Firestore Security Rules에서 차단된 사용자의 문서 접근을 거부 (permission-denied)

### Permission 체크 패턴

```dart
// UserService에서 프로필 조회 시 차단 처리
try {
  doc = await _fs.collection('users').doc(targetUid).get();
} on FirebaseException catch (e) {
  if (e.code == 'permission-denied') {
    return null;  // 상호 차단 등으로 규칙에서 거절
  }
  rethrow;
}
```

---

## 외부 API

### OpenAI GPT-4o-mini 연동

`RecipeEditPage`에서 음성 입력된 레시피 수정 사항을 처리하기 위해 사용합니다.

- **사용 위치**: `lib/recipe/RecipeEditPage.dart`
- **API 키**: `.env` 파일의 `OPENAI_API_KEY`
- **모델**: `gpt-4o-mini`
- **용도**: 원본 레시피 + 사용자 수정 사항 → 수정된 레시피 생성
- **패키지**: `flutter_dotenv`로 환경 변수 로딩

---

## 관련 문서

- [기능 및 사용자 플로우](./FEATURES.md)
- [아키텍처](./ARCHITECTURE.md)
- [데이터 모델](./DATA_MODELS.md)
- [개발 환경 설정](./SETUP.md)
