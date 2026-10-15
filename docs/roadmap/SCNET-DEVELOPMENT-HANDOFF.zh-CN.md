# SCNet 开发交接与后续 TODO

- 交接日期：2026-10-15
- 当前状态：`in progress`
- 关联仓库：`deepseek-harness-linux-desktop`、`dsh-scnet`
- 计划依据：[`SCNET-PLATFORM-DEVELOPMENT-PLAN.zh-CN.md`](SCNET-PLATFORM-DEVELOPMENT-PLAN.zh-CN.md)

## 0. 当前总体进度

### M0：外部合同与凭证

- [ ] OAuth2/API 正式合同冻结（阻塞：等待 SCNet 书面确认）
- [ ] issuer、authorization/token/revoke/JWKS endpoint、scope 和 redirect URI 确认（阻塞：等待 SCNet）
- [ ] 正式 client ID、测试账户和 sandbox 凭证发放（阻塞：等待 SCNet）
- [x] 未发布服务端免登手册完成审阅，并与 OAuth2 + PKCE 分开建模

### M1：Desktop 预制 Bundle 与离线能力

- [x] 固定 `dsh-scnet@0.6.9` 并纳入 Desktop package set
- [x] 新安装 profile 默认激活 Bundle
- [x] 用户显式禁用状态跨升级保留
- [x] Python 3 路径注入和错误路径拒绝
- [x] 本地 SCNet 连接诊断页
- [x] 24 个补丁在全新上游树重放；`0023` 修复上游 Linux 门禁中的补丁自身 lint 与翻译配对失败，
  `0024` 更新到已发布的 `dsh-scnet@0.6.9`
- [x] Desktop 定向测试 `170/170` 和 host build
- [x] `0024` 本地新增版本断言测试 `26/26` 通过；`dsh-scnet@0.6.9` npm 包为 54 个文件、MIT
  许可证，未引入凭证或 endpoint
- [x] Ubuntu 24.04 基础 deb 安装、首次启动和 `dsh://` 激活 CI 验收（Run `38233490072`）
- [x] Debian 13 离线安装、首次启动、profile 状态、`dsh://` 激活和卸载在手动多发行版 Run `38233720311` 验收通过；该 job 只在 `run-multidistro=true` 时运行，不阻塞 push
- [x] Ubuntu 24.04 从公开 `.4` 到当前候选 deb 的升级路径验收（Run `38336572137`）
- [x] Debian 13 候选升级路径验收（Run `38660453246`；base/candidate 文件隔离，`legacy-default`、`disabled`、`custom` 均通过）
- [x] Ubuntu release-preflight 全门禁通过并形成 `.5` 发布证据（Run `38506728139`；上游门禁仅精确容忍 3 个已知 coverage 竞态）
- [x] 旧默认 profile、显式禁用状态和自定义 profile 的发行包迁移验收（Run `38336572137`）
- [x] 发布包内容、凭据、内部 endpoint、缓存和生成文件扫描
- [x] draft `.5` 产物验证（发布 Run `38516862762`，验证 Run `38521128578`）

### M2：OAuth2 / Connector

- [x] OAuth2 + PKCE 离线协议骨架
- [x] callback state、issuer、redirect 校验
- [x] callback 一次性消费和重放拒绝
- [x] 稳定错误码和 JSON error envelope
- [x] 凭据存储适配器接口，禁止明文回退
- [ ] 协议无关的 loopback callback 监听器（待 connector 发布流程纳入）
- [ ] 真实 issuer / endpoint 接入（阻塞：等待合同）
- [ ] 真实 sandbox 登录、刷新、撤销（阻塞：等待凭证）
- [ ] 账户关联 API（阻塞：等待合同）
- [ ] 只读 OpenAPI 查询（阻塞：等待 sandbox）

### M3：Desktop 登录与安全存储

- [x] 本地状态和诊断展示
- [ ] Linux Secret Service/Keyring 实际 Desktop 适配
- [ ] `dsh://auth/scnet` 回调
- [ ] loopback 回调协议层监听器
- [ ] login/refresh/logout/link/unlink UI 与 IPC
- [ ] 凭据清理、锁屏和无桌面会话测试

## 1. 当前提交与仓库对应关系

| 仓库 | 分支/提交 | 当前交付 |
|---|---|---|
| `scnet-hpc`（canonical） | `main` / `3b5d0a8` | Skill、VERSION、发布文档和同步源；当前版本 `0.6.9` |
| `dsh-scnet` | `main` / `d9e41ca` | canonical Skill 同步后的 DSH Bundle、connector contract、OAuth2 + PKCE 离线协议骨架、结构化错误、一次性回调会话、凭据存储适配器和受控 Python 解释器路径注入；版本 `0.6.9` |
| `codex-scnet-hpc` | `main` / 待实时查询 | canonical Skill 同步后的 Codex skills-only Plugin；版本 `0.6.9` |
| `deepseek-harness-linux-desktop` | `main` / 本文档所在提交 | 补丁 `0018` 预置 `0.6.6`，`0019` 更新到 `0.6.7`，`0020` 更新到 `0.6.8`，`0021` 增加用户可见的 SCNet 本地诊断页，`0022` 声明 Electron 的 ALSA 运行时依赖，`0023` 修复 Linux release gate 的 lint/翻译配对问题，`0024` 更新到已发布的 `0.6.9`；默认激活并保留用户显式禁用状态 |
| 上游临时验证树 | `6f66c83` | 补丁 `0018`–`0024` 应用后的上游提交，仅用于补丁生成和验证，不是独立发布源 |

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

- 构建时使用固定版本 `dsh-scnet@0.6.9`，记录包版本、完整性和许可证；`0018` 保留为
  0.6.6 的历史预置，`0019` 更新到 0.6.7，`0020` 完成 0.6.8 切换，`0024` 完成 0.6.9 切换。
- 将固定包纳入 Desktop 本地 package set，首次启动不运行 pnpm，也不依赖 npm 网络。
- 新安装的默认 Desktop profile 自动启用 `dsh-scnet`。
- 旧默认 profile 自动迁移；用户显式禁用后写入 `.dsh-scnet.disabled`，后续升级不重新启用。
- Web profile 仍保持显式安装，不自动加入 `dsh-scnet`。
- 应用菜单新增“SCNet 连接诊断…”，显示 Bundle、Python、backend、凭据就绪和认证状态；诊断只读本地信息，不发起网络请求。
- 诊断窗口通过隔离 preload 和来源校验提供状态，不向 renderer 暴露 token、AK/SK 或服务端免登凭证；在未收到正式合同/凭证时，认证状态保持“需要授权”。

## 3. 验证证据

### 3.1 `dsh-scnet`

```sh
npm test
npm run validate
git diff --check
```

结果：

- connector 全量测试 `24/24` 通过（包含 callback、错误和凭据适配覆盖）。
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

`0021` 的临时上游验证已通过，`0022` 在其基础上补充运行时依赖：

- 新增 SCNet 状态读取、诊断窗口、preload 和静态 renderer 资源。
- 定向 Desktop 测试 `170/170` 通过；新增测试覆盖 profile 禁用、Python 缺失、本地 metadata、
  IPC 来源校验和凭据脱敏。
- `pnpm run build:lib:host` 通过，产出 `lib/preload-scnet-diagnostics.cjs` 和诊断页资源。
- `0022` 的 Desktop 定向打包测试通过，并在生成 deb 的 control 字段中确认包含 `libasound2`。
- `0023` 的 `pnpm run lint:contracts-ready`、Desktop 相关 4 个测试文件（50 passed，1 skipped）
  和 `verify-translation-pairing apps/desktop/README.md` 均通过；`0023` 已在基线 tag 上与前 22 个补丁顺序重放成功。
- Run `38338147889` 暴露的 sandbox 失败不是内核回归：主门禁失败后，Landlock launcher 构建步骤被
  GitHub Actions 默认跳过，导致 Landlock 测试自跳过。工作流已改为 `if: always()`；Run
  `38343669703` 已确认 launcher 构建成功，bwrap/Landlock 两个测试文件均实际运行并通过，
  keyless agent smoke 也通过。该 run 仍因 upstream Linux primary gate 失败而未形成 release-preflight
  证据；在取得 `linux-gates.log` 的具体失败任务前，不得修改 coverage 容忍或创建 `.5` release。

### 3.3 M1 发行包审计

新增 `ci/scnet-release-audit.mjs`，并接入 `verify.sh --full`、Linux Desktop 当前源码构建
workflow 和新版本发布前 re-verification。脚本不下载 ASAR 工具，而是使用产物自带
Electron 的 Node 模式读取同一份 `app.asar`，验证：

- package-set 中固定 `dsh-scnet@0.6.9` 的 SHA-512、字节数和 MIT 许可证；
- archived runtime、runtime descriptor、Bundle、`scnet-hpc` Skill 和 `VERSION` 一致；
- Bundle 的 54 个文件逐个匹配 runtime descriptor 的 SHA-256 和字节数；
- 不存在带值的 token、AK/SK、`appId`/`appSecret`、私钥、JWT、私网 endpoint；
- 不存在 `clusters/.cache`、`__pycache__` 或 `.pyc`。

2026-10-12 本地真实构建结果：

- `pnpm --dir apps/desktop run package:linux:x64`：通过；
- deb：`deepseek-harness-0.2.0-rc.2-linux-amd64.deb`，SHA-256
  `3723dbe924a3f3ffb841e26505f950f4849bc2514a7fabf53d4989f8d4280cd6`；
- `app.asar` SHA-256：`93b05653868135d06213834bf60068290d9390d40854bafeda3c4c2f6cd99f0f`；
- `dsh-scnet-0.6.9.tgz` SHA-512：
  `sha512-3WHl5leZEf/iQ0AZ7CMOwj1W7JKFs/vY2cbEw1vv+2oPPMeUvHf5ZB42pda9vVhU5BS6CBvmV8ooEjvzrmP0NA==`；
- unpacked app 与 deb 审计均通过；正例扫描 54 个文本文件，0 个敏感发现；
- 反例 fixture 对 `.pyc` 缓存和带值 `access_token` 均按预期失败；
- Desktop 定向测试 3 个文件通过，`42 passed / 1 skipped`；
- packaged Electron 的 profile 激活断言命令通过。

本机缺少 Xvfb、openbox、xdotool，且 sudo 需要交互密码，因此本轮没有执行 deb 安装后的完整
GUI session。GitHub Actions Run `38233490072` 已通过 Ubuntu 24.04 push 基础门禁；手动
多发行版 Run `38233720311` 使用 Ubuntu job 生成的同一个 deb，通过 Debian 13
`--network none` 容器验收：离线安装、首次启动、Bundle/Skill、`dsh://` 注册与激活、显式
禁用 profile 和卸载均通过。Debian job 仍按设计跳过 Xvfb 不可靠的普通第二次启动恢复断言，
因此 Debian 只作为后续多发行版验收，不进入日常 push 阻塞链。

手动 Run `38233714945` 通过已发布 `v0.2.0-rc.2-linux.3 -> v0.2.0-rc.2-linux.4` 的
升级、旧 launcher 清理、AppArmor user namespace 限制下启动；该 job 对早期发布包使用
`PROFILE_EXPECTATION=legacy`，不把尚未存在的 `dsh-scnet@0.6.8` 预置合同误报为回归。
该次验收针对旧版已发布包的兼容启动，不代表当前候选包的 profile 迁移；当前候选包的
Ubuntu 迁移由后续 Run `38336572137` 单独覆盖，Debian 迁移仍留在多发行版阶段。

手动 Run `38336572137` 进一步使用已发布 `v0.2.0-rc.2-linux.4` 和同一运行中构建的当前
候选 deb，在 Ubuntu 24.04 完成包替换、旧 launcher 清理和三类 profile 验收：旧默认
profile 自动加入 `dsh-scnet`，显式禁用 marker 和无 Bundle 状态保持，自定义 bundles 及
自定义字段不被覆盖。

完整 release-preflight Run `38506728139` 已成功；上游 Linux primary gate 的 warning
只包含已知的 3 个 coverage 竞态，Landlock、bwrap、keyless smoke、Wayland、AppArmor、
候选升级和其他发布腿均通过。随后发布 workflow Run `38516862762` 创建了保持 draft 的
`v0.2.0-rc.2-linux.5`，deb SHA-256 为
`13c01b002d9a9564fb531eb33a9cc61fad88550ab212671a1508bc588213db18`；Run `38521128578`
以 `released-profile-expectation=default` 完成 draft checksum、安装、Ubuntu 会话、
`dsh://`、`.4 → .5` 升级、AppArmor 和 Wayland 复验。draft `.5` 尚未发布。

Debian 候选升级最初 Run `38522369417` 暴露两处测试基础问题：镜像未预装 Debian 13 的
`libasound2t64`，且 base/candidate 同名 deb 在 Docker context 中互相覆盖。提交
`d8f1640` 补齐 ALSA 运行库，提交 `2cb3a31` 固定为不同的
`deepseek-harness-base.deb` / `deepseek-harness-candidate.deb` 文件名；Run
`38660453246` 已通过 Debian 13 离线安装、升级、卸载、`dsh://` 和三种 profile 合同。

Run `38221395453` 首次验证暴露干净 Debian 启动缺少 `libasound.so.2`；补丁 `0022` 显式声明
`libasound2`，并在后续 Run `38233720311` 中得到验证。Debian 13 测试镜像另预装
`libasound2t64`，供离线候选升级解析该运行库。

## 4. 当前边界与禁止事项

- M0 外部合同尚未冻结，因此不得写入、猜测或硬编码 SCNet 内部 issuer、endpoint、client ID 或 scope。
- 不得把 access token、refresh token、DeepSeek 凭据、账户标识或内部 endpoint 提交到仓库。
- OpenAPI 登录状态与 SSH 密钥/集群配置是独立状态，不得静默切换 backend 或互相冒充。
- Linux 当前只发布 deb，不启用应用内自动更新。
- 当前交付是离线 connector 骨架和固定 bundle 预置，不得对外宣称 SCNet 登录已完成。
- 当前诊断页是本地就绪检查，不是 SCNet 登录入口；在 M0 合同和凭证发放前不得把“需要授权”
  改成“已登录”，也不得根据手册示例值打开真实请求。

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
- [x] 增加首个用户可见的 SCNet 本地诊断页，区分 Bundle、Python、backend、凭据和认证状态；
  真实登录按钮仍等待 M0 合同和凭证。
- [x] 为 `dsh-scnet` 增加受控 Python 路径注入，不假设系统存在 `python3`。
- [ ] 增加协议无关的 loopback callback 监听器，校验固定路径、一次性消费和超时关闭；
  该项应先在 connector 发布流程中完成，再由 Desktop 接入。
- [ ] 未登录、scope 不足、网络失败、区域错误和平台不支持均返回稳定的结构化错误。
- [ ] 对日志、崩溃报告、session 和模型上下文执行凭据脱敏测试。

### P1：完成 M1 离线验收

- [x] 在全新 Ubuntu 24.04 环境完成 deb 安装、首次启动、`dsh://` 激活和卸载（Run `38233490072`）。
- [x] Debian 13 同等验收已通过（Run `38233720311`）；后续由 `run-multidistro` 手动 job 复验，不作为日常阻塞门禁。
- [x] 在 Ubuntu 24.04 完成公开 `.4` 到当前候选 deb 的升级路径验收（Run `38336572137`）。
- [x] 在 Debian 13 完成候选 deb 升级路径验收（Run `38660453246`；三种 profile 合同均通过）。
- [x] 验证首次启动不访问 npm，能列出 active `dsh-scnet` 并加载 `scnet-hpc` Skill（Run `38233720311`）。
- [x] 验证旧默认 profile 自动迁移、显式禁用跨升级保留、自定义 profile 不被覆盖（Run `38336572137`）。
- [x] 验证发行包不包含凭据、内部 endpoint、缓存、`__pycache__` 或 `.pyc`。
- [x] 将完整 deb 验收结果和 draft `.5` release artifact 校验值记录到发布证据中。

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
