# AGENTS.md — Sub-Agent & Skill Architecture

> Claude Code 개발용 서브 에이전트 정의 및 스킬 할당 문서. `docs/*.md`의 모든 기능을 검증할 수 있는 최소한의 에이전트 구성을 다룬다.

---

## 1. Overview

T!ng 프로젝트의 모든 기능을 검증하기 위해 **7개의 서브 에이전트**를 정의한다. 각 에이전트는 `.claude/skills/` 디렉토리에 스킬 파일로 구현되며, `context: fork`로 독립된 컨텍스트에서 실행된다.

```
┌─────────────────────────────────────────────────────────┐
│                    Claude Code (Main)                     │
│                                                          │
│  /test-auth    /test-feed    /test-post    /test-social  │
│  /test-recipe  /test-infra   /review-code                │
│                                                          │
│  각 스킬은 context: fork 으로 독립 서브에이전트 생성       │
└─────────────────────────────────────────────────────────┘
         │            │            │            │
         ▼            ▼            ▼            ▼
   ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
   │ test-auth│ │test-feed │ │test-post │ │  ...     │
   │ (fork)   │ │ (fork)   │ │ (fork)   │ │ (fork)   │
   └──────────┘ └──────────┘ └──────────┘ └──────────┘
```

---

## 2. Agent Definitions

### 2.1 Agent Summary

| Agent | Slash Command | 역할 | 허용 도구 |
|---|---|---|---|
| **Auth Agent** | `/test-auth` | 인증, 온보딩, 토큰 관리 검증 | Read, Grep, Glob, Bash |
| **Feed Agent** | `/test-feed` | 피드 시스템, 게시물 상세, 댓글 검증 | Read, Grep, Glob, Bash |
| **Post Agent** | `/test-post` | 게시물 작성, 공개범위, 관리, 이미지 검증 | Read, Grep, Glob, Bash |
| **Social Agent** | `/test-social` | 좋아요, 팔로우, 차단, 프로필, 방명록 검증 | Read, Grep, Glob, Bash |
| **Recipe Agent** | `/test-recipe` | 레시피 목록/상세/편집, AI, 음성 검증 | Read, Grep, Glob, Bash |
| **Infra Agent** | `/test-infra` | 빌드, 테마, 네비게이션, 한국어, Firebase 검증 | Read, Grep, Glob, Bash |
| **Review Agent** | `/review-code` | 서비스 레이어, 데이터 모델, 타입, 코드 품질 리뷰 | Read, Grep, Glob |

> **최소 도구 원칙**: Review Agent는 코드를 수정하지 않으므로 Bash를 제외한다. 나머지 에이전트는 테스트 실행을 위해 Bash를 포함한다.

### 2.2 Agent Details

#### `/test-auth` — Auth & Onboarding Agent

```yaml
context: fork
agent: general-purpose
allowed-tools: Read, Grep, Glob, Bash
```

**검증 대상**:
- Google OAuth 로그인 플로우 (`signInWithGoogle`)
- Auth 상태 머신 (Zustand 4 states)
- Auth Guard 리다이렉트 로직
- 온보딩 (`registerUser`)
- 토큰 관리 (SecureStore)

**소스 파일**: `authService.ts`, `authStore.ts`, `useAuth.ts`, `app/_layout.tsx`, `app/(onboarding)/setup.tsx`

---

#### `/test-feed` — Feed System Agent

```yaml
context: fork
agent: general-purpose
allowed-tools: Read, Grep, Glob, Bash
```

**검증 대상**:
- 4종 피드 (realtime, hot, wack, personal)
- `buildFeedData()` 병렬 조회
- `chunk()` 유틸리티 (whereIn 10개 제한 우회)
- FeedCard 컴포넌트 구조 (Head, FeedImages, StatIcons, Content)
- 게시물 상세 + 실시간 댓글

**소스 파일**: `feedService.ts`, `useFeed.ts`, `useComments.ts`, `FeedCard.tsx`, `[postId].tsx`, `chunk.ts`

---

#### `/test-post` — Post System Agent

```yaml
context: fork
agent: general-purpose
allowed-tools: Read, Grep, Glob, Bash
```

**검증 대상**:
- 게시물 작성 2단계 플로우 (create → confirm)
- 카테고리별 조건부 입력 필드
- 공개 범위 필터링 (PUBLIC/FOLLOWER/PRIVATE)
- 핀/수정/소프트 삭제
- 이미지 병렬 업로드 + URL 기반 삭제

**소스 파일**: `postService.ts`, `storageService.ts`, `create/index.tsx`, `create/confirm.tsx`, create 컴포넌트 5개

---

#### `/test-social` — Social Features Agent

```yaml
context: fork
agent: general-purpose
allowed-tools: Read, Grep, Glob, Bash
```

**검증 대상**:
- 좋아요 (Optimistic UI + Transaction)
- 팔로우/언팔로우 (양방향 관계)
- 차단/차단해제 (팔로우 해제 + blocked 문서)
- 사용자 목록 (3탭: followers/following/blocked)
- 프로필 표시 + 통계 (owner vs visitor)
- 방명록 (스티키 노트 CRUD + 실시간)

**소스 파일**: `useLike.ts`, `useFollow.ts`, `followService.ts`, `guestBookService.ts`, `profileService.ts`, profile 컴포넌트 5개, `list.tsx`

---

#### `/test-recipe` — Recipe System Agent

```yaml
context: fork
agent: general-purpose
allowed-tools: Read, Grep, Glob, Bash
```

**검증 대상**:
- 레시피 목록/카테고리 필터/태그 검색
- 레시피 상세 (영양 정보, 재료, 조리법)
- 레시피 편집 (1100+ 라인 복합 페이지)
- AI 편집 (GPT-4o-mini JSON 모드)
- 음성 입력 (expo-speech-recognition 한국어)

**소스 파일**: `recipeService.ts`, `gptService.ts`, `useRecipes.ts`, `recipes/index.tsx`, `[recipeId].tsx`, `edit.tsx`

---

#### `/test-infra` — Infrastructure Agent

```yaml
context: fork
agent: general-purpose
allowed-tools: Read, Grep, Glob, Bash
```

**검증 대상**:
- EAS 빌드 프로파일 3종 (development/preview/production)
- Expo 설정 + 플러그인 11개
- 테마 상수 (colors, spacing, radius)
- 네비게이션 구조 (파일 기반 라우팅, 인증 가드, 탭 바)
- 상태 관리 전략 (Zustand + React Query + Firestore listeners)
- 한국어 유틸리티 (조사 처리, 상대 시간, 숫자 포맷)
- 환경 변수 + 보안 설정

**소스 파일**: `app.config.ts`, `eas.json`, `colors.ts`, `_layout.tsx`, `useFirestoreStream.ts`, `koreanGrammar.ts`, `formatTimestamp.ts`, `formatNumber.ts`

---

#### `/review-code` — Code Review Agent

```yaml
context: fork
agent: general-purpose
allowed-tools: Read, Grep, Glob
```

**검증 대상**:
- 서비스 레이어 10개 파일 API 일치 검증
- Firestore 데이터 모델 7개 컬렉션 필드 검증
- TypeScript 타입 5개 파일 인터페이스 검증
- RN Firebase `.exists()` 메서드 사용 확인 (버그 방지)
- `whereIn` + `chunk()` 사용 검증
- API 키 노출 여부 점검

**소스 파일**: `src/services/*.ts`, `src/types/*.ts`, `src/utils/chunk.ts`

> **Bash 제외 이유**: 리뷰 에이전트는 읽기 전용 작업만 수행하므로, 코드 실행이나 수정이 불필요하다.

---

## 3. Feature Coverage Matrix

아래 매트릭스는 `docs/*.md`의 **모든 기능**이 최소 1개 이상의 에이전트에 의해 검증됨을 보장한다.

| # | Feature | Source Doc | auth | feed | post | social | recipe | infra | review |
|---|---------|-----------|:----:|:----:|:----:|:------:|:------:|:-----:|:------:|
| F1 | Google OAuth 로그인 | BE 2.2, 5; FEAT 2.1 | **O** | | | | | | |
| F2 | 온보딩 (프로필 설정) | BE 4.1; FEAT 2.2 | **O** | | | | | | |
| F3 | 토큰 관리 (SecureStore) | BE 6 | **O** | | | | | | |
| F4 | 피드 시스템 (4종) | BE 4.2; FEAT 3.1 | | **O** | | | | | |
| F5 | FeedCard 컴포넌트 | FEAT 3.2; FE 6.1 | | **O** | | | | | |
| F6 | 게시물 상세 + 댓글 | FEAT 3.3; FE 5.4 | | **O** | | | | | |
| F7 | 게시물 작성 플로우 | FEAT 4; FE 6.3 | | | **O** | | | | |
| F8 | 게시물 공개범위 | BE 4.3; FEAT 5 | | | **O** | | | | |
| F9 | 게시물 관리 (핀/수정/삭제) | FEAT 10; BE 4.3 | | | **O** | | | | |
| F10 | 이미지 처리 | FEAT 11; BE 4.6 | | | **O** | | | | |
| F11 | 좋아요 시스템 | FEAT 6; BE 3.3; FE 5.2 | | | | **O** | | | |
| F12 | 팔로우/언팔로우 | FEAT 7.1; BE 3.5 | | | | **O** | | | |
| F13 | 차단/차단해제 | FEAT 7.2; BE 3.5 | | | | **O** | | | |
| F14 | 사용자 목록 | FEAT 7.3; BE 4.4 | | | | **O** | | | |
| F15 | 프로필 표시 + 통계 | FEAT 2.3; BE 4.9 | | | | **O** | | | |
| F16 | 방명록 (게스트북) | FEAT 9; BE 3.6, 4.7 | | | | **O** | | | |
| F17 | 레시피 목록/상세 | FEAT 8.1, 8.2; BE 4.8 | | | | | **O** | | |
| F18 | 레시피 편집 | FEAT 8.3 | | | | | **O** | | |
| F19 | AI 레시피 편집 (GPT) | FEAT 8.3; BE 4.10 | | | | | **O** | | |
| F20 | 음성 입력 | FEAT 8.3 | | | | | **O** | | |
| F21 | 테마/스타일링 | FEAT 12; FE 8 | | | | | | **O** | |
| F22 | 한국어 지원 | FEAT 13 | | | | | | **O** | |
| F23 | 네비게이션/라우팅 | FE 3 | | | | | | **O** | |
| F24 | 상태 관리 전략 | FE 4 | | | | | | **O** | |
| F25 | 빌드 & 배포 | FE 10 | | | | | | **O** | |
| F26 | Firebase 설정 & 보안 | BE 7, 8; FE 10.4 | | | | | | **O** | |
| F27 | Firestore 데이터 모델 | BE 3 | | | | | | | **O** |
| F28 | TypeScript 타입 정의 | FE 7 | | | | | | | **O** |

**Coverage: 28/28 features (100%)**

---

## 4. Usage

### 4.1 개별 에이전트 실행

```bash
# 전체 범위 검증
/test-auth
/test-feed
/test-post
/test-social
/test-recipe
/test-infra
/review-code

# 특정 영역에 집중
/test-auth onboarding
/test-feed personal
/test-social guestbook
/test-recipe ai
/test-infra theme
/review-code authService
```

### 4.2 전체 기능 검증 (순차 실행)

```
/test-auth → /test-feed → /test-post → /test-social → /test-recipe → /test-infra → /review-code
```

### 4.3 주요 검증 포인트

| 에이전트 | 핵심 검증 항목 |
|---------|--------------|
| test-auth | Auth 상태 머신 4단계 전환, `.exists()` 메서드 사용 |
| test-feed | `chunk(10)` 구현, React Query 캐싱 설정 |
| test-post | 공개범위 3단계 필터링, 소프트 삭제 (hard delete 아님) |
| test-social | Transaction 원자성, Optimistic UI 롤백, 양방향 팔로우 |
| test-recipe | GPT JSON 모드 응답, 음성 입력 폴백 |
| test-infra | 플러그인 11개 완전성, 테마 상수 일치 |
| review-code | `.exists` 버그 패턴, API 키 노출, 타입 일치 |

---

## 5. Skill File Structure

```
.claude/skills/
├── test-auth/
│   └── SKILL.md              # Auth, onboarding, token management
├── test-feed/
│   └── SKILL.md              # Feed system, post detail, comments
├── test-post/
│   └── SKILL.md              # Post creation, visibility, management, images
├── test-social/
│   └── SKILL.md              # Like, follow, block, profile, guestbook
├── test-recipe/
│   └── SKILL.md              # Recipe list/detail/edit, AI, voice
├── test-infra/
│   └── SKILL.md              # Build, theme, navigation, i18n, Firebase
└── review-code/
    └── SKILL.md              # Service API, data model, types, code quality
```

### 5.1 공통 스킬 설정

모든 에이전트에 공통 적용되는 설정:

| 설정 | 값 | 이유 |
|---|---|---|
| `context` | `fork` | 독립 컨텍스트에서 실행하여 메인 대화를 오염시키지 않음 |
| `agent` | `general-purpose` | 범용 에이전트로 다양한 도구 활용 가능 |
| `user-invocable` | `true` (기본값) | 슬래시 명령어로 직접 호출 가능 |

### 5.2 도구 할당 원칙

| 도구 | 할당 에이전트 | 용도 |
|---|---|---|
| `Read` | 전체 7개 | 소스 파일 읽기 |
| `Grep` | 전체 7개 | 패턴 검색 (함수명, 버그 패턴 등) |
| `Glob` | 전체 7개 | 파일 탐색 |
| `Bash` | 6개 (review 제외) | 테스트 실행, 빌드 검증, 스크립트 실행 |

> **최소 할당 원칙**: review-code 에이전트는 읽기 전용이므로 Bash를 제외하여 실수로 코드를 수정하는 것을 방지한다.
