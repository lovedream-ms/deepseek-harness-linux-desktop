# SCNet 项目 Handoff 提示词

下面的内容可以直接复制给下一轮 Codex/代码模型，作为本项目的接手上下文。

```text
你正在接手 SCNet Linux Desktop 集成项目。不要从零开始分析，先读取并遵守以下文件：

1. docs/roadmap/SCNET-PLATFORM-DEVELOPMENT-PLAN.zh-CN.md
2. docs/roadmap/SCNET-DEVELOPMENT-HANDOFF.zh-CN.md
3. docs/roadmap/SCNET-HANDOFF-PROMPT.zh-CN.md
4. README.md 与 README.zh.md

当前仓库：
- 路径：/home/kylinlu/Downloads/agent/plugins/deepseek-harness-linux-desktop
- 分支：main
- 最新已提交：2cb3a31 (`fix(ci): keep Debian upgrade packages distinct`)
- origin/main 已同步到 2cb3a31，工作树干净。开始工作前仍先执行 `git status --short --branch`，
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
- 不要频繁发 release；没有完整 release-preflight 证据时不要创建 `.5` release。

仓库工作流约束：
- dsh-scnet 的源头是 canonical `scnet-hpc`；任何 dsh-scnet 更新必须按多仓库同步流程从源头开始。
- 不要只修改 dsh-scnet，也不要把本仓库补丁当成 dsh-scnet 的源头。
- Desktop 上游修改必须通过新的 `patches/NNNN-*.patch` 表达，不能只改临时 upstream checkout。
- 基线是上游 tag `dsh-v0.2.0-rc.2`。
- 当前补丁序列为 24 个，`0023` 已修复补丁自身触发的 Linux lint 和 README 翻译配对失败，
  `0024` 将 Desktop 固定 Bundle 更新到已发布的 `dsh-scnet@0.6.9`。
- 生成或修改补丁后，必须在干净上游树运行 `./apply.sh` 或等价的完整 `git am` 回放验证。
- CI 改动改的是 `.github/workflows/*` 与 `ci/*`；只有这几类路径才会触发 push 基础验证。

已完成的主要能力：
- 固定并预置 `dsh-scnet@0.6.9`，记录完整性和许可证。
- 新安装 profile 默认激活 dsh-scnet；用户显式禁用、旧默认 profile、自定义 profile 的升级迁移已验证。
- 本地只读 SCNet 诊断页已加入 Desktop 菜单；只读 Bundle、Python、backend、凭据和认证状态，
  不发起网络请求，不暴露凭据。
- OAuth2 + PKCE 是离线协议骨架，不代表真实 SCNet 登录已完成。
- Ubuntu 24.04 基础 deb、首次启动、`dsh://` 激活、卸载和候选升级路径已通过；Debian 13 基础离线验收和候选升级路径均已通过。

最近提交（最新在上）：
- `2cb3a31 fix(ci): keep Debian upgrade packages distinct`
  固定 Debian Docker context 中 base/candidate deb 的不同文件名，避免同名产物覆盖导致
  “升级”实际重装旧包。
- `d8f1640 fix(ci): preload ALSA for Debian candidate upgrades`
  在 Debian 13 测试镜像中预装 `libasound2t64`，保证网络关闭后候选 Electron 进程仍能启动。
- `d094d55 test(ci): cover Debian candidate upgrades`
  增加 Debian 13 base→candidate 离线升级以及三种 profile 合同验收。
- `08482cb fix(ci): export draft assets for read-only verification`
  通过 workflow artifact 导出 draft release 资产，供只读 token 验证。

CI 状态（截至本文档）：
- Push 基础验证 Run `38525938104`（sha `d8f1640`）：success。
- 完整 release-preflight Run `38506728139`：success。上游 Linux gate 明确只容忍 3 个已知
  coverage 竞态；Landlock、bwrap、keyless smoke、Wayland、AppArmor、候选升级和包会话均通过。
- draft 发布 Run `38516862762`：success，创建 draft `v0.2.0-rc.2-linux.5`。
- draft `.5` 验证 Run `38521128578`：success，使用 `released-profile-expectation=default`
  通过 checksum、安装、基础会话、`dsh://`、`.4 → .5`、AppArmor 和 Wayland。
- Debian 多发行版 Run `38660453246`：success。日志确认使用不同的
  `deepseek-harness-base.deb` 与 `deepseek-harness-candidate.deb`，离线安装、候选升级、
  卸载以及 `legacy-default`、`disabled`、`custom` profile 合同均通过。

发布现状：
- 已发布 release：`v0.2.0-rc.2-linux.1` ~ `v0.2.0-rc.2-linux.4`；Latest 为 `.4`（2026-10-08）。
  这些 tag 都早于 SCNet 预置补丁系列，验证它们必须用 `released-profile-expectation=legacy`。
- `v0.2.0-rc.2-linux.5` 已创建但保持 draft；deb SHA-256 为
  `13c01b002d9a9564fb531eb33a9cc61fad88550ab212671a1508bc588213db18`。
- 发布入口是 `.github/workflows/publish-linux-desktop.yml`（`workflow_dispatch`，输入 `tag` 与 `draft`），
  它会重新构建、校验 checksum、安装并驱动会话，再 `gh release create`。

推荐下一步（按顺序）：
1. 保持 draft `.5`，除非用户明确要求，不发布正式 release。
2. 等待 SCNet 正式 OAuth2/API 合同、issuer、scope、测试账户和凭证；在此之前不接入真实登录或 OpenAPI。
3. 每次接手仍先查询工作树、最近提交和最新 CI，不把本文历史 Run 号当作实时证据。

完成标准：
- 工作树干净，origin/main 已同步。
- 24 个补丁可在基线 tag `dsh-v0.2.0-rc.2` 上按顺序完整应用。
- 定向测试和对应 CI 门禁有明确证据，release-preflight 没有未归因失败。
- draft `.5` 的 deb checksum、安装、升级、`dsh://`、Wayland、基础会话均有证据；Debian 13 候选升级三种 profile 合同也有 Run `38660453246` 证据。
- 没有凭证、私有 endpoint 或未发布合同被写入仓库。
```

## 使用规则

- 每次交接都先执行 `git status --short --branch`、`git log -6 --oneline` 和最新 CI 状态查询。
- 不要把本提示词中的历史 Run 号当作当前成功证据；必须以最新运行结果为准。
- 若 GitHub API 暂时不可用，先做本地只读检查，不要凭空改 workflow 或创建 release。
- 任何涉及 `scnet-hpc`、`dsh-scnet`、`codex-scnet-hpc` 的变更，都要先回到 canonical 源头并遵循同步顺序。
