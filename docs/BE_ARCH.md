# BE_ARCH.md — 백엔드 아키텍처

## 1. 아키텍처 개요

T!ng은 **서버리스 아키텍처**를 채택하며, Firebase를 전면 사용한다. 별도 백엔드 서버 없이 클라이언트에서 Firebase SDK (`@react-native-firebase/*`)를 직접 호출하여 데이터를 읽고 쓴다.

```
┌──────────────────┐
│   T!ng App       │
│  (React Native)  │
└────────┬─────────┘
         │
         ▼
┌────────────────────────────────────────────────────┐
│                  Firebase Services                  │
│                                                     │
│  ┌─────────────────────────────────────────────┐   │
│  │  Firestore                                   │   │
│  │  ├── users/{uid}                            │   │
│  │  ├── posts/{postId}                         │   │
│  │  │   ├── likes/{uid}                        │   │
│  │  │   └── comments/{commentId}               │   │
│  │  ├── follows/{uid}                          │   │
│  │  │   ├── followers/{uid}                    │   │
│  │  │   ├── following/{uid}                    │   │
│  │  │   └── blocked/{uid}                      │   │
│  │  ├── guest_notes/{noteId}                   │   │
│  │  └── recipes/{recipeId}                     │   │
│  └─────────────────────────────────────────────┘   │
│                                                     │
│  ┌──────────────┐  ┌──────────────┐               │
│  │ Auth         │  │ Storage      │               │
│  │ (Google)     │  │ (Images)     │               │
│  └──────────────┘  └──────────────┘               │
└────────────────────────────────────────────────────┘
         │
         ▼
┌──────────────────┐
│   OpenAI API     │
│  (GPT-4o-mini)   │
│  레시피 AI 편집   │
└──────────────────┘
```

---

## 2. Firebase 서비스

### 2.1 Firestore (데이터베이스)

실시간 데이터 동기화와 영구 저장을 담당한다.

- **프로젝트**: `vibeyum-alpha`
- 실시간 리스너 (`onSnapshot`)를 통한 댓글, 좋아요, 방명록 동기화
- `chunk()` 유틸리티로 Firestore `whereIn` 10개 제한 우회

### 2.2 Authentication

- **Google OAuth**: `@react-native-google-signin/google-signin`
  - `webClientId`: `1088275016090-h5uuerbcan6kmskqe0rudflke5c5a95h` (웹 클라이언트)
  - `iosClientId`: `1088275016090-re9fu4ssqd2iti97kfmqjgti3k0hm2qm` (iOS 클라이언트)
- Firebase Auth `signInWithCredential(GoogleAuthProvider.credential(idToken))`
- ID 토큰 SecureStore 저장 (`auth_token` 키)
- 로그인 이력 추적 (`has_logged_in_before` 키)

### 2.3 Storage

- 게시물 이미지: `posts/{postId}/{uuid}.{ext}`
- 프로필 이미지: `users/{uid}/profile.{ext}`
- `uploadBytes` → `getDownloadURL` 패턴
- 다중 이미지 병렬 업로드 (`Promise.all`)
- URL 기반 파일 삭제 (`refFromURL`)

---

## 3. Firestore 데이터 모델

### 3.1 `users/{uid}` (사용자 프로필)

| 필드 | 타입 | 설명 |
|---|---|---|
| `user_id` | string | Firebase UID (문서 ID와 동일) |
| `email` | string | 이메일 주소 |
| `user_name` | string | 닉네임 |
| `profile_image` | string | 프로필 이미지 URL |
| `bio` | string | 자기소개 |
| `country_code` | string | 국가 코드 (KR, US, JP) |
| `country_name` | string | 국가 이름 |
| `provider` | string | 인증 제공자 (google.com 등) |
| `title` | string | 사용자 타이틀 |
| `status_message` | string | 상태 메시지 |
| `created_at` | Timestamp | 가입 시각 (`serverTimestamp()`) |

### 3.2 `posts/{postId}` (게시물)

| 필드 | 타입 | 설명 |
|---|---|---|
| `user_id` | string | 작성자 UID |
| `post_id` | string | 게시물 ID (문서 ID와 동일) |
| `title` | string | 제목 (카테고리 + 리뷰 조합) |
| `content` | string | 본문 내용 |
| `image_urls` | string[] | 이미지 URL 배열 |
| `likes_count` | number | 좋아요 수 |
| `comments_count` | number | 댓글 수 |
| `category` | string | 카테고리 (요리/밀키트/식당/배달) |
| `value` | string | 리뷰 값 (Fire/Tasty/Soso/Woops/Wack) |
| `visibility` | string | `PUBLIC` \| `FOLLOWER` \| `PRIVATE` |
| `archived` | boolean | 소프트 삭제 여부 |
| `pin_order` | number? | 핀 순서 (핀된 게시물만) |
| `created_at` | Timestamp | 작성 시각 |

### 3.3 `posts/{postId}/likes/{uid}` (좋아요)

| 필드 | 타입 | 설명 |
|---|---|---|
| `user_id` | string | 좋아요 누른 사용자 UID |
| `created_at` | Timestamp | 좋아요 시각 |

좋아요 토글 시 Firestore Transaction으로 `likes_count` 증감 + `likes/{uid}` 문서 추가/삭제를 원자적으로 처리한다.

### 3.4 `posts/{postId}/comments/{commentId}` (댓글)

| 필드 | 타입 | 설명 |
|---|---|---|
| `comment_id` | string | 댓글 ID |
| `post_id` | string | 게시물 ID |
| `user_id` | string | 작성자 UID |
| `content` | string | 댓글 내용 |
| `created_at` | Timestamp | 작성 시각 |
| `updated_at` | Timestamp | 수정 시각 |

### 3.5 `follows/{uid}` (팔로우 관계)

서브컬렉션 기반 양방향 관계 관리:

```
follows/{uid}/
├── followers/{followerUid}    — 나를 팔로우하는 사용자
│   └── { created_at: Timestamp }
├── following/{targetUid}      — 내가 팔로우하는 사용자
│   └── { created_at: Timestamp }
└── blocked/{blockedUid}       — 내가 차단한 사용자
    └── { created_at: Timestamp }
```

**팔로우 처리**:
```
follow(uid, targetUid):
  1. follows/{uid}/following/{targetUid} 생성
  2. follows/{targetUid}/followers/{uid} 생성

unfollow(uid, targetUid):
  1. follows/{uid}/following/{targetUid} 삭제
  2. follows/{targetUid}/followers/{uid} 삭제
```

**차단 처리**:
```
block(uid, targetUid):
  1. 양방향 팔로우 관계 삭제 (unfollow 양쪽)
  2. follows/{uid}/blocked/{targetUid} 생성

unblock(uid, targetUid):
  1. follows/{uid}/blocked/{targetUid} 삭제
```

### 3.6 `guest_notes/{noteId}` (방명록)

| 필드 | 타입 | 설명 |
|---|---|---|
| `target_uid` | string | 프로필 소유자 UID |
| `author_id` | string | 작성자 UID |
| `author_name` | string | 작성자 닉네임 |
| `author_avatar_url` | string | 작성자 프로필 이미지 |
| `text` | string | 메모 내용 |
| `color` | number | ARGB 색상 코드 |
| `pinned` | boolean | 상단 고정 여부 |
| `created_at` | Timestamp | 작성 시각 |

정렬: `pinned` DESC → `created_at` DESC

### 3.7 `recipes/{recipeId}` (레시피)

| 필드 | 타입 | 설명 |
|---|---|---|
| `id` | string | 레시피 ID |
| `title` | string | 레시피 제목 |
| `tips` | string | 요리 팁 |
| `images` | object | `{ main: string, steps: string[] }` |
| `ingredients` | array | `[{ name, amount }]` |
| `methods` | array | `[{ step, description, image?, tip? }]` |
| `nutrition` | object | `{ calories, carbs, protein, fat }` |
| `tags` | string[] | 검색용 태그 |
| `food_category` | string | 음식 종류 |
| `cooking_category` | string | 조리 방법 |
| `created_at` | Timestamp | 작성 시각 |

---

## 4. 서비스 레이어

모든 서비스는 `src/services/`에 정의된다. Firebase SDK를 직접 호출하는 비즈니스 로직 계층이다.

### 4.1 authService — 인증 관리

| 함수 | 시그니처 | 설명 |
|---|---|---|
| `currentUser` | getter | 현재 Firebase Auth 사용자 |
| `currentUserId` | getter | 현재 사용자 UID |
| `onAuthStateChanged` | `(cb) → unsubscribe` | 인증 상태 리스너 |
| `getIdToken` | `(forceRefresh?) → string \| null` | Firebase ID 토큰 조회 |
| `saveIdToken` | `() → void` | ID 토큰 SecureStore 저장 |
| `verifyStoredIdToken` | `() → boolean` | 저장된 토큰 유효성 검증 |
| `registerUser` | `(params) → void` | Firestore 사용자 문서 생성 |
| `signInWithGoogle` | `() → boolean` | Google OAuth 로그인 |
| `signOut` | `() → void` | 로그아웃 (Google + Firebase + SecureStore 정리) |
| `hasLoggedInBefore` | `() → boolean` | 이전 로그인 이력 확인 |
| `markHasLoggedInBefore` | `() → void` | 로그인 이력 기록 |

**`signInWithGoogle()` 플로우**:
```
1. GoogleSignin.configure({ webClientId, iosClientId })
2. GoogleSignin.hasPlayServices()
3. GoogleSignin.signIn() → response.data.idToken
4. auth.GoogleAuthProvider.credential(idToken)
5. auth().signInWithCredential(credential)
6. saveIdToken() + markHasLoggedInBefore()
```

**`registerUser()` 로직**:
```
1. currentUserId 확인
2. users/{uid} 문서 존재 확인 → 이미 존재하면 리턴
3. providerData에서 providerId 추출
4. users/{uid} 문서 생성 (user_name, country, profile_image, bio, provider, created_at)
```

### 4.2 feedService — 피드 조회

| 함수 | 설명 |
|---|---|
| `fetchRealtimeFeeds()` | 공개 게시물 최신순 조회, 사용자/좋아요/댓글 정보 병합 |
| `fetchHotFeeds()` | 공개 게시물 좋아요순 조회 |
| `fetchWackFeeds()` | Wack 리뷰 게시물 좋아요순 조회 |
| `fetchPersonalFeed()` | 팔로잉 유저 게시물 조회 (차단 유저 제외) |

**`buildFeedData()` 헬퍼**:
```
PostData → 병렬로:
  1. users/{userId} 조회 → UserData
  2. posts/{postId}/likes/{myUid} 조회 → isLikedByUser
  3. (선택) posts/{postId}/pinOrder 조회 → isPinned
→ FeedData { user, post, isPinned, isLikedByUser, numLikes, numComments }
```

**Personal Feed의 `chunk()` 처리**:
```
팔로잉 UID 목록 → chunk(10)으로 분할 (Firestore whereIn 10개 제한)
→ 각 청크별 posts 쿼리 → 병합 → 정렬
```

### 4.3 postService — 게시물 CRUD

| 함수 | 설명 |
|---|---|
| `fetchUserPosts(userId, viewerId)` | 사용자 게시물 조회 (공개 범위 필터링) |
| `fetchPinnedPosts(userId)` | 핀된 게시물 순서대로 조회 |
| `createPost(input)` | 게시물 생성 |
| `updateFields(postId, fields)` | 필드 업데이트 (visibility, category, value) |
| `softDelete(postId)` | 소프트 삭제 (archived: true) |
| `toggleLike(postId, userId)` | 좋아요 토글 (Transaction) |
| `pinPost/unpinPost/togglePin` | 핀 관리 |
| `addComment/editComment/deleteComment` | 댓글 CRUD |
| `commentsStream(postId)` | 댓글 실시간 쿼리 반환 |
| `isLikedRef(postId, uid)` | 좋아요 상태 참조 반환 |

**공개 범위 필터링 로직**:
```
fetchUserPosts(userId, viewerId):
  if userId === viewerId:
    → 모든 게시물 (PUBLIC + FOLLOWER + PRIVATE)
  else if 팔로워인 경우:
    → PUBLIC + FOLLOWER
  else:
    → PUBLIC만
  → Firestore whereIn(['PUBLIC', ...]) 쿼리
```

### 4.4 userService — 사용자 관리

| 함수 | 설명 |
|---|---|
| `fetchUserForViewer(userId, viewerId)` | 프로필 + 관계 기반 게시물 수 조회 |
| `fetchUserRaw(userId)` | 현재 사용자 프로필 조회 |
| `fetchUserRegion(userId)` | 사용자 지역 조회 |
| `uploadProfileImage(uid, uri)` | 프로필 이미지 업로드 |
| `updateStatusMessage(uid, msg)` | 상태 메시지 업데이트 |
| `fetchUserList(uid, type)` | followers/following/blocked 목록 조회 |

### 4.5 followService — 팔로우 관리

| 함수 | 설명 |
|---|---|
| `follow(uid, targetUid)` | 양방향 팔로우 생성 |
| `unfollow(uid, targetUid)` | 양방향 팔로우 삭제 |
| `block(uid, targetUid)` | 차단 (팔로우 해제 + blocked 생성) |
| `unblock(uid, targetUid)` | 차단 해제 |
| `followerCount/followingCount` | 팔로워/팔로잉 수 집계 |
| `isFollowingRef(uid, target)` | 팔로우 상태 참조 반환 |
| `isBlockedRef(uid, target)` | 차단 상태 참조 반환 |
| `fetchFollowersPage/FollowingPage/BlockedPage` | 페이지네이션 목록 |

### 4.6 storageService — 파일 업로드

| 함수 | 설명 |
|---|---|
| `uploadPostImage(postId, uri, index)` | 단일 이미지 업로드 (메타데이터 포함) |
| `uploadPostImages(postId, uris)` | 다중 이미지 병렬 업로드 |
| `deleteByUrl(url)` | URL 기반 파일 삭제 |

### 4.7 guestBookService — 방명록

| 함수 | 설명 |
|---|---|
| `watchQuery(userId)` | 실시간 쿼리 반환 (pinned DESC, created_at DESC) |
| `addNote(params)` | 스티키 노트 생성 |
| `updateNote(noteId, fields)` | 노트 수정 |
| `deleteNote(noteId)` | 노트 삭제 |

### 4.8 recipeService — 레시피 조회

| 함수 | 설명 |
|---|---|
| `fetchLatestRecipes()` | 최신 레시피 조회 |
| `fetchRecipesByCategory(food, cooking)` | 카테고리별 필터 |
| `searchRecipesByTag(tag)` | 태그 검색 |

### 4.9 profileService — 프로필 집계

| 함수 | 설명 |
|---|---|
| `loadProfile(userId, viewerId)` | 프로필 + 게시물 + 핀 게시물 통합 로드 |

### 4.10 gptService — AI 레시피 편집

| 함수 | 설명 |
|---|---|
| `sendRecipeEditRequest(recipe, userMessage)` | GPT-4o-mini로 레시피 수정 요청 |

**GPT 설정**:
- 모델: `gpt-4o-mini`
- 응답 형식: JSON (`response_format: { type: 'json_object' }`)
- 시스템 프롬프트: 한국어 요리 도우미 역할
- API 키: `EXPO_PUBLIC_OPENAI_API_KEY` (app.config.ts `extra.openaiApiKey`)

---

## 5. 인증 플로우

### 5.1 최초 로그인

```
1. 사용자 → Google 로그인 버튼 탭
2. GoogleSignin.signIn() → Google OAuth 화면
3. idToken 획득 → Firebase signInWithCredential()
4. authStore.bootstrap() 실행
5. Firestore users/{uid} 조회
6. 문서 없음 or user_name 누락 → status: 'needsOnboarding'
7. _layout.tsx 리다이렉트 → /(onboarding)/setup
8. 프로필 입력 → authService.registerUser() → 문서 생성
9. authStore.setStatus('authenticated')
10. _layout.tsx 리다이렉트 → /(tabs)/feed
```

### 5.2 재로그인

```
1. 앱 실행 → useAuthListener() 활성화
2. Firebase Auth 자동 세션 복원
3. onAuthStateChanged → user 존재
4. authStore.bootstrap()
5. Firestore users/{uid} 확인 → 문서 + user_name 존재
6. status: 'authenticated'
7. _layout.tsx 리다이렉트 → /(tabs)/feed
```

### 5.3 로그아웃

```
1. GoogleSignin.signOut() (실패 무시)
2. auth().signOut()
3. SecureStore에서 auth_token 삭제
4. authStore → status: 'unauthenticated', user: null
5. _layout.tsx 리다이렉트 → /(auth)/login
```

---

## 6. 토큰 관리

| 키 | 저장소 | 용도 |
|---|---|---|
| `auth_token` | Expo SecureStore | Firebase ID 토큰 캐시 |
| `has_logged_in_before` | Expo SecureStore | 최초 로그인 여부 플래그 |

- 로그인 성공 시 `saveIdToken()`으로 토큰 저장
- `verifyStoredIdToken()`으로 저장된 토큰과 현재 토큰 일치 여부 확인
- 로그아웃 시 `auth_token` 삭제

---

## 7. 환경 변수

| 변수 | 용도 |
|---|---|
| `EXPO_PUBLIC_OPENAI_API_KEY` | OpenAI GPT-4o-mini API 키 (레시피 AI 편집) |

- `app.config.ts`의 `extra.openaiApiKey`로 참조
- `.env` 파일에 정의 (gitignored)
- Firebase 설정은 `GoogleService-Info.plist`로 관리 (네이티브 모듈)

---

## 8. 주요 기술 노트

### 8.1 RN Firebase `.exists()` 메서드

React Native Firebase에서 `doc.exists`는 메서드 `.exists()`이다 (웹 Firebase SDK의 프로퍼티 `.exists`와 다름).

```typescript
// 올바른 사용
const snap = await ref.get();
if (snap.exists()) { ... }

// 웹 SDK 방식 (RN에서는 동작하지 않음)
// if (snap.exists) { ... }
```

### 8.2 Firestore `whereIn` 10개 제한

Firestore의 `whereIn` 쿼리는 최대 10개 값만 허용한다. `chunk()` 유틸리티로 배열을 10개씩 분할하여 여러 쿼리를 병렬 실행한다.

```typescript
// src/utils/chunk.ts
function chunk<T>(arr: T[], size: number): T[][] {
  const result: T[][] = [];
  for (let i = 0; i < arr.length; i += size) {
    result.push(arr.slice(i, i + size));
  }
  return result;
}
```

### 8.3 좋아요 Transaction

좋아요 토글은 Firestore Transaction으로 원자적으로 처리한다:

```
Transaction:
  1. likes/{uid} 문서 존재 확인
  2-a. 존재 → 삭제 + likes_count -= 1
  2-b. 미존재 → 생성 + likes_count += 1
```

### 8.4 보안 고려사항

**현재 상태**:
- 클라이언트에서 Firestore를 직접 읽고 쓰는 구조
- OpenAI API 키가 클라이언트 번들에 포함됨

**권장 개선사항**:
1. OpenAI API 호출을 Cloud Functions로 이전
2. Firestore Security Rules 강화
3. Firebase App Check 도입
4. 이미지 업로드 크기 제한 규칙 추가
