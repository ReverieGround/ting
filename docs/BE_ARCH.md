# BE_ARCH.md — Backend Architecture

> T!ng의 백엔드 아키텍처 문서. Firebase 기반 서버리스 구조, 데이터 모델, 서비스 레이어, 인증 플로우를 다룬다.

---

## 1. Architecture Overview

### 1.1 서버리스란?

T!ng은 **서버리스(Serverless) 아키텍처**를 채택한다. 전통적인 백엔드는 별도의 서버 컴퓨터를 직접 관리해야 하지만, 서버리스는 클라우드 제공자(Firebase)가 인프라를 대신 관리한다.

> **비유**: 전통적인 백엔드가 "내 주방에서 직접 요리하는 것"이라면, 서버리스는 "공유 주방(Firebase)에서 필요한 장비를 빌려 요리하는 것"과 같다. 주방 관리(서버 유지보수)는 공유 주방 운영자가 알아서 한다.

### 1.2 전체 구조

앱에서 Firebase SDK(`@react-native-firebase/*`)를 직접 호출하여 데이터를 읽고 쓴다. 별도 백엔드 서버가 필요 없다.

```
┌──────────────────────┐
│      T!ng App        │
│   (React Native)     │
│                      │
│  사용자가 직접        │
│  상호작용하는 앱      │
└──────────┬───────────┘
           │  Firebase SDK 직접 호출
           ▼
┌──────────────────────────────────────────────────────┐
│                   Firebase Services                   │
│                                                       │
│  ┌───────────────────────────────────────────────┐   │
│  │  Firestore (NoSQL 데이터베이스)                │   │
│  │                                                │   │
│  │  users/{uid}              ← 사용자 프로필       │   │
│  │  posts/{postId}           ← 게시물              │   │
│  │    ├── likes/{uid}        ← 좋아요              │   │
│  │    └── comments/{cid}     ← 댓글                │   │
│  │  follows/{uid}            ← 팔로우 관계          │   │
│  │    ├── followers/{uid}    ← 나를 팔로우하는 사람  │   │
│  │    ├── following/{uid}    ← 내가 팔로우하는 사람  │   │
│  │    └── blocked/{uid}      ← 차단한 사람          │   │
│  │  guest_notes/{noteId}     ← 방명록               │   │
│  └───────────────────────────────────────────────┘   │
│                                                       │
│  ┌───────────────┐   ┌───────────────┐               │
│  │ Authentication │   │ Cloud Storage │               │
│  │ (Google OAuth) │   │ (이미지 저장)  │               │
│  └───────────────┘   └───────────────┘               │
└──────────────────────────────────────────────────────┘
           │
           ▼  (레시피 AI 편집 기능)
┌──────────────────────┐
│     OpenAI API       │
│    (GPT-4o-mini)     │
│  레시피 수정 요청     │
└──────────────────────┘
```

### 1.3 왜 서버리스인가?

| 장점 | 설명 |
|---|---|
| 빠른 개발 | 서버 코드 작성 없이 클라이언트에서 바로 데이터 접근 |
| 자동 확장 | 사용자 수에 따라 Firebase가 자동으로 인프라 조절 |
| 실시간 동기화 | Firestore `onSnapshot`으로 실시간 데이터 업데이트 |
| 낮은 운영 비용 | 사용량 기반 과금, 초기 비용 거의 없음 |

---

## 2. Firebase Services

### 2.1 Firestore (데이터베이스)

Firestore는 Firebase의 NoSQL 문서 데이터베이스다. JSON과 유사한 구조로 데이터를 저장하며, 실시간 데이터 동기화를 지원한다.

> **비유**: Firestore는 "실시간으로 업데이트되는 공유 스프레드시트"와 같다. 한 사용자가 데이터를 변경하면, 같은 데이터를 보고 있는 다른 사용자에게 즉시 반영된다.

- **프로젝트**: `vibeyum-alpha`
- **실시간 리스너**: `onSnapshot`을 통한 댓글, 좋아요, 방명록 자동 동기화
- **쿼리 제한 우회**: `chunk()` 유틸리티로 Firestore `whereIn` 10개 제한을 우회

```typescript
// 예시: 실시간으로 댓글 변경 감지
firestore()
  .collection('posts')
  .doc(postId)
  .collection('comments')
  .orderBy('created_at', 'desc')
  .onSnapshot(snapshot => {
    // 댓글이 추가/수정/삭제될 때마다 자동 호출
    const comments = snapshot.docs.map(doc => doc.data());
    updateUI(comments);
  });
```

### 2.2 Authentication (인증)

사용자 로그인/로그아웃을 관리한다. 현재 Google OAuth만 지원하며, 향후 Kakao/Naver 등 추가 예정이다.

- **Google OAuth**: `@react-native-google-signin/google-signin` v16.1.1
  - `webClientId`: `1088275016090-h5uuerbcan6kmskqe0rudflke5c5a95h` (웹 클라이언트)
  - `iosClientId`: `1088275016090-re9fu4ssqd2iti97kfmqjgti3k0hm2qm` (iOS 클라이언트)
- Firebase Auth `signInWithCredential(GoogleAuthProvider.credential(idToken))`
- ID 토큰을 SecureStore에 안전하게 저장 (`auth_token` 키)
- 로그인 이력 추적 (`has_logged_in_before` 키)

### 2.3 Cloud Storage (파일 저장)

이미지 파일을 클라우드에 저장하고 URL로 접근한다.

| 저장 경로 | 용도 | 예시 |
|---|---|---|
| `posts/{postId}/{uuid}.{ext}` | 게시물 이미지 | `posts/abc123/550e8400.jpg` |
| `users/{uid}/profile.{ext}` | 프로필 이미지 | `users/uid123/profile.png` |

- **업로드 패턴**: `uploadBytes` → `getDownloadURL` (업로드 후 공개 URL 획득)
- **다중 이미지**: `Promise.all()`로 여러 이미지를 동시에 업로드 (순차 대비 2~5배 빠름)
- **삭제**: `refFromURL()`로 URL에서 Storage 참조를 추출하여 삭제

---

## 3. Firestore Data Model

Firestore는 **컬렉션(Collection) → 문서(Document)** 구조를 사용한다.

> **비유**: 컬렉션은 "폴더", 문서는 "파일"이라고 생각하면 된다. `users` 폴더 안에 각 사용자별 파일(`users/uid123`)이 있고, 각 파일에 해당 사용자의 정보가 담겨 있다.

### 3.1 `users/{uid}` — 사용자 프로필

| 필드 | 타입 | 설명 | 예시 |
|---|---|---|---|
| `user_id` | string | Firebase UID (문서 ID와 동일) | `"abc123def456"` |
| `email` | string | 이메일 주소 | `"user@gmail.com"` |
| `user_name` | string | 닉네임 | `"맛집탐험가"` |
| `profile_image` | string | 프로필 이미지 URL | `"https://..."` |
| `bio` | string | 자기소개 | `"음식을 사랑합니다"` |
| `country_code` | string | 국가 코드 | `"KR"`, `"US"`, `"JP"` |
| `country_name` | string | 국가 이름 | `"한국"` |
| `provider` | string | 인증 제공자 | `"google.com"` |
| `title` | string | 사용자 타이틀 | `"푸드 크리에이터"` |
| `status_message` | string | 상태 메시지 | `"오늘도 맛있는 하루!"` |
| `created_at` | Timestamp | 가입 시각 | `serverTimestamp()` |

### 3.2 `posts/{postId}` — 게시물

| 필드 | 타입 | 설명 | 예시 |
|---|---|---|---|
| `user_id` | string | 작성자 UID | `"abc123"` |
| `post_id` | string | 게시물 ID (문서 ID) | `"post456"` |
| `title` | string | 제목 (카테고리 + 리뷰 조합) | `"요리 · Fire"` |
| `content` | string | 본문 내용 | `"오늘 만든 파스타!"` |
| `image_urls` | string[] | 이미지 URL 배열 | `["https://...", ...]` |
| `likes_count` | number | 좋아요 수 | `42` |
| `comments_count` | number | 댓글 수 | `7` |
| `category` | string | 카테고리 | `"요리"`, `"밀키트"`, `"식당"`, `"배달"` |
| `value` | string | 리뷰 값 | `"Fire"`, `"Tasty"`, `"Soso"`, `"Woops"`, `"Wack"` |
| `visibility` | string | 공개 범위 | `"PUBLIC"`, `"FOLLOWER"`, `"PRIVATE"` |
| `archived` | boolean | 소프트 삭제 여부 | `false` |
| `pin_order` | number? | 핀 순서 (핀된 게시물만) | `1` |
| `created_at` | Timestamp | 작성 시각 | `serverTimestamp()` |

### 3.3 `posts/{postId}/likes/{uid}` — 좋아요

| 필드 | 타입 | 설명 |
|---|---|---|
| `user_id` | string | 좋아요 누른 사용자 UID |
| `created_at` | Timestamp | 좋아요 시각 |

좋아요 토글 시 **Firestore Transaction**으로 `likes_count` 증감 + `likes/{uid}` 문서 추가/삭제를 **원자적(atomic)**으로 처리한다.

> **원자적 처리란?** "전부 성공하거나, 전부 실패하거나" 두 가지 결과만 보장하는 것이다. 좋아요 수를 올렸는데 문서 생성이 실패하면, 좋아요 수도 원래대로 되돌아간다.

### 3.4 `posts/{postId}/comments/{commentId}` — 댓글

| 필드 | 타입 | 설명 |
|---|---|---|
| `comment_id` | string | 댓글 ID |
| `post_id` | string | 게시물 ID |
| `user_id` | string | 작성자 UID |
| `content` | string | 댓글 내용 |
| `created_at` | Timestamp | 작성 시각 |
| `updated_at` | Timestamp | 수정 시각 |

### 3.5 `follows/{uid}` — 팔로우 관계

서브컬렉션 기반의 **양방향 관계 관리** 구조다.

```
follows/{uid}/
├── followers/{followerUid}    ← 나를 팔로우하는 사용자
│   └── { created_at: Timestamp }
├── following/{targetUid}      ← 내가 팔로우하는 사용자
│   └── { created_at: Timestamp }
└── blocked/{blockedUid}       ← 내가 차단한 사용자
    └── { created_at: Timestamp }
```

> **왜 양방향인가?** A가 B를 팔로우하면, A의 `following`에도, B의 `followers`에도 기록한다. 이렇게 하면 "내가 팔로우하는 사람 목록"과 "나를 팔로우하는 사람 목록" 모두 빠르게 조회할 수 있다.

**팔로우 처리**:
```
follow(uid, targetUid):
  1. follows/{uid}/following/{targetUid} 생성     ← "내가 팔로우함" 기록
  2. follows/{targetUid}/followers/{uid} 생성      ← "상대에게 팔로워 추가" 기록

unfollow(uid, targetUid):
  1. follows/{uid}/following/{targetUid} 삭제
  2. follows/{targetUid}/followers/{uid} 삭제
```

**차단 처리**:
```
block(uid, targetUid):
  1. 양방향 팔로우 관계 삭제 (양쪽 모두 unfollow)
  2. follows/{uid}/blocked/{targetUid} 생성

unblock(uid, targetUid):
  1. follows/{uid}/blocked/{targetUid} 삭제
```

### 3.6 `guest_notes/{noteId}` — 방명록

프로필 페이지에 남기는 포스트잇 스타일의 짧은 메모다.

| 필드 | 타입 | 설명 | 예시 |
|---|---|---|---|
| `target_uid` | string | 프로필 소유자 UID | `"owner123"` |
| `author_id` | string | 작성자 UID | `"visitor456"` |
| `author_name` | string | 작성자 닉네임 | `"맛집탐험가"` |
| `author_avatar_url` | string | 작성자 프로필 이미지 | `"https://..."` |
| `text` | string | 메모 내용 | `"프로필 멋져요!"` |
| `color` | number | ARGB 색상 코드 | `4294967040` |
| `pinned` | boolean | 상단 고정 여부 | `true` |
| `created_at` | Timestamp | 작성 시각 | `serverTimestamp()` |

**정렬 규칙**: `pinned` DESC → `created_at` DESC (고정 메모 우선, 그 다음 최신순)

### 3.7 `recipes/{recipeId}` — 레시피

| 필드 | 타입 | 설명 |
|---|---|---|
| `id` | string | 레시피 ID |
| `title` | string | 레시피 제목 |
| `tips` | string | 요리 팁 |
| `images` | object | `{ main: string, steps: string[] }` |
| `ingredients` | array | `[{ name: string, amount: string }]` |
| `methods` | array | `[{ step: number, description: string, image?: string, tip?: string }]` |
| `nutrition` | object | `{ calories, carbs, protein, fat }` (각 string) |
| `tags` | string[] | 검색용 태그 |
| `food_category` | string | 음식 종류 (한식, 양식 등) |
| `cooking_category` | string | 조리 방법 (볶음, 찜 등) |
| `created_at` | Timestamp | 작성 시각 |

---

## 4. Service Layer

모든 서비스는 `src/services/`에 정의된다. 앱의 UI(화면)와 Firebase(데이터) 사이의 **중간 다리** 역할을 한다.

> **비유**: 서비스 레이어는 "음식점의 웨이터"와 같다. 손님(UI)이 주문(요청)하면, 웨이터(서비스)가 주방(Firebase)에 전달하고, 완성된 음식(데이터)을 다시 손님에게 가져다준다.

### 4.1 authService — 인증 관리

| 함수 | 시그니처 | 설명 |
|---|---|---|
| `currentUser` | getter | 현재 Firebase Auth 사용자 객체 |
| `currentUserId` | getter | 현재 사용자 UID 문자열 |
| `onAuthStateChanged` | `(cb) → unsubscribe` | 인증 상태 변경 리스너 등록 |
| `getIdToken` | `(forceRefresh?) → string \| null` | Firebase ID 토큰 조회 |
| `saveIdToken` | `() → void` | ID 토큰을 SecureStore에 안전하게 저장 |
| `verifyStoredIdToken` | `() → boolean` | 저장된 토큰과 현재 토큰 일치 여부 확인 |
| `registerUser` | `(params) → void` | Firestore에 사용자 문서 생성 (온보딩 완료) |
| `signInWithGoogle` | `() → boolean` | Google OAuth 로그인 실행 |
| `signOut` | `() → void` | 로그아웃 (Google + Firebase + 토큰 정리) |
| `hasLoggedInBefore` | `() → boolean` | 이전 로그인 이력 확인 |
| `markHasLoggedInBefore` | `() → void` | 로그인 이력을 SecureStore에 기록 |

**`signInWithGoogle()` 전체 플로우**:
```
1. GoogleSignin.configure({ webClientId, iosClientId })   ← OAuth 설정
2. GoogleSignin.hasPlayServices()                          ← 기기 호환성 확인
3. GoogleSignin.signIn() → response.data.idToken           ← Google 로그인 팝업
4. auth.GoogleAuthProvider.credential(idToken)              ← Firebase 인증 정보 생성
5. auth().signInWithCredential(credential)                  ← Firebase에 로그인
6. saveIdToken() + markHasLoggedInBefore()                  ← 토큰 저장 + 이력 기록
```

**`registerUser()` 로직**:
```
1. currentUserId 확인 (로그인 상태인지)
2. users/{uid} 문서 존재 확인 → 이미 존재하면 중복 생성 방지
3. providerData에서 providerId 추출 (google.com 등)
4. users/{uid} 문서 생성 (user_name, country, profile_image, bio, provider, created_at)
```

### 4.2 feedService — 피드 조회

| 함수 | 설명 |
|---|---|
| `fetchRealtimeFeeds()` | 모든 공개 게시물을 최신순으로 조회. 작성자/좋아요/댓글 정보를 병합 |
| `fetchHotFeeds()` | 공개 게시물을 좋아요 수 내림차순으로 조회 |
| `fetchWackFeeds()` | value가 `Wack`인 게시물을 좋아요순으로 조회 |
| `fetchPersonalFeed()` | 내가 팔로우하는 유저의 게시물 조회 (차단한 유저 제외) |

**`buildFeedData()` — 게시물 데이터 조립 과정**:

```
PostData 하나가 주어지면 → 3가지 정보를 동시에 조회:
  1. users/{userId}               → 작성자 프로필 (UserData)
  2. posts/{postId}/likes/{myUid} → 내가 좋아요 눌렀는지 (boolean)
  3. posts/{postId}/pinOrder      → 핀 고정 여부 (선택)

→ 합쳐서 FeedData { user, post, isPinned, isLikedByUser, numLikes, numComments }
```

**Personal Feed의 `chunk()` 처리** — Firestore 쿼리 제한 우회:

```
팔로잉 UID가 25명이라면:
  [uid1, uid2, ..., uid25]
  → chunk(10)으로 분할: [[uid1~10], [uid11~20], [uid21~25]]
  → 각 10개씩 whereIn 쿼리 3개를 병렬 실행
  → 결과를 합치고 정렬
```

> **왜 10개 제한?** Firestore의 `whereIn` 쿼리는 한 번에 최대 10개 값만 비교할 수 있다. 이는 Firestore의 성능 보장을 위한 설계 제한이다.

### 4.3 postService — 게시물 CRUD

| 함수 | 설명 |
|---|---|
| `fetchUserPosts(userId, viewerId)` | 사용자의 게시물 조회 (공개 범위에 따라 필터링) |
| `fetchPinnedPosts(userId)` | 핀 고정된 게시물을 순서대로 조회 |
| `createPost(input)` | 새 게시물 생성 |
| `updateFields(postId, fields)` | 게시물 필드 수정 (visibility, category, value) |
| `softDelete(postId)` | 소프트 삭제 (`archived: true`로 변경, 실제 삭제 아님) |
| `toggleLike(postId, userId)` | 좋아요 토글 (Transaction으로 원자적 처리) |
| `pinPost` / `unpinPost` / `togglePin` | 핀 고정 관리 |
| `addComment` / `editComment` / `deleteComment` | 댓글 CRUD |
| `commentsStream(postId)` | 댓글 실시간 쿼리 반환 |
| `isLikedRef(postId, uid)` | 좋아요 상태 Firestore 참조 반환 |

**공개 범위 필터링 — 누가 어떤 게시물을 볼 수 있는가?**

```
fetchUserPosts(userId, viewerId):

  본인이 보는 경우 (userId === viewerId):
    → 모든 게시물 (PUBLIC + FOLLOWER + PRIVATE)

  팔로워가 보는 경우:
    → PUBLIC + FOLLOWER만

  일반 방문자가 보는 경우:
    → PUBLIC만

  → Firestore whereIn(['PUBLIC', ...]) 쿼리로 필터링
```

### 4.4 userService — 사용자 관리

| 함수 | 설명 |
|---|---|
| `fetchUserForViewer(userId, viewerId)` | 프로필 정보 + 관계에 따른 게시물 수 조회 |
| `fetchUserRaw(userId)` | 사용자 프로필 데이터 조회 |
| `fetchUserRegion(userId)` | 사용자 지역(국가) 조회 |
| `uploadProfileImage(uid, uri)` | 프로필 이미지 업로드 |
| `updateStatusMessage(uid, msg)` | 상태 메시지 업데이트 |
| `fetchUserList(uid, type)` | followers/following/blocked 목록 조회 |

### 4.5 followService — 팔로우 관리

| 함수 | 설명 |
|---|---|
| `follow(uid, targetUid)` | 양방향 팔로우 관계 생성 |
| `unfollow(uid, targetUid)` | 양방향 팔로우 관계 삭제 |
| `block(uid, targetUid)` | 차단 (양방향 팔로우 해제 + blocked 문서 생성) |
| `unblock(uid, targetUid)` | 차단 해제 (blocked 문서 삭제) |
| `followerCount` / `followingCount` | 팔로워/팔로잉 수 집계 |
| `isFollowingRef(uid, target)` | 팔로우 상태 Firestore 참조 반환 |
| `isBlockedRef(uid, target)` | 차단 상태 Firestore 참조 반환 |
| `fetchFollowersPage` / `fetchFollowingPage` / `fetchBlockedPage` | 페이지네이션 목록 조회 |

### 4.6 storageService — 파일 업로드

| 함수 | 설명 |
|---|---|
| `uploadPostImage(postId, uri, index)` | 단일 이미지 업로드 (메타데이터 포함) |
| `uploadPostImages(postId, uris)` | 다중 이미지 병렬 업로드 (`Promise.all`) |
| `deleteByUrl(url)` | URL 기반 파일 삭제 |

### 4.7 guestBookService — 방명록

| 함수 | 설명 |
|---|---|
| `watchQuery(userId)` | 실시간 쿼리 반환 (`pinned` DESC, `created_at` DESC 정렬) |
| `addNote(params)` | 스티키 노트 생성 |
| `updateNote(noteId, fields)` | 노트 수정 |
| `deleteNote(noteId)` | 노트 삭제 |

### 4.8 recipeService — 레시피 조회

| 함수 | 설명 |
|---|---|
| `fetchLatestRecipes()` | 최신 레시피 조회 |
| `fetchRecipesByCategory(food, cooking)` | 카테고리별 필터링 조회 |
| `searchRecipesByTag(tag)` | 태그 기반 검색 |

### 4.9 profileService — 프로필 집계

| 함수 | 설명 |
|---|---|
| `loadProfile(userId, viewerId)` | 프로필 + 게시물 + 핀 게시물을 한번에 통합 로드 |

### 4.10 gptService — AI 레시피 편집

| 함수 | 설명 |
|---|---|
| `sendRecipeEditRequest(recipe, userMessage)` | GPT-4o-mini에게 레시피 수정을 요청하고 결과를 반환 |

**GPT 연동 설정**:

| 항목 | 값 |
|---|---|
| 모델 | `gpt-4o-mini` |
| 응답 형식 | JSON (`response_format: { type: 'json_object' }`) |
| 시스템 프롬프트 | 한국어 요리 도우미 역할 |
| API 키 | `EXPO_PUBLIC_OPENAI_API_KEY` (app.config.ts의 `extra.openaiApiKey`) |

---

## 5. Authentication Flow

### 5.1 최초 로그인 (신규 사용자)

```
 사용자                     앱                         Firebase / Firestore
   │                        │                              │
   │  Google 로그인 버튼 탭  │                              │
   │ ─────────────────────> │                              │
   │                        │  GoogleSignin.signIn()       │
   │                        │ ───────────────────────────> │
   │                        │       idToken 반환            │
   │                        │ <─────────────────────────── │
   │                        │  signInWithCredential()      │
   │                        │ ───────────────────────────> │
   │                        │       인증 완료               │
   │                        │ <─────────────────────────── │
   │                        │  users/{uid} 문서 조회        │
   │                        │ ───────────────────────────> │
   │                        │       문서 없음!              │
   │                        │ <─────────────────────────── │
   │                        │                              │
   │  온보딩 페이지 표시     │  status: 'needsOnboarding'   │
   │ <───────────────────── │                              │
   │                        │                              │
   │  프로필 정보 입력       │                              │
   │ ─────────────────────> │  registerUser()              │
   │                        │ ───────────────────────────> │
   │                        │       문서 생성 완료          │
   │                        │ <─────────────────────────── │
   │  피드 페이지로 이동     │  status: 'authenticated'     │
   │ <───────────────────── │                              │
```

### 5.2 재로그인 (기존 사용자)

```
1. 앱 실행 → useAuthListener() 자동 활성화
2. Firebase Auth가 저장된 세션을 자동 복원
3. onAuthStateChanged 콜백 → user 존재 확인
4. authStore.bootstrap() 실행
5. Firestore users/{uid} 문서 확인 → 문서 + user_name 모두 존재
6. status: 'authenticated' → 피드 페이지로 바로 이동
```

### 5.3 로그아웃

```
1. GoogleSignin.signOut()              ← Google 세션 해제 (실패 시 무시)
2. auth().signOut()                    ← Firebase 세션 해제
3. SecureStore에서 auth_token 삭제     ← 저장된 토큰 정리
4. authStore → status: 'unauthenticated', user: null
5. _layout.tsx 리다이렉트 → 로그인 페이지
```

---

## 6. Token Management

| 키 | 저장소 | 용도 |
|---|---|---|
| `auth_token` | Expo SecureStore | Firebase ID 토큰 캐시 |
| `has_logged_in_before` | Expo SecureStore | 최초 로그인 여부 플래그 |

> **SecureStore란?** iOS의 Keychain, Android의 EncryptedSharedPreferences를 래핑한 Expo 모듈이다. 일반 AsyncStorage보다 보안이 강화된 저장소로, 토큰처럼 민감한 데이터를 저장하기에 적합하다.

- 로그인 성공 시 `saveIdToken()`으로 토큰을 안전하게 저장
- `verifyStoredIdToken()`으로 저장된 토큰과 현재 토큰 일치 여부 확인
- 로그아웃 시 `auth_token`을 삭제하여 보안 유지

---

## 7. Environment Variables

| 변수 | 용도 |
|---|---|
| `EXPO_PUBLIC_OPENAI_API_KEY` | OpenAI GPT-4o-mini API 키 (레시피 AI 편집) |

- `app.config.ts`의 `extra.openaiApiKey`로 런타임에서 참조
- `.env` 파일에 정의 (`.gitignore`에 포함되어 Git에 올라가지 않음)
- Firebase 설정은 `GoogleService-Info.plist`로 관리 (네이티브 모듈이 직접 읽음)

---

## 8. Technical Notes

### 8.1 RN Firebase `.exists()` — 메서드 vs 프로퍼티

React Native Firebase에서 문서 존재 여부를 확인할 때, **웹 Firebase SDK와 문법이 다르다**.

```typescript
// React Native Firebase (올바른 사용법)
const snap = await ref.get();
if (snap.exists()) { /* 문서가 존재함 */ }

// 웹 Firebase SDK 방식 (RN에서는 동작하지 않음!)
// if (snap.exists) { /* ... */ }
```

> 이 차이를 모르면 `snap.exists`가 항상 `truthy`(함수 레퍼런스)로 평가되어, 존재하지 않는 문서도 "존재한다"고 판단하는 버그가 발생한다.

### 8.2 Firestore `whereIn` 10개 제한

Firestore의 `whereIn` 쿼리는 **한 번에 최대 10개 값**만 비교할 수 있다. 팔로잉 유저가 10명을 초과하면 쿼리가 실패한다.

**해결책**: `chunk()` 유틸리티로 배열을 10개씩 분할하여 병렬 쿼리를 실행한다.

```typescript
// src/utils/chunk.ts
function chunk<T>(arr: T[], size: number): T[][] {
  const result: T[][] = [];
  for (let i = 0; i < arr.length; i += size) {
    result.push(arr.slice(i, i + size));
  }
  return result;
}

// 사용 예시: 25명의 팔로잉 → 3개 쿼리로 분할
const followingIds = ['uid1', 'uid2', ..., 'uid25'];
const chunks = chunk(followingIds, 10);
// → [['uid1'~'uid10'], ['uid11'~'uid20'], ['uid21'~'uid25']]

const results = await Promise.all(
  chunks.map(ids =>
    firestore().collection('posts').where('user_id', 'in', ids).get()
  )
);
```

### 8.3 좋아요 Transaction

좋아요 토글은 Firestore Transaction으로 **원자적(atomic)**으로 처리한다. 동시에 여러 사용자가 같은 게시물에 좋아요를 눌러도 `likes_count`가 정확하게 유지된다.

```
Transaction 동작:
  1. likes/{uid} 문서 존재 확인
  2-a. 존재함 → 문서 삭제 + likes_count -= 1  (좋아요 취소)
  2-b. 미존재 → 문서 생성 + likes_count += 1  (좋아요 추가)
  ※ 둘 중 하나라도 실패하면 모든 변경이 롤백됨
```

### 8.4 Security Considerations

**현재 상태**:

| 항목 | 상태 | 위험도 |
|---|---|---|
| Firestore 직접 접근 | 클라이언트에서 SDK로 직접 읽기/쓰기 | 중 |
| OpenAI API 키 | 클라이언트 번들에 포함됨 | **높음** |
| Firestore Security Rules | 기본 설정 | 중 |
| 이미지 업로드 제한 | 미설정 | 낮음 |

**권장 개선사항**:

1. **OpenAI API 호출을 Cloud Functions로 이전** — API 키가 클라이언트에 노출되지 않도록 서버 측에서 처리
2. **Firestore Security Rules 강화** — 문서별 읽기/쓰기 권한을 세밀하게 설정
3. **Firebase App Check 도입** — 앱이 정상적인 기기에서 실행되는지 검증
4. **이미지 업로드 크기 제한** — Storage Rules에서 파일 크기/형식 제한 추가
