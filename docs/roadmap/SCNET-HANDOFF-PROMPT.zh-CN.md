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
- 最新已提交：8156729 (`docs: add copy-ready handoff prompt`)
- `origin/main` 仍停在 `dd9e9d0`；本轮 release-gate 证据更新尚未提交，开始工作前先执行
  `git status --short --branch`，不要假设工作树干净。

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
- 当前补丁序列为 23 个，`0023` 已修复补丁自身触发的 Linux lint 和 README 翻译配对失败。
- 生成或修改补丁后，必须在干净上游树运行 `./apply.sh` 或等价的完整 `git am` 回放验证。

已完成的主要能力：
- 固定并预置 `dsh-scnet@0.6.8`，记录完整性和许可证。
- 新安装 profile 默认激活 dsh-scnet。
- 用户显式禁用状态、旧默认 profile 和自定义 profile 的升级迁移已验证。
- 本地只读 SCNet 诊断页已加入 Desktop 菜单；只读 Bundle、Python、backend、凭据和认证状态，
  不发起网络请求，不暴露凭据。
- OAuth2 + PKCE 是离线协议骨架，不代表真实 SCNet 登录已完成。
- Ubuntu 24.04 基础 deb、首次启动、dsh:// 激活、卸载和 Ubuntu 当前候选升级路径已通过。
- Debian 13 基础离线验收已通过；Debian 候选升级仍待后续手动多发行版阶段。

最近提交：
- `bef75e0 fix(ci): build Landlock launcher after gate failures`
  将 Landlock launcher 构建步骤改为 `if: always()`，避免主门禁失败后构建被默认跳过。
- `5edc281 docs: record release gate remediation`
  记录 release gate 修复和当前验证证据。
- `dd9e9d0 docs: update patch series count`
  将 README 中补丁数更新为 23。

CI 状态：
- Push 基础验证 Run `38343523693`：success。
  已覆盖补丁应用、依赖安装、类型检查、Desktop 构建、package preflight、deb 构建和安装验证。
- 手动完整门禁 Run `38343669703`：failure。
  已确认 `Build the Landlock launcher`、`Sandbox confinement e2e` 和 `Keyless agent smoke` 通过；
  唯一失败 job 是 `upstream Linux gates`。该 job 的精确失败任务仍必须从 `linux-gates.log` 归因；
  在此之前不要凭猜测修改 coverage 容忍、lint 或 release workflow。
- 先执行：
  `gh run view 38343669703 --repo lql341/deepseek-harness-linux-desktop --json jobs`
  `gh run view 38343669703 --repo lql341/deepseek-harness-linux-desktop --log-failed`
- 重点确认：
  1. `lint:contracts-ready` 是否仍失败；
  2. `translation pairing` 是否通过；
  3. `test:coverage` 是否仍命中上游 welcome-startup 竞态；
  4. Landlock launcher 构建是否真正执行（已通过）；
  5. Landlock 两个测试文件是否实际运行，而不是全部 self-skip（已通过）；
  6. keyless agent smoke 是否通过（已通过）；
  7. 下载的 `linux-gates.log` 中 upstream primary gate 的具体失败任务。

已知历史问题：
- Run `38338147889` 中的 7 个 lint 错误已由 `0023` 修复。
- 同一 run 的 README 翻译配对失败已通过上游脚本
  `pnpm run verify-translation-pairing --write apps/desktop/README.md` 修复。
- 同一 run 的 Landlock self-skip 原因是 launcher 构建步骤在主门禁失败后被 GitHub Actions 跳过；
  workflow 已加 `if: always()`，但必须用新 run 日志确认真实结果。
- `welcome-startup.spec.ts` 的 coverage 竞态是上游既有问题。只有在日志明确证明唯一失败就是该已知测试、
  且没有 patch-owned 失败时，才可以做精确容忍；不要放宽成任意 coverage 失败都通过。

推荐下一步：
1. 拉取 `38343669703` 的失败日志并逐项归因。
2. 如果 lint、翻译或 Landlock 仍有 patch-owned 问题，继续通过新补丁修复并做定向验证。
3. 如果只剩已知 coverage 竞态，改为精确文件/测试名匹配的容忍，并重新跑完整门禁。
4. 重新跑完整 release-preflight；在它通过前不要创建 `v0.2.0-rc.2-linux.5`。
5. 门禁通过后再按发布 workflow 创建 draft `.5`，随后验证 draft 的 deb checksum、安装、升级、
   dsh://、Wayland 和 Ubuntu 基础会话。
6. Debian 候选升级最后用 `run-multidistro=true` 手动执行，结果写回 roadmap 和 handoff。
7. 每次完成一个阶段都更新 checkbox、handoff 文档，并提交/推送；保持本地和 origin/main 一致。

完成标准：
- 工作树干净，origin/main 已同步。
- 新补丁可在基线 tag 上按顺序完整应用。
- 定向测试和对应 CI 门禁有明确证据。
- release-preflight 没有未归因失败。
- 没有凭证、私有 endpoint 或未发布合同被写入仓库。
```

## 使用规则

- 每次交接都先执行 `git status --short --branch`、`git log -5 --oneline` 和最新 CI 状态查询。
- 不要把本提示词中的历史 Run 号当作当前成功证据；必须以最新运行结果为准。
- 若 GitHub API 暂时不可用，先做本地只读检查，不要凭空改 workflow 或创建 release。
- 任何涉及 `scnet-hpc`、`dsh-scnet`、`codex-scnet-hpc` 的变更，都要先回到 canonical 源头并遵循同步顺序。
