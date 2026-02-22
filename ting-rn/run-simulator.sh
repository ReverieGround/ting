#!/bin/bash
set -e

cd "$(dirname "$0")"

BUNDLE_ID="com.reverieground.ting"
APP_NAME="Tng"

echo "📱 T!ng Simulator Launch 스크립트"
echo "=================================="
echo ""

# 1. Node 버전 확인
echo "📌 Node 버전 확인..."
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
nvm use 20 2>/dev/null || true
echo "   Node: $(node -v)"

# 2. 의존성 설치
echo ""
echo "📦 의존성 설치..."
npm install --silent

# 3. 시뮬레이터 선택 (부팅된 것 우선, 없으면 최신 iPhone)
BOOTED_UDID=$(xcrun simctl list devices booted -j | python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data['devices'].items():
    for d in devices:
        if d['state'] == 'Booted' and 'iPhone' in d['name']:
            print(d['udid']); sys.exit()
" 2>/dev/null || true)

if [ -z "$BOOTED_UDID" ]; then
  echo "🔍 부팅된 시뮬레이터 없음. 최신 iPhone 시뮬레이터 부팅 중..."
  UDID=$(xcrun simctl list devices available -j | python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime in sorted(data['devices'].keys(), reverse=True):
    for d in data['devices'][runtime]:
        if 'iPhone' in d['name'] and d['isAvailable']:
            print(d['udid']); sys.exit()
")
  xcrun simctl boot "$UDID"
  BOOTED_UDID="$UDID"
fi

SIM_NAME=$(xcrun simctl list devices -j | python3 -c "
import json, sys
data = json.load(sys.stdin)
udid = '$BOOTED_UDID'
for runtime, devices in data['devices'].items():
    for d in devices:
        if d['udid'] == udid:
            print(d['name']); sys.exit()
")
echo "   시뮬레이터: $SIM_NAME ($BOOTED_UDID)"

# 4. Simulator.app 열기
open -a Simulator

# 5. 기존 빌드 확인 — 없으면 EAS 빌드
echo ""
INSTALLED=$(xcrun simctl listapps "$BOOTED_UDID" 2>/dev/null | grep -c "$BUNDLE_ID" || true)

if [ "$INSTALLED" -gt 0 ]; then
  echo "✅ 앱이 이미 설치되어 있습니다."
  echo ""
  read -p "🔨 새로 빌드할까요? (y/N) " BUILD_NEW
  if [[ "$BUILD_NEW" =~ ^[Yy]$ ]]; then
    INSTALLED=0
  fi
fi

if [ "$INSTALLED" -eq 0 ]; then
  echo "🔨 EAS Development 빌드 시작..."
  echo "   (EAS Cloud에서 빌드됩니다. 약 10-15분 소요)"
  echo ""
  npx eas build --platform ios --profile development

  # 최신 빌드 다운로드
  echo ""
  echo "📥 빌드 다운로드 중..."
  BUILD_URL=$(npx eas build:list --platform ios --distribution internal --limit 1 --json 2>/dev/null \
    | python3 -c "import json,sys; print(json.load(sys.stdin)[0]['artifacts']['buildUrl'])")

  TMPDIR_BUILD=$(mktemp -d)
  curl -sL "$BUILD_URL" -o "$TMPDIR_BUILD/build.tar.gz"

  echo "📦 압축 해제 중..."
  tar -xzf "$TMPDIR_BUILD/build.tar.gz" -C "$TMPDIR_BUILD"
  APP_PATH=$(find "$TMPDIR_BUILD" -name "*.app" -type d | head -1)

  if [ -z "$APP_PATH" ]; then
    echo "❌ .app 파일을 찾을 수 없습니다."
    rm -rf "$TMPDIR_BUILD"
    exit 1
  fi

  # 설치
  echo "📲 시뮬레이터에 설치 중..."
  xcrun simctl install "$BOOTED_UDID" "$APP_PATH"
  rm -rf "$TMPDIR_BUILD"
fi

# 6. 앱 실행
echo ""
echo "🚀 앱 실행 중..."
xcrun simctl launch "$BOOTED_UDID" "$BUNDLE_ID"

# 7. Metro 시작
echo ""
echo "⚡ Metro 번들러 시작..."
echo "   (Ctrl+C로 종료)"
echo ""
npx expo start --dev-client
