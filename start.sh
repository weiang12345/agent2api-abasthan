#!/bin/sh
# Abasthan 启动阶段：桥接平台注入的 PORT，启动 Agent2API
# 关键点：Abasthan 的 Start Command 执行器不做完整 shell 解析，
#         所以这里把所有复杂逻辑封装进脚本，Start Command 只写 `sh start.sh`。
set -eu
cd "$(dirname "$0")"

VERSION="${AGENT2API_VERSION:-v3.5.0-beta.4}"
ARCH="${AGENT2API_ARCH:-amd64}"

# 兜底：构建产物缺失时现场下载（例如构建缓存异常）
if [ ! -x ./agent2api-server ]; then
  echo "==> binary missing, downloading ${VERSION}"
  PKG="agent2api-server-linux-${ARCH}.tar.gz"
  URL="https://github.com/aimod-cc/Agent2API/releases/download/${VERSION}/${PKG}"
  curl -fsSL --retry 3 --connect-timeout 20 --max-time 300 -o "/tmp/${PKG}" "$URL"
  tar -xzf "/tmp/${PKG}" -C .
  chmod +x agent2api-server
fi

# 平台注入 PORT；未注入时回落 3065
export AGENT2API_PROXY_PORT="${PORT:-3065}"
# 数据目录：容器内可写路径（注意：Abasthan 临时盘，重部署即清零）
export AGENT2API_PROXY_HOME="${AGENT2API_PROXY_HOME:-$PWD/data}"
export AGENT2API_UI_DIR="$PWD/ui"
# 容器内自更新在临时盘上无意义，关掉；升级走改 AGENT2API_VERSION 重新部署
export AGENT2API_SELF_UPDATE=0

mkdir -p "$AGENT2API_PROXY_HOME"

echo "==> starting Agent2API ${VERSION}"
echo "    port: ${AGENT2API_PROXY_PORT}"
echo "    data: ${AGENT2API_PROXY_HOME}"
echo "    ui  : ${AGENT2API_UI_DIR}"

exec ./agent2api-server
