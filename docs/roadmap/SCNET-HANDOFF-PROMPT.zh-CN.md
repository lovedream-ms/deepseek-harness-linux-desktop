# SCNet 项目 Handoff 提示词

下面的内容可以直接复制给下一轮 Codex/代码模型，作为本项目的接手上下文。

```text
你正在接手 SCNet Linux Desktop 集成项目。不要从零开始分析，先读取并遵守以下文件：

1. docs/roadmap/SCNET-PLATFORM-DEVELOPMENT-PLAN.zh-CN.md
2. docs/roadmap/SCNET-DEVELOPMENT-HANDOFF.zh-CN.md
3. docs/roadmap/SCNET-HANDOFF-PROMPT.zh-CN.md
4. README.md 与 README.zh.md

当前仓库：
- 路径：以当前工作区为准，先执行 `git rev-parse --show-toplevel`；不要假设固定路径。
- 分支：先执行 `git status --short --branch`、`git branch -vv` 和
  `git rev-parse HEAD origin/main`。当前交接提交是
  `4a5ba8b feat: move updates and SCNet setup into settings`；必须实时确认
  `HEAD == origin/main`，不要把本文档的历史描述当成远端事实。
- 最新提交、origin/main、CI 和公开 release 必须实时查询。开始工作前先执行
  `git status --short --branch`、`git log -6 --oneline`、
  `gh run list -R lql341/deepseek-harness-linux-desktop --limit 8` 和
  `gh release list -R lql341/deepseek-harness-linux-desktop --limit 8`，
  不要把本文档的描述当作实时状态。

项目边界：
- 当前目标是 Linux x64 Desktop deb 发布线和离线 SCNet Bundle 能力。
- SCNet 正式 OAuth2/API 合同、issuer、endpoint、client ID、scope、测试账户和凭证尚未提供。
- 不得猜测、硬编码或提交任何生产 endpoint、appId、appSecret、access token、refresh token、AK/SK、
  私有域名或服务端免登凭证。
- 用户提供的接入手册标记为“未发布”，只能作为候选服务端 handoff 协议证据；它不能替代 OAuth2 + PKCE
  正式合同，也不能直接驱动客户端请求。
- 不需要等待 SCNet 的工作继续推进；真实登录、刷新、撤销、账户关联和真实 OpenAPI 查询继续标记为阻塞。
- Debian 候选升级放到后续 `run-multidistro` 手动阶段，不得成为日常开发阻塞。
- 没有完整 release-preflight 证据时不要创建或发布新的 Linux Desktop release。

当前公开发布：

- 最新公开 release：`v0.2.1-rc.2-linux.4`
- 发布 workflow Run：`39371196163`，提交 `4a5ba8b`，结果为 success。
- 发布页：`https://github.com/lql341/deepseek-harness-linux-desktop/releases/tag/v0.2.1-rc.2-linux.4`
- deb SHA-256：`9c5bd3b13a6d70fe399ee33acb80efcbc4a70c06b6d508e7a01b76a7b7a5d859`
- 设置页已经提供 `Check for updates` 和 `Configure SCNet`；更新入口保留在设置页，
  不要恢复浮窗或 sidebar badge。

仓库工作流约束：
- dsh-scnet 的源头是 canonical `scnet-hpc`；任何 dsh-scnet 更新必须按多仓库同步流程从源头开始。
- 不要只修改 dsh-scnet，也不要把本仓库补丁当成 dsh-scnet 的源头。
- Desktop 上游修改必须通过新的 `patches/NNNN-*.patch` 表达，不能只改临时 upstream checkout。
- 基线是上游 tag `dsh-v0.2.1-rc.2`。
- 当前补丁链以 `patches/` 目录和 `apply.sh` 为准，包含最终迁移差异、Linux 更新修复、
  SCNet 0.6.13、托盘/更新入口和设置页入口；不要引用旧的 29/30 个主题补丁数量。
- 当前 Desktop Bundle 固定为 `dsh-scnet@0.6.13`。
- 生成或修改补丁后，必须在干净上游树运行 `./apply.sh` 或等价的完整 `git am` 回放验证。
- CI 改动改的是 `.github/workflows/*` 与 `ci/*`；只有这几类路径才会触发 push 基础验证。

已完成的主要能力：
- 固定并预置 `dsh-scnet@0.6.13`，记录完整性、许可证和 loopback listener 导出。
- 新安装 profile 默认激活 dsh-scnet；用户显式禁用、旧默认 profile、自定义 profile 的升级迁移已验证。
- 本地只读 SCNet 诊断页已加入 Desktop 菜单；主窗口也显示可关闭的 SCNet 状态入口，且窗口重新获得焦点时刷新本地状态。Linux Secret Service 适配器已具备离线读写/清理接口。两者只读 Bundle、Python、backend、凭据和认证状态，
  不发起网络请求，不暴露凭据。
- OAuth2 + PKCE 和 loopback callback listener 是离线协议骨架，不代表真实 SCNet 登录已完成。
- `dsh://auth/scnet` 当前只做本地协议解析、一次性 state 消费和第二次启动参数转发，不执行 token
  交换或任何真实网络请求。
- 设置页的 `Check for updates` 已连接到现有 Desktop/Harness 更新 IPC；Linux 仍是客户端和
  Harness 整包交付，不要声称两者已经物理分离。
- 设置页的 `Configure SCNet` 已连接到本地 setup launcher，但当前公开 release 存在一个
  必须优先修复的回归：终端会闪退。
- Ubuntu 24.04 基础 deb、首次启动、`dsh://` 激活、卸载和候选升级路径已通过；Debian 13 基础离线验收和候选升级路径均已通过。

Configure SCNet 闪退的已知根因与修复 TODO：

- `apps/desktop/src/main.ts` 在 packaged app 中把 `dshRoot` 指向 `app.asar/dsh`。
- `apps/desktop/src/scnet-setup.ts` 再把该路径拼成 `dsh-scnet/.../scnet.py` 并交给外部
  `python3`；Electron 的 Node 文件 API 能读取 ASAR 虚拟路径，但外部 Python 不能读取。
- 终端因此打开后立即退出，用户只看到闪一下。
- 最高优先级修复：在 electron-builder 的 `asarUnpack` 中解包 dsh-scnet Python 脚本及其
  相邻模块；启动时把路径映射到 `app.asar.unpacked` 的真实文件系统路径。
- 同时增加打包后真实路径测试、Python/终端失败时的可见错误输出，以及 Ubuntu/X11 或等价
  桌面会话中的实际点击验收。
- 修复完成前不要继续扩展 SCNet UI，也不要把当前入口描述为已完成的 SCNet 配置流程。

最近提交（最新在上）：
- `4a5ba8b feat: move updates and SCNet setup into settings`
  把更新和 SCNet 配置入口移入设置页，移除浮窗和 sidebar badge；当前 release 中
  `Configure SCNet` 仍有 ASAR 外部 Python 路径闪退回归。
- `9068974 fix: satisfy setup action async contract`
  修复 setup action 的异步契约。
- `22eddcb fix: make setup and update actions actionable`
  让更新和 setup 入口调用真实 Desktop IPC。
- `48a83c5 fix: clear Linux release gate regressions`
  修复 Linux release gate 回归。
- `bc0d3e7 ci: allow candidate runtime reinstall downgrade`
  修复候选包安装验证流程。

CI 状态（截至本文档）：
- 当前发布 Run `39371196163`（sha `4a5ba8b`）：success，完成补丁迁移、deb 构建、
  SCNet release audit、安装和桌面会话验证。
- 设置页变更的本地验证：`pnpm typecheck` 5 个 gate 通过；设置相关 Vitest
  7 个文件、85 个测试通过。
- 下一次发布前必须针对 ASAR 路径修复重新运行完整 release-preflight；历史 Run 不能替代
  当前修复的证据。

发布现状：
- 最新公开 release 为 `v0.2.1-rc.2-linux.4`，Bundle 为 `dsh-scnet@0.6.13`；
  deb SHA-256 为 `9c5bd3b13a6d70fe399ee33acb80efcbc4a70c06b6d508e7a01b76a7b7a5d859`。
- 当前 release 的 UI 入口已经发布，但 `Configure SCNet` 因 ASAR 外部 Python 路径问题闪退；
  修复前不要把该入口描述为可用的配置流程。
- 发布入口是 `.github/workflows/publish-linux-desktop.yml`（`workflow_dispatch`，输入 `tag` 与 `draft`），
  它会重新构建、校验 checksum、安装并驱动会话，再 `gh release create`。

推荐下一步（按顺序）：
1. 修复 `Configure SCNet`：解包 dsh-scnet Python 目录，映射到 `app.asar.unpacked`，
   增加打包后真实路径测试和终端/Python 错误可见性。
2. 在干净上游树回放补丁，运行 typecheck、Desktop 测试、host build、package check、
   SCNet release audit 和真实桌面会话。
3. 更新 `SCNET-DEVELOPMENT-HANDOFF.zh-CN.md`，然后重新执行完整 release-preflight；
   未归因失败不得创建 release。
4. 发布修正版 Linux deb，记录新的 commit、Run ID、release tag、下载地址和 checksum。
5. 在正式 OAuth2/API 合同和 sandbox 凭证提供前，不接入真实登录、刷新、撤销、账户关联或 OpenAPI。
6. 合同到位后先完成 M2 真实 connector，再完成 M3 Linux 登录链路；移动端和更多发行版排在其后。
7. 每次接手仍先查询工作树、最近提交和最新 CI，不把本文历史 Run 号当作实时证据。

完成标准：
- 工作树干净，origin/main 已同步。
- `patches/` 中的最终迁移差异和修复补丁可在基线 tag `dsh-v0.2.1-rc.2` 上完整应用。
- Configure SCNet 修复后的定向测试、打包路径测试、桌面会话和 release-preflight 有明确证据。
- 最新公开 release 的 deb checksum、安装、升级、`dsh://`、SCNet bundle audit 和基础会话有证据。
- 没有凭证、私有 endpoint 或未发布合同被写入仓库。
- 交接时应确认工作树干净，且 `HEAD` 与 `origin/main` 指向同一提交；若处于 detached
  `HEAD`，只要两者一致即可继续，不要擅自重写分支或历史。
```

## 使用规则

- 每次交接都先执行 `git status --short --branch`、`git log -6 --oneline` 和最新 CI 状态查询。
- 不要把本提示词中的历史 Run 号当作当前成功证据；必须以最新运行结果为准。
- 若 GitHub API 暂时不可用，先做本地只读检查，不要凭空改 workflow 或创建 release。
- 任何涉及 `scnet-hpc`、`dsh-scnet`、`codex-scnet-hpc` 的变更，都要先回到 canonical 源头并遵循同步顺序。
