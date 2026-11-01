#!/bin/bash
# 编译 iBar（本机自用版本）并安装到 /Applications。
#
# 用法：
#   ./Scripts/build_ibar.sh          # 编译并安装
#   ./Scripts/build_ibar.sh --build  # 只编译，不安装
#
# ---------------------------------------------------------------------------
# 为什么必须用「稳定身份」签名，不能用 ad-hoc（`-`）
# ---------------------------------------------------------------------------
# ad-hoc 签名的 designated requirement 是 **cdhash 本身**：
#
#     # designated => cdhash H"f042e8d6e1f2…"
#
# 于是每重新编译一次，cdhash 就换一个值，系统认为「这不是同一个程序」，
# 已经授予的辅助功能（Accessibility）权限当场作废 —— 表现是 iBar 每次重建后
# 都重新弹「需要开启辅助功能权限」，而系统设置里那条开关看着还是打开的。
#
# 换成基于证书的签名后，designated requirement 变成
#
#     # designated => identifier "com.ji1360677347.ibar" and certificate leaf = H"…"
#
# 证书不变，重建就不动这个需求，授权可以一直留着。
#
# ---------------------------------------------------------------------------
# 为什么需要 -disable-sandbox
# ---------------------------------------------------------------------------
# 编译 SwiftUI 代码时，编译器会把宏插件（swift-plugin-server）放进 sandbox-exec
# 里跑。某些受限环境下这一步会被拒（报 `sandbox_apply: Operation not permitted`），
# 于是 @State 之类的宏全部展开失败，报出一堆假的「cannot find '$isPressed' in scope」。
# 这个开关让编译器跳过该沙箱；没有它整棵树都编不过。
#
# ---------------------------------------------------------------------------
# 为什么必须指定 DEVELOPER_DIR
# ---------------------------------------------------------------------------
# xcode-select 指向的是 Command Line Tools 时，xcodebuild 直接报错。
# ---------------------------------------------------------------------------

set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME="iBar"
CONFIG="Release"
DERIVED="build"
BUNDLE_ID="com.ji1360677347.ibar"

# --- 选签名身份：优先本仓库约定，其次本机开发者证书，最后才退回 ad-hoc ----
pick_identity() {
  local identities
  identities="$(security find-identity -v -p codesigning 2>/dev/null || true)"

  # 1) 上游工程配置里写死的本地自签名证书（若本机也建过，最贴合原设计）
  if printf '%s' "$identities" | grep -q "macos-dock-cc Local Code Signing"; then
    printf 'macos-dock-cc Local Code Signing'
    return
  fi

  # 2) Apple Development 证书：同样能给出稳定的证书型 designated requirement
  local dev
  dev="$(printf '%s' "$identities" | sed -n 's/.*"\(Apple Development: .*\)"/\1/p' | head -1)"
  if [ -n "$dev" ]; then
    printf '%s' "$dev"
    return
  fi

  # 3) 兜底：ad-hoc。能跑，但每次重建都会丢辅助功能授权，必须提示。
  printf '%s' "-"
}

IDENTITY="$(pick_identity)"

if [ "$IDENTITY" = "-" ]; then
  echo "!! 警告：本机没有可用的代码签名证书，退回 ad-hoc 签名。"
  echo "!! 后果：每次重新编译都会改变 cdhash，辅助功能授权会失效，需要重新勾选。"
  echo "!! 想避免的话，用「钥匙串访问 > 证书助理 > 创建证书」建一张代码签名证书。"
else
  echo "==> 签名身份：${IDENTITY}"
fi

echo "==> 编译 ${APP_NAME}（${CONFIG}，arm64）"
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project macos-dock-cc-v2.xcodeproj \
  -scheme macos-dock-cc-v2 \
  -configuration "$CONFIG" \
  -derivedDataPath "$DERIVED" \
  CODE_SIGN_IDENTITY="$IDENTITY" \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM="" \
  PROVISIONING_PROFILE_SPECIFIER="" \
  ARCHS=arm64 \
  ONLY_ACTIVE_ARCH=YES \
  OTHER_SWIFT_FLAGS='$(inherited) -disable-sandbox' \
  build

BUILT="${DERIVED}/Build/Products/${CONFIG}/${APP_NAME}.app"
[ -d "$BUILT" ] || { echo "!! 没找到产物 $BUILT" >&2; exit 1; }

if [ "${1:-}" = "--build" ]; then
  echo "==> 产物：$BUILT"
  exit 0
fi

echo "==> 安装到 /Applications"
# 先退出旧实例，否则替换会在已运行的进程上留下悬空的 bundle
if pgrep -x "$APP_NAME" >/dev/null 2>&1; then
  pkill -TERM -x "$APP_NAME" || true
  for _ in $(seq 1 20); do pgrep -x "$APP_NAME" >/dev/null 2>&1 || break; sleep 0.2; done
fi

rm -rf "/Applications/${APP_NAME}.app"
cp -R "$BUILT" /Applications/
codesign -v "/Applications/${APP_NAME}.app" && echo "签名完整性 OK"

echo "==> 设计需求（换证书或换 bundle id 时这里会变，变了就要重新授权）"
codesign -d -r- "/Applications/${APP_NAME}.app" 2>&1 | sed -n 's/^# designated => /    /p'
echo "==> bundle id: $(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "/Applications/${APP_NAME}.app/Contents/Info.plist")"
echo "==> 完成：/Applications/${APP_NAME}.app"
