---
layout: post
title: "Harness Practice With OpenSpec Superpowers Ponytail Caveman CodeGraph RTK"
date: 2026-09-07 10:00:00 +0800
categories: [Harness]
tags: [GitHub, Harness]
description: "Seven open-source projects combined into a governance stack for AI coding — one gate each for flow, retrieval, generation, output, and execution."
---

# 7 个开源项目，整合出一套治理失控的 AI 编码 Harness

> 流程有人管、检索有人管、生成有人管、输出有人管、执行有人管——五个环节各守一道闸。
>
> 文章分三步走：**第一节**说清楚 AI 编码为什么会失控，以及治住它需要解决哪五个问题；**第二节**逐个介绍 7 个开源项目，看它们各自守的是哪道闸；**第三节**把其中五个组合成一套能直接落地的 Harness，附 Claude Code 和 Codex 的完整配置。
>
> 关于数据来源，先交代一句：文中每个数字都标了出处。**A 级是本轮在自己机器上复现的**，**B 级是项目官方 README / 文档 / 博客的声明，但我没有独立复测**，**C 级来自历史记录或二手转载**。凡属时效性强、可能随版本变化的信息，我在正文标了【待人工审核】，并在文末附一张**时效性信息清单**；如需引用，请以各项目 GitHub 的最新信息为准，或自行验证。

---

## 一、AI 编码为什么会失控：五个要害

用 AI 写代码久了会有个体感：失控的从来不是模型不够聪明，而是没人给它划跑道。换个更强的模型，往往只是让失控来得更快、账单更大。

所谓 Harness，就是套在模型外面那层工程外壳。它要解决的是下面五个问题——这也是贯穿全文的主线。

### 1.1 上下文工程：三个口子在漏 token

模型的上下文窗口是稀缺资源，而 agent 每转一圈，就有三个口子往里灌东西：

- **读**：为了搞懂一个函数，先 grep 一轮，再 Read 十几个文件——探索成本原样进了窗口，也进了账单；
- **拿**：跑一次测试吐回 200 行日志，`ls -la` 又是 45 行——命令输出整段倒进上下文；
- **说**：寒暄、铺垫、免责声明、最后再来一段总结复述——对话里的废话同样按 token 收费。

三个口子各配一个节流阀，互不重叠：**CodeGraph 管「读」、RTK 管「拿」、Caveman 管「说」**，Comet 的 Context Compression 再在阶段交接时补一道。

上下文工程也有反面，而且不止一个：CodeGraph 官方承认检索用久了会有约 80% 的上下文残留在窗口里（详见 2.2 节）；RTK 官方声明输出削减会被逐层稀释，不等于账单打一折（详见 2.3 节）；Caveman 更是自曝在简洁任务上净收益可能为负（详见 2.5 节）。**省了一头，往往胀了另一头。**

### 1.2 工具的设计：给什么工具，决定它怎么干活

给模型什么工具、工具长什么样，直接塑造 agent 的行为。这一层有四个反直觉的经验：

- **工具不是越多越好**。CodeGraph 只往外暴露一个 MCP 工具 `codegraph_explore`，另外 7 个能力藏着不往外列。官方的说法是：一个强工具，比一堆窄工具更能引导 agent 做对选择。
- **改写胜过说教**。RTK 从不劝 agent「别读长日志」——它在 PreToolUse 钩子里直接把 `git status` 改成 `rtk git status`。agent 全程没感觉，行为已经被改掉了。
- **入口要收敛**。Comet 在每个平台只装一个 Rule 加一个 Hook Router，再按配置分发。否则五六个工具各装一套 hooks，迟早打架。
- **能力要有能覆盖到子代理的入口形态**。CodeGraph 除了 MCP server，还提供一套完整 CLI（`codegraph explore "<你的问题>"`，输出与 MCP 工具相同）——因为 MCP 的使用指引只送达主 agent，子代理（比如 Claude Code 的 Explore subagent）根本看不到，拿到任务还是只能 grep 乱翻；命令行则谁都能调。至于这套 CLI 到底省多少，我在自己项目上做了一组对照：同一查询走 CodeGraph 比走「grep + Read」少吞进 96.7%–99.2% 的字节（完整数据见 2.2 节）。

### 1.3 状态和记忆：这就是 SDD

「会话即焚」是 agent 最大的健壮性漏洞：退出终端、重开会话，AI 从零开始重新理解项目；需求改了三轮，没人说得清哪一版才是最终版。

把状态存进文件只是治标。这件事背后有个更硬的方法论：**SDD（Spec-Driven Development，规范驱动开发）**。它的核心主张比「持久化」激进得多——

> **规范是唯一真相，代码只是规范的实现产物。**

OpenSpec 官方的原话是 *"One source of truth your whole team and every coding agent can read"*。落到做法上，SDD 有四条原则：

1. **规范先行**。动手写代码之前，先写清楚「要做什么、做到什么算完」。AI 从不缺写码能力，它缺的是没有歧义的需求——需求含糊时，再强的模型也只是把猜测写得更快；
2. **变更先改规范**。需求变了，先更新 spec，再由 spec 推导出实现要改什么。OpenSpec 用 delta spec 表达这件事（格式是 `## ADDED Requirements` → `### Requirement:` → `#### Scenario:`，明确标注这次是新增、修改还是移除），而不是改完代码回头补文档；
3. **规范即验收标尺**。spec 里写的是可验证的场景，不是形容词。有了它，验证阶段才有可对照的标尺，而不是靠「感觉做完了」；
4. **规范是人机协作的评审界面**。人审的是一份几百字能读完的 spec，不是几千行读不完的 diff——这是人工介入成本最低、收益最高的位置。

为什么它对 AI 编码尤其关键？对话式需求（想到哪说到哪）有三个致命伤：上下文一断就没了、中间过程没人能审、做完了没有对照物。SDD 把「散落在对话里的意图」固化成「项目里的文件」，由此换来四件事：

- **可回溯**：三轮需求变更留下三份 proposal，谁都能看清是怎么一步步演变到今天的；
- **可跨会话**：规范是文件，换 session、换人、换 AI 工具都能接着干；
- **可沉淀**：实现完成后 delta spec 合并回主 spec，需求库随时间长成一份「活文档」；
- **可在写码前拦错**：设计阶段有明确的人工确认点，需求理解错了在动工之前就被发现。

在这套 Harness 里，SDD 落在两处：**Comet** 在 active workflow、Router Hook 生效且目标路径受 Guard 管辖时，用阶段门禁阻止越阶段写入（见 1.5 节），并把每次变更的阶段与状态写进项目内的 Runtime / change 状态文件；**OpenSpec** 负责四件套产物（proposal / design / tasks / specs）与归档时的 delta 合并。

一点诚实的补充：第 4 条在 Native 工作流里要打个折——Native 把验证交给独立的只读 Verifier，不再强制人工审 spec，这是它给强模型的自由度（详见 2.1 节）。

### 1.4 验证回路 + 评测集：这就是 TDD

「agent 说做完了」和「真的做完了」之间，隔着一条必须有人守的线。守这条线的方式，正是 **TDD（Test-Driven Development，测试驱动开发）**。它的循环很短：**红**——先写一个失败的测试，把「做完」的定义固化成可执行的东西；**绿**——写刚好能让测试通过的实现；**重构**——在测试的保护下收拾代码。

注意它和上一节的衔接：SDD 的 spec 里那些 `#### Scenario:` 描述的行为，落到 TDD 里就是一条条具体的测试用例。**规范负责定义「做到什么算完」，测试负责把它变成机器能判定的东西。**「绿」这一步要求的「刚好通过」，又和 1.5 节 Ponytail 的最小实现是同一个取向。

这个题目下其实有两套机制，一个管运行时，一个管演进：

- **验证回路（运行时）**：Comet 的验证证据门——没有真实存在的 verification report 就别想过关，由脚本校验而不是听 agent 汇报；Native 工作流还会派一个独立的只读 Verifier，写代码的人不能给自己判卷；Superpowers 按变更配置启用 TDD 和两阶段审查；RTK 的 tee 留了底牌，命令失败时完整原始输出自动落盘，随时回看。
- **评测集（演进时）**：严格说这一层已经不属于 TDD 了——TDD 验的是「这次代码对不对」，评测集验的是「这套流程本身靠不靠谱」，属于对方法的元评测。Comet 自带 `comet eval`，可以给任何 Skill 跑标准化评测、用独立的 LLM-as-Judge 打分、把结果同步到 LangSmith / LangFuse。

官方的评测方法学也值得抄作业：Comet 用 **pass^3**（连续三次全过才算稳定）而不是单次通过率；CodeGraph 做对照实验时，连控制组都不许偷用被测工具，28 次运行做到 0 污染。

**这两节的关系可以用一句话记住：SDD 定义「要做什么、做到什么算完」，TDD 证明「已经做完」——前者是契约，后者是证据。**

### 1.5 熵减：三种熵在同时增长

熵增是长任务、长会话的必然。但把它理解成「代码越写越乱」就窄了——agent 系统里其实有三种熵在同时涨：

- **流程熵**：范围蔓延（一个 bugfix 改着改着动了半个模块）、阶段跳跃（设计还没确认，代码已经写了三千行），以及最隐蔽的**目标漂移**——做着做着偏离了最初的目标，而且 agent 自认为还在正轨上；
- **代码熵**：过度工程（装个日期选择器要引第三方库 + 包装组件 + 样式表）、同一个功能被写出三套实现；
- **上下文熵**：多轮之后窗口里堆满过时信息、失败尝试和无关输出，模型的注意力被稀释。这一条常被忽略，但它正是 1.1 节 CodeGraph 那 80% 残留、以及 Comet Context Compression 存在的动因。

Comet 把自己的守卫命名为 **Anti-drift Phase Guards**（面向长上下文会话的防漂移守卫），主打流程熵：当 active change 存在、Router Hook 已受信任并命中受管辖路径时，Hook Router 会把文件写入路由到当前工作流的 Guard——Native 只允许在 Build 阶段写实现代码，Classic 允许 Build 和 Verify。当前机器已确认 Router 安装与信任状态，但尚未做完整的阶段拒绝对照实验【待人工审核】。

另外两道闸：

- **Ponytail 的懒人阶梯**：写代码前强制走一遍七层决策——「这东西需要存在吗 → 代码库里已有吗 → 标准库能做吗 → ……」，熵在生成端就被压掉；
- **路由门禁与归档闭环**：团队规则决定什么任务值得进流程；阶段守卫和归档共同形成生命周期闭环。

两点诚实的补充：一是**闭环不等于「只减不增」**——验证失败时允许退回 Build 重来，这是必要的返工通道；二是**上下文熵目前只能缓解、不能根除**——压缩本身就会丢信息，Comet 的 Context Compression 同样是拿 5% 的 spec 覆盖率去换 token（见 2.1 节）。

先看全景图，再进第二节逐个拆：

| 问题                | 环节   | 工具                                                         | 一句话定位                     | 在 Harness 中的角色                   |
| ----------------- | ---- | ---------------------------------------------------------- | ------------------------- | -------------------------------- |
| 状态和记忆 + 验证回路 + 熵减 | 流程编排 | **[Comet](https://github.com/rpamis/comet)**               | 把 SDD 阶段串成可执行的状态机         | 非平凡开发任务的流程主入口                   |
| （Classic 配套）需求规格  | WHAT | [OpenSpec](https://github.com/Fission-AI/OpenSpec)         | proposal / specs / tasks  | Classic 中由 Comet 管理，按 adapter 调用 |
| （Classic 配套）工程方法  | HOW  | [Superpowers](https://github.com/obra/superpowers)         | brainstorming / TDD / 子代理 | Classic 中由 Comet 按阶段调用           |
| 上下文工程 + 工具设计      | 检索   | **[CodeGraph](https://github.com/colbymchenry/codegraph)** | 预索引代码知识图谱，替代乱 grep        | 中大型代码仓库推荐；小仓库/文档库按需             |
| 上下文工程             | 执行   | **[RTK](https://github.com/rtk-ai/rtk)**                   | 命令输出过滤器，减少日志噪音            | 执行端（推荐）                          |
| 熵减                | 生成   | **[Ponytail](https://github.com/DietrichGebert/ponytail)** | 懒人决策阶梯，从源头少写代码            | 生成端（**可选**）                      |
| 上下文工程             | 输出   | **[Caveman](https://github.com/JuliusBrussee/caveman)**    | 电报体回复，砍掉客套话               | 输出端（**可选**）                      |

---

## 二、七个开源实现：七件工具，各管一道闸

> 这一节每个项目只讲四件事：它是什么、它怎么起作用、官方给的数据是多少、它管不了什么。想直接上手，跳到第三节看完整配置。

### 2.1 Comet：流程编排层，管「什么时候做、下一步做什么」

**GitHub：<https://github.com/rpamis/comet>**（rpamis 出品，MIT 许可；Classic 工作流里内嵌 [OpenSpec](https://github.com/Fission-AI/OpenSpec) 管需求、[Superpowers](https://github.com/obra/superpowers) 管工程方法）

**主要解决：状态和记忆 · 验证回路 + 评测集 · 熵减**

Comet 是整个 Harness 的主入口，管的是编排。它提供两条互不干扰的工作流：

- **Native（给强模型用）**：四阶段 **Shape → Build → Verify → Archive**。只依赖自己的运行时，不依赖 OpenSpec、Superpowers，连 Bash/Git Bash/WSL 都不需要——纯 Node 就能跑。Shape 澄清需求、写 brief 和目标规格并等你确认；Build 让模型自己挑实现路径；Verify 派一个**独立的只读 Verifier** 去验收；Archive 用可恢复事务收尾。官方原话：「Native 是给能自主规划、自主验证的强模型用的」。入口 `/comet-native`。
- **Classic（给需要完整方法论约束的场景）**：五阶段 **Open → Design → Build → Verify → Archive**，也就是 OpenSpec + Superpowers 那套完整阶段治理。官方原话：「Classic 是给从完整分阶段方法论和更强约束中受益的场景用的」。入口 `/comet-classic`。

两条工作流**互不升级**，不是「轻量版 / 重量级」的关系。共享入口 `/comet` 会读项目配置决定转发给谁，不靠猜任务大小。

**官方评测（0.4.0-beta.7，B 级官方自述）**：Native 与 0.4.0 Classic 的对齐实验——16 个工作流任务 × 48 次运行，挑出 41 对「两边都通过」的样本做对比：**总 Token −76.8%、轮次 −57.4%、耗时 −47.4%、pass^3 87.5%（+12.5pp）、pass@3 100%**。只比两边都通过的样本对，是种保守的公平对比；pass^3（连续三次全过）也比单次通过率严格得多。这组数字是 Comet 自己跑出来的，我没有复测。

**状态和记忆怎么落地**。两套工作流的 Runtime 分别落盘，路径与状态格式不同，别混着说（以下为 0.4.0-beta 官方口径，README 原文印证 "Native stores user-readable artifacts under `docs/comet/` by default, while machine Runtime is fixed under the project-local `.comet/runtime/native/`"）：

- **Native**：用户可读产物默认在 `docs/comet/`（想换位置就设 `native.artifact_root`，比如 `artifacts/comet/`）；机器 Runtime 固定在项目内的 `.comet/runtime/native/`，下面分 `changes/<id>/`（`state.json` 与日志）、`locks/`、`transactions/`；「当前 change 归谁」记在 `.comet/current-change.json`；
- **Classic**：产物布局由 `classic.artifact_layout` 控制——新项目是 `docs`（即 `docs/openspec/` + `docs/superpowers/`），老项目若保留 legacy，OpenSpec 根在仓库级 `openspec/`、Superpowers 仍在 `docs/superpowers/`；变更级状态在 `<classic-change-dir>/.comet.yaml`，引擎机器态在 `<classic-change-dir>/.comet/run-state.json`（camelCase 字段：`currentStep` / `status` / `iteration`），审计日志是 `<classic-change-dir>/.comet/state-events.jsonl`；
- **共享**：`.comet/config.yaml` 是唯一的 **Comet 项目级配置**（含 schema、default_workflow、workflows、ambient_resume、hook.allow_paths、classic.*、native.*）。

Hook 路由也是共享的：每个平台装一个 `comet-workflow-guard` Rule，有 Hook 能力的平台只装 `comet-hook-router.mjs` 一个入口，由 `current-change.json` 决定这次写请求落到 Native 还是 Classic 的 Guard——**不会两边同写**。另外 0.4.0-beta 起整套 Runtime 是纯 Node（TypeScript 编译后由 node 执行），不依赖 Bash/WSL。

**验证回路怎么落地**：Verify 阶段必须有真实存在的 verification report，由脚本校验；注意这时候 `branch_status` 还是 `pending`，要等归档提交前才被置为 `handled`。另外 `comet eval` 可以给任何 Skill 跑标准化评测，关键设计是**裁判和运动员分开**——主 Agent 与 LLM-as-Judge 各有独立的 agent / model / API 地址 / 凭证：

```yaml
# comet/eval.yaml —— 评测配置：执行者与裁判分离（官方 README 示例）
execution:
  agent: codex
  model: subject-model
  baseUrl: https://subject.example/v1
judge:
  agent: claude-code
  model: judge-model
  baseUrl: https://judge.example/v1
```

常用入口有三类：`--collect` 做静态检查（不起 Agent/Docker）、`--html` 出本地评测报告、`--suite langsmith` 把结果同步到 LangSmith。它们仍依赖对应的评测配置与可写目录；本机 sandbox 中尚未完成端到端执行。

**熵减怎么落地——Anti-drift Phase Guards**，官方的说法是「面向长上下文会话的防漂移守卫」。阶段强制力不靠 prompt 说教，靠的是一条三层链路：

```text
agent 发起文件写入
   │
   ▼
comet-hook-router.mjs        ← 平台唯一的 Hook 入口
   │  读 .comet/current-change.json 路由到恰好一个 Guard
   │  官方原话：一次写至多到达一个 Guard；
   │          归属歧义或过期 → fail closed（失败关闭，绝不猜）
   ▼
comet-guard.mjs / comet-native-hook-guard.mjs（Classic / Native 各自独立的 Guard）
   ▼
校验阶段退出条件 + 允许写入路径
```

- **Rule 层**：每个平台只装一个 `comet-workflow-guard` 规则，只套一套阶段模型；
- **Hook 层**：支持 Hook 的平台只装 `comet-hook-router.mjs` 一个 Hook（官方脚本表原话："The platform's only Hook entry"）；
- **Guard 层**：官方原话 "Native permits ordinary implementation writes only in Build; Classic permits them in Build and Verify"——Native 只在 Build 允许写实现，Classic 允许 Build + Verify。只有 active change、Router 已受信任且写入命中受管辖路径时，才会由 Guard 执行这项限制；「设计没确认，物理上写不了实现」是满足这些前提后的行为描述，当前本机的完整拒绝实验仍待人工审核。

Guard 的核心约束包括入口校验、状态迁移守卫、isolation 与分支绑定、验证证据门。如果 agent 确实需要在非编码阶段写项目内的共享规则或团队笔记，就要在 `.comet/config.yaml` 里显式放行：

```yaml
hook:
  allow_paths:
    - .agents/rules
    - docs/team-notes
```

`hook.allow_paths` 是 0.4.0 文档定义的**共享写策略字段**（shared entry field）。本项目当前配置未启用该字段，具体可用性仍待人工审核。文档规则是：项目相对路径白名单、默认空列表；**前缀匹配、子目录继承**（放行 `docs/team-notes` 就等于放行它下面所有层级）；但 `.comet/` Runtime 目录与 Classic 的 OpenSpec / Superpowers 产物根是禁区，靠它绕不过去，项目外路径则维持原有 scope 行为。README 原文印证："…this setting cannot bypass `.comet` or workflow artifact directories."（「前缀匹配」与「越界由 `comet doctor` 报告」两条出自官方文档补充，README 未逐字写明【待人工审核】。）

另外还有 Hotfix（跳过完整 brainstorming）和 Tweak（轻量档）两个快捷档位——注意它们在 Codex 里的菜单名是「Comet Classic 预设:Hotfix / Tweak」，详见 3.4。

#### Comet 怎么和 Claude Code / Codex 联动

先把安装的次数说清楚，这是最容易被误解的地方：

- **`npm install -g @rpamis/comet` 装的是 CLI，一台机器装一次就够了**；
- **`comet init` 是给项目接上 Comet，一个项目目录跑一次**——跑的时候由你选择要接哪些 coding agent（Claude Code、Codex、WorkBuddy、Antigravity……可以多选），也可以事后改配置；
- 换项目就再 `comet init` 一次，CLI 不用重装；升级用 `comet update`。

接上之后，「联动」由三个入口和两个共享点构成：

1. **命令入口**：Claude Code 用斜杠命令 `/comet`，Codex 用 skill 语法 `$comet`。两边都有共享入口（按配置转发 Native/Classic）、逐阶段命令（`/comet-open`、`/comet-design`……）和预设档。2026-08-29 历史实录显示 `$comet-native` 在 Codex 里可以直接敲（3.4 节有入口清单）；但 Hotfix / Tweak 在 Codex 里的名字是「Comet Classic 预设:Hotfix / Tweak」，不能照 Claude Code 的 `/comet-hotfix` 硬套【待人工审核】。
2. **写拦截入口**：支持 Hook 的平台只装 `comet-hook-router.mjs` 一个 Hook。Claude Code 挂在原生 hook 系统的 PreToolUse 事件上；Codex 和 WorkBuddy 由 `comet init` 自动装好，不需要手工接线（项目级 `.codex/hooks.json`，matcher `Write|Edit`，3.4 节有实测落盘）；
3. **恢复入口**：`comet init/update` 会把 `<comet-ambient-resume>` 托管块合并进 `CLAUDE.md` / `AGENTS.md`；项目规则要求在开始可能涉及 active workflow 的改动或调查前运行一次 `comet resume-probe`。它只做只读探测，返回 `auto_resume` / `ask_user` / `out_of_scope` / `none` 四选一，再路由到对应入口。

两个共享点，是「状态和记忆」能跨平台生效的关键：

- **状态文件在项目里，不归任何平台私有**：`.comet/config.yaml`（工作流配置）、`.comet/current-change.json`（当前变更归属），加上 Native 的 `.comet/runtime/native/changes/<id>/` 或 Classic 的 `<classic-change-dir>/.comet.yaml` 与 `<classic-change-dir>/.comet/run-state.json`（布局详见上文）。Claude Code 和 Codex 读的是同一份，换宿主不丢进度；
- **Classic 会把 OpenSpec + Superpowers 的 skills 一起装进平台 skills 目录**（`.claude/skills/` 下会出现 `openspec-*`、`brainstorming` 等）；Native 只装 Comet 自己的。

#### 本机 `comet init` 实录（v0.4.0-beta.20）

官方口径之外，放一份真实安装记录节选，让「联动」这件事落地可感：

```text
Comet v0.4.0-beta.20 — You are on the latest version.
✔ 安装范围: 项目（当前目录）
✔ Comet 模式: 两者 — Native + Classic 双入口（/comet 默认 Native）
✔ 安装模式: Symlink（共享中央存储，节省空间）
✔ 平台: Claude Code, Codex, WorkBuddy, Antigravity 2.0
# OpenSpec：11 skills + 11 commands → .claude / .agents / .codebuddy/
#   "Codex, Antigravity share .agents/skills; writing one tree for codex"
# Superpowers：14 skills → .agents/skills/（universal；symlink → Claude Code）
#   安全审查（Gen / Socket / Snyk 三引擎）: 14 个全 Safe / 0 alerts / Low Risk
#   （using-git-worktrees Med Risk、using-superpowers 1 alert，如实标出）
# Comet：78 files/平台 + 1 规则 + Phase guard hook（Claude Code/Codex/WorkBuddy 实测装）
# CodeGraph：skipped（已有索引）/ CLI 已装 / MCP registered (global)
# 工作目录：Native → docs/comet/；Classic → docs/openspec/
```

这份实录暴露了两处「README 表格 vs 安装器实际行为」的差异：一是**Codex 的 skills 不在 `.codex/` 而在 `.agents/skills/`**（与 Antigravity 共用 universal 目录，Claude Code 侧用 symlink 指过去）；二是**Codex 与 WorkBuddy 的 Hook 由安装器自动装**，README 只笼统说「支持 Hook 的平台安装 Router」却没列名单，实测推翻了「需要手工接线」的猜测。另一个亮点是 Superpowers 安装时跑了 **Gen / Socket / Snyk 三引擎安全审查**，14 个 skill 全绿才落地，审查结果原样留在输出里（包括 using-git-worktrees 的 Med Risk 和 using-superpowers 的 1 个 alert）——供应链风险处理得比多数工具链透明。

另外还有 `comet dashboard`（本地只读仪表盘）、初始化时用 `--codegraph init|skip` 决定是否同时建 CodeGraph 索引，以及 **35 个 AI 编码平台**的覆盖（README 原文：「`comet init` supports 35 AI coding platforms」）。

还有一项 Classic 专属的 **Context Compression**：在 Design → Build 交接点开启后，`comet-handoff.mjs` 会生成紧凑上下文包，把 Build 阶段的输入 token 砍掉 25–30%，测试通过率不变，任务越大省得越多（大任务约 15,000 tokens）。代价是 **Spec 覆盖率从 100% 掉到 95%**——想省 token 就得接受这点边缘细节的损失。开关在 `.comet/config.yaml` 的 `classic:` 块下（`context_compression: beta`），默认 `off`，本机也保持关闭。完整数据与出处见 4.1、4.2 节。

#### Classic / both 初始化时由 Comet 安装：OpenSpec 与 Superpowers

**OpenSpec**（<https://github.com/Fission-AI/OpenSpec>，MIT）——**主要解决：状态和记忆**。它把「改代码」变成一条文档流水线：主入口 `/opsx:propose` 一次产出 proposal.md / design.md / tasks.md / specs/ 四件套（Cursor/Copilot 写成 `/opsx-propose`，Codex 写成 `$openspec-propose`），实现完成后把增量 spec 合并回主 spec 再归档。支持 **30+ 种 AI 助手**，要求 Node.js 20.19.0+。

**Superpowers**（<https://github.com/obra/superpowers>，MIT）——**主要解决：验证回路**。一套可组合的编码方法论 Skills：brainstorming、writing/executing-plans（计划拆到 2–5 分钟粒度、带精确文件路径和验证步骤）、subagent-driven-development（两阶段审查）、test-driven-development、systematic-debugging。支持 **14 个平台**。

它 6.0 那轮自优化过程（官方博客，B 级）本身就是「评测集驱动改进」的标本：三轮优化下来，审查包 shell 化省约 10%、双审查合并再省约 15%、25 轮实验花了约 165 美元换来简洁审查合同 −41%，官方口径是 "up to 50% faster / up to 60% cheaper"（注意 up to 是上限）。还有一个反直觉的发现：**限制 thinking token 反而更贵**——回合数从 92 涨到 138，输出翻倍。（版本 **6.3.0**，发布于 2026-08-12，本机已装版本一致。注意 `comet doctor` 对 Superpowers 只报 detected、明确说 version not recorded by skills installer，所以版本号得从官方发布页查。）

一句话收尾：**Comet 把「规范纪律」变成了自动执行的状态机，让团队从「能写好」变成「每次都写得好」。**

### 2.2 CodeGraph：检索端，管「读」（砍乱翻）

**GitHub：<https://github.com/colbymchenry/codegraph>**（colbymchenry 出品，MIT 许可）

**主要解决：上下文工程 · 工具的设计**

CodeGraph 是一张**预先建好的代码知识图谱**：Rust 内核把符号、调用和依赖关系解析出来，`codegraph init` 一条命令建索引，之后文件监听会在你保存时增量同步。我这台机器上索引了 49 个文件、17,740 个节点、65,626 条边，状态 current。索引也会有延迟、有解析不了的语法，实在没命中就直接读文件，别跟它较劲。

**它真正的价值在「出事的时候」。** 平时写代码，快一点慢一点体感不强；真正要命的是程序报错、行为不对、要定位「问题代码到底在哪」。这时候 agent 的传统做法是 grep 一个关键词，命中几十个文件，再挨个 Read 进去看——窗口瞬间塞满，还经常找错地方。CodeGraph 的活法不一样：查询命中已索引的代码符号时，你可以用自然语言描述现象（比如「guard 在非 Build 阶段拦截了写入」），由它返回**相关符号的逐字源码 + 调用路径 + 影响半径**，每条都带着精确到行号的 `文件:行号`。文档、配置、未支持语法或表述太宽的查询仍可能不命中，此时应直接读文件。本节末尾那组历史对照记录说的就是这种理想命中场景。

**官方基准（2026-08-05 复测，B 级官方自述）**：Claude Opus 4.8 × 7 个真实仓库（VS Code、Excalidraw、Django、Tokio、OkHttp、Gin、Alamofire），每个 arm 跑 4 次取中位数：

> **"The universal win — every repo, every size: 88% fewer tool calls · 53% faster · 62% fewer tokens · 44% cheaper · file reads cut to zero on all seven repos."**
>
> （工具调用 −88%、速度 +53%、token −62%、成本 −44%，**文件读取在全部 7 个仓库归零**。）

那是官方在人家自己挑的 7 个仓库上测出来的，不是我复测的，也不能直接外推成你项目的收益。

**2026-08-29 的一次本机对照（C 级历史记录）**：官方那组数字来自别人挑的仓库，当时在这个仓库上另做了一组对照——同一个定位任务，分别走「CodeGraph 一次调用」和「grep 定位 + Read 命中文件」两条路径。由于没有把完整命令、文件选择规则和字节统计脚本保存为可运行产物，下面的具体数字暂列【待人工审核】：

| 查询                            | CodeGraph（1 次调用） | grep + Read                                    | 减少     |
| ----------------------------- | --------------- | ---------------------------------------------- | ------ |
| comet guard state transition  | 14,261 字节      | 1,595,917 字节（grep 444 KB + 读 5 个文件）                | −99.2% |
| hook router platform codex    | 10,701 字节      | 318,714 字节（grep 30 KB + 读 1 个文件）                  | −96.7% |
| resume probe current change   | 13,408 字节      | 1,416,630 字节（grep 450 KB + 读 5 个文件）                | −99.1% |

口径必须说清楚：我这个仓库里堆着大量压缩过的 `.mjs`（单文件 289 KB–500 KB），grep 命中一行就是几十 KB，属于对 CodeGraph 特别有利的场景，别拿 −99% 当预期收益——官方跨 7 个仓库的 −62% 保守得多。这组实测真正说明的只有一件事：**在大文件和打包产物面前，grep 的代价被严重低估了。**

**代价也得说**，这是官方自己写在 README 里的：多轮会话里，检索上下文的残留会比文件读取基线多出约 80%。检索端省了探索，代价是窗口更满——长会话可以考虑配合压缩策略。

**工具设计上有两条值得抄的决策**：

- **MCP 默认只暴露一个工具 `codegraph_explore`**：一次调用返回符号源码 + 调用路径 + 影响半径。一个强工具，比一堆窄工具更能引导 agent 做对选择；
- **把用法写进 MCP initialize 响应和指令文件的 marker 段**：直接告诉 agent「别用 grep 复查、把返回的源码当作已读」。因为子代理和非 MCP agent 看不到 MCP guidance，安装器还会往 `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` 写一段围栏指引，专门教它们用 CLI。

**CLI 模式**：`codegraph explore "<你的问题>"` 提供和 MCP 探索相同的能力，`codegraph affected` 能顺着 import 依赖找出被改动波及的测试文件（CI 精准跑测试很好用）。CLI 与 MCP 在输出细节、计数口径上的差异取决于宿主和查询，我没有逐项复测【待人工审核】。

其他要点：**100% 本地**（SQLite + FTS5，不需要 API key）；性能参考——Swift 编译器仓库（27k 文件）全新索引约 **100 秒**、单文件重同步约 4 秒，Linux 内核（70k 文件、200 万符号）在 2 核 VPS 上 **12 分钟**建完，再索引比最快的竞品 **快 2–7 倍**（31 仓库、30 语言基准）；**9 类 Agent**（Claude Code、Cursor、Codex CLI、opencode、Gemini CLI、Antigravity、Kiro、Copilot 等）由安装器自动写 MCP 配置。

边界也要讲清楚：CodeGraph 只能「劝」agent 别乱 grep，最终调不调还是模型说了算。所以实践中要把使用规则写进全局配置（3.3 / 3.4 有完整代码）。

### 2.3 RTK：执行端，管「拿」（砍日志）

**GitHub：<https://github.com/rtk-ai/rtk>**（rtk-ai 出品，Apache 2.0）

**主要解决：上下文工程（执行端）**

RTK 是守在 shell 出口的**命令输出过滤器**。官方定位原话：*"High-performance CLI proxy that cuts up to 90% of the bash output your agent reads"*——砍的是 agent 读到的 bash 输出，最多九成。单个 Rust 二进制，覆盖 100+ 命令，开销不到 10ms。【待人工审核：RTK 仓库约 77,200 star / 4,850 fork / 创建于 2026-01-22 / v0.45.0，来自公众号转载，GitHub 数值天天在变，如需引用请以项目页与 Releases 为准（见 4.3 第 1 项）；官方 README 内部版本号也不一致（0.28.2 vs v0.37.2+），只能以 Releases 为准。】

**它的机制是「钩子改写」，不是网络代理**——这是最值得学的一点。装好之后会注册一个 PreToolUse 钩子：agent 每次要跑 `git status`，钩子在执行前把它改写成 `rtk git status`；RTK 包住真命令拿到完整输出，压缩后只把摘要交回去。**agent 全程无感，行为却已经被改变。** 压缩就四招：**过滤**（去注释、空白、样板）、**分组**（按目录或错误类型聚合）、**截断**（长行砍尾）、**去重**（重复日志折叠成计数）。

官方削减幅度（bash 输出口径，不是账单口径）：

| 命令类型  | 代表命令                                 | 输出削减        |
| ----- | ------------------------------------ | ----------- |
| 测试运行器 | pytest · cargo test · go test · jest | −90%        |
| 编译    | cargo build · cargo clippy           | −80%        |
| Lint  | ruff · golangci-lint · eslint        | −80% ~ −85% |

典型对比：一次 `cargo test`（15 个挂 2 个）原样 200+ 行，RTK 版约 20 行；`git push` 15 行变成一行 `ok main`；`ls -la` 45 行变成 12 行目录树。

**两个给验证回路兜底的设计**：

- **tee 保险**：命令失败时完整原始输出自动落盘（macOS 默认在 `~/Library/Application Support/rtk/tee/`，Linux 常见在 `~/.local/share/rtk/tee/`），摘要末尾带上路径。agent 想深挖就去翻日志，不用重跑命令：

```text
FAILED: 2/15 tests
[full output: ~/.local/share/rtk/tee/1707753600_cargo_test.log]
```

- **诚实稀释声明（官方原文）**：*"…it is not the same as cutting your bill by 90%. Bash output is one contributor to input tokens…The reduction dilutes at every step."*——bash 输出只是输入 token 的一部分，输入又只是账单的一部分，**削减在每一层都被稀释**。RTK 按 `bytes / 4` 估算节省，百分比可靠，绝对 token 数只能算近似值。

**本机接线状态**（这是两侧差异最大的一个组件）：

- **Claude Code**：PreToolUse hook 已启用，但只匹配 Bash——Read / Grep / Glob 不会被改写。想让这些也走 RTK，就改走 shell 命令，或者显式调 `rtk read` / `rtk grep` / `rtk find`；
- **Codex**：走规则文件档。我实测跑过 `rtk init --codex`，它会写入项目 `RTK.md` 并在项目 `AGENTS.md` 里加一行 `@RTK.md` 引用：

```text
$ rtk init --codex

RTK configured for Codex CLI.

  RTK.md:    RTK.md
  AGENTS.md: @RTK.md reference already present

  Codex project instructions path: AGENTS.md
```

这里有个坑：全局 `~/.codex/AGENTS.md` 里的引用写成了绝对路径，而且指向了错误的用户目录，得手工改回项目里的 `RTK.md`。另外规则档靠模型自觉遵守，没有钩子那样的强制力——想在 Codex 上也强制执行，就让 agent 走 shell 命令而不是内建工具。

### 2.4 Ponytail：生成端，管熵减（可选组件）

**GitHub：<https://github.com/DietrichGebert/ponytail>**（Dietrich Gebert 出品，MIT 许可）

**主要解决：熵减（生成端）**

Ponytail 是一层**前置决策规则**：写代码之前先强制走一遍「资深懒人的思维阶梯」，从源头杜绝冗余，而不是事后回来重构。Codex 当前安装版本为 **4.9.0**——这次是从安装路径和插件 manifest 里直接读到的（`~/.codex/plugins/cache/ponytail/ponytail/4.9.0`）。Claude Code 当前同时启用了 user scope 4.7.0 与 local scope 4.9.0，最终生效优先级【待人工审核】。

官方的决策阶梯有 7 层，停在第一个成立的台阶上：

```text
1. 这东西需要存在吗？   → 不需要，跳过（YAGNI）
2. 代码库里已经有了吗？ → 复用，不重写
3. 标准库能做吗？       → 用标准库
4. 平台原生特性能做吗？ → 用原生特性
5. 已安装的依赖能做吗？ → 用它
6. 一行能搞定吗？       → 就写一行
7. 最后才写：能工作的最小实现
```

官方特别强调：阶梯是在**理解问题之后**才运行的——先把改动涉及的代码读完、把真实流程追一遍，再去选台阶。原话是「对方案懒惰，对阅读绝不懒惰」。经典例子是日期选择器：普通 AI 会装上 flatpickr + 包装组件 + 样式表，再花两轮讨论时区；Ponytail 只写一行：

```html
<input type="date">
```

**官方基准（B 级官方自述，agentic 无头 Claude Code 会话，Haiku 4.5）**：

| 指标              | vs 无 skill 基线                                      |
| --------------- | -------------------------------------------------- |
| 代码量 LOC         | **−54%**（过度构建场景最高 −94%）                            |
| Token / 成本 / 耗时 | **−22% / −20% / −27%**                             |
| 安全性             | **100%**（无 skill 基线同为 100%；朴素「YAGNI+一行流」提示词方案 95%） |

注意口径：−94% 是过度构建场景的峰值（日期选择器 404 行 → 23 行），平均是 −54%；早先 single-shot 基准里 80–94% 那个数，官方已澄清是「会话基线伪影」（issue #126）。

它的核心原则（README 原文）：**"The rule was never 'fewest tokens.'"**——规则从来不是「用最少 token」，而是「只写任务真正需要的」，**永远不裁剪验证、错误处理、安全、无障碍**（lazy, not negligent）。官方也诚实指出了边界：terse 模型可能为了爬阶梯烧掉大量 thinking token，反而更贵。

插件里装的东西（我直接读了安装目录，不是照抄 README）：**6 个 skills**（`ponytail`、`ponytail-audit`、`ponytail-debt`、`ponytail-gain`、`ponytail-help`、`ponytail-review`）+ 一一对应的 6 个 command，外加 lite/full/ultra/off 四档强度，兼容 **20 个 Agent 宿主**。

还有个容易被忽略的点：**插件自带 lifecycle hooks**。manifest 里写着 `"hooks": "./hooks/claude-codex-hooks.json"`，实际挂了三组（下面这份是我为了省版面压成紧凑排版的，字段名和参数与原始文件一致）：

```json
{
  "hooks": {
    "SessionStart":     [{ "matcher": "startup|resume|clear|compact",
                           "hooks": [{ "type": "command", "command": "node \"${CLAUDE_PLUGIN_ROOT}/hooks/ponytail-activate.js\"", "timeout": 5 }] }],
    "SubagentStart":    [{ "hooks": [{ "type": "command", "command": "node \"${CLAUDE_PLUGIN_ROOT}/hooks/ponytail-subagent.js\"", "timeout": 5 }] }],
    "UserPromptSubmit": [{ "hooks": [{ "type": "command", "command": "node \"${CLAUDE_PLUGIN_ROOT}/hooks/ponytail-mode-tracker.js\"", "timeout": 5 }] }]
  }
}
```

这就是「always-on 激活」的实现方式——前提是插件已启用、对应 hook 已受信任且宿主确实加载了它；满足这些条件后，会话开始、子代理启动和提交 prompt 时会重新加载 Ponytail 模式，不用手动触发。

但这里有个很容易踩的坑：**装完插件不等于激活了**。按官方文档，装插件不会自动信任它捆绑的 hook。我在 Codex 的 `/hooks` 里实测，刚装完时这三组的状态是 `Installed 1 / Active 0 / Review 1`——**没审之前它们会被直接跳过，always-on 等于没发生**。

审完之后，Codex 会把信任结果按 hook 内容的 hash 落到 `~/.codex/config.toml`，三组各一条：

```toml
[hooks.state."ponytail@ponytail:hooks/claude-codex-hooks.json:session_start:0:0"]
trusted_hash = "sha256:5f81d38f…"

[hooks.state."ponytail@ponytail:hooks/claude-codex-hooks.json:user_prompt_submit:0:0"]
trusted_hash = "sha256:6a6f42bc…"

[hooks.state."ponytail@ponytail:hooks/claude-codex-hooks.json:subagent_start:0:0"]
trusted_hash = "sha256:1423b56c…"
```

`trusted_hash` 只在审过之后才会写入，所以它能直接证明 hook **已经受信任**；要判断是否正在生效，还应同时确认插件 enabled，并观察当前会话是否实际加载。它记的是内容 hash：插件一升级、脚本内容一变，hash 可能对不上，宿主会重新要求审查。

作为**可选组件**，它的收益集中在「AI 过度工程」高发的场景（原型、内部工具、常见 CRUD）；算法密集或领域建模重的代码，强行最小化收益有限，甚至有害。

### 2.5 Caveman：输出端，管「说」（砍废话）——可选组件

**GitHub：<https://github.com/JuliusBrussee/caveman>**（JuliusBrussee 出品）

**主要解决：上下文工程（输出端）**

Caveman 是这几个项目里最欢乐的一个：让 AI 用「原始人电报体」说话——删掉寒暄、铺垫、免责声明、总结复述，只留结论、动作和代码（当前版本 v2.3.1，由官方安装命令的 URL tag 确认）。

**Caveman 2 是双产品架构**（官方 README）：

| 产品               | 管什么                                    | 节省                                               | 许可                               |
| ---------------- | -------------------------------------- | ------------------------------------------------ | -------------------------------- |
| **Skill**        | 管**输出**：电报体回答，代码/报错保持原样                | 10 任务平均 1214→294 token；任务级平均 **65%**（区间 22%–87%） | **MIT**                          |
| **Proxy/Engine** | 管**输入**：本地代理在每次 provider 调用前压缩，字节级精确恢复 | 54-run 基准：**输入 token −33.2%**，18 项精确检查全过         | **BSL-1.1**（非 OSI，有 Change Date） |

效果对比（官方示例）：普通回答 69 tokens → Caveman 19 tokens（"New object ref each render… Wrap in `useMemo`"）。

但它是**可选组件**，而且官方的诚实声明比收益声明更值得看（**"Honest number warning"** 原文）：*"The skill only shrinks output tokens. Input and reasoning tokens are untouched, and the skill itself adds ~1–1.5k input tokens per turn. Whole-session savings run smaller… on already-terse workloads they can go net-negative. The real win is readability and speed; cost savings are the bonus."*——只压输出 token，输入和推理 token 不动，skill 本身每轮还要吃掉约 1–1.5k 输入 token；整会话的节省要小得多，本来就简洁的任务甚至可能是负收益；**真正的收益是可读性和速度，省钱只是赠品。**

结论：**Caveman 是约束工具，不是省钱工具。** 上游建议按需使用。我这个项目里装上的 skill 正文写的是 `ACTIVE EVERY RESPONSE`、默认 `full`，所以「按需触发」是推荐策略，不是装完就有的默认状态。【待人工审核】

## 三、整合成一套 Harness：Comet + CodeGraph + Ponytail + Caveman + RTK

### 3.1 分层原则

七个项目，为什么最后是五件套？因为 OpenSpec 和 Superpowers 在 Classic 里属于 Comet 的配套能力，Native 压根不依赖它们。我这个项目里两者都已经由 Comet 装好了——「由 Comet 管理」不等于「项目里不存在」，要不要单独装，看 `comet init` 的结果就行。

核心原则一句话：

> **Comet 管流程，OpenSpec 管需求，Superpowers 管工程方法，CodeGraph 管检索，RTK 管执行，Ponytail 管代码形态，Caveman 管聊天话术。**

它们不是平级竞争，而是分层组合。一张图看全景（每个组件旁标注了它对应哪个主题）：

```text
                    ┌─────────────────────────────────┐
                    │   Comet（流程编排 + 状态机）      │
                    │   Classic: Open→Design→Build→    │
                    │   Verify→Archive                 │
                    │   Native: Shape→Build→Verify→    │
                    │   Archive                        │
                    │   ├─ 内嵌 OpenSpec（WHAT）        │
                    │   │   [状态和记忆·活文档]         │
                    │   └─ 内嵌 Superpowers（HOW）      │
                    │       [验证回路·TDD/两阶段审查]   │
                    │   + comet eval [评测集]           │
                    └───────────────┬─────────────────┘
                                    │
          ┌─────────────────────────┼─────────────────────────┐
          ▼                         ▼                         ▼
  ┌───────────────┐       ┌───────────────┐        ┌───────────────┐
  │ CodeGraph     │       │ Ponytail      │        │ RTK           │
  │ [上下文工程·读]│       │ [熵减·生成]   │        │ [上下文工程·拿]│
  │ [工具设计·单  │       │ 懒人决策阶梯  │        │ 命令输出过滤  │
  │  工具哲学]    │       │ （可选）      │        │ （推荐）      │
  │（代码仓库推荐）│       └───────────────┘        └───────────────┘
  └───────────────┘                │                     │
          │                        └──────────┬──────────┘
          ▼                                   ▼
  ┌───────────────────┐             ┌───────────────────┐
  │ Caveman           │             │ Comet Verify Gate │
  │ [上下文工程·说]   │             │ [验证回路+评测集]  │
  │ （可选；默认策略待确认）│         │ 独立 Verifier     │
  └───────────────────┘             └───────────────────┘
```

### 3.2 五个问题如何被逐一解决

| 问题             | 谁来管                                      | 怎么管                                                                                                                         |
| -------------- | ---------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| **上下文工程**      | CodeGraph + RTK + Caveman + Comet        | 读：官方 benchmark 说一次探索能替代几十次工具调用，2026-08-29 的一次本机对照记录为 96.7%–99.2%【待人工审核】；拿：RTK 压命令输出；说：Caveman 压对话；交接：Context Compression 生成紧凑交接包。各组数据口径不同，不宜直接相加 |
| **工具的设计**      | CodeGraph + RTK + Comet                  | CodeGraph 单工具哲学（一个强工具引导正确选择）；RTK 钩子改写（行为无感被改变，不靠说教）；Comet 一个 Rule + 一个 Hook Router（入口收敛，hooks 不打架）                          |
| **状态和记忆**      | Comet + OpenSpec                         | SDD：规范先行、变更先改 spec；change 状态文件跨会话恢复，`state-events.jsonl` 留审计，delta spec 归档沉淀成活文档                                          |
| **验证回路 + 评测集** | Comet + Superpowers + RTK + `comet eval` | verify-pass 证据门（脚本校验）；独立只读 Verifier（写代码的人不能给自己判卷）；TDD + 两阶段审查；tee 底牌可回溯；`comet eval` 用独立 LLM-as-Judge 评 Skill，接 LangSmith 追踪 |
| **熵减**         | Comet 守卫 + Ponytail + 路由门禁               | 流程熵：阶段守卫拦住不符合当前 phase 的写入，也防目标漂移；代码熵：七层懒人阶梯约束过度工程；上下文熵：靠压缩缓解，无法根除；路由表决定什么任务进 workflow；Verify 失败仍可退回 Build，闭环不是「只减不增」 |

### 3.3 Claude Code 实战案例

下面是在 Claude Code 上搭这套 Harness 的完整配置。配置格式都来自各项目官方 README，由安装器写入或可手工核对。

**第一步：安装四件套**

```bash
# Comet：流程主入口（当前发行版要求 Node.js 22+）
npm install -g @rpamis/comet          # CLI，一台机器装一次
cd your-project
comet init --codegraph init           # 每个项目目录跑一次；初始化时选平台和 workflow
                                      # 不想建索引用 --codegraph skip

# RTK：执行端输出过滤（注意别用 cargo install rtk，crates.io 上有同名包）
brew install rtk
rtk init -g                           # Claude Code 接线：注册 PreToolUse hook

# Ponytail（可选）：生成端懒人阶梯
# 在 Claude Code 里分两次发送（官方 README 明确要求分开发送才生效）：
#   /plugin marketplace add DietrichGebert/ponytail
#   /plugin install ponytail@ponytail

# Caveman（可选）：输出端电报体；先下载并审阅固定版本，再执行（远程脚本示例）【待人工审核】
curl -fsSL https://raw.githubusercontent.com/JuliusBrussee/caveman/v2.3.1/install.sh -o /tmp/caveman-install.sh
less /tmp/caveman-install.sh
bash /tmp/caveman-install.sh
```

**Ponytail 在 Claude Code 里的实际安装过程**（本机实录，两条命令要分开跑）：

```text
❯ /plugin marketplace add DietrichGebert/ponytail
  ⎿  Successfully added marketplace: ponytail

❯ /plugin install ponytail@ponytail

   Plugins  Discover   Installed   Marketplaces   Errors

   Plugin Details

   ponytail

   Forces the laziest solution that works. YAGNI, stdlib first, one line over fifty.

   Will install:
   · Components will be discovered at installation

   ⚠ Make sure you trust a plugin before installing, updating, or using it...

     Install for you (user scope)
     Install for all collaborators on this repository (project scope)
   > Install for you, in this repo only (local scope)
     Back to plugin list
❯ /plugin install ponytail@ponytail
  ⎿  ✓ Installed ponytail. Plugin is now active.
```

两个细节值得注意：一是安装前会弹出**作用域选择**——用户级（你自己的所有项目）、项目级（仓库所有协作者）、本地级（只有当前仓库的你自己）。团队想统一工程规范就选项目级，自己试水选本地级。二是那条警告不是套话：Anthropic 明确声明它无法验证第三方插件里的 MCP server 和文件会不会按预期工作，所以**装之前先看一眼插件主页**。选完作用域再敲一次 `/plugin install ponytail@ponytail` 才真正装上。

**第二步：核对安装器写入的配置**

CodeGraph 的 MCP server 配置（写入 `~/.claude.json`）：

```json
{
  "mcpServers": {
    "codegraph": {
      "type": "stdio",
      "command": "codegraph",
      "args": ["serve", "--mcp"]
    }
  }
}
```

CodeGraph 工具自动放行（写入 `~/.claude/settings.json`，一个通配符放行全部 CodeGraph 工具）：

```json
{
  "permissions": {
    "allow": [
      "mcp__codegraph__*"
    ]
  }
}
```

RTK 的行为配置（macOS 路径为 `~/Library/Application Support/rtk/config.toml`）：

```toml
[hooks]
exclude_commands = ["curl", "playwright"]  # 这些命令不做改写

[tee]
enabled = true          # 命令失败时保存完整原始输出（默认开启）
mode = "failures"       # "failures" / "always" / "never"
```

**第三步：全局路由规则**（写入 `~/.claude/CLAUDE.md`，节选核心）

```markdown
# Harness 路由规则（团队策略示例，不是 Comet 内置默认）

## 团队约定哪些任务走 /comet
- 新功能、较大 bugfix、重构、跨文件/跨模块改动
- 需要设计、验收、验证、归档的任务
- 恢复 `<classic-root>/changes/*` 已有工作（本项目为 `docs/openspec/changes/*`）

## 团队约定哪些任务可跳过 /comet
- 纯问答、单文件琐碎改动、一行修复、无行为契约的文案调整

## 边界
- Comet 项目里新变更必经 /comet 或 /comet-open，禁止直接 /opsx:new
- 只在当前 workflow/continuation 明确要求的决策点等待用户；不要额外制造确认点
- OpenSpec / Superpowers 在 Classic 中由 Comet 管理；Native 不依赖它们
- 理解工程结构优先用 codegraph_explore，不要逐文件 grep
- 子代理与非 MCP 工具链改用 CLI：codegraph explore "query"（输出与 MCP 工具相同）
- CodeGraph 未命中、文档/配置未索引或索引延迟时，直接读取文件；shell 输出可按需用 RTK
- Caveman 只压缩聊天输出；proposal / design doc / verification report /
  commit message / PR description 必须保持完整语言
```

**第四步：跑一次 Classic 任务**（下面是机制示意，不是我这次的端到端执行日志；跑之前项目默认入口要设成 Classic，或显式调用 Classic 入口）

```text
> /comet 给订单模块加一个导出 CSV 的功能

[Comet] 当前阶段: Open（Classic 五阶段）
[Comet] 已生成 docs/openspec/changes/add-csv-export/
        ├─ proposal.md   变更提案
        ├─ design.md     设计决策
        ├─ tasks.md      任务清单
        └─ specs/        规格文档
[Comet] ⏸ 决策点：等待用户确认 proposal

> （AI 试图提前写实现文件时——Hook 链拦截）
[Hook Router] Write src/orders/export.csv.ts
        → 读 .comet/current-change.json → 路由至 Classic Guard
[Guard] [HARD STOP] Blocked
        原因: 当前阶段 Open，实现写入仅允许 Build / Verify 阶段

> 确认 proposal，进入 Design 阶段

[CodeGraph] codegraph_explore "orders module export interfaces"
        → 返回: OrderService 相关符号逐字源码 + 调用路径 + 影响半径
        → 文件读取: 0 次（替代 grep/Read 探索）

> 设计确认，进入 Build 阶段（TDD：先写失败测试）

[RTK] agent 调用 pytest → 钩子改写为 rtk pytest
        200+ 行输出压缩为:
        FAILED: 2/15 tests
        [full output: ~/.local/share/rtk/tee/1707753600_pytest.log]

[Ponytail] CSV 转义逻辑 → 标准库 csv 模块可做 → 不引第三方依赖

> （会话中断后重开）
> comet status
[Comet] 只读显示当前 change 与阶段；实际恢复走 resume-probe 返回的 nextCommand 或对应永久入口

> 测试全绿，verify-pass → Archive
[Comet] delta spec 已合并回主 spec，归档至 docs/openspec/changes/archive/
```

**日常维护三件套**：`comet status`（只读看状态）、`comet doctor`（体检）、`comet update`（升级）。其中 `comet doctor` 输出最全，可检查安装接线、索引与部分状态；它不能替代真实任务中的阶段拒绝和端到端执行验证。本机实测输出（节选）：

```text
> comet doctor

Comet Doctor (scope: auto)

  ✓ Scope: auto checks project scope first, then global scope when it is different
  ✓ Environment: node v26.7.0; platform darwin/arm64; project <项目根>; global <用户主目录>
  ✓ Comet CLI: installed (0.4.0-beta.20)
  ✓ openspec CLI: installed (1.11.0)
  ✓ Superpowers: detected (Claude Code project, Codex project, WorkBuddy project,
    Antigravity project, Antigravity 2.0 project, Codex global;
    version not recorded by skills installer)
  ✓ Classic artifact layout: docs: configured docs/openspec/ present
  ✓ Classic OpenSpec root: docs/openspec/config.yaml is valid (spec-driven)
  ✓ working directories: present (docs)
  ✓ skills: Claude Code (project): complete (78 files)
  ✓ rules: Claude Code (project): complete (1 files)
  ✓ hook runtime: Claude Code (project): current
  ✓ hooks: Claude Code (project): exactly one managed Router Hook present
  ✓ skills: Codex (project): complete (78 files)
  ✓ rules: Codex (project): complete (1 files)
  ✓ hook runtime: Codex (project): current
  ✓ hooks: Codex (project): exactly one managed Router Hook present
  ✓ skills: WorkBuddy (project): complete (78 files)
  ✓ hook runtime: WorkBuddy (project): current
  ✓ hooks: WorkBuddy (project): exactly one managed Router Hook present
  ✓ scripts present: OK (12 scripts)
  ✓ CodeGraph CLI: CodeGraph CLI is installed
  ✓ CodeGraph project index: CodeGraph index is initialized and current
  ✓ CodeGraph MCP registration: Claude Code: registered; Codex CLI: registered
  ✓ CodeGraph effective for Claude Code: CLI, current project index, and MCP registration are ready
  ✓ CodeGraph effective for Codex CLI: CLI, current project index, and MCP registration are ready
  ✓ current selection: no active Comet change
```

几个值得盯的判据：**「exactly one managed Router Hook present」**——每个平台有且仅有一个 Router Hook，多了少了都说明接线有问题（这正是 2.1 节「入口收敛」的落地检查）；**「CodeGraph effective for …」**——它要求 CLI、项目索引、MCP 注册三者同时就位才算生效，缺一个都不行；另外注意 Superpowers 那行，doctor 只报「detected」并注明 **version not recorded by skills installer**——它不记录版本号，所以想知道版本还得另找来源。Antigravity 这边只出现在 Superpowers 的 detected 列表里，没有 skills/hooks 检查项，与 2.1 节实录中「Antigravity 2.0 未显示 hook」一致。

```bash
comet status      # 只读查看当前阶段与状态，不替代恢复入口
comet doctor      # 检查安装健康、skills、脚本、CodeGraph 索引
comet update      # 更新
```

### 3.4 Codex 实战案例

先把最容易搞混的两件事说清楚，能省掉不少重复劳动：

- **`npm install -g @rpamis/comet` 装的是 CLI，一台机器装一次**，之后所有项目共用，换项目不用重装；
- **`comet init` 是给项目接上 Comet，一个项目目录跑一次**。跑的时候由你勾选要接哪些 coding agent——Claude Code、Codex、WorkBuddy、Antigravity 可以多选，也可以只选一个。这就是「装到哪些 agent 由人决定」的落点。

和 Claude Code 相比，Codex 这边最大的差异在 RTK：Codex 只能用 `AGENTS.md` + `RTK.md` 规则文件（靠模型自觉遵守），不像 Claude Code 有 PreToolUse hook 能强制改写。**我本机现在的状态**是：Claude Code 的 RTK hook 已启用；Codex 侧项目级 `RTK.md` 和 `AGENTS.md` 引用都已就位（2.3 节有实测输出），但全局 `~/.codex/AGENTS.md` 里那条引用指向了错误路径，得手工改。Comet 这边两边都有项目级 `.codex/hooks.json` 与 trust hash，它们提供了 `Write|Edit` 的拦截入口；是否在具体 active change 中拒绝越阶段写入仍待人工审核。Codex 里的入口为 2026-08-29 历史实录：`$comet-native` 可直接敲，`$comet-` 能补全出入口（详见本节第四步）。

**第一步：安装与接线**

```bash
# Comet：CLI 全局装一次；初始化时选 Codex 平台
npm install -g @rpamis/comet
cd your-project
comet init --platform codex           # 也可以不加参数交互多选平台
                                      # --workflow native|classic|both 选工作流
                                      # --codegraph init|skip 决定是否建索引

# RTK：规则文件档接线（项目级）
rtk init --codex                      # 写入项目 RTK.md，并在项目 AGENTS.md 加 @RTK.md 引用
# 坑：全局 ~/.codex/AGENTS.md 里的 @RTK.md 引用可能指向错误路径，需手工修正

# Ponytail（可选）：Codex 插件
codex plugin marketplace add DietrichGebert/ponytail
codex plugin add ponytail@ponytail
# 装完运行 codex，打开 /hooks，审核并信任插件自带的 lifecycle hooks
```

**Codex 侧的实际安装过程**（本机历史实录，和 Claude Code 的交互方式不同；插件安装后仍需在 `/hooks` 审核捆绑 hook）：

```text
> codex plugin marketplace add DietrichGebert/ponytail
Marketplace `ponytail` is already added from https://github.com/DietrichGebert/ponytail.git.
Installed marketplace root: ~/.codex/.tmp/marketplaces/ponytail

> codex plugin add ponytail@ponytail
Added plugin `ponytail` from marketplace `ponytail`.
Installed plugin root: ~/.codex/plugins/cache/ponytail/ponytail/4.9.0
```

装完用 `codex plugin list` 复查，当前 Codex 状态是 `ponytail@ponytail  installed, enabled  4.9.0`。还有一步：**插件自带的三组 lifecycle hooks 需要在 `/hooks` 里逐个审核信任**，否则会被直接跳过（官方文档原话：装插件不会自动信任它捆绑的 hook）。下面的 `/hooks` 数字是安装后的历史截图；当前是否仍显示同样的三列状态【待人工审核】。

**第二步：CodeGraph 的 MCP 配置**

Codex 的 MCP server 写在 `~/.codex/config.toml`（安装器自动写入，与官方 README 给 Claude 的配置等价）：

```toml
[mcp_servers.codegraph]
command = "codegraph"
args = ["serve", "--mcp"]
```

**第三步：规则作用域**。团队约束优先写项目 `AGENTS.md`，个人全局默认才写 `~/.codex/AGENTS.md`。我这个项目的 `<comet-ambient-resume>` 托管块和 Ponytail 规则都在项目 `AGENTS.md` 里；CodeGraph 的 marker 段有没有，取决于你有没有跑过它的安装器——别把两者当成同一个文件里必然同时存在的东西。

```markdown
# Harness 路由规则（项目 AGENTS.md 或用户级 AGENTS.md，按作用域选择）

- 新功能 / 重构 / 跨文件改动 → 团队策略可要求走 $comet；Comet 入口仍按项目配置选 Native/Classic
- 理解工程结构优先 codegraph_explore，不要逐文件 grep
- 执行命令后若需完整输出，读 RTK tee 日志，不要重跑命令
- 本文件中的 <comet-ambient-resume> 块与 CodeGraph marker 段为工具托管，勿手改
```

**第三步半：Codex 的 Hook 写拦截——官方机制 + 本机落盘 + 信任**

先说机制。Codex 官方文档（<https://learn.chatgpt.com/docs/hooks>；老地址 `developers.openai.com/codex/hooks` 会 301 跳过去）把 Hooks 定义为 **"an extensibility framework for Codex"**——允许你在 agent 主循环的固定切面上挂自己的脚本或 MCP 工具。几个要点：

- **11 个事件切面**：一轮对话内的 `PreToolUse` / `PermissionRequest` / `PostToolUse` / `PreCompact` / `PostCompact` / `UserPromptSubmit` / `SubagentStop` / `Stop`；会话或子代理启动时的 `SessionStart` / `SubagentStart`；主线程结束时的 `SessionEnd`；
- **matcher 按正则过滤**：`PreToolUse` 过滤的是工具名。官方文档里有一句关键注解——**对 `apply_patch`，matcher 值也可以写成 `Edit` 或 `Write`**。这正是 Comet 落盘里 `Write|Edit` 的来历：它不是 Comet 自造的写法，而是 Codex 写文件工具的标准匹配名。另外 `UserPromptSubmit` 和 `Stop` 不支持 matcher，配了也会被忽略；
- **stdin / stdout 双向协议**：每个 command hook 从 stdin 收到一个 JSON（含 `session_id`、`cwd`、`hook_event_name`、`model`，以及 `tool_name` / `tool_input` 等事件专属字段），往 stdout 写决策。`PreToolUse` 用 `permissionDecision: "deny"` 拒绝（legacy 的 `decision: "block"` 也接受，退出码 2 同理）；`PostToolUse` 用 `decision: "block"` 加 `additionalContext` 把反馈塞回模型；
- **信任门禁**：非受管 hook 首次运行前必须审查并信任，信任按 hook 内容的 **hash** 记录——脚本一改 hash 就变，重新进审查队列。CLI 里用 `/hooks` 查看和信任，一次性自动化可以加 `--dangerously-bypass-hook-trust`；企业能通过 `requirements.toml` 下发受管 hook，默认按策略信任；
- **多来源全部加载，不互相覆盖**：`~/.codex/hooks.json`、`~/.codex/config.toml`、`<项目>/.codex/hooks.json`、`<项目>/.codex/config.toml` 是最常用的四个位置，命中的 hook 全部执行，同一事件的多个 command hook 并发启动。注意项目级 hook 只在 `.codex/` 层被信任时才加载；
- **timeout 默认 600 秒**（`SessionEnd` 是例外：默认 1 秒、上限 3 秒）；handler 分 `command` 和 `mcp_tool` 两种，加 `async: true` 可以丢到后台跑。想整体关掉就设 `[features] hooks = false`（`codex_hooks` 是它的 deprecated alias）。

最小配置长这样（官方形状）：

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "^Bash$",
        "hooks": [
          { "type": "command", "command": "python3 ~/.codex/hooks/pre_tool_use_policy.py", "timeout": 30, "statusMessage": "Checking Bash command" }
        ]
      }
    ],
    "PostToolUse": [
      { "matcher": "^Bash$", "hooks": [ { "type": "command", "command": "python3 ~/.codex/hooks/post_tool_use_review.py", "timeout": 30 } ] }
    ]
  }
}
```

**本机落盘（Codex CLI v0.150.1）**：`comet init` 在 Codex 上会自动写项目级 `.codex/hooks.json`，不需要手工接线。当前文件里没有显式 `timeout`，超时走宿主默认值：

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "node \"<项目根>/.agents/skills/comet/scripts/comet-hook-router.mjs\" --platform \"codex\" --project-root \"<项目根>\""
          }
        ]
      }
    ]
  }
}
```

（路径用 `<项目根>` 占位；落盘原文是安装时项目的真实路径。）对照上面的官方机制看，两个关键字段一目了然：

- **Matcher `Write|Edit`**——就是官方说的 apply_patch 匹配名写法，两个写文件工具一并匹配；
- **router 带平台参数**：`--platform "codex" --project-root "<项目根>"`——同一个 router 脚本服务所有平台，靠参数区分平台和项目边界。

**信任界面**（首次运行时出现过，之后 trust hash 持久化）：

```text
  PreToolUse hooks
  1 hook needs review before it can run. 选择信任即可。

  [!] Hook 1 · new

  Event     PreToolUse
  Matcher   Write|Edit
  Source    Project config - <项目根>/.codex/hooks.json
  Command   node "…/.agents/skills/comet/scripts/comet-hook-router.mjs" --platform "codex"
            --project-root "…"
  Mode      Sync
  Timeout   600s
  Trust     New hook - review required

  Press t to trust; esc to go back
```

现在本机 `config.toml` 里已经存了对应的 `trusted_hash`，说明这个 hook 过了审查。脚本内容一变（比如升级 Comet 导致 router 更新），下次启动会重新要你确认。

**`/hooks` 全景长什么样**（2026-08-29 实测）。在 Codex 里输入 `/hooks`，看到的是一张总表，把「装了什么、哪些在跑、哪些等你审」一次列全：

```text
Hooks
  Lifecycle hooks from config and enabled plugins.

  ⚠ 3 hooks need review before they can run.

  Event                 Installed   Active      Review      Description
  PreToolUse            1           1           0           Before a tool executes
  PermissionRequest     0           0           0           When permission is requested
  PostToolUse           0           0           0           After a tool executes
  PreCompact            0           0           0           Before context compaction
  PostCompact           0           0           0           After context compaction
  SessionStart          1           0           1           When a new session starts
  SessionEnd            0           0           0           Right before a session ends
  UserPromptSubmit      1           0           1           When the user submits a prompt
  SubagentStart         1           0           1           When a subagent is created
  SubagentStop          0           0           0           Right before a subagent ends its turn
  Stop                  0           0           0           Right before Codex ends its turn
  Interrupt             0           0           0           Right before an interrupted turn is aborted
```

这张表一次说清了三件事：

- **Comet 的写拦截在跑**：`PreToolUse` 那行是 Installed 1 / **Active 1** / Review 0——装了、激活了、不用再管；
- **Ponytail 的三组 hook 全在等你审**：`SessionStart`、`UserPromptSubmit`、`SubagentStart` 三行都是 Installed 1 / **Active 0** / **Review 1**（这张截图是刚装完、还没审的状态，顶部那行 `⚠ 3 hooks need review` 也在提示这一点）。它们正好对应 2.4 节那个 hooks 文件里的三组事件，一个不差。**没审之前会被直接跳过——插件装完了，但「always-on 激活」其实还没发生。** 三列数字的关系就是 `Installed = Active + Review`：装了不等于在跑。

  怎么确认自己到底审没审过？**看 `~/.codex/config.toml` 里有没有对应的 `trusted_hash`**，比看 UI 更可靠。我这边审完之后，三组 hook 各落了一条记录（格式见 2.4 节），至此 Ponytail 的 always-on 才真正生效；
- **界面比文档多一个事件**：官方文档列了 11 个，实际界面是 **12 行**，多出一个 `Interrupt`（一轮对话被中断前触发）。文档没提它，但界面里确实存在。

顺带一提，Codex CLI 本身是开源的，仓库在 <https://github.com/openai/codex>；上面这些机制的 wire schema 官方指向仓库里的 `codex-rs/hooks/schema/generated`（注意 main 分支的 schema 可能包含当前 release 还没支持的字段）。

**第四步：实际运行**

```bash
# 新任务
codex
> $comet 给订单模块加一个导出 CSV 的功能
# （Comet 状态机接管：Open → Design → Build → Verify → Archive，
#   RTK 靠 AGENTS.md 里的规则指引，Ponytail 阶梯约束生成；
#   Codex 的 skill 触发语法是 $comet，不是 Claude Code 的 /comet）

# 会话中断后恢复
codex resume                   # Codex 侧恢复会话
# Comet 侧的恢复探测：
#   comet resume-probe 返回 auto_resume / ask_user / out_of_scope / none，
#   并按项目配置路由到对应工作流入口（Claude Code：/comet-native 或
#   /comet-classic；Codex：$comet 展开的对应入口）
```

**Codex 里的 Comet 入口清单**（2026-08-29 实测）。先直接回答那个悬着的问题——**`$comet-native` 可以直接调用**：

```text
› $comet-native
  Comet Native  [Skill] Comet Native workflow
```

再输入 `$comet-` 看自动补全，会把全部入口一次列全：

```text
› $comet-

  Comet Any / Skill Creator     [Skill] 创建或升级 Comet Classic workflow Skill
  Comet Classic                 [Skill] Comet Classic workflow:OpenSpec + Superpowers
  Comet Classic 阶段 1:Open     [Skill] 开启 OpenSpec change 并建立其产物
  Comet Classic 阶段 2:Design   [Skill] 为 change 产出深度技术 Design Doc
  Comet Classic 阶段 3:Build    [Skill] 恢复或创建实施计划并执行其任务
  Comet Classic 阶段 4:Verify   [Skill] 验证 change、记录证据并驱动修复循环
  Comet Classic 阶段 5:Archive  [Skill] 确认归档、合并 delta spec 并完成分支收尾
  Comet Classic 预设:Hotfix     [Skill] 通过 open-build-verify-archive 短流程修复已有行为 bug
  Comet Classic 预设:Tweak      [Skill] 处理可收敛为单一 OpenSpec change 的轻量或中等变更
  Comet Native                  [Skill] Comet Native workflow
  Comet 手动代码审查            [Skill] 只读审查当前 change，不推进工作流
```

三个要点：

- **`$comet-native` 和 `$comet` 都能直接敲**，不用先展开菜单再选；
- **Hotfix 和 Tweak 的真实名字是「Comet Classic 预设:Hotfix / Tweak」**——它们是 Classic 的预设档，不是 `comet-hotfix` 这样的独立前缀。想在 Codex 里用，输入 `$comet-` 从菜单里选，别照着 Claude Code 的 `/comet-hotfix` 硬套；
- 菜单里还多出一个 Claude Code 侧没提过的 **「Comet 手动代码审查」**（只读审查当前 change，不推进工作流），以及别的插件混进来的 skill（我这儿出现了 `control-chrome`）——`$` 补全列的是**所有已安装 skill**，不只有 Comet 的。

**`$` 和 `@` 不是一回事**（实测对比，这是 Codex 里最容易搞混的一组前缀）。同样拿 Ponytail 试：

```text
› $ponytail

  ponytail                   [Skill] Forces the laziest solution that actually works…
  ponytail (ponytail)        [Skill] Forces the laziest solution that actually works…
  ponytail-audit             [Skill] Whole-repo audit for over-engineering…
  ponytail-audit (ponytail)  [Skill] Whole-repo audit for over-engineering…
  ponytail-debt              [Skill] Harvest every `ponytail:` comment into a debt ledger…
  ponytail-debt (ponytail)   [Skill] Harvest every `ponytail:` comment into a debt ledger…
  …
```

```text
› @ponytail

  Ponytail         Lazy senior developer mode                         Plugin
  ponytail         Forces the laziest solution that actually works…   Skill
  ponytail-audit   Whole-repo audit for over-engineering…             Skill
  ponytail-debt    Harvest every `ponytail:` comment into a ledger…   Skill
  ponytail-gain    Show ponytail's measured impact as a scoreboard…   Skill
  ponytail-help    Quick-reference card for all ponytail modes…       Skill
  ponytail-review  Code review focused exclusively on over-engineering…  Skill
  ponytail         .agents/skills/                                    Dir

› @ponytail-review
  ponytail-review  Code review focused exclusively on over-engineering…  Skill
  ponytail-review  .agents/skills/                                       Dir
  SKILL.md         .agents/skills/ponytail-review/
```

两个结论：

- **`$` 是执行，`@` 是引用**。输入 `@ponytail` 时，菜单里除了 skill，还会列出插件本体（标 `Plugin`）、`.agents/skills/` 目录（标 `Dir`），再往下钻还会出现 `SKILL.md` 文件——它是 Codex 的**资源引用**入口，作用是把文件或目录挂进上下文。想让 agent 进入 Ponytail 模式干活，用 `$ponytail`；想让它把 skill 的源码读一遍，用 `@`。所以官方 README 那句「Codex 里用 `@` 前缀调用」，按实测更准确地说是**引用**而非执行；
- **每个 skill 都出现了两次**。一次是项目里已有的 `.agents/skills/` 版本，一次是刚装进来的插件版本（括号里带 `ponytail` 命名空间）。项目里本来就有 Ponytail skills 时，装插件不会覆盖它，而是两套并存，调用时可按命名空间区分。

**双平台当前差异**：Claude Code 的 RTK Bash hook 已启用（强制改写）；Codex 的项目级 RTK 规则已接上，但靠模型自觉。Comet Router 两边的配置里都在，不过我没做完整的阶段写入对照实验。**Ponytail 两边都装上了，但版本和作用域并不完全相同**——Codex 显示 `installed, enabled 4.9.0`；Claude Code 同时有 user scope 4.7.0 与 local scope 4.9.0，最终生效优先级【待人工审核】。Codex 侧必须去 `/hooks` 逐个审，当前 `config.toml` 里三组各有 `trusted_hash` 落盘；这证明已受信任，不单独证明每个当前会话都在执行。Claude Code 侧的 hook 加载与版本选择仍应以宿主实际状态为准【待人工审核】。

### 3.5 一次任务的生命周期走读（含中途断电恢复）

拿「给订单模块加一个导出 CSV 的功能」串一遍。

**第 0 步·路由判断**。团队规则可以规定新功能、跨文件改动必须进 Comet，琐碎任务直接做。这是 Harness 层的策略——Comet Runtime 不会按任务大小自动换 workflow。进了 Comet 之后走 Native 还是 Classic，仍然由项目配置决定。

**第 1 步·Open（Classic）或 Shape（Native）**。Classic 下 OpenSpec 生成 proposal / design / tasks / specs 四件套；Native 下 Shape 澄清需求、写 brief 和目标规格。要不要停下来等你确认、还是自动往下走，取决于当前 workflow、Runtime continuation 和项目配置——不是每个阶段都必然有人工确认点。

**第 2 步·Design / 进入 Build 前**。Classic 完整流程里由 Superpowers 的 brainstorming 接管；Hotfix/Tweak 各有自己的缩短路径。这时候 CodeGraph 可以一次探索拿到订单模块的接口和调用链，但查询也可能为空、有歧义，或者带进一堆无关符号，必要时就回退直接读文件。−88% 和文件读取归零是官方 benchmark 的说法，不是每次查询的保证。

**第 3 步·Build**。按 change 选择 direct、executing-plans 还是 subagent-driven-development；TDD 也可能选 `tdd` 或 `direct`，不是所有路径都强制。Claude Code 的 Bash 命令会被 RTK hook 改写，Codex 这边则要看规则有没有接上。写代码时套用 Ponytail 阶梯；开了 Context Compression 就用 Comet 生成的交接包。

**第 4 步·Verify**。验证门强制校验：测试全绿 + tasks 勾完 + 设计目标达成，而且 verification report 必须真实存在——这些由脚本校验，缺一样都进不了下一阶段（Native 下由独立只读 Verifier 把关）。测试挂了？RTK 的 tee 日志里有完整输出，让子代理自己去翻，别重跑命令。

**第 5 步·Archive**。Classic 按增量 spec 语义合并回主 spec；Native 用自己的 archive transaction。两边的状态文件也不是同一套。

**中途断电怎么办？** 重开会话先跑一次只读的 `comet resume-probe . --stdin --json`：返回 `auto_resume` 就顺着它给的 `nextCommand` 继续，返回 `ask_user` 就选一个 change。`comet status` 只负责查看，不是恢复入口。我这个项目目前没有 Ponytail 的 nudge/PostToolUse hook，只有项目级 skills 和 `AGENTS.md` 规则。

### 3.6 路由门禁与协同边界

整合的关键不在装了什么，而在**规则**。四条核心边界：

**路由门禁——团队推荐什么时候走 Comet**（不是 Runtime 按规模自动切换）：

| 推荐走 /comet    | 通常可跳过 /comet   |
| ------------- | -------------- |
| 新功能           | 纯问答            |
| 较大 bugfix     | 单文件琐碎改动        |
| 重构            | 一行修复           |
| 跨文件/跨模块改动     | 无行为契约的小文案/格式调整 |
| 需要设计、验收、验证、归档 |                |

**Ponytail 边界——不可省略清单**：安全检查、信任边界的数据校验、错误处理、数据丢失保护、无障碍要求、必要的可观测性、保护真实行为的测试。Ponytail 能让代码更小，但不能替你跳过 Comet 的阶段门或省掉验证；是否强制 TDD 由当前 change 的 `tdd_mode` 决定。

**Caveman 边界——绝不压缩落盘产物**：proposal、design doc、spec、tasks、implementation plan、verification report、archive notes、commit message、PR description 必须保持完整语言。遇到安全警告、不可逆操作确认、用户决策点、验证失败时自动暂停。

**CodeGraph 边界**：MCP guidance 和项目指令能覆盖到哪些 agent，取决于宿主；子代理可以用 `codegraph explore` CLI，也可以在未命中、索引延迟或文档/配置场景回退直接读取。那个 +80% 是上游特定 benchmark 的残留上下文口径，不是固定值。

### 3.7 收益与限制（诚实版）

**收益**（都是各项目官方口径，叠起来之后的综合效果没有独立基准）：

| 维度    | 工具        | 官方声明                                                                                                         |
| ----- | --------- | ------------------------------------------------------------------------------------------------------------ |
| 流程可靠性 | Comet     | 双工作流状态机 + 阶段守卫 + 可恢复状态；上游 Native vs Classic benchmark 报告 Token −76.8%、轮次 −57.4%、耗时 −47.4%、pass^3 87.5%，非本机复测 |
| 探索成本  | CodeGraph | 上游 7 仓库 benchmark 报告工具调用 −88%、token −62%、成本 −44%、文件读取归零；2026-08-29 历史对照记录为 96.7%–99.2%【待人工审核】（口径不同，不可直接比较）                   |
| 执行输出  | RTK       | 上游宣称测试日志最多约 −90%；本机验证 `154/154` 自测通过，未做原始输出对照                                                                |
| 代码量   | Ponytail  | 上游报告平均 −54% 等数据；本机只验证 root suite `84/84`，没测过自己项目的代码量收益                                                       |
| 聊天输出  | Caveman   | 上游报告 Skill/Proxy 节省数据；本机只有项目 skill 文件，没有独立 benchmark                                                        |

**限制与风险**（认真读）：

1. **组合没有联合基准**。五个工具各有官方数据，叠起来会怎样没人测过。它们理论上正交，但 Ponytail 砍代码量和 Superpowers 的 TDD 全面性之间存在张力——一个求少、一个求全，靠边界规则调和，不会自动平衡。
2. **规则档工具的采纳率要打折**。我这台机器上 Claude Code 有 RTK Bash hook（强制改写），Codex 只有规则（靠模型自觉）。CodeGraph 有 MCP 和规则指引，但用不用仍取决于查询命中和 agent 当时的判断。
3. **Caveman 的净收益可能为负**。简洁任务 + 长会话里，规则自身每轮约 1–1.5k 输入 token 的成本可能吃掉节省。所以设为可选、按需触发。
4. **CodeGraph 的上下文残留**。官方明示多轮会话约 +80% 检索上下文残留——检索省了，窗口更满，长会话可以考虑配合压缩策略。
5. **维护成本是真实的**。我这台机器上跑的是 Comet `0.4.0-beta.20`、OpenSpec `1.11.0`、CodeGraph `1.6.0`、RTK `0.45.0`、Codex `0.150.1`、Superpowers plugin manifest `6.3.0`、Ponytail `4.9.0`（插件 manifest）；上游 benchmark 可能是别的版本跑出来的。另外全局规则本身就是一份需要维护的配置资产。
6. **BSL-1.1 许可警示**。Caveman 的 Proxy/Engine 用的是 BSL-1.1（非 OSI 开源），商用集成前需经法务确认。

---

## 四、数据核验与说明

原始资料以各项目 README / 官方博客为一手数据源，本轮复核则优先用本机 CLI、配置和实测。可信度分三级：**A = 我在这台机器上能复现**；**B = 项目官方自述、我没独立复测**；**C = 历史记录或二手来源**。

顺便更正上一版的一处错误：之前写「OpenAI 官方文档因网络不可达」，当时判断包含 URL 错误。2026-08-29 的历史记录显示老地址 `developers.openai.com/codex/hooks` 曾跳到 `learn.chatgpt.com/docs/hooks`；本轮（2026-08-31）因 DNS 不可达，无法重新验证跳转、正文或当前可达性【待人工审核】。因此下文把官方机制和本机行为分开记录，不把历史访问结果写成当前事实。

### 4.1 本机验证（macOS 26.4；基线采集 2026-08-29，本轮复查 2026-08-31）

| 验证项               | 当前结果                                                                                                        |
| ----------------- | ----------------------------------------------------------------------------------------------------------- |
| 环境                | macOS 26.4（Build 25E246）                                                                                    |
| Comet             | `0.4.0-beta.20`；默认入口 Native；Native/Classic 均无 active change                                                |
| Comet roots       | Native `docs/comet`；Classic `docs/openspec`；Superpowers `docs/superpowers`                                   |
| Comet 配置        | `default_workflow: native`；Classic `artifact_layout: docs`；`context_compression: off`（默认关闭，未启用压缩）      |
| Comet health      | `comet doctor . --json` PASS；Codex/Claude/WorkBuddy 各一个 managed Router Hook                                 |
| OpenSpec          | `1.11.0`；Classic adapter 可调用                                                                                |
| Codex CLI         | `0.150.1`；项目 `.codex/hooks.json` 已注册 `Write\|Edit` Router，trust hash 存在                                     |
| Codex Hook 官方文档   | 2026-08-29 历史记录曾核对 <https://learn.chatgpt.com/docs/hooks>；本轮因 DNS 不可达未能复验 11 个事件、matcher、timeout 或跳转【待人工审核】 |
| Codex `/hooks` 界面   | 2026-08-29 安装后历史截图：Comet 的 `PreToolUse` 为 `Installed 1 / Active 1 / Review 0`；Ponytail 三组为 `Installed 1 / Active 0 / Review 1`。本轮通过 `config.toml` 确认三组 Ponytail `trusted_hash` 均存在，但未重新打开界面【待人工审核】 |
| CodeGraph         | `1.6.0`；49 files、17,740 nodes、65,626 edges，索引 current；Codex/Claude MCP 已注册                                 |
| CodeGraph CLI 实测  | 2026-08-29 历史对照记录为 96.7% / 99.1% / 99.2%（本仓库含压缩 `.mjs`，属有利场景）；未保存可运行的统计脚本【待人工审核】 |
| RTK               | `0.45.0`；`rtk verify` 为 154/154；Claude Bash hook 已启用；`rtk init --codex` 已执行，项目 `RTK.md` + `AGENTS.md` 引用就位 |
| Ponytail          | Codex 插件 **4.9.0**，installed & enabled；6 skills + 6 commands + 3 组 lifecycle hooks；root suite 84/84。Claude Code 同时存在 user scope 4.7.0 与 local scope 4.9.0，最终优先级【待人工审核】。Codex 三组 hook 的 `trusted_hash` 均已写入，表示已受信任；当前会话是否全部执行仍需宿主界面确认 |
| Caveman           | 项目 skill 存在；无独立测试套件                                                                                        |
| Comet Eval        | 命令存在，但 sandbox 下因无法创建 `~/.comet/eval` 未完成执行验证                                                              |

上面这些 A 级结论，证明的是「这台机器、这个项目、这个版本」的状态——它不代表上游 benchmark 成立，也不保证下一个版本行为一致。

### 4.2 上游声明与来源

这一节汇总正文引用过的上游资料，按项目分组。三档含义与 4.1 保持一致：**A = 本轮本机可复现**；**B = 项目官方 README / 文档或博客明确声明，但我没有独立复测**；**C = 历史记录或二手转载**。同一事实若既有本机证据又有上游声明，以本机证据单独列在 4.1，不因“官方写过”自动升为 A。

**Comet**

| 声明                                                                                          | 级别  | 依据                                                             |
| ------------------------------------------------------------------------------------------- | --- | -------------------------------------------------------------- |
| 双工作流：Native 四阶段 / Classic 五阶段；Native 不依赖 OpenSpec/Superpowers/Bash/WSL                      | B   | 官方 README                                                      |
| `comet init` 支持 35 个 AI 编码平台（原始材料写的 29 是错的）                                                  | B   | README 原文「`comet init` supports 35 AI coding platforms」         |
| 评测：Token −76.8%、轮次 −57.4%、耗时 −47.4%、pass^3 87.5%、pass@3 100%                               | B   | README 自述的 Native vs Classic 对齐实验（16 任务 × 48 次，取 41 对双方通过样本） |
| Context Compression：Build 输入 −25~30%、测试通过率 100%、大任务约 15,000 tokens；代价是 Spec 覆盖率 100%→95%     | B   | README 的 Context Compression 章节                                |
| Runtime 布局：Native 产物 `docs/comet/`（可改 `native.artifact_root`）+ 机器态 `.comet/runtime/native/`；Classic `<classic-change-dir>/.comet.yaml` + `run-state.json` + `state-events.jsonl`；共享 `.comet/config.yaml` 与 `current-change.json` | B   | README 原文印证 + 官方文档补充；本项目根路径见 4.1                         |
| Hook 机制：每平台一个 Rule + 一个 Router；一次写至多到一个 Guard、fail closed；Native 仅 Build 可写实现、Classic 为 Build+Verify | B【待人工审核】 | README 的 Guard & Automation Scripts 脚本表 + Classic Reliability 第 7 条；本机尚未完成阶段拒绝对照 |
| `hook.allow_paths` 为当前共享写策略字段（项目相对白名单，不能绕过 `.comet` 与产物根）                                     | B【待人工审核】 | README 原文；前缀匹配、子目录继承、越界由 `comet doctor` 报告三条尚未在本机复验 |
| 双平台联动：各平台独立 skills 目录、每平台一个 Rule、`<comet-ambient-resume>` 托管块                               | B（部分 A）   | README Supported Platforms 表 + resume-probe + 项目结构章节；Codex / WorkBuddy 自动装 Router hook 已在本机配置中确认 |

**CodeGraph**

| 声明                                                                | 级别  | 依据                                    |
| ----------------------------------------------------------------- | --- | ------------------------------------- |
| Rust 内核 20 语言、总支持 34 语言、9 类 Agent、MCP 单工具哲学                        | B   | 官方 README                             |
| 上游基准：工具调用 −88%、速度 +53%、token −62%、成本 −44%、文件读取归零                  | B   | README 自述（7 个指定仓库 × 4 次运行取中位数）         |
| 上下文残留 +80%                                                        | B   | README 的诚实声明（多轮会话实测）                   |
| 性能：Swift 仓库 27k 文件 ~100s、Linux 内核 <12min（2 核 VPS）、再索引快 2–7×        | B   | README 性能参考（31 仓库、30 语言基准）              |
| CLI 模式：`codegraph explore` 输出与 MCP 工具相同；安装器写 marker 段教子代理用 CLI      | B【待人工审核】 | README 的 CLI Reference 与 Quick Start 节；本机未逐项复测 CLI/MCP 输出等价性 |
| 配置格式（`~/.claude.json` 的 mcpServers、`settings.json` 的权限通配符）        | B   | README 的 Manual Setup 节                 |

**Codex CLI 与 Hook**

| 声明                                                                        | 级别  | 依据                                                     |
| ------------------------------------------------------------------------- | --- | ------------------------------------------------------ |
| 11 个事件、stdin/stdout 协议、matcher 语义、timeout 默认 600s、managed hook、`codex_hooks` deprecated alias | B【待人工审核】 | 官方文档 <https://learn.chatgpt.com/docs/hooks>；本轮网络不可达，未能复验页面或跳转 |
| `/hooks` 界面实际显示 12 行，比文档多一个 `Interrupt`                                   | C【待人工审核】 | 2026-08-29 历史实录；本轮未重新打开界面                                                   |
| `$` 是执行、`@` 是引用；`$comet-native` 可直接调用；Hotfix/Tweak 菜单名为「Comet Classic 预设:Hotfix / Tweak」 | C【待人工审核】 | 2026-08-29 历史实录；本轮未重新执行交互                                                   |

**RTK**

| 声明                                                     | 级别    | 依据                                       |
| ------------------------------------------------------ | ----- | ---------------------------------------- |
| 机制四板斧、tee 保险、削减表、稀释声明、bytes/4 估算、config.toml 格式        | B     | 官方 README                                |
| crates.io 同名包（Rust Type Kit）安装坑                        | B     | 官方 README 确认                             |
| 全称「Rust Token Killer」                                   | B（弱）  | README 徽标 alt 文本；正文自称 "CLI proxy"，未在正文正式声明 |
| ~77,200 star / 4,850 fork / 创建于 2026-01-22 / v0.45.0    | C     | 公众号转载，数值动态变化（见 4.3 第 1 项）                 |

**Ponytail**

| 声明                                                                        | 级别  | 依据                                                   |
| ------------------------------------------------------------------------- | --- | ---------------------------------------------------- |
| 7 层阶梯、6 个 skill、4 档强度、20 个 agent 宿主、「never fewest tokens」、「lazy, not negligent」 | B   | 官方 README                                            |
| 插件自带 3 组 lifecycle hooks（`SessionStart` / `SubagentStart` / `UserPromptSubmit`）  | A   | 直读插件安装目录的 `hooks/claude-codex-hooks.json` 与 manifest     |
| 双侧安装命令与实际安装过程                                                             | 混合【待人工审核】 | README 原文 + 本机当前插件状态；完整安装过程为历史实录                                    |
| agentic 基准：LOC −54% / token −22% / cost −20% / time −27% / safe 100%       | B   | README（Haiku 4.5 无头会话）；−94% 为过度构建峰值，issue #126 已澄清为「会话基线伪影」 |

**Caveman**

| 声明                                                                            | 级别          | 依据                                    |
| ----------------------------------------------------------------------------- | ----------- | ------------------------------------- |
| 双产品架构与许可拆分（MIT Skill + BSL-1.1 Proxy）                                          | B           | 官方 README                             |
| Skill 输出节省：10 任务平均 1214→294 token、任务级平均 65%（22%–87%）；Proxy 输入 −33.2%          | B           | README 自述基准（Proxy 为 54-run、18 项精确检查全过） |
| 诚实警告：每轮 +1–1.5k 输入 token、净收益可能为负、真收益是速度与可读性                                   | B           | README 原文                             |
| 第三方实测「创意网页代码量 +18.9%」                                                         | C           | 第三方对比数据，非官方，引用前请自行复核                   |

**OpenSpec / Superpowers**

| 声明                                                              | 级别  | 依据                 |
| --------------------------------------------------------------- | --- | ------------------ |
| OpenSpec：`/opsx:propose` 主入口、Stores beta、30+ 工具、Node 20.19+      | B   | 官方 README          |
| Superpowers：14 个平台与核心 skills 库                                   | B   | 官方 README          |
| Superpowers 6.0 自优化过程（−10% / +15% / $165 / −41%）、thinking token 反直觉发现 | B   | 官方博客 blog.fsck.com |
| Superpowers "up to 50% faster / up to 60% cheaper"               | B   | 官方博客口径（注意 up to 是上限） |

**版本与可达性**

| 声明                                                                                                                                        | 级别         | 依据                                                                                          |
| ----------------------------------------------------------------------------------------------------------------------------------------- | ---------- | ------------------------------------------------------------------------------------------- |
| 7 个项目仓库 + Codex CLI 仓库在 2026-08-29 的历史记录中可访问                                                                                              | C【待人工审核】 | 2026-08-29 记录为 curl HTTP 200；本轮 DNS 不可达，未能复验当前可达性                                                           |
| 各组件版本：Comet `0.4.0-beta.20` / OpenSpec `1.11.0` / CodeGraph `1.6.0` / RTK `0.45.0` / Codex CLI `0.150.1` / Superpowers `6.3.0` / Ponytail `4.9.0` / Caveman `v2.3.1` | 混合（见依据）   | Comet/OpenSpec/CodeGraph/RTK/Codex/Ponytail 有本机或安装目录证据；Superpowers 来自官方发布页；Caveman `v2.3.1` 来自安装命令 URL tag，未在本机独立验证【待人工审核】 |

**几个容易被记错的数**（网上流传的版本常写错，顺手记在这里）：Comet 支持 **35** 个平台（不是 29）、OpenSpec 支持 **30+** 种工具（不是 21）、Ponytail 的决策阶梯是 **7** 层（不是 6 层，漏掉的是第 2 层「代码库里已经有了吗」）。

**关于文中的演示代码**：3.3 / 3.4 的会话流是机制示意，不是端到端执行日志；3.4 的 hooks.json 是 2026-08-29 的当前落盘，信任界面则是 2026-08-27 的实录。

### 4.3 时效性信息清单

文中「我这台机器上跑出来的」结论，只对**当时的版本、当时的项目**成立。下面几类信息时效性较强——版本号、仓库统计、宿主相关的口径等都会随时间变化，如需引用，请以最新来源为准：

| #   | 项目                                 | 核对来源                                                               | 变动原因                                                                         |
| --- | --------------------------------- | ------------------------------------------------------------------ | ---------------------------------------------------------------------------- |
| 1   | RTK 的 star / fork / 创建日期 / 最新版本号 | GitHub 项目页与 Releases                                             | 统计数值每日变动；官方 README 内部版本号本身就不一致（0.28.2 vs v0.37.2+），只能以 Releases 为准   |
| 2   | CodeGraph CLI 与 MCP 的输出差异         | 官方未发布对照数据；如需具体数值，可在目标仓库上同一查询两边各跑一次对比                            | 输出细节与计数口径随宿主、查询、仓库而异，不存在可照搬的通用比例                                        |
| 3   | Caveman 的默认触发策略                   | 官方 README 的 Honest number warning 章节                             | 是否默认开启取决于任务类型；官方承认简洁任务上净收益可能为负——规则每轮约消耗 1–1.5k 输入 token       |
| 4   | Ponytail 三组 hook 的启用状态             | `~/.codex/config.toml` 的 `hooks.state` 是否写入 `trusted_hash`        | 装插件不等于激活；该字段是信任动作的直接产物，比 UI 显示更稳定（UI 状态与截图时点相关）                     |

除上述四项外，正文还混有三类证据，不能统称“本次实测”：

- **本轮可复现**：Comet `doctor/status/root`、当前配置与项目 hooks、CodeGraph 索引状态、RTK `verify`、Ponytail Codex 插件 manifest / trust hash、Caveman 项目 skill 存在；
- **历史实录**：Codex 侧 `$comet-native` 与 `$` 自动补全入口、Hotfix/Tweak 菜单名、`/hooks` 界面数字、CodeGraph 三组字节对照、2026-08-29 的仓库 HTTP 200 结果；
- **上游声明**：Comet 支持 35 个平台、Context Compression 的 25–30% 与 95% 覆盖率代价、`hook.allow_paths` 细节、Runtime 双套布局、各项目 benchmark。

历史实录或本轮无法重跑的行为统一保留【待人工审核】。

---

## 结语

回到开头的五个问题，这套 Harness 的本质是一次分工明确的权力制衡：

- **上下文工程**：CodeGraph 把探索成本前置成索引（AI 想乱翻文件，不如查图；代价是残留变多，需一起管理）；RTK 把执行噪音挡在上下文外（想读 200 行日志，只给 20 行）；Caveman 把废话挡在终端里（想客套，电报体伺候）；
- **工具的设计**：一个强工具胜过一堆窄工具（CodeGraph）、改写胜过说教（RTK）、一个入口胜过一堆 hooks（Comet）；
- **状态和记忆**：SDD 把规范立为唯一真相、代码降为实现产物——变更先改 spec 再动代码，四件套与 delta 归档让需求可回溯、可跨会话、可沉淀；
- **验证回路 + 评测集**：verify-pass 证据门 + 独立 Verifier 让「说完成了」变成「证明完成了」，`comet eval` 让 Skill 本身也被评测；
- **熵减**：三种熵分头治理——Comet 的 Anti-drift 守卫治流程熵（阶段跳跃、目标漂移），Ponytail 阶梯治代码熵（过度工程），上下文熵则只能靠压缩缓解；闭环留了退回 Build 的返工通道。

每一个工具单独看都只是「省了一点 token」或「多了一道检查」，组合起来改变的是博弈结构：**AI 的每一个失误倾向，都有一道闸在对应位置等着。**

至于要不要全上？推荐按项目规模和痛点分层，而不是默认全装：**非平凡开发先上 Comet + RTK；中大型代码仓库再加 CodeGraph；Ponytail 与 Caveman 按需启用**。

- **Comet** 是这套组合里承担流程强制的组件。满足 active change、Router 受信任和路径受管辖等前提后，Guard 才能拦截越阶段写入；本机 `comet doctor` 显示三个受管平台各 78 个 skill 文件、1 条规则、一个 Router Hook，接线可自检；
- **RTK** 的投入产出比最高：一个二进制、一个 hook，把命令输出的噪音砍掉大半，失败时还有 tee 兜底；
- **CodeGraph** 解决的是中大型仓库里定位代码的痛点。它生效的条件很硬——doctor 会检查 CLI、项目索引、MCP 注册是否同时就位，缺一个就不算 effective；小仓库或文档库可跳过；

**Ponytail 和 Caveman 则是按项目可选的**：Ponytail 在「AI 过度工程」高发的场景（原型、内部工具、常见 CRUD）收益明显，但算法密集或领域建模重的代码，强行最小化可能帮倒忙；Caveman 官方自己就承认，在原本就简洁的任务上净收益可能为负——它真正卖的是可读性，省钱只是赠品。

这不是从 benchmark 推出来的结论，是本机装完、接完、跑通之后的选择。官方数据只能说明单个组件的上限，组合起来效果如何，取决于具体项目——benchmark 适合当参考，不适合当收益承诺。

**项目地址**：

- Comet：<https://github.com/rpamis/comet>（内嵌 OpenSpec <https://github.com/Fission-AI/OpenSpec> 与 Superpowers <https://github.com/obra/superpowers>）
- CodeGraph：<https://github.com/colbymchenry/codegraph>
- Ponytail：<https://github.com/DietrichGebert/ponytail>
- Caveman：<https://github.com/JuliusBrussee/caveman>
- RTK：<https://github.com/rtk-ai/rtk>

**文中提到的平台与文档**：

- Codex CLI（开源）：<https://github.com/openai/codex>
- Codex Hooks 官方文档：<https://learn.chatgpt.com/docs/hooks>（2026-08-29 历史记录显示老地址 `developers.openai.com/codex/hooks` 曾跳转到这里；当前跳转与可达性【待人工审核】）

---

*本文资料核验时间：2026-08-26 至 2026-08-27 为初始采集，2026-08-29 在 macOS 26.4 上建立本机基线，2026-08-31 复查了 CLI、配置、索引、测试与可用文件。A 级表示本轮本机可复现，B 级表示上游项目声明但未独立复测，C 级表示历史记录或二手来源；4.3 列出时效性较强的信息。Codex Hook 官方页面、`/hooks` 当前界面、CodeGraph 字节对照、Claude Code Ponytail 版本优先级以及阶段拒绝实验仍标为【待人工审核】，不要把历史记录当作当前事实。*
