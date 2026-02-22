# T!ng

#### "T!ng: 소셜 푸드 커뮤니티"

T!ng은 음식이라는 공통된 즐거움을 통해 사람들을 연결하는 소셜 푸드 커뮤니티 앱입니다. 맛있는 순간을 기록하고, 레시피를 탐색하며, AI 보조 요리 편집 기능으로 나만의 요리를 완성할 수 있습니다.

> 이전 프로젝트명: VibeYum

## 기술 스택

- **React Native** 0.81 + **Expo SDK 54**
- **TypeScript** (strict mode)
- **Expo Router v6** (파일 기반 라우팅)
- **Zustand** (인증 상태) + **React Query v5** (서버 상태)
- **React Native Firebase** v23 (Auth, Firestore, Storage)
- **OpenAI GPT-4o-mini** (레시피 AI 편집)

## 시작하기

### 전제 조건

- **Node.js 20** (`nvm use 20`)
- **EAS CLI** (`npm install -g eas-cli`)
- Expo 계정 + EAS 프로젝트 설정
- Firebase 프로젝트 (`vibeyum-alpha`) + `GoogleService-Info.plist`

### 설치

```bash
git clone https://github.com/ReverieGround/ting.git
cd ting/ting-rn
nvm use 20
npm install
```

### 개발 (시뮬레이터)

```bash
# dev 빌드 생성 (최초 1회)
npx eas build --platform ios --profile development

# Metro 번들러 + 앱 실행
npx expo start --dev-client

# 또는 원스텝 스크립트
./run-simulator.sh
```

### TestFlight 배포

```bash
./deploy-testflight.sh
```

## 프로젝트 구조

```
ting-rn/
├── app/                # Expo Router 라우트
│   ├── (auth)/         #   로그인
│   ├── (onboarding)/   #   프로필 설정
│   └── (tabs)/         #   메인 탭 (피드, 레시피, 기록, 프로필)
├── src/
│   ├── components/     # UI 컴포넌트
│   ├── hooks/          # 커스텀 훅
│   ├── services/       # Firebase 서비스 레이어
│   ├── stores/         # Zustand 스토어
│   ├── theme/          # 색상, 간격, 라디우스
│   ├── types/          # TypeScript 인터페이스
│   └── utils/          # 유틸리티
├── assets/             # 앱 아이콘, 스플래시
└── plugins/            # Expo 커스텀 플러그인
```

## 문서

자세한 문서는 [`docs/`](./docs) 디렉토리를 참조하세요:

- [**FEATURES.md**](./docs/FEATURES.md) — 기능 명세서
- [**FE_ARCH.md**](./docs/FE_ARCH.md) — 프론트엔드 아키텍처
- [**BE_ARCH.md**](./docs/BE_ARCH.md) — 백엔드 (Firebase) 아키텍처

## 주요 기능

| 기능 | 설명 |
|---|---|
| 소셜 피드 | 전체/Hot/Wack/Personal 피드, 좋아요, 댓글 |
| 게시물 작성 | 이미지, 카테고리, 리뷰, 공개 범위 설정 |
| 레시피 탐색 | 레시피 목록, 상세, 영양 정보 |
| AI 요리 편집 | 음성/텍스트 입력 → GPT로 레시피 수정 |
| 프로필 | 팔로우/팔로잉, 방명록, 게시물 핀 |

---

Created by **ReverieGround**
