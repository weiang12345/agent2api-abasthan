# agent2api-abasthan

Abasthan 免费档部署 Agent2API 网关。**脚本进仓库，Build/Start Command 各一行**——升级只改一个环境变量，不用动平台配置。

## 仓库结构

```
build.sh    # 构建阶段：下载对应版本的二进制 + UI，校验 sha256
start.sh    # 启动阶段：桥接 PORT，启动服务
README.md
```

## Abasthan 部署配置

| 配置项 | 值 |
|---|---|
| App Language | **Python 3.12**（挂名，仅借 shell 运行时） |
| Branch | `main` |
| Build Command | `sh build.sh` |
| Start Command | `sh start.sh` |

## 环境变量

| Key | Value | 说明 |
|---|---|---|
| `AGENT2API_VERSION` | `v3.5.0-beta.4` | **升级就改这里**，然后重新部署 |
| `AGENT2API_ARCH` | `amd64` | ARM 机器改 `arm64` |
| `AGENT2API_ADMIN_USER` | 你的管理员名 | 面板登录账号 |
| `AGENT2API_ADMIN_PASSWORD` | 强密码 | 面板登录密码 |

> 稳定版是 `v3.4.2`；`v3.5.0-beta.*` 为测试版（含 DB schema v24→v30 迁移）。

## 部署后清单

1. `https://<app>.abasthan.app/health` 返回 `{"status":"ok"}`
2. 面板登录 → **网关 Key** 页创建第一把 Key（未建 Key 时 `/v1/*` 全部 fail-closed）
3. 面板内安装 provider 插件、配置账号
4. UptimeRobot 加 5 分钟监控 `.../health`（保活 + 宕机告警）

## 纪律

- **`./data` 重部署即清零**：账号、网关 Key、插件配置全在 SQLite 里。升级前先在面板记录，升级后重配。
- 0.1 vCPU / 512MB 为轻量位，实测极轻端点上限约 400–500 RPS；真实中转约 10–20 路并发流。
- 主力大流量（如 5 亿 token/天）不要放这里，走自有服务器。
- 平台带宽无明面上限但有公平使用约束。

## 升级流程

1. Abasthan → Environment Variables → 改 `AGENT2API_VERSION`
2. 点 **Redeploy**
3. 面板重新配置账号与 Key（`./data` 已清空）
