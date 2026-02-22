# FE_ARCH.md — 프론트엔드 아키텍처

## 1. 기술 스택

| 분류 | 기술 | 용도 |
|---|---|---|
| **Framework** | React 19.1 + React Native 0.81.5 | UI 렌더링 |
| **Platform** | Expo SDK 54 | 개발/빌드 프레임워크 |
| **Navigation** | Expo Router v6 | 파일 기반 라우팅 + 딥링킹 |
| **Auth State** | Zustand 5 | 인증 상태 관리 (1개 스토어) |
| **Server State** | React Query v5 | 서버 데이터 페칭/캐싱 |
| **Styling** | React Native StyleSheet | 인라인 스타일 |
| **Backend** | React Native Firebase v23 | Auth, Firestore, Storage |
| **Images** | expo-image v3 | 고성능 이미지 렌더링 |
| **Lists** | @shopify/flash-list | 고성능 리스트 |
| **Icons** | @expo/vector-icons (Ionicons) | UI 아이콘 |
| **Animation** | react-native-reanimated 4 | GPU 기반 애니메이션 |
| **AI** | OpenAI GPT-4o-mini | 레시피 AI 편집 |
| **Voice** | expo-speech-recognition | 한국어 음성 인식 |

---

## 2. 프로젝트 구조

```
ting-rn/
├── app/                              # Expo Router 라우트 (파일 기반)
│   ├── _layout.tsx                   # 루트 레이아웃 (인증 리다이렉트, 프로바이더)
│   ├── index.tsx                     # 스플래시 (로딩 스피너)
│   ├── (auth)/
│   │   └── login.tsx                 # 로그인 페이지
│   ├── (onboarding)/
│   │   └── setup.tsx                 # 프로필 설정 페이지
│   └── (tabs)/
│       ├── _layout.tsx               # 탭 바 레이아웃 (4탭)
│       ├── feed/
│       │   ├── _layout.tsx           # Stack 네비게이터
│       │   ├── index.tsx             # 피드 목록
│       │   └── [postId].tsx          # 게시물 상세 + 댓글
│       ├── recipes/
│       │   ├── _layout.tsx           # Stack 네비게이터
│       │   ├── index.tsx             # 레시피 목록
│       │   ├── [recipeId].tsx        # 레시피 상세
│       │   └── edit.tsx              # 레시피 편집 (요리 기록)
│       ├── create/
│       │   ├── _layout.tsx           # Stack 네비게이터
│       │   ├── index.tsx             # 게시물 작성
│       │   └── confirm.tsx           # 게시물 확인 + 업로드
│       ├── profile/
│       │   ├── _layout.tsx           # Stack 네비게이터
│       │   ├── index.tsx             # 내 프로필
│       │   └── [userId].tsx          # 다른 사용자 프로필
│       └── users/
│           ├── _layout.tsx           # Stack 네비게이터
│           └── [userId]/
│               └── list.tsx          # 팔로워/팔로잉/차단 목록
│
├── src/
│   ├── components/                   # 재사용 UI 컴포넌트 (19개)
│   │   ├── common/                   # ProfileAvatar, Tag, TimeAgoText
│   │   ├── create/                   # CategoryChips, ReviewChips, DatePickerButton, PostTextField, LinkInputRow
│   │   ├── feed/                     # FeedCard, Head, Content, FeedImages, StatIcons, CommentTile
│   │   └── profile/                  # ProfileHeader, FollowButton, YumTab, GuestBookTab, StickyNoteCard
│   ├── hooks/                        # 커스텀 훅 (8개)
│   │   ├── useAuth.ts                # Firebase Auth 리스너
│   │   ├── useFeed.ts                # React Query 피드 훅
│   │   ├── useComments.ts            # 실시간 댓글 CRUD
│   │   ├── useProfile.ts             # React Query 프로필 훅
│   │   ├── useRecipes.ts             # React Query 레시피 훅
│   │   ├── useFirestoreStream.ts     # 범용 Firestore 실시간 리스너
│   │   ├── useLike.ts                # Optimistic 좋아요 토글
│   │   └── useFollow.ts              # Optimistic 팔로우 토글
│   ├── services/                     # Firebase 서비스 레이어 (10개)
│   ├── stores/
│   │   └── authStore.ts              # Zustand 인증 스토어
│   ├── theme/
│   │   └── colors.ts                 # 색상, 간격, 라디우스 상수
│   ├── types/                        # TypeScript 인터페이스 (5개)
│   │   ├── user.ts                   # UserData, ProfileInfo
│   │   ├── post.ts                   # PostData, PostInputData, Visibility
│   │   ├── feed.ts                   # FeedData
│   │   ├── recipe.ts                 # Recipe, Ingredient, Nutrition, Method
│   │   └── guestbook.ts             # StickyNote, FollowEntry
│   └── utils/                        # 유틸리티 (4개)
│       ├── chunk.ts                  # 배열 청크 분할
│       ├── formatTimestamp.ts        # 날짜 포맷 + 상대 시간
│       ├── formatNumber.ts           # 숫자 포맷 (1k, 1m)
│       └── koreanGrammar.ts          # 한국어 조사 처리
│
├── assets/                           # 앱 아이콘, 스플래시 이미지
├── plugins/
│   └── withFirebaseFixes.js          # Firebase iOS 빌드 커스텀 플러그인
├── app.config.ts                     # Expo 설정
├── eas.json                          # EAS Build 프로파일
├── GoogleService-Info.plist          # Firebase iOS 설정
├── deploy-testflight.sh              # TestFlight 배포 스크립트
└── run-simulator.sh                  # 시뮬레이터 실행 스크립트
```

---

## 3. 네비게이션

### 3.1 라우트 구조

Expo Router v6의 파일 기반 라우팅을 사용한다. 그룹 라우트 `(auth)`, `(onboarding)`, `(tabs)`로 인증 상태별 화면을 분리한다.

```
/                     → index.tsx (스플래시)
/(auth)/login         → 로그인
/(onboarding)/setup   → 프로필 설정
/(tabs)/feed          → 피드 목록
/(tabs)/feed/[postId] → 게시물 상세
/(tabs)/recipes       → 레시피 목록
/(tabs)/recipes/[id]  → 레시피 상세
/(tabs)/recipes/edit  → 레시피 편집
/(tabs)/create        → 게시물 작성
/(tabs)/create/confirm → 게시물 확인
/(tabs)/profile       → 내 프로필
/(tabs)/profile/[uid] → 다른 사용자 프로필
/(tabs)/users/[uid]/list → 팔로워/팔로잉 목록
```

### 3.2 인증 가드

`app/_layout.tsx` (루트 레이아웃)에서 `useSegments()` + `useRouter()`로 중앙 집중식 리다이렉트:

```typescript
useEffect(() => {
  if (status === 'initializing') return;
  const inAuth = segments[0] === '(auth)';
  const inOnboarding = segments[0] === '(onboarding)';
  const inTabs = segments[0] === '(tabs)';

  if (status === 'unauthenticated' && !inAuth)
    router.replace('/(auth)/login');
  else if (status === 'needsOnboarding' && !inOnboarding)
    router.replace('/(onboarding)/setup');
  else if (status === 'authenticated' && !inTabs)
    router.replace('/(tabs)/feed');
}, [status, segments, router]);
```

### 3.3 탭 바

4개 메인 탭 + 1개 숨김 라우트:

| 탭 | 라벨 | 아이콘 | 라우트 |
|---|---|---|---|
| 커뮤니티 | 커뮤니티 | `chatbubbles-outline` | `feed/` |
| 요리하기 | 요리하기 | `book-outline` | `recipes/` |
| 기록 | 기록 | `create-outline` | `create/` |
| 프로필 | 프로필 | `person-outline` | `profile/` |
| (숨김) | - | - | `users/` (`href: null`) |

### 3.4 중첩 라우트

각 탭 디렉토리에 `_layout.tsx`를 두어 `Stack` 네비게이터를 생성한다. 이렇게 하면 탭 내부의 동적 라우트 (`[postId].tsx`, `edit.tsx` 등)가 별도 탭으로 표시되지 않는다.

```typescript
// app/(tabs)/feed/_layout.tsx
export default function FeedLayout() {
  return (
    <Stack screenOptions={{
      headerShown: false,
      contentStyle: { backgroundColor: colors.bgLight },
    }} />
  );
}
```

---

## 4. 상태 관리

### 4.1 Zustand — 인증 상태 (authStore)

```typescript
type AppStatus =
  | 'initializing'      // 앱 부팅 중
  | 'unauthenticated'   // 미로그인
  | 'needsOnboarding'   // 로그인됨, 프로필 미완성
  | 'authenticated';     // 완전 인증

interface AuthState {
  status: AppStatus;
  user: FirebaseAuthTypes.User | null;
  userId: string | null;
  bootstrap(): Promise<void>;
  setStatus(status: AppStatus): void;
  signOut(): Promise<void>;
}
```

**`bootstrap()` 로직**:
```
1. auth().currentUser 확인
2. null → status: 'unauthenticated'
3. 존재 → Firestore users/{uid} 문서 조회
4. 문서 없음 or user_name/country_code 누락 → 'needsOnboarding'
5. 모두 존재 → 'authenticated'
```

### 4.2 React Query — 서버 상태

서버 데이터 페칭에 React Query v5를 사용한다.

```typescript
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60 * 5,  // 5분
      retry: 2,
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

`useFirestoreStream.ts`에서 범용 실시간 리스너 훅을 제공한다:

```typescript
// 단일 문서 구독
useFirestoreDoc<T>(ref, transform?) → { data: T | null, exists: boolean, loading: boolean }

// 컬렉션 쿼리 구독
useFirestoreQuery<T>(query, transform) → { data: T[], loading: boolean }
```

사용처:
- `useLike`: `postService.isLikedRef()` → 좋아요 상태 실시간 동기화
- `useFollow`: `followService.isFollowingRef()` → 팔로우 상태 실시간 동기화
- `useComments`: `postService.commentsStream()` → 댓글 실시간 동기화
- `GuestBookTab`: `guestBookService.watchQuery()` → 방명록 실시간 동기화

---

## 5. 커스텀 훅

### 5.1 useAuth

Firebase `onAuthStateChanged` 리스너를 설정하고, 인증 상태 변경 시 `authStore.bootstrap()`을 트리거한다.

```typescript
export function useAuthListener() {
  useEffect(() => {
    const unsub = auth().onAuthStateChanged(async (user) => {
      if (user) {
        useAuthStore.getState().bootstrap();
      } else {
        useAuthStore.getState().setStatus('unauthenticated');
      }
    });
    return unsub;
  }, []);
}
```

### 5.2 useLike — Optimistic UI 패턴

```typescript
export function useLike(postId, postOwnerId) {
  // 1. useFirestoreDoc로 실시간 좋아요 상태 구독
  // 2. 로컬 optimistic 상태 관리
  // 3. 가드: 자기 게시물 좋아요 방지, 더블탭 방지 (busyRef)
  // 4. toggleLike 호출 → 실패 시 롤백
}
```

### 5.3 useFollow — Optimistic UI 패턴

```typescript
export function useFollow(targetUid) {
  // 1. useFirestoreDoc로 실시간 팔로우 상태 구독
  // 2. 로컬 optimistic 상태 관리
  // 3. 가드: 자기 자신 팔로우 방지, 더블탭 방지
  // 4. follow/unfollow 호출 → 실패 시 Alert + 롤백
}
```

### 5.4 useComments — 실시간 CRUD

```typescript
export function useComments(postId) {
  // 1. useFirestoreQuery로 댓글 실시간 구독
  // 2. addComment, editComment, deleteComment 함수 제공
  // 3. Comment 인터페이스: comment_id, post_id, user_id, content, timestamps
}
```

---

## 6. 컴포넌트 구조

### 6.1 피드 컴포넌트 (feed/) — 6개

| 컴포넌트 | Props | 설명 |
|---|---|---|
| `FeedCard` | feed, fontColor, showTopWriter, showTags, showContent, showIcons, imageHeight, blockNavPost | 피드 카드 메인. Head + FeedImages + StatIcons + Content 조합 |
| `Head` | profileImageUrl, userName, userId, userTitle, createdAt, fontColor, isMine, onEdit, overlay | 게시물 헤더 (아바타, 이름, 시간, 메뉴) |
| `Content` | content, fontColor | 게시물 본문 텍스트 |
| `FeedImages` | imageUrls, category, value, showTags, height, maxHeight, aspectRatio | 이미지 캐러셀 + 페이지네이션 + 태그 오버레이 |
| `StatIcons` | postId, postOwnerId, likesCount, commentsCount, fontColor, iconSize, fontSize | 좋아요/댓글 아이콘 + 카운트 |
| `CommentTile` | comment, postId, onDelete | 개별 댓글 (아바타, 이름, 시간, 삭제) |

### 6.2 프로필 컴포넌트 (profile/) — 5개

| 컴포넌트 | Props | 설명 |
|---|---|---|
| `ProfileHeader` | profile, isOwner | 프로필 카드 (아바타, 이름, 통계) |
| `FollowButton` | targetUid, width, height | 팔로우/언팔로우 토글 버튼 |
| `YumTab` | posts, loading, onPin | 게시물 3열 그리드 (롱프레스 핀) |
| `GuestBookTab` | userId | 방명록 스티키 노트 그리드 |
| `StickyNoteCard` | note, onPress, onLongPress, messy | 개별 스티키 노트 카드 |

### 6.3 작성 컴포넌트 (create/) — 5개

| 컴포넌트 | Props | 설명 |
|---|---|---|
| `CategoryChips` | selected, onSelect | 카테고리 선택 칩 (요리/밀키트/식당/배달) |
| `ReviewChips` | selected, onSelect | 리뷰 선택 칩 (Fire/Tasty/Soso/Woops/Wack) |
| `PostTextField` | value, onChangeText | 멀티라인 텍스트 입력 |
| `LinkInputRow` | value, onChangeText, placeholder, icon | URL 입력 필드 |
| `DatePickerButton` | date, onDateChange | 날짜 선택 (iOS: 모달, Android: 네이티브) |

### 6.4 공통 컴포넌트 (common/) — 3개

| 컴포넌트 | Props | 설명 |
|---|---|---|
| `ProfileAvatar` | profileUrl, size | 원형 프로필 이미지 (폴백 아이콘) |
| `TimeAgoText` | createdAt, fontSize, color | 한국어 상대 시간 ("5분 전") |
| `Tag` | label, backgroundColor, textColor, fontSize | 카테고리/리뷰 뱃지 |

---

## 7. 타입 정의

### 7.1 PostData

```typescript
type Visibility = 'PUBLIC' | 'FOLLOWER' | 'PRIVATE';

interface PostData {
  userId: string;
  postId: string;
  title: string;
  content: string;
  imageUrls: string[];
  likesCount: number;
  commentsCount: number;
  category: string;
  value: string;
  visibility: Visibility;
  archived: boolean;
  createdAt: FirebaseFirestoreTypes.Timestamp;
  pinOrder?: number;
}
```

### 7.2 UserData / ProfileInfo

```typescript
interface UserData {
  userId: string;
  userName: string;
  countryCode: string;
  countryName: string;
  title: string;
  statusMessage: string;
  profileImage: string;
}

interface ProfileInfo extends UserData {
  postCount: number;
  followerCount: number;
  followingCount: number;
  recipeCount: number;
}
```

### 7.3 FeedData

```typescript
interface FeedData {
  user: UserData;
  post: PostData;
  isPinned: boolean;
  isLikedByUser: boolean;
  numLikes: number;
  numComments: number;
}
```

### 7.4 Recipe

```typescript
interface Recipe {
  id: string;
  title: string;
  tips: string;
  images: RecipeImages;
  ingredients: Ingredient[];
  methods: RecipeMethod[];
  nutrition: Nutrition;
  tags: string[];
  foodCategory: string;
  cookingCategory: string;
  createdAt: FirebaseFirestoreTypes.Timestamp;
}

interface Ingredient {
  name: string;
  amount: string;
}

interface Nutrition {
  calories: string;
  carbs: string;
  protein: string;
  fat: string;
}
```

### 7.5 StickyNote

```typescript
interface StickyNote {
  id: string;
  authorId: string;
  authorName: string;
  authorAvatarUrl: string;
  createdAt: Date;
  text: string;
  color: number;       // ARGB 색상 코드
  pinned: boolean;
}
```

---

## 8. 스타일링 컨벤션

### 8.1 방식

`StyleSheet.create()` — React Native 인라인 스타일. CSS 파일 사용하지 않음.

```typescript
const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.bgLight, padding: spacing.md },
  title: { fontSize: 18, fontWeight: '700', color: colors.primary },
});
```

### 8.2 테마 상수 (`src/theme/colors.ts`)

```typescript
export const colors = {
  bgLight: '#0F1115',
  bgDark: '#0B0D10',
  primary: '#EAECEF',
  // ... derived colors via rgba()
} as const;

export const spacing = { xs: 4, sm: 8, md: 16, lg: 24, xl: 32 } as const;
export const radius = { sm: 8, md: 14, lg: 20, full: 9999 } as const;
```

### 8.3 레이아웃 규칙

- Flexbox 기반 레이아웃 전체
- `SafeAreaView` + `useSafeAreaInsets()` — 노치/홈 인디케이터 대응
- 반투명 탭 바: `rgba(15,17,21,0.85)`, absolute 포지션
- `KeyboardAvoidingView` — 입력 화면에서 키보드 대응
- 리스트 하단 여백: `contentContainerStyle={{ paddingBottom: 100 }}` (탭 바 높이 고려)

---

## 9. 프로바이더 구조

`app/_layout.tsx`에서 설정하는 프로바이더 계층:

```
GestureHandlerRootView
└── QueryClientProvider
    └── StatusBar (light)
        └── Stack (expo-router)
```

---

## 10. 빌드 및 배포

### 10.1 개발 (시뮬레이터)

```bash
cd ting-rn
nvm use 20
npm install
npx eas build --platform ios --profile development   # dev 빌드 (최초 1회)
npx expo start --dev-client                           # Metro 번들러
# 또는
./run-simulator.sh                                    # 원스텝 스크립트
```

### 10.2 프로덕션 (TestFlight)

```bash
cd ting-rn
./deploy-testflight.sh
# 내부 실행: npm install → eas build --production → eas submit
```

### 10.3 EAS 빌드 프로파일

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

`plugins/withFirebaseFixes.js` — Firebase iOS 빌드 시 gRPC 모듈 헤더 관련 이슈 해결을 위한 커스텀 Podfile 수정 플러그인.

```javascript
// app.config.ts plugins 배열
plugins: [
  'expo-router',
  '@react-native-firebase/app',
  '@react-native-firebase/auth',
  'expo-secure-store',
  '@react-native-google-signin/google-signin',
  'expo-build-properties',
  'expo-image-picker',
  '@react-native-community/datetimepicker',
  './plugins/withFirebaseFixes',
  'expo-speech-recognition',
]
```
