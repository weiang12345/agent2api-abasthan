#!/bin/sh
# Abasthan 启动阶段：启动 Agent2API
# 关键点：
#  1) Abasthan 的 Start Command 执行器不做完整 shell 解析 → Start Command 只写 `sh start.sh`
#  2) agent2api-server 默认监听 9400，平台端口发现能识别它；不要强行改端口
set -u
cd "$(dirname "$0")"

VERSION="${AGENT2API_VERSION:-v3.5.0-beta.4}"
ARCH="${AGENT2API_ARCH:-amd64}"

echo "===== ENV DIAG ====="
echo "PWD=$(pwd)"
echo "PORT=${PORT:-<unset>}"
echo "VERSION=${VERSION} ARCH=${ARCH}"
echo "os: $( (cat /etc/os-release 2>/dev/null | grep -E '^(ID|VERSION_ID)=' | tr '\n' ' ') || echo unknown )"
echo "===================="

# 兜底：构建产物缺失时现场下载
if [ ! -x ./agent2api-server ]; then
  echo "==> binary missing, downloading ${VERSION}"
  PKG="agent2api-server-linux-${ARCH}.tar.gz"
  URL="https://github.com/aimod-cc/Agent2API/releases/download/${VERSION}/${PKG}"
  curl -fsSL --retry 3 --connect-timeout 20 --max-time 300 -o "/tmp/${PKG}" "$URL" || {
    echo "ERROR: fallback download failed"; sleep 30; exit 1; }
  tar -xzf "/tmp/${PKG}" -C .
  chmod +x agent2api-server
fi

# 数据目录与 UI 目录
export AGENT2API_PROXY_HOME="${AGENT2API_PROXY_HOME:-$PWD/data}"
export AGENT2API_UI_DIR="$PWD/ui"
# 容器内自更新在临时盘上无意义；升级走改 AGENT2API_VERSION 重新部署
export AGENT2API_SELF_UPDATE=0
# 监听所有网卡
export AGENT2API_HOST="${AGENT2API_HOST:-0.0.0.0}"

# 端口策略：
#   二进制默认 9400，平台能自动发现 → 优先用它自己的默认值。
#   仅当你显式设置了 AGENT2API_PROXY_PORT 环境变量时才覆盖。
if [ -n "${AGENT2API_PROXY_PORT:-}" ]; then
  export AGENT2API_PROXY_PORT
  PORT_DESC="${AGENT2API_PROXY_PORT} (explicit)"
else
  unset AGENT2API_PROXY_PORT 2>/dev/null || true
  PORT_DESC="9400 (binary default)"
fi

mkdir -p "$AGENT2API_PROXY_HOME"

echo "===== BINARY DIAG ====="
ls -la agent2api-server 2>&1
[ -d "$AGENT2API_UI_DIR" ] && echo "ui: $(ls "$AGENT2API_UI_DIR" 2>/dev/null | head -n 3 | tr '\n' ' ')" || echo "ui: MISSING"
echo "======================="

echo "==> starting Agent2API ${VERSION}"
echo "    host: ${AGENT2API_HOST}"
echo "    port: ${PORT_DESC}"
echo "    data: ${AGENT2API_PROXY_HOME}"

./agent2api-server
CODE=$?

echo "==> agent2api-server exited with code ${CODE}"
sleep 30
exit "$CODE"
