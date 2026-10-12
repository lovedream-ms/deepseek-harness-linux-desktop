# SCNet 开发交接与后续 TODO

- 交接日期：2026-10-12
- 当前状态：`in progress`
- 关联仓库：`deepseek-harness-linux-desktop`、`dsh-scnet`
- 计划依据：[`SCNET-PLATFORM-DEVELOPMENT-PLAN.zh-CN.md`](SCNET-PLATFORM-DEVELOPMENT-PLAN.zh-CN.md)

## 1. 当前提交与仓库对应关系

| 仓库 | 分支/提交 | 当前交付 |
|---|---|---|
| `dsh-scnet` | `main` / `46179cb` | SCNet connector contract、OAuth2 + PKCE 离线协议骨架、结构化错误、一次性回调会话、凭据存储适配器和受控 Python 解释器路径注入 |
| `deepseek-harness-linux-desktop` | `main` / 本文档所在提交 | 补丁 `0018` 预置 `0.6.6`，`0019` 更新到 `0.6.7`，`0020` 更新到 `0.6.8`，默认激活并保留用户显式禁用状态 |
| 上游临时验证树 | `65f40e1` | 补丁 `0018`、`0019`、`0020` 应用后的上游提交，仅用于补丁生成和验证，不是独立发布源 |

## 2. 已完成内容

### 2.1 `dsh-scnet` connector

- 定义版本化 connector contract `0.1.0`，包含操作权限、scope 和平台能力状态。
- 实现 OAuth2 Authorization Code + PKCE S256 的离线协议骨架。
- 校验 `state`、`nonce`、`issuer` 和 redirect URI，并构造 token exchange/refresh 请求。
- 实现 token 生命周期判断、并发刷新去重和内存凭据存储抽象。
- 导出 `./connector`，并阻止 `__pycache__`、`.pyc` 等生成文件进入 npm 包。
- 未绑定真实 SCNet endpoint、client ID、scope 或 UI，不代表真实 OAuth2 登录已经完成。
- 本机脚本支持 `DSH_SCNET_PYTHON`（优先）或 `SCNET_PYTHON` 注入 Python 3 绝对路径；
  会拒绝无效路径和 Python 2，不会把该路径传到远端计算节点。
- connector 提供稳定错误码和 JSON 安全错误信封；OAuth 回调会话只消费一次并拒绝重放；
  平台凭据存储通过适配器接入，不提供明文回退。

### 2.2 Linux Desktop 补丁 `0018` + `0019`

- 构建时使用固定版本 `dsh-scnet@0.6.8`，记录包版本、完整性和许可证；`0018` 保留为
  0.6.6 的历史预置，`0019` 更新到 0.6.7，`0020` 完成当前版本切换。
- 将固定包纳入 Desktop 本地 package set，首次启动不运行 pnpm，也不依赖 npm 网络。
- 新安装的默认 Desktop profile 自动启用 `dsh-scnet`。
- 旧默认 profile 自动迁移；用户显式禁用后写入 `.dsh-scnet.disabled`，后续升级不重新启用。
- Web profile 仍保持显式安装，不自动加入 `dsh-scnet`。

## 3. 验证证据

### 3.1 `dsh-scnet`

```sh
npm test
npm run validate
git diff --check
```

结果：

- connector 测试 `20/20` 通过。
- npm dry-run 包校验通过，共 52 个文件，生成的 Python 文件为 0。
- Git whitespace 检查通过。

### 3.2 Linux Desktop

补丁 `0018` 与 `0019` 已在上游基线 `dsh-v0.2.0-rc.2` 上通过 `git am` 应用，并完成：

- 完整上游 `pnpm run typecheck`：通过。
- 针对性 Desktop 测试：71 passed，1 skipped。
- 全量 Desktop 测试：118 个测试文件通过，1337 passed，58 skipped。

全量测试中的 17 个失败来自上游基线环境：macOS flock 原生 addon 未构建，以及既有 welcome
启动竞态。它们与补丁 `0018` 修改的 bundle 准备、profile 初始化和迁移路径无关；后续升级
上游基线时仍应重新确认。

## 4. 当前边界与禁止事项

- M0 外部合同尚未冻结，因此不得写入、猜测或硬编码 SCNet 内部 issuer、endpoint、client ID 或 scope。
- 不得把 access token、refresh token、DeepSeek 凭据、账户标识或内部 endpoint 提交到仓库。
- OpenAPI 登录状态与 SSH 密钥/集群配置是独立状态，不得静默切换 backend 或互相冒充。
- Linux 当前只发布 deb，不启用应用内自动更新。
- 当前交付是离线 connector 骨架和固定 bundle 预置，不得对外宣称 SCNet 登录已完成。

## 5. 新收到的接入手册证据

2026-10-12 收到《超算互联网平台标准 API 服务端接入使用说明手册》`.docx`。文档自身标记为
“未发布”、版本 `1.0.0`，因此以下内容只能作为候选服务端免登合同，不能替代正式合同或凭证发放。

| 项目 | 手册给出的候选内容 | 当前处理 |
|---|---|---|
| 调用模型 | 第三方自有服务端通过 HTTPS `POST` 调用平台接口，平台返回重定向 URL | 可设计 server-side handoff 适配层；不在公开客户端直连 |
| 接口形态 | `/api/user/v1/user-info`，JSON 请求和响应 | 记录为候选路径；正式 domain、版本和错误码待确认 |
| 认证字段 | Header 中的 `appId`、`appSecret` | 未收到正式凭证；示例值一律视为不可信，不写入仓库 |
| 用户字段 | `openId`、手机号为必填，其他用户资料可选；示例还出现 `targetUrlFlag` | 必填性、字段最小化、枚举和隐私边界待确认 |
| 返回值 | `code`、`msg`、`data`，其中 `data` 是免登/重定向链接 | 需要确认链接有效期、一次性使用、重放防护和允许目标 |
| 环境 | 手册列出多个测试地址和一个正式地址 | 未发布前不写入默认配置，不主动连通 |

这条流程与当前 OAuth2 + PKCE 连接器不是同一个协议。除非 SCNet 书面确认二者关系，否则不得把
服务端免登链接当作 OAuth callback，也不得把 `appSecret` 放入 Desktop、Skill、模型上下文、
浏览器前端或普通配置文件。

## 6. 下一步 TODO

### P0：冻结外部合同

- [ ] 确认这份“服务端免登”手册是否为正式合同，以及它与 OAuth2 方案是并存、替代还是仅用于特定合作方。
- [ ] 为服务端免登流程单独确认正式 domain、appId/appSecret 发放、来源 IP/VPN 白名单和轮换流程。
- [ ] 确认 `targetUrlFlag`、重定向 URL 的 TTL/一次性语义、重放防护、目标 allowlist 和错误码。
- [ ] 确认 `openId`、手机号和姓名等字段的最小必需集、脱敏要求、账号合并/解绑语义及审计责任。
- [ ] 确认并版本化 issuer、authorization、token、revoke、JWKS/introspection endpoint。
- [ ] 确认公开客户端的 client ID、注册和轮换模式，禁止在客户端内放置 client secret。
- [ ] 冻结最小 scope 集、授权确认文案和权限升级规则。
- [ ] 注册 Desktop deep link 与 loopback redirect URI，明确多用户桌面会话约束。
- [ ] 确认 access/refresh token 生命周期、refresh rotation、重放处理和撤销语义。
- [ ] 冻结 DeepSeek 与 SCNet 的 account link/unlink API、最小账户标识和错误码。
- [ ] 提供可自动化测试的 OAuth2/OpenAPI sandbox、测试账户和非敏感示例数据。

### P1：完成 Linux Desktop 登录链路

- [ ] 接入 Linux Secret Service/Keyring，并验证锁屏、无 keyring、无桌面会话和凭据清理场景。
- [ ] 实现 `dsh://auth/scnet` 深链回调及 `127.0.0.1` loopback 回退。
- [ ] 将 connector 状态和 login/refresh/logout/link/unlink 接入 Desktop UI 与 IPC。
- [x] 为 `dsh-scnet` 增加受控 Python 路径注入，不假设系统存在 `python3`。
- [ ] 未登录、scope 不足、网络失败、区域错误和平台不支持均返回稳定的结构化错误。
- [ ] 对日志、崩溃报告、session 和模型上下文执行凭据脱敏测试。

### P1：完成 M1 离线验收

- [ ] 在全新 Ubuntu 24.04 和 Debian 13 环境完成 deb 离线安装、启动、升级和卸载。
- [ ] 验证首次启动不访问 npm，能列出 active `dsh-scnet` 并加载 `scnet-hpc` Skill。
- [ ] 验证旧默认 profile 自动迁移、显式禁用跨升级保留、自定义 profile 不被覆盖。
- [ ] 验证发行包不包含凭据、内部 endpoint、缓存、`__pycache__` 或 `.pyc`。
- [ ] 将完整 deb 验收结果和 release artifact 校验值记录到发布证据中。

### P2：真实沙盒与后续平台

- [ ] 完成真实沙盒登录、刷新、撤销、账户关联和一个只读 OpenAPI 查询。
- [ ] 增加 PKCE、state 重放、错误 issuer/redirect、refresh 竞态和越权 scope 自动化测试。
- [ ] M2 通过后再启动 Android；移动端只复用协议和 OpenAPI connector，不复制桌面 shell 能力。

## 7. 接手顺序

1. 先完成 P0 合同冻结，不在此之前接入猜测的生产 endpoint。
2. 并行推进 Secret Service/Keyring、深链注册、Python 路径和结构化错误。
3. 完成 deb 离线验收，关闭 M1。
4. 在 sandbox 完成端到端 OAuth2 与只读 OpenAPI 验证，关闭 M2。
5. 更新主计划、ADR、兼容矩阵和发布说明后再扩展移动端。
