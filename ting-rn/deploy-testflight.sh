#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "🚀 T!ng TestFlight 배포 스크립트"
echo "================================="
echo ""

# 1. Node 버전 확인
echo "📌 Node 버전 확인..."
if command -v nvm &>/dev/null; then
  nvm use 20 2>/dev/null || true
fi
node_ver=$(node -v)
echo "   Node: $node_ver"

# 2. 의존성 설치
echo ""
echo "📦 의존성 설치..."
npm install

# 3. EAS 로그인 확인
echo ""
echo "🔑 EAS 로그인 확인..."
npx eas whoami || {
  echo "❌ EAS 로그인이 필요합니다. 'npx eas login'을 실행하세요."
  exit 1
}

# 4. iOS Production 빌드
echo ""
echo "🔨 iOS Production 빌드 시작..."
echo "   (EAS Cloud에서 빌드됩니다. 약 15-20분 소요)"
echo ""
npx eas build --platform ios --profile production

# 5. TestFlight 제출
echo ""
echo "📤 TestFlight에 제출..."
npx eas submit --platform ios --latest

echo ""
echo "✅ 완료! App Store Connect에서 TestFlight 빌드를 확인하세요."
echo "   https://appstoreconnect.apple.com"
