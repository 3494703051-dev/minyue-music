#!/bin/bash
# 民族音乐-畲塔怒鄂版 · 生成 .dmg 安装包
# 用法: bash make_dmg.sh <path-to-.app> <output-dir>
set -euo pipefail

APP="${1:?需要 .app 路径}"
OUTDIR="${2:?需要输出目录}"
APP_NAME="民族音乐-畲塔怒鄂版"
VOLNAME="$APP_NAME"
DMG="$OUTDIR/${APP_NAME}.dmg"

mkdir -p "$OUTDIR"
[ -d "$APP" ] || { echo "找不到 .app: $APP"; exit 1; }

echo "== 1. 清理扩展属性 =="
xattr -cr "$APP" 2>/dev/null || true

echo "== 2. ad-hoc 签名（arm64 必须，否则被内核拒绝） =="
# 先签内部所有 Mach-O / dylib / so，再签外层 bundle
find "$APP/Contents" -type f \( -name "*.so" -o -name "*.dylib" -o -name "*.node" \) -print0 2>/dev/null \
  | xargs -0 -I{} codesign --force --sign - --timestamp=none {} 2>/dev/null || true
if [ -f "$APP/Contents/MacOS/$APP_NAME" ]; then
  codesign --force --sign - --timestamp=none "$APP/Contents/MacOS/$APP_NAME" 2>/dev/null || true
fi
codesign --force --deep --sign - --timestamp=none "$APP" 2>&1 | tail -3 || true
echo "--- 签名校验 ---"
codesign --verify --verbose=2 "$APP" 2>&1 | tail -5 || echo "(verify 有告警，继续)"

echo "== 3. 搭建 dmg 根目录 =="
STAGE="$(mktemp -d /tmp/mre_dmg.XXXXXX)"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

echo "== 4. hdiutil 生成压缩镜像 =="
rm -f "$DMG"
hdiutil create -volname "$VOLNAME" -srcfolder "$STAGE" -ov -format UDZO -fs HFS+ "$DMG" 2>&1 | tail -5

echo "== 5. 校验镜像 =="
hdiutil verify "$DMG" 2>&1 | tail -3

rm -rf "$STAGE"
echo "== 完成: $DMG =="
ls -lh "$DMG"
