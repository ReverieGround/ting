# FE_ARCH.md — Frontend Architecture

> T!ng의 프론트엔드 아키텍처 문서. 기술 스택, 프로젝트 구조, 네비게이션, 상태 관리, 컴포넌트 설계를 다룬다.

---

## 1. Tech Stack

| 분류 | 기술 | 버전 | 용도 |
|---|---|---|---|
| **Framework** | React + React Native | 19.1.0 + 0.81.5 | UI 렌더링 엔진 |
| **Platform** | Expo SDK | ~54.0.33 | 개발/빌드 프레임워크 (네이티브 기능 래핑) |
| **Navigation** | Expo Router | ^6.0.23 | 파일 기반 라우팅 + 딥링킹 |
| **Auth State** | Zustand | ^5.0.11 | 인증 상태 관리 (가벼운 전역 상태) |
| **Server State** | React Query (TanStack) | ^5.90.21 | 서버 데이터 페칭/캐싱/동기화 |
| **Styling** | React Native StyleSheet | 내장 | 인라인 스타일 (CSS 파일 없음) |
| **Backend SDK** | React Native Firebase | ^23.8.6 | Auth, Firestore, Storage 접근 |
| **Images** | expo-image | ^3.0.11 | 고성능 이미지 렌더링 + 캐싱 |
| **Lists** | @shopify/flash-list | 2.0.2 | 대량 리스트 고성능 렌더링 |
| **Icons** | @expo/vector-icons (Ionicons) | 내장 | UI 아이콘 세트 |
| **Animation** | react-native-reanimated | ~4.1.1 | GPU 기반 네이티브 애니메이션 |
| **AI** | OpenAI GPT-4o-mini | API | 레시피 AI 편집 |
| **Voice** | expo-speech-recognition | ^3.1.0 | 한국어 음성 인식 |

> **Expo란?** React Native 위에 구축된 프레임워크로, 네이티브 기능(카메라, 파일 시스템, 푸시 알림 등)을 쉽게 사용할 수 있게 해준다. "React Native의 편의점"이라고 생각하면 된다 — 필요한 것을 직접 만들 필요 없이 꺼내 쓸 수 있다.

---

## 2. Project Structure

```
ting-rn/
├── app/                              # Expo Router 라우트 (파일 = 페이지)
│   ├── _layout.tsx                   # 루트 레이아웃 (인증 리다이렉트, 프로바이더 설정)
│   ├── index.tsx                     # 스플래시 화면 (로딩 스피너)
│   ├── (auth)/
│   │   └── login.tsx                 # 로그인 페이지
│   ├── (onboarding)/
│   │   └── setup.tsx                 # 프로필 설정 (온보딩)
│   └── (tabs)/
│       ├── _layout.tsx               # 하단 탭 바 레이아웃 (4개 탭)
│       ├── feed/
│       │   ├── _layout.tsx           # 피드 내부 Stack 네비게이터
│       │   ├── index.tsx             # 피드 목록
│       │   └── [postId].tsx          # 게시물 상세 + 댓글
│       ├── recipes/
│       │   ├── _layout.tsx           # 레시피 내부 Stack 네비게이터
│       │   ├── index.tsx             # 레시피 목록
│       │   ├── [recipeId].tsx        # 레시피 상세
│       │   └── edit.tsx              # 레시피 편집 (요리 기록)
│       ├── create/
│       │   ├── _layout.tsx           # 작성 내부 Stack 네비게이터
│       │   ├── index.tsx             # 게시물 작성
│       │   └── confirm.tsx           # 게시물 확인 + 업로드
│       ├── profile/
│       │   ├── _layout.tsx           # 프로필 내부 Stack 네비게이터
│       │   ├── index.tsx             # 내 프로필
│       │   └── [userId].tsx          # 다른 사용자 프로필
│       └── users/
│           ├── _layout.tsx           # 유저 목록 Stack 네비게이터
│           └── [userId]/
│               └── list.tsx          # 팔로워/팔로잉/차단 목록
│
├── src/
│   ├── components/                   # 재사용 UI 컴포넌트 (총 19개)
│   │   ├── common/ (3개)             # ProfileAvatar, Tag, TimeAgoText
│   │   ├── create/ (5개)             # CategoryChips, ReviewChips, DatePickerButton,
│   │   │                             #   PostTextField, LinkInputRow
│   │   ├── feed/ (6개)               # FeedCard, Head, Content, FeedImages,
│   │   │                             #   StatIcons, CommentTile
│   │   └── profile/ (5개)            # ProfileHeader, FollowButton, YumTab,
│   │                                 #   GuestBookTab, StickyNoteCard
│   ├── hooks/ (8개)                  # 커스텀 훅
│   │   ├── useAuth.ts                # Firebase Auth 상태 리스너
│   │   ├── useFeed.ts                # React Query 피드 데이터 훅
│   │   ├── useComments.ts            # 실시간 댓글 CRUD
│   │   ├── useProfile.ts             # React Query 프로필 데이터 훅
│   │   ├── useRecipes.ts             # React Query 레시피 데이터 훅
│   │   ├── useFirestoreStream.ts     # 범용 Firestore 실시간 리스너
│   │   ├── useLike.ts                # Optimistic 좋아요 토글
│   │   └── useFollow.ts              # Optimistic 팔로우 토글
│   ├── services/ (10개)              # Firebase 서비스 레이어 (BE_ARCH.md 참조)
│   ├── stores/
│   │   └── authStore.ts              # Zustand 인증 상태 스토어
│   ├── theme/
│   │   └── colors.ts                 # 색상, 간격, 라디우스 상수
│   ├── types/ (5개)                  # TypeScript 인터페이스
│   │   ├── user.ts                   # UserData, ProfileInfo
│   │   ├── post.ts                   # PostData, PostInputData, Visibility
│   │   ├── feed.ts                   # FeedData
│   │   ├── recipe.ts                 # Recipe, Ingredient, Nutrition, Method
│   │   └── guestbook.ts              # StickyNote, FollowEntry
│   └── utils/ (4개)                  # 유틸리티 함수
│       ├── chunk.ts                  # 배열을 N개씩 분할
│       ├── formatTimestamp.ts         # 날짜 포맷 + 한국어 상대 시간
│       ├── formatNumber.ts            # 숫자 축약 (1k, 1m)
│       └── koreanGrammar.ts           # 한국어 조사 자동 처리
│
├── assets/                           # 앱 아이콘, 스플래시 이미지
├── plugins/
│   └── withFirebaseFixes.js          # Firebase iOS 빌드 커스텀 Expo 플러그인
├── app.config.ts                     # Expo 설정 (앱 이름, 번들 ID, 플러그인 등)
├── eas.json                          # EAS Build 프로파일 (개발/프리뷰/프로덕션)
├── GoogleService-Info.plist          # Firebase iOS 설정 파일
├── deploy-testflight.sh              # TestFlight 원클릭 배포 스크립트
└── run-simulator.sh                  # iOS 시뮬레이터 실행 스크립트
```

> **파일 기반 라우팅이란?** `app/` 디렉토리에 파일을 만들면 자동으로 페이지가 생긴다. 예를 들어 `app/(tabs)/feed/index.tsx` 파일은 `/feed` 경로의 페이지가 된다. URL 경로를 별도로 설정할 필요가 없다.

---

## 3. Navigation

### 3.1 라우트 구조

Expo Router v6의 파일 기반 라우팅을 사용한다. `(auth)`, `(onboarding)`, `(tabs)` 그룹 라우트로 인증 상태별 화면을 분리한다.

```
경로                            파일                       설명
/                             → index.tsx                 스플래시 (로딩)
/(auth)/login                 → (auth)/login.tsx          로그인 화면
/(onboarding)/setup           → (onboarding)/setup.tsx    프로필 설정
/(tabs)/feed                  → (tabs)/feed/index.tsx     피드 목록
/(tabs)/feed/[postId]         → (tabs)/feed/[postId].tsx  게시물 상세
/(tabs)/recipes               → (tabs)/recipes/index.tsx  레시피 목록
/(tabs)/recipes/[recipeId]    → (tabs)/recipes/[id].tsx   레시피 상세
/(tabs)/recipes/edit          → (tabs)/recipes/edit.tsx   레시피 편집
/(tabs)/create                → (tabs)/create/index.tsx   게시물 작성
/(tabs)/create/confirm        → (tabs)/create/confirm.tsx 게시물 확인
/(tabs)/profile               → (tabs)/profile/index.tsx  내 프로필
/(tabs)/profile/[userId]      → (tabs)/profile/[uid].tsx  타 사용자 프로필
/(tabs)/users/[userId]/list   → (tabs)/users/.../list.tsx 팔로워/팔로잉 목록
```

### 3.2 인증 가드 (Auth Guard)

`app/_layout.tsx`(루트 레이아웃)에서 **중앙 집중식 리다이렉트**를 수행한다. 인증 상태에 따라 사용자를 올바른 페이지로 자동 이동시킨다.

> **비유**: 건물 입구의 경비원처럼, 모든 사용자의 "통행증(인증 상태)"을 확인하고 올바른 층(페이지)으로 안내하는 역할이다.

```typescript
// app/_layout.tsx — 인증 상태에 따른 자동 리다이렉트
useEffect(() => {
  if (status === 'initializing') return;  // 아직 확인 중이면 대기

  const inAuth = segments[0] === '(auth)';
  const inOnboarding = segments[0] === '(onboarding)';
  const inTabs = segments[0] === '(tabs)';

  // 미로그인 → 로그인 페이지로
  if (status === 'unauthenticated' && !inAuth)
    router.replace('/(auth)/login');

  // 로그인 했지만 프로필 미완성 → 온보딩으로
  else if (status === 'needsOnboarding' && !inOnboarding)
    router.replace('/(onboarding)/setup');

  // 완전 인증 → 피드로
  else if (status === 'authenticated' && !inTabs)
    router.replace('/(tabs)/feed');
}, [status, segments, router]);
```

### 3.3 탭 바 (Tab Bar)

4개의 메인 탭과 1개의 숨김 라우트로 구성된다.

| 탭 | 라벨 | 아이콘 | 라우트 | 비고 |
|---|---|---|---|---|
| 커뮤니티 | 커뮤니티 | `chatbubbles-outline` | `feed/` | 메인 피드 |
| 요리하기 | 요리하기 | `book-outline` | `recipes/` | 레시피 탐색 |
| 기록 | 기록 | `create-outline` | `create/` | 게시물 작성 |
| 프로필 | 프로필 | `person-outline` | `profile/` | 내 프로필 |
| *(숨김)* | — | — | `users/` | 팔로워/팔로잉 목록 (`href: null`로 탭 바에 비표시) |

### 3.4 중첩 라우트 (Nested Routes)

각 탭 디렉토리에 `_layout.tsx`를 두어 **Stack 네비게이터**를 생성한다. 이렇게 하면 탭 내부에서 상세 페이지로 이동할 때 별도의 탭이 생기지 않고, 같은 탭 안에서 화면이 쌓인다.

> **비유**: 책의 챕터(탭) 안에서 페이지(화면)를 넘기는 것과 같다. 피드 탭 안에서 게시물 상세로 이동해도 여전히 "피드" 탭에 머물러 있다.

```typescript
// app/(tabs)/feed/_layout.tsx — 피드 탭 내부 Stack
export default function FeedLayout() {
  return (
    <Stack screenOptions={{
      headerShown: false,                          // 기본 헤더 숨김
      contentStyle: { backgroundColor: colors.bgLight },  // 배경색 통일
    }} />
  );
}
```

---

## 4. State Management

앱의 상태 관리는 크게 3가지 방식으로 나뉜다.

```
┌────────────────────────────────────────────────────────────┐
│                    상태 관리 전략                            │
├──────────────────┬──────────────────┬──────────────────────┤
│    Zustand       │   React Query    │  Firestore 리스너     │
│  (인증 상태)      │  (서버 데이터)    │  (실시간 동기화)       │
├──────────────────┼──────────────────┼──────────────────────┤
│ 로그인/로그아웃   │ 피드 목록         │ 좋아요 상태           │
│ 앱 상태 전환     │ 프로필 정보       │ 팔로우 상태           │
│                  │ 레시피 목록       │ 댓글 목록             │
│                  │                  │ 방명록                │
└──────────────────┴──────────────────┴──────────────────────┘
```

### 4.1 Zustand — 인증 상태 (authStore)

Zustand는 가벼운 전역 상태 관리 라이브러리다. T!ng에서는 **인증 상태 관리** 전용으로 사용한다.

> **비유**: Zustand는 "앱의 신분증 관리소"와 같다. 사용자가 누구인지, 로그인 상태가 무엇인지를 앱 전체에서 일관되게 관리한다.

```typescript
// 앱의 4가지 인증 상태
type AppStatus =
  | 'initializing'      // 앱 부팅 중 — Firebase 세션 확인 중
  | 'unauthenticated'   // 미로그인 — 로그인 페이지 표시
  | 'needsOnboarding'   // 로그인 완료, 프로필 미완성 — 온보딩 페이지 표시
  | 'authenticated';     // 완전 인증 — 메인 앱 사용 가능

interface AuthState {
  status: AppStatus;
  user: FirebaseAuthTypes.User | null;
  userId: string | null;
  bootstrap(): Promise<void>;          // 앱 시작 시 상태 결정
  setStatus(status: AppStatus): void;  // 상태 직접 변경
  signOut(): Promise<void>;            // 로그아웃
}
```

**`bootstrap()` — 앱 시작 시 인증 상태 결정 로직**:

```
앱 시작
  │
  ├─ auth().currentUser가 null? → status: 'unauthenticated' (로그인 필요)
  │
  └─ auth().currentUser가 있음
       │
       ├─ Firestore users/{uid} 문서가 없거나
       │  user_name/country_code가 누락?
       │    → status: 'needsOnboarding' (프로필 설정 필요)
       │
       └─ 모두 존재
            → status: 'authenticated' (메인 앱 진입)
```

### 4.2 React Query — 서버 데이터

서버에서 가져오는 데이터(피드, 프로필, 레시피)의 페칭과 캐싱을 React Query v5가 담당한다.

> **비유**: React Query는 "데이터 배달 서비스"다. 한 번 주문(fetch)한 데이터는 일정 시간 동안 보관(cache)해두고, 같은 데이터를 다시 요청하면 서버에 가지 않고 보관된 것을 바로 전달한다.

```typescript
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60 * 5,  // 5분 동안 "신선"하다고 간주 (재요청 안 함)
      retry: 2,                   // 실패 시 2번까지 재시도
    },
  },
});
```

**React Query 훅 목록**:

| 훅 | 쿼리 키 | 데이터 소스 |
|---|---|---|
| `useRealtimeFeed()` | `['feed', 'realtime']` | `feedService.fetchRealtimeFeeds()` |
| `useHotFeed()` | `['feed', 'hot']` | `feedService.fetchHotFeeds()` |
| `useWackFeed()` | `['feed', 'wack']` | `feedService.fetchWackFeeds()` |
| `usePersonalFeed()` | `['feed', 'personal']` | `feedService.fetchPersonalFeed()` |
| `useProfile(uid)` | `['profile', uid]` | `profileService.loadProfile()` |
| `useLatestRecipes()` | `['recipes', 'latest']` | `recipeService.fetchLatestRecipes()` |
| `useRecipesByCategory()` | `['recipes', 'category', ...]` | `recipeService.fetchRecipesByCategory()` |
| `useRecipeSearch(tag)` | `['recipes', 'search', tag]` | `recipeService.searchRecipesByTag()` |

### 4.3 Firestore 실시간 리스너

좋아요, 팔로우, 댓글, 방명록처럼 **즉시 반영이 필요한 데이터**는 Firestore 실시간 리스너를 사용한다.

`useFirestoreStream.ts`에서 범용 실시간 리스너 훅을 제공한다:

```typescript
// 단일 문서 구독 — 특정 문서의 변경을 실시간으로 감지
useFirestoreDoc<T>(ref, transform?)
  → { data: T | null, exists: boolean, loading: boolean }

// 컬렉션 쿼리 구독 — 쿼리 결과의 변경을 실시간으로 감지
useFirestoreQuery<T>(query, transform)
  → { data: T[], loading: boolean }
```

**사용처**:

| 훅 | 리스너 | 감지 대상 |
|---|---|---|
| `useLike` | `postService.isLikedRef()` | 좋아요 상태 변경 |
| `useFollow` | `followService.isFollowingRef()` | 팔로우 상태 변경 |
| `useComments` | `postService.commentsStream()` | 댓글 추가/수정/삭제 |
| `GuestBookTab` | `guestBookService.watchQuery()` | 방명록 메모 변경 |

---

## 5. Custom Hooks

### 5.1 useAuth — 인증 상태 리스너

Firebase `onAuthStateChanged` 리스너를 설정한다. 사용자의 로그인/로그아웃을 자동으로 감지하여 앱 상태를 업데이트한다.

```typescript
export function useAuthListener() {
  useEffect(() => {
    // Firebase Auth 상태 변경을 실시간으로 감지
    const unsub = auth().onAuthStateChanged(async (user) => {
      if (user) {
        // 로그인됨 → bootstrap으로 상세 상태 결정
        useAuthStore.getState().bootstrap();
      } else {
        // 로그아웃됨
        useAuthStore.getState().setStatus('unauthenticated');
      }
    });
    return unsub;  // 컴포넌트 언마운트 시 리스너 해제
  }, []);
}
```

### 5.2 useLike — Optimistic UI 좋아요

좋아요 버튼을 누르면 **서버 응답을 기다리지 않고 즉시 UI를 업데이트**하는 패턴이다.

```typescript
export function useLike(postId, postOwnerId) {
  // 1. Firestore 실시간 리스너로 좋아요 상태 구독
  //    → 다른 기기에서 변경해도 자동 동기화

  // 2. 로컬 optimistic 상태 관리
  //    → 서버 응답 전에 UI를 먼저 변경

  // 3. 가드 조건:
  //    - 자기 게시물 좋아요 방지
  //    - 더블탭 방지 (busyRef로 연타 차단)

  // 4. toggleLike 호출
  //    → 성공: 서버 상태와 UI 일치
  //    → 실패: UI를 원래 상태로 롤백
}
```

### 5.3 useFollow — Optimistic UI 팔로우

좋아요와 동일한 Optimistic UI 패턴을 팔로우/언팔로우에 적용한다.

```typescript
export function useFollow(targetUid) {
  // 1. Firestore 실시간 리스너로 팔로우 상태 구독
  // 2. 로컬 optimistic 상태 관리
  // 3. 가드: 자기 자신 팔로우 방지, 더블탭 방지
  // 4. follow/unfollow 호출 → 실패 시 Alert 표시 + 롤백
}
```

### 5.4 useComments — 실시간 댓글 CRUD

댓글을 실시간으로 구독하면서 생성/수정/삭제 기능을 제공한다.

```typescript
export function useComments(postId) {
  // 1. useFirestoreQuery로 댓글 목록 실시간 구독
  //    → 다른 사용자가 댓글을 달면 자동으로 화면에 표시

  // 2. 제공하는 함수들:
  //    - addComment(content)     — 새 댓글 작성
  //    - editComment(id, text)   — 댓글 수정
  //    - deleteComment(id)       — 댓글 삭제
}
```

---

## 6. Component Architecture

### 6.1 피드 컴포넌트 (`components/feed/`) — 6개

| 컴포넌트 | 주요 Props | 설명 |
|---|---|---|
| `FeedCard` | `feed`, `fontColor`, `showTopWriter`, `showTags`, `showContent`, `showIcons`, `imageHeight`, `blockNavPost` | 피드 카드 메인. Head + FeedImages + StatIcons + Content를 조합 |
| `Head` | `profileImageUrl`, `userName`, `userId`, `userTitle`, `createdAt`, `fontColor`, `isMine`, `onEdit`, `overlay` | 게시물 헤더 (아바타, 닉네임, 시간, 더보기 메뉴) |
| `Content` | `content`, `fontColor` | 게시물 본문 텍스트 표시 |
| `FeedImages` | `imageUrls`, `category`, `value`, `showTags`, `height`, `maxHeight`, `aspectRatio` | 이미지 캐러셀 + 페이지 인디케이터 + 태그 오버레이 |
| `StatIcons` | `postId`, `postOwnerId`, `likesCount`, `commentsCount`, `fontColor`, `iconSize`, `fontSize` | 좋아요/댓글 아이콘 + 카운트 (좋아요 토글 연동) |
| `CommentTile` | `comment`, `postId`, `onDelete` | 개별 댓글 표시 (아바타, 닉네임, 시간, 삭제 버튼) |

### 6.2 프로필 컴포넌트 (`components/profile/`) — 5개

| 컴포넌트 | 주요 Props | 설명 |
|---|---|---|
| `ProfileHeader` | `profile`, `isOwner` | 프로필 카드 (아바타, 닉네임, 통계 카운터) |
| `FollowButton` | `targetUid`, `width`, `height` | 팔로우/언팔로우 토글 버튼 |
| `YumTab` | `posts`, `loading`, `onPin` | 게시물 3열 이미지 그리드 (롱프레스로 핀 토글) |
| `GuestBookTab` | `userId` | 방명록 스티키 노트 그리드 |
| `StickyNoteCard` | `note`, `onPress`, `onLongPress`, `messy` | 개별 스티키 노트 카드 (회전 효과 옵션) |

### 6.3 작성 컴포넌트 (`components/create/`) — 5개

| 컴포넌트 | 주요 Props | 설명 |
|---|---|---|
| `CategoryChips` | `selected`, `onSelect` | 카테고리 칩 선택 (요리/밀키트/식당/배달) |
| `ReviewChips` | `selected`, `onSelect` | 리뷰 칩 선택 (Fire/Tasty/Soso/Woops/Wack) |
| `PostTextField` | `value`, `onChangeText` | 멀티라인 텍스트 입력 필드 |
| `LinkInputRow` | `value`, `onChangeText`, `placeholder`, `icon` | URL 입력 필드 (아이콘 + placeholder) |
| `DatePickerButton` | `date`, `onDateChange` | 날짜 선택 버튼 (iOS: 모달, Android: 네이티브 픽커) |

### 6.4 공통 컴포넌트 (`components/common/`) — 3개

| 컴포넌트 | 주요 Props | 설명 |
|---|---|---|
| `ProfileAvatar` | `profileUrl`, `size` | 원형 프로필 이미지 (URL 없으면 기본 아이콘 표시) |
| `TimeAgoText` | `createdAt`, `fontSize`, `color` | 한국어 상대 시간 표시 ("5분 전", "어제") |
| `Tag` | `label`, `backgroundColor`, `textColor`, `fontSize` | 카테고리/리뷰 뱃지 (라운드 칩) |

---

## 7. Type Definitions

### 7.1 PostData — 게시물

```typescript
type Visibility = 'PUBLIC' | 'FOLLOWER' | 'PRIVATE';

interface PostData {
  userId: string;       // 작성자 UID
  postId: string;       // 게시물 ID
  title: string;        // 제목 (카테고리 + 리뷰 조합, 예: "요리 · Fire")
  content: string;      // 본문 내용
  imageUrls: string[];  // 이미지 URL 배열
  likesCount: number;   // 좋아요 수
  commentsCount: number;// 댓글 수
  category: string;     // 카테고리 (요리/밀키트/식당/배달)
  value: string;        // 리뷰 값 (Fire/Tasty/Soso/Woops/Wack)
  visibility: Visibility;// 공개 범위
  archived: boolean;    // 소프트 삭제 여부
  createdAt: FirebaseFirestoreTypes.Timestamp;
  pinOrder?: number;    // 핀 순서 (핀된 게시물만 존재)
}
```

### 7.2 UserData / ProfileInfo — 사용자

```typescript
interface UserData {
  userId: string;        // Firebase UID
  userName: string;      // 닉네임
  countryCode: string;   // 국가 코드 (KR, US, JP)
  countryName: string;   // 국가 이름
  title: string;         // 사용자 타이틀
  statusMessage: string; // 상태 메시지
  profileImage: string;  // 프로필 이미지 URL
}

// UserData를 확장하여 통계 정보 추가
interface ProfileInfo extends UserData {
  postCount: number;      // 게시물 수
  followerCount: number;  // 팔로워 수
  followingCount: number; // 팔로잉 수
  recipeCount: number;    // 레시피 수
}
```

### 7.3 FeedData — 피드 카드 데이터

```typescript
interface FeedData {
  user: UserData;          // 작성자 정보
  post: PostData;          // 게시물 정보
  isPinned: boolean;       // 핀 고정 여부
  isLikedByUser: boolean;  // 현재 사용자가 좋아요 눌렀는지
  numLikes: number;        // 좋아요 수
  numComments: number;     // 댓글 수
}
```

### 7.4 Recipe — 레시피

```typescript
interface Recipe {
  id: string;
  title: string;          // 레시피 제목
  tips: string;           // 요리 팁
  images: RecipeImages;   // 메인 이미지 + 단계별 이미지
  ingredients: Ingredient[];  // 재료 목록
  methods: RecipeMethod[];    // 조리 단계
  nutrition: Nutrition;       // 영양 정보
  tags: string[];         // 검색용 태그
  foodCategory: string;   // 음식 종류 (한식, 양식 등)
  cookingCategory: string;// 조리 방법 (볶음, 찜 등)
  createdAt: FirebaseFirestoreTypes.Timestamp;
}

interface Ingredient {
  name: string;   // 재료 이름
  amount: string; // 재료 양 ("300g", "1큰술")
}

interface Nutrition {
  calories: string;  // 칼로리
  carbs: string;     // 탄수화물
  protein: string;   // 단백질
  fat: string;       // 지방
}
```

### 7.5 StickyNote — 방명록 메모

```typescript
interface StickyNote {
  id: string;
  authorId: string;        // 작성자 UID
  authorName: string;      // 작성자 닉네임
  authorAvatarUrl: string; // 작성자 프로필 이미지
  createdAt: Date;         // 작성 시각
  text: string;            // 메모 내용
  color: number;           // ARGB 색상 코드
  pinned: boolean;         // 상단 고정 여부
}
```

---

## 8. Styling Conventions

### 8.1 스타일링 방식

React Native의 `StyleSheet.create()`를 사용한다. CSS 파일이 아닌 **JavaScript 객체로 스타일을 정의**한다.

```typescript
const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.bgLight,  // 테마 상수 참조
    padding: spacing.md,               // 간격 상수 참조
  },
  title: {
    fontSize: 18,
    fontWeight: '700',
    color: colors.primary,
  },
});
```

### 8.2 테마 상수 (`src/theme/colors.ts`)

모든 색상, 간격, 라디우스 값은 중앙에서 관리한다. 하드코딩된 값 대신 상수를 사용하여 일관성을 유지한다.

```typescript
export const colors = {
  bgLight: '#0F1115',     // 기본 배경
  bgDark: '#0B0D10',      // 더 어두운 배경
  primary: '#EAECEF',     // 기본 텍스트 + 주요 UI 요소
  chipActive: '#C7F464',  // 활성 카테고리 칩
  // ... 파생 색상은 rgba()로 투명도 적용
} as const;

export const spacing = {
  xs: 4, sm: 8, md: 16, lg: 24, xl: 32
} as const;

export const radius = {
  sm: 8, md: 14, lg: 20, full: 9999
} as const;
```

### 8.3 레이아웃 규칙

| 규칙 | 설명 | 예시 |
|---|---|---|
| Flexbox 기반 | 모든 레이아웃에 Flexbox 사용 | `flex: 1`, `flexDirection: 'row'` |
| Safe Area 대응 | `SafeAreaView` + `useSafeAreaInsets()` | 노치/다이나믹 아일랜드 대응 |
| 반투명 탭 바 | `rgba(15,17,21,0.85)`, absolute 포지션 | 스크롤해도 항상 표시 |
| 키보드 대응 | `KeyboardAvoidingView` | 입력 시 키보드에 맞춰 화면 조절 |
| 리스트 하단 여백 | `paddingBottom: 100` | 탭 바에 콘텐츠가 가려지지 않도록 |

---

## 9. Provider Structure

`app/_layout.tsx`에서 설정하는 프로바이더 계층이다. 앱 전체에 공유되는 설정을 감싸는 구조다.

```
GestureHandlerRootView          ← 제스처 인식 (스와이프 등)
└── QueryClientProvider          ← React Query 캐싱 설정
    └── StatusBar (light)        ← 상태바 스타일 (밝은 아이콘)
        └── Stack (expo-router)  ← 라우트 네비게이션
```

> **프로바이더(Provider)란?** React에서 하위 컴포넌트 전체에 공유 설정이나 데이터를 전달하는 패턴이다. 마치 "전체 건물의 전기 배선"처럼, 한번 설정하면 모든 방(컴포넌트)에서 사용할 수 있다.

---

## 10. Build & Deploy

### 10.1 개발 환경 (시뮬레이터)

```bash
cd ting-rn
nvm use 20                                                  # Node 20 사용
npm install                                                  # 의존성 설치
npx eas build --platform ios --profile development           # 개발용 빌드 (최초 1회)
npx expo start --dev-client                                  # Metro 번들러 시작

# 또는 원스텝 스크립트:
./run-simulator.sh
```

> **주의**: T!ng은 `expo-dev-client`를 사용하므로, **Expo Go 앱에서는 실행되지 않는다**. Firebase 네이티브 모듈이 필요하기 때문에 반드시 개발용 빌드(`--profile development`)를 먼저 생성해야 한다.

### 10.2 프로덕션 (TestFlight)

```bash
cd ting-rn
./deploy-testflight.sh
# 내부 실행: npm install → eas build --production → eas submit
```

### 10.3 EAS Build 프로파일 (`eas.json`)

| 프로파일 | 용도 | 특징 |
|---|---|---|
| `development` | 개발/디버깅 | dev-client 활성, iOS 시뮬레이터 지원 |
| `preview` | 내부 테스트 배포 | 실제 기기 설치 (내부 배포) |
| `production` | 앱스토어/TestFlight | 자동 빌드 번호 증가, 최적화 빌드 |

```json
{
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal",
      "ios": { "simulator": true }
    },
    "preview": {
      "distribution": "internal"
    },
    "production": {
      "autoIncrement": true
    }
  }
}
```

### 10.4 Expo Config 플러그인

`app.config.ts`에서 사용하는 Expo 플러그인 목록이다. 각 플러그인이 네이티브 코드를 자동으로 설정해준다.

```javascript
plugins: [
  'expo-router',                          // 파일 기반 라우팅
  '@react-native-firebase/app',           // Firebase 코어
  '@react-native-firebase/auth',          // Firebase 인증
  'expo-secure-store',                    // 보안 저장소
  'expo-font',                            // 커스텀 폰트
  '@react-native-google-signin/google-signin', // Google 로그인
  'expo-build-properties',                // 네이티브 빌드 속성 (newArchEnabled 등)
  'expo-image-picker',                    // 이미지 선택/카메라
  '@react-native-community/datetimepicker', // 날짜/시간 선택
  './plugins/withFirebaseFixes',          // Firebase iOS 빌드 이슈 수정 (커스텀)
  'expo-speech-recognition',              // 음성 인식
]
```

**`withFirebaseFixes.js`**: Firebase iOS 빌드 시 gRPC 모듈 헤더 관련 이슈를 해결하기 위한 커스텀 Podfile 수정 플러그인이다.
