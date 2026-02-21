# T!ng (VibeYum) Flutter → React Native (Expo) 마이그레이션 계획

## Context

1인 개발자가 다른 프로젝트와 프레임워크를 통일하기 위해 Flutter 앱을 React Native (Expo)로 전환합니다.
현재 앱은 초기 단계 (16개 화면, 9개 서비스, iOS만 지원)이고 테스트/상태관리가 기본적이라 지금이 전환 최적 시점입니다.

## 기술 스택

| 항목 | 선택 |
|---|---|
| Framework | Expo SDK 52+ with `expo-dev-client` |
| Language | TypeScript (strict) |
| Navigation | Expo Router v4 (파일 기반 라우팅) |
| State | Zustand 5.x |
| Data Fetching | TanStack Query v5 + Firestore |
| Firebase | `@react-native-firebase/*` (app, auth, firestore, storage) |
| Animation | React Native Reanimated 3 + Gesture Handler |
| Image | `expo-image` (캐싱 내장), `expo-image-picker`, `expo-image-manipulator` |
| Auth | `@react-native-google-signin/google-signin`, `react-native-fbsdk-next` |
| Form | React Hook Form + Zod |
| List | `@shopify/flash-list` |
| Platform | iOS 우선, Android 추후 |

## 제외할 기능

| 기능 | 이유 |
|---|---|
| NearbyPage | 미사용 (코드에 "未使用?" 표시) |
| Kakao/Naver 로그인 | 백엔드 Custom Token 미구현. 추후 백엔드 완성 후 추가 |
| Gemma LLM | 전체 주석 처리됨. 온디바이스 LLM 비실용적 |
| Profile Recipe 탭 | 스텁 (하드코딩 placeholder 텍스트) |
| Desktop SQLite | RN에서 불필요 |
| Email/Password 로그인 | UI 없음, 어디서도 호출 안 됨 |

## 프로젝트 구조

```
ting-rn/
├── app/                          # Expo Router 파일 기반 라우트
│   ├── _layout.tsx               # Root (Firebase init, auth provider, theme)
│   ├── index.tsx                 # Auth 상태 기반 리다이렉트
│   ├── (auth)/
│   │   └── login.tsx             # 로그인 화면
│   ├── (onboarding)/
│   │   └── setup.tsx             # 온보딩 화면
│   └── (tabs)/                   # 메인 앱 (인증 후)
│       ├── _layout.tsx           # Bottom Tab Navigator
│       ├── feed/
│       │   ├── index.tsx         # 피드
│       │   └── [postId].tsx      # 포스트 상세
│       ├── recipes/
│       │   ├── index.tsx         # 레시피 목록
│       │   ├── [recipeId].tsx    # 레시피 상세
│       │   └── edit.tsx          # AI 레시피 편집
│       ├── profile/
│       │   ├── index.tsx         # 내 프로필
│       │   └── [userId].tsx      # 타인 프로필
│       ├── create/
│       │   ├── index.tsx         # 포스트 작성
│       │   └── confirm.tsx       # 업로드 확인
│       └── users/
│           └── [userId]/list.tsx # 팔로워/팔로잉/차단 목록
│
├── src/
│   ├── stores/                   # Zustand
│   │   ├── authStore.ts          # AppState 상태머신 대체
│   │   ├── feedStore.ts
│   │   └── profileStore.ts
│   ├── services/                 # Firebase 서비스 (Flutter 1:1 포팅)
│   │   ├── authService.ts
│   │   ├── feedService.ts
│   │   ├── postService.ts
│   │   ├── userService.ts
│   │   ├── followService.ts
│   │   ├── guestBookService.ts
│   │   ├── recipeService.ts
│   │   └── storageService.ts
│   ├── hooks/                    # React 커스텀 훅
│   │   ├── useAuth.ts
│   │   ├── useFeed.ts
│   │   ├── useFirestoreStream.ts # StreamBuilder 대체 (범용)
│   │   ├── useLike.ts            # Optimistic UI
│   │   ├── useFollow.ts
│   │   └── useComments.ts
│   ├── types/                    # Flutter 모델 → TS 인터페이스
│   │   ├── post.ts
│   │   ├── user.ts
│   │   ├── feed.ts
│   │   ├── recipe.ts
│   │   └── guestbook.ts
│   ├── components/               # 재사용 UI
│   │   ├── common/
│   │   ├── feed/
│   │   ├── profile/
│   │   ├── create/
│   │   └── recipe/
│   ├── theme/
│   │   └── colors.ts             # AppTheme.dart 색상 포팅
│   └── utils/
│       ├── chunk.ts              # Firestore whereIn 10개 분할
│       ├── koreanGrammar.ts      # attachObjectParticle()
│       └── formatTimestamp.ts
│
├── assets/                       # Flutter에서 복사 (SVG, PNG, 폰트)
├── app.config.ts                 # Expo 설정
├── eas.json                      # EAS Build 설정
└── .env                          # OPENAI_API_KEY
```

---

## Phase 0: 프로젝트 기반 구축

**복잡도: 중간 | 목표: 앱 부팅 + Firebase 연결 + 빈 탭 네비게이션**

1. `npx create-expo-app ting-rn` 으로 Expo 프로젝트 생성
2. `expo-dev-client` 설치 (Expo Go 대신 커스텀 개발 클라이언트 사용 — RN Firebase 필수)
3. `@react-native-firebase/app`, `auth`, `firestore`, `storage` 설치
4. Flutter 프로젝트의 `ios/Runner/GoogleService-Info.plist` 복사 → iOS Firebase 설정
5. `app.config.ts`에 번들 ID (`com.example.vibeyum`) + Firebase Config Plugin 등록
6. Zustand, TanStack Query, expo-router 등 핵심 의존성 설치
7. 테마 시스템 구축 (`AppTheme.dart`의 색상 상수 포팅: `#0F1115` 배경, `#EAECEF` 텍스트)
8. Expo Router 파일 구조 + Bottom Tab Layout 생성
9. EAS Build로 iOS 개발 빌드 생성 및 시뮬레이터 테스트

**검증**: `npx expo run:ios` → Firebase 초기화 로그 확인 + 4개 빈 탭 렌더링

---

## Phase 1: 인증 + 온보딩

**복잡도: 높음 | 목표: Google/Facebook 로그인 → 온보딩 → 홈 화면 진입**

1. **Auth Store 생성** — Flutter `AppState` (ChangeNotifier) → Zustand store로 전환
   - 상태: `initializing` | `unauthenticated` | `needsOnboarding` | `authenticated`
   - `bootstrap()`: `currentUser` 확인 → Firestore `users/{uid}` 문서 존재 여부 → 상태 결정

2. **AuthService 포팅** (`lib/services/AuthService.dart` → `src/services/authService.ts`)
   - Google: `@react-native-google-signin/google-signin` → `GoogleAuthProvider.credential()` → `signInWithCredential()`
   - Facebook: `react-native-fbsdk-next` → `FacebookAuthProvider.credential()` → `signInWithCredential()`
   - 토큰 관리: `expo-secure-store` (key: `auth_token`, `has_logged_in_before`)
   - `registerUser()`: Firestore `users/{uid}` 문서 생성 (동일 필드)

3. **Root Layout** (`app/_layout.tsx`)에서 auth 상태 기반 자동 리다이렉트

4. **LoginPage** (`app/(auth)/login.tsx`) — Google, Facebook 버튼 + Kakao/Naver 비활성 placeholder

5. **OnboardingPage** (`app/(onboarding)/setup.tsx`) — 닉네임, 국가, 바이오, 프로필 이미지

6. **생체인증** (stretch goal) — `expo-local-authentication`

**핵심 설정값**:
- iOS Client ID: `1088275016090-ilhbipi5g51hg7aklkguhfe7gv7vb1af.apps.googleusercontent.com`
- Facebook App ID: `1135413371934546`
- Firebase Project: `vibeyum-alpha`

**검증**: Google 로그인 → Firestore 유저 문서 생성 → 신규 유저 온보딩 → 기존 유저 홈 직행

---

## Phase 2: 데이터 레이어 (타입 + 서비스 + 훅)

**복잡도: 중간 | 목표: 모든 TS 타입 정의, 서비스 포팅, React Query 훅 작동**

1. **Flutter 모델 → TypeScript 인터페이스** 포팅 (7개)
2. **9개 서비스 전체 포팅** (Future → Promise, Stream → onSnapshot)
3. **범용 `useFirestoreStream<T>` 훅** 생성
4. **React Query 훅**: `useFeed()`, `useProfile()`, `useRecipes()` 등
5. **유틸 함수 포팅**: `chunk()`, `formatTimestamp()`, `attachObjectParticle()`

**N+1 최적화**: 피드 아이템당 4-5회 → 배치 조회로 ~25회/20아이템으로 축소

**검증**: 서비스 메서드 호출 → 데이터 정상 로드 확인

---

## Phase 3: 피드 + 포스트 상세

**복잡도: 높음 | 목표: 피드 표시, 좋아요 Optimistic UI, 실시간 댓글**

1. **FeedPage** — `FlashList` + `RefreshControl`
2. **FeedCard** — Head, Images, Content 서브컴포넌트 + 오버레이 모드
3. **Optimistic Like** — UI 즉시 토글 → Firestore 트랜잭션 → 실패 롤백
4. **PostPage** — 풀 FeedCard + 실시간 댓글 + 하단 입력바

**검증**: 피드 로드 → 좋아요 토글 → 포스트 상세 → 댓글 실시간

### --- MVP 체크포인트 (Phase 0~3) ---

---

## Phase 4: 프로필 + 팔로우

**복잡도: 높음 | 목표: 프로필 페이지, 팔로우/언팔로우, 유저 목록**

1. **ProfilePage** — `react-native-collapsible-tab-view` + 2탭 (Yum, Guestbook)
2. **FollowButton** — 실시간 상태 + 배치 쓰기
3. **FollowService 포팅**
4. **UserListPage** — 3탭 (팔로워/팔로잉/차단)

**검증**: 프로필 통계 → 팔로우/언팔로우 → 유저 목록

---

## Phase 5: 포스트 작성

**복잡도: 높음 | 목표: 멀티 이미지 → 메타데이터 → 업로드**

1. **CreatePostPage** — `expo-image-picker` + `react-native-pager-view`
2. **이미지별 메타데이터**: 카테고리, 리뷰, 텍스트, 링크
3. **EditPage** — `react-native-draggable-flatlist` + 크롭
4. **ConfirmPage** — 공개범위 + Firebase Storage 업로드

**검증**: 이미지 선택 → 메타데이터 → 업로드 → 피드 표시

---

## Phase 6: 레시피 시스템

**복잡도: 중상 | 목표: 레시피 목록/상세 + AI 음성 편집**

1. **RecipeListPage** — Firestore 레시피 로드
2. **RecipeDetailPage** — 영양정보, 재료, 조리법
3. **RecipeEditPage** — 음성 (`@react-native-voice/voice`) + GPT-4o-mini + 인라인 편집

**검증**: 레시피 목록 → 상세 → 음성 편집 → 포스트 공유

---

## Phase 7: 방명록 + 마무리

**복잡도: 중간 | 목표: 방명록 + 전체 폴리시**

1. **GuestBookTab** — Masonry 그리드 + 랜덤 회전
2. **StickyNoteCard** — NanumPenScript 폰트, 색상
3. **전체 폴리시**: 다크 테마, shimmer, 에러 처리, safe area

**검증**: 방명록 CRUD → Masonry 표시 → 앱 전체 QA

---

## 타임라인

| Phase | 이름 | 누적 |
|---|---|---|
| 0 | 프로젝트 기반 | ~3일 |
| 1 | 인증 + 온보딩 | ~1주 |
| 2 | 데이터 레이어 | ~2주 |
| 3 | 피드 + 포스트 | **~3주 (MVP)** |
| 4 | 프로필 + 팔로우 | ~4주 |
| 5 | 포스트 작성 | ~5주 |
| 6 | 레시피 시스템 | ~6주 |
| 7 | 방명록 + 마무리 | **~7주** |

## 주요 리스크

| 리스크 | 대응 |
|---|---|
| RN Firebase가 Expo Go에서 안 됨 | Day 1부터 `expo-dev-client` 사용 |
| Google Sign-In iOS 설정 복잡 | Flutter 프로젝트의 기존 Client ID/URL scheme 재사용 |
| N+1 Firestore 읽기 비용 | 배치 조회 + 카운트 필드 활용 + React Query 캐싱 |
| 1인 개발 번아웃 | Phase 3까지 MVP 우선 완성 |
| Flutter/RN 앱 공존 | 같은 Firebase 프로젝트 공유 가능 |
