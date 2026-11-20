#!/bin/sh
# Abasthan 构建阶段：下载 Agent2API 服务端二进制 + 面板 UI
# 版本通过环境变量 AGENT2API_VERSION 覆盖（在 Abasthan 的 Environment Variables 里加即可）
set -eu

VERSION="${AGENT2API_VERSION:-v3.5.0-beta.4}"
ARCH="${AGENT2API_ARCH:-amd64}"
PKG="agent2api-server-linux-${ARCH}.tar.gz"
URL="https://github.com/aimod-cc/Agent2API/releases/download/${VERSION}/${PKG}"

echo "==> Agent2API ${VERSION} (${ARCH})"

download() {
  i=1
  while [ "$i" -le 3 ]; do
    if curl -fsSL --connect-timeout 20 --max-time 300 -o "$2" "$1"; then
      return 0
    fi
    echo "    attempt ${i} failed, retrying in 3s..."
    sleep 3
    i=$((i + 1))
  done
  return 1
}

echo "==> downloading ${URL}"
download "$URL" "/tmp/${PKG}" || { echo "ERROR: download failed"; exit 1; }
[ -s "/tmp/${PKG}" ] || { echo "ERROR: empty package"; exit 1; }

# 校验 sha256（上游提供则校验，格式不兼容时仅告警不中断）
if curl -fsSL --connect-timeout 20 -o "/tmp/${PKG}.sha256" "${URL}.sha256" 2>/dev/null; then
  EXPECTED=$(awk '{print $1}' "/tmp/${PKG}.sha256" 2>/dev/null | head -n1)
  if [ -n "$EXPECTED" ]; then
    ACTUAL=$(sha256sum "/tmp/${PKG}" | awk '{print $1}')
    if [ "$EXPECTED" = "$ACTUAL" ]; then
      echo "==> checksum OK"
    else
      echo "ERROR: checksum mismatch (expected ${EXPECTED}, got ${ACTUAL})"
      exit 1
    fi
  fi
else
  echo "==> checksum file unavailable, skipping"
fi

echo "==> extracting"
tar -xzf "/tmp/${PKG}" -C .
chmod +x agent2api-server
[ -d ui ] || echo "WARN: ui/ not found in package"

echo "==> build complete"
ls -la agent2api-server
