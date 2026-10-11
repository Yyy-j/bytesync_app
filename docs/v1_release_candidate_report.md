# BiteSync Step 5B Release Candidate 验收记录

自动检查日期：2026-10-12（Asia/Tokyo）

本报告不代表真机 Smoke 已完成。自动检查与人工检查分开记录；只有下方所有
`MANUAL CHECK` 项目均由测试人员确认 `PASS` 后，才能把最终状态改为
`STEP 5B READY — V1 RELEASE CANDIDATE`。

## 1. Git

自动检查前重新 fetch 了两个仓库的 `origin/lib`。本地 HEAD 与对应远端
`origin/lib` 一致，检查期间未切换 `main`，未 commit 或 push。

| Project | Repository | Branch | HEAD |
| --- | --- | --- | --- |
| Frontend | `Yyy-j/bytesync_app` | `lib` | `a31e1a84f1604a1c7e6749675aa9109a57ab330a` |
| Backend | `Yyy-j/bytesyn_api` | `lib` | `3f089d572c509f29cda7b4838cf472ca88743244` |

## 2. CI 与测试

### Frontend

- Latest `lib` GitHub Actions run: `38129104216`
- Workflow conclusion: `success`
- `dart format --output=none --set-exit-if-changed .`: PASS
- `flutter analyze`: PASS
- `flutter test`: PASS
- 本地同一 HEAD 复跑测试总数：149 passed
- `test/v1_core_flow_test.dart`: PASS；完整 `flutter test` 输出中实际执行
  `restore retry -> onboarding -> Home -> relaunch -> 401 Login`
- 本地同一 HEAD 复跑 analyze：PASS，`No issues found`

CI URL：<https://github.com/Yyy-j/bytesync_app/actions/runs/38129104216>

### Backend

- Latest `lib` GitHub Actions run: `37551712920`
- Workflow conclusion: `success`
- `Run test suite`: PASS
- 本地同一 HEAD、隔离 PostgreSQL 测试库复跑：279 passed
- Warning：1 条第三方 `StarletteDeprecationWarning`，没有 test failure

CI URL：<https://github.com/Yyy-j/bytesyn_api/actions/runs/37551712920>

## 3. NAS 自动检查

以下 Git 命令在 NAS 的 `/home/yyy/bytesync-api` checkout 中实际执行：

```text
git branch --show-current
lib

git rev-parse HEAD
3f089d572c509f29cda7b4838cf472ca88743244
```

注意：上述结果证明 NAS checkout 的版本；运行容器没有内嵌 `.git` metadata，
因此它不是容器镜像 commit provenance 的独立证明。

### Health

实际请求 `GET http://127.0.0.1:8000/health`：

```json
{"status":"ok","database":true}
```

结果：PASS。Backend 进程可响应，PostgreSQL readiness 为 `true`。

### OpenAPI

实际读取 `GET http://127.0.0.1:8000/openapi.json` 并检查以下 paths：

| Path | Result |
| --- | --- |
| `/users/me/onboarding` | PASS |
| `/users/me/body` | PASS |
| `/users/me/weight-measurements` | PASS |
| `/users/me/calorie-recommendation` | PASS |

### Database migration

对 production PostgreSQL 只执行了只读查询。`schema_migrations` 查询结果包含：

```text
016_body_onboarding
```

结果：PASS。未执行 `DROP`、`TRUNCATE`、migration、重建或其他 production DB
写操作。

## 4. iPhone 与网络

### 自动确认配置

- Effective default `API_BASE_URL`：`https://yyynas.tail935349.ts.net`
- Scheme：HTTPS
- Host 不是 `localhost` 或 `127.0.0.1`
- Host 不是临时局域网 IPv4 地址
- `API_BASE_URL` 是 compile-time `String.fromEnvironment`，因此测试人员仍需确认
  真机安装包没有通过 `--dart-define` 覆盖为其他地址

### MANUAL CHECK

填写规则：每项只能填写 `PASS` 或 `FAIL`；填写 `FAIL` 时同时记录复现步骤、
期望结果和实际结果。不要在报告中粘贴 token、cookie 或完整认证响应。

| # | 真机检查项目 | Result（PASS/FAIL） | Notes |
| --- | --- | --- | --- |
| 1 | Wi-Fi 正常使用 |  |  |
| 2 | 5G 正常使用 |  |  |
| 3 | App kill/reopen session restore |  |  |
| 4 | Meal create/edit/delete |  |  |
| 5 | Favorite |  |  |
| 6 | “今天也吃了”显示当天全量 |  |  |
| 7 | Pair create/join |  |  |
| 8 | Shared allocation |  |  |
| 9 | End Pair |  |  |
| 10 | Historical shared meal read-only |  |  |
| 11 | Re-pair isolation |  |  |
| 12 | Training |  |  |
| 13 | Weight create/edit/delete |  |  |
| 14 | Nutrition Goals |  |  |
| 15 | Connected Delete Account |  |  |
| 16 | Partner data preserved |  |  |
| 17 | Light/Dark basic sanity |  |  |

测试设备与环境：

- iPhone model：
- iOS version：
- App version/build：
- 测试日期：
- 测试人员：

## 5. Release 配置

| Item | Value | Status |
| --- | --- | --- |
| Version/build | `1.0.0+1` | Configured |
| Bundle Identifier | `com.bytesync.bytesync` | Configured |
| Development Team | `432ZVDFUX4` | Configured |
| Code signing style | Automatic | Configured |
| Archive/provisioning validation | 未在当前 Linux 环境执行 | NOT RUN |

`Development Team` 和 Automatic Signing 已写入 Xcode project；实际证书、
provisioning profile 与 Archive 签名仍需在 macOS/Xcode 发布环境验证。

## 6. Final status

自动 NAS 检查已通过，但真机 `MANUAL CHECK` 尚未填写完成。

**STEP 5B MANUAL SMOKE PENDING**
