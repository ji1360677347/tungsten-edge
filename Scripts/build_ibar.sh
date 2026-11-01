#!/bin/bash
# 编译 iBar（本机自用版本）并安装到 /Applications。
#
# 三个必需参数，缺一个就失败：
#
#   DEVELOPER_DIR   xcode-select 指向的是 Command Line Tools，不指过去 xcodebuild 直接报错。
#
#   -disable-sandbox
#       编译 SwiftUI 代码时，编译器会把宏插件（swift-plugin-server）放进 sandbox-exec
#       里跑。某些受限环境下这一步会被拒（报 `sandbox_apply: Operation not permitted`），
#       于是 @State 之类的宏全部展开失败，报出一堆假的「cannot find '$isPressed' in scope」。
#       这个开关让编译器跳过该沙箱；没有它整棵树都编不过。
#
#   CODE_SIGN_IDENTITY="-" CODE_SIGN_STYLE=Manual
#       工程默认用仓库作者的本地自签名证书 "macos-dock-cc Local Code Signing"，
#       本机没有这张证书，必须改成 ad-hoc。
#
# 用法：
#   ./Scripts/build_ibar.sh          # 编译并安装
#   ./Scripts/build_ibar.sh --build  # 只编译，不安装

set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME="iBar"
CONFIG="Release"
DERIVED="build"

echo "==> 编译 ${APP_NAME}（${CONFIG}，arm64）"
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project macos-dock-cc-v2.xcodeproj \
  -scheme macos-dock-cc-v2 \
  -configuration "$CONFIG" \
  -derivedDataPath "$DERIVED" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGN_STYLE=Manual \
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
rm -rf "/Applications/${APP_NAME}.app"
cp -R "$BUILT" /Applications/
codesign -v "/Applications/${APP_NAME}.app" && echo "签名完整性 OK"

echo "==> 完成：/Applications/${APP_NAME}.app"
