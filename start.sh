#!/bin/sh
# Abasthan 启动阶段：桥接平台注入的 PORT，启动 Agent2API
# 关键点：Abasthan 的 Start Command 执行器不做完整 shell 解析，
#         所以把所有复杂逻辑封装进脚本，Start Command 只写 `sh start.sh`。
set -u
cd "$(dirname "$0")"

VERSION="${AGENT2API_VERSION:-v3.4.2}"
ARCH="${AGENT2API_ARCH:-amd64}"

echo "===== ENV DIAG ====="
echo "PWD=$(pwd)"
echo "PORT=${PORT:-<unset>}"
echo "VERSION=${VERSION} ARCH=${ARCH}"
echo "libc: $( (ldd --version 2>&1 | head -n1) || echo unknown )"
echo "os:   $( (cat /etc/os-release 2>/dev/null | grep -E '^(ID|VERSION_ID)=' | tr '\n' ' ') || echo unknown )"
echo "===================="

# 兜底：构建产物缺失时现场下载（例如构建缓存异常）
if [ ! -x ./agent2api-server ]; then
  echo "==> binary missing, downloading ${VERSION}"
  PKG="agent2api-server-linux-${ARCH}.tar.gz"
  URL="https://github.com/aimod-cc/Agent2API/releases/download/${VERSION}/${PKG}"
  curl -fsSL --retry 3 --connect-timeout 20 --max-time 300 -o "/tmp/${PKG}" "$URL" || {
    echo "ERROR: fallback download failed"; sleep 30; exit 1; }
  tar -xzf "/tmp/${PKG}" -C .
  chmod +x agent2api-server
fi

echo "===== BINARY DIAG ====="
ls -la agent2api-server 2>&1
echo "--- file ---"
file agent2api-server 2>&1 || echo "(file command unavailable)"
echo "--- ldd ---"
ldd agent2api-server 2>&1 || echo "(ldd failed - likely musl/alpine or static)"
echo "--- ui dir ---"
ls -d ui 2>&1 && ls ui 2>&1 | head -n 5
echo "======================="

# 平台注入 PORT；未注入时回落 3065
export AGENT2API_PROXY_PORT="${PORT:-3065}"
# 必须监听所有网卡，否则平台探测不到端口
export AGENT2API_HOST="0.0.0.0"
# 数据目录：容器内可写路径（注意：Abasthan 临时盘，重部署即清零）
export AGENT2API_PROXY_HOME="${AGENT2API_PROXY_HOME:-$PWD/data}"
export AGENT2API_UI_DIR="$PWD/ui"
# 容器内自更新在临时盘上无意义，关掉；升级走改 AGENT2API_VERSION 重新部署
export AGENT2API_SELF_UPDATE=0

mkdir -p "$AGENT2API_PROXY_HOME"

echo "==> starting Agent2API ${VERSION} on 0.0.0.0:${AGENT2API_PROXY_PORT}"

./agent2api-server
CODE=$?

echo "==> agent2api-server exited with code ${CODE}"
# 退避：避免平台热循环（崩溃 -> 立刻重启 -> 重复下载 22MB）
sleep 30
exit "$CODE"
