---
layout: post
title: "代码知识图谱 CLI 选型：Understand-Anything、Graphify、CodeGraph、GitNexus 横向评测"
date: 2026-09-08 10:30:00 +0800
lang: zh-CN
categories: [Tooling]
tags: [Knowledge-Graph, License, CLI, 中文]
description: "四款代码知识图谱 CLI 的横向评测：一手实测 Graphify 的 AST 抽取质量与 token 削减实况，并揪出 GitNexus 的 PolyForm 非商用许可证与 Graphify 的 MIT/Apache-2.0 双声明。"
---

# 代码知识图谱 CLI 选型评测：四个候选，一个因许可证出局

> 让 AI 看懂代码库这件事，最近冒出了一整条赛道：预索引一张知识图谱，让 agent 沿着边遍历，而不是满仓库 grep。
>
> 本文测评四个候选——**Understand-Anything**、**Graphify**、**CodeGraph**、**GitNexus**。结论先行：**如果项目要走商业交付，GitNexus 因 PolyForm Noncommercial 许可证直接出局**；剩下三个里，Graphify 是**本轮四个候选中唯一在我本机无 API key 条件下跑通完整 AST 抽取的**（另三家里 Understand-Anything 依赖宿主 Agent、GitNexus 的 npx 安装被我的沙箱拦截，均未验证；详见 3.4）。我在 12 文件 / 327 行的受控语料上给出了一手实测数据。
>
> 关于数据来源，沿用本站惯例：**A 级是本轮在自己机器上跑出来的**，**B 级是官方 README / 官网 / API 的声明，我没有独立复测**，**C 级来自二手转载**。所有 star 数、许可证、版本号均取自 2026-09-08 的 GitHub REST API 与 PyPI JSON API，属于**可复核的一手数据**，但仍是**时点快照**。

---

## 一、先说结论

| 工具 | 仓库 | Star | 许可证 | 主语言 | 商业可用 |
| --- | --- | --- | --- | --- | --- |
| **Graphify** | Graphify-Labs/graphify | 115,734 | ⚠️ Apache-2.0 / MIT 双声明 | Python | ✅ 但需澄清 |
| **Understand-Anything** | Egonex-AI/Understand-Anything | 81,750 | MIT | TypeScript | ✅ |
| **CodeGraph** | colbymchenry/codegraph | 69,973 | MIT | C | ✅ |
| **GitNexus** | abhigyanpatwari/GitNexus | 47,122 | ❌ PolyForm Noncommercial 1.0.0 | TypeScript | ❌ 否 |

三条最实用的判断：

1. **GitNexus 直接出局**（商业场景）。不是推测——它的 `LICENSE` 文件正文第一行就是 `PolyForm Noncommercial License 1.0.0`，且 GitHub License API 判定为 `NOASSERTION`（A 级，本人核对于 2026-09-08）；
2. **Graphify 许可证存在内部冲突**：Git 发布分支 `v8` 带 Apache-2.0 LICENSE，PyPI 声明 `Apache-2.0`，但 `main` 分支根目录既没有 LICENSE 文件、`pyproject.toml` 里又写着 `license = { text = "MIT" }`（A 级，本人核对）。**两个都是宽松许可证，不阻断商用**，但这属于应当先问清楚的工程卫生问题；
3. **71.5× token 削减在小型仓库上不成立**。我在 12 文件 / 327 行语料上实测，Graphify 自己的 benchmark 给出的是 **2.6×**（A 级）。

---

## 二、为什么需要这一层

先说清它到底省什么。agent 理解陌生代码库的朴素路径是「grep → Read 十几个文件」，把探索成本原样灌进上下文窗口、也灌进账单。知识图谱把这件事前置成一次离线索引：结构事实预先算好，查询时只返回沿途的边。

三件事值得提前建立预期：

- **图谱是索引，不是答案**。它能告诉你是谁调用了谁，不能告诉你为什么这么设计；
- **省的是检索，不省的是存储**。图谱文件本身占地方——实测中 8,556 字节源码生成了 **82,871 字节**的 `graph.json`（A 级），**9.7 倍**；
- **收益随语料规模放大，小仓库很可能亏**。见第五节实测数据。

---

## 三、四个候选逐个拆解

> 每个工具只讲四件事：它是什么、怎么起作用、官方数据多少、有什么坑。想直接看选型跳到第六节。

### 3.1 Understand-Anything：可视化理解层，图谱是给人看的

**GitHub：<https://github.com/Egonex-AI/Understand-Anything>**（MIT，TypeScript，81,750 star，2026-03-15 创建）

> ⚠️ **身份变更**：本项目原名 `Lum1104/Understand-Anything`，现仓库已迁至 `Egonex-AI/Understand-Anything`（该地址返回 301 跳转，A 级）。README 自称 "An open-source project from Egonex, Originally created by Lum1104"。**引用时请以现地址为准**；仓库迁移后 star 计数、issue 归属需重新核对【待人工审核】。

**怎么起作用**。五阶段多智能体管道：project-scanner 发现文件、file-analyzer 提取函数与类、architecture-analyzer 构建依赖图、tour-generator 生成导览路径、graph-reviewer 校验完整性。技术路线是 **Tree-sitter（确定性）+ LLM（语义）混合**：静态解析器产出导入、导出、调用点、继承这些硬事实，LLM 负责静态解析做不到的事：通俗摘要、标签、架构层归属、业务领域映射。

产物是 `.ua/knowledge-graph.json`，配 `/understand-dashboard` 打开交互式 Web 面板。

**官方数据与已知边界（B 级）**：

| 维度 | 官方口径 |
| --- | --- |
| 覆盖平台 | 14+：Claude Code、Codex、Cursor、Copilot CLI、Gemini CLI、OpenCode、Cline、Kiro 等 |
| 语言参数 | `--language` 支持 en / zh / zh-TW / ja / ko / ru |
| 首次开销 | 官方明确提醒「大型项目首次运行可能消耗大量 token」，建议配本地模型或订阅额度 |
| 后续运行 | 默认增量，只重分析变更文件 |

**坑在哪里**。一是**依赖 Claude Code 等宿主 Agent 平台**，本质上是插件而非独立 CLI——想要「一条命令在 CI 里跑完」，它是四个里最不合适的；二是**首次全量分析成本高**，官方自己都在 README 里挂了 token 警告；三是**缩容需要手动框定范围**，monorepo 场景官方建议 `/understand src/frontend` 划子目录。

适合接手陌生项目、给新人做 onboarding、给 PM 看架构；不适合做 CI 门禁。

### 3.2 Graphify：唯一的「无 key 可跑」纯 AST 通道

**GitHub：<https://github.com/Graphify-Labs/graphify>**（Python，115,734 star，2026-04-03 创建，最新 release `v0.9.56` 于 2026-09-07 发布）

PyPI 包名 **`graphifyy`**（注意双写 y），CLI 命令仍是 `graphify`；requires-python >= 3.10。

**怎么起作用**。七阶段管道：`detect → extract → build → cluster → analyze → report → export`。核心亮点是 **`--code-only` 模式：全程由本地 tree-sitter 做 AST 抽取，不调用任何 LLM，不需要 API key**（A 级，本人验证）。这是四个候选里唯一能在完全离线、零密钥条件下产出可用图谱的。边上带溯源标签：`EXTRACTED` 来自 AST、`INFERRED` 来自模型、`AMBIGUOUS` 证据不足。

**官方数据（B 级）**：支持 36 种语言，MCP server 暴露 10 个工具，声称 71.5× token 削减。

**许可证问题（A 级，本人核对，重点）**。三处声明互相不一致：

| 来源 | 声明 |
| --- | --- |
| 发布分支 `v8` 的 LICENSE 文件 | Apache License 2.0（正文核实） |
| PyPI `graphifyy` 元数据 | `license_expression: Apache-2.0`，且同时打包 `LICENSE`、`LICENSE-MIT`、`NOTICE` 三个文件 |
| `main` 分支根目录 | **无 LICENSE 文件**；`pyproject.toml` 写 `license = { text = "MIT" }`，且 version 仍为 `0.1.14`（PyPI 已发 0.9.56） |

**解读**：Apache-2.0 与 MIT 都是 OSI 批准的宽松许可证、都含专利条款差异但都允许商用，因此**不构成商用阻断**。真正的问题是**声明混乱**——版本号不同步 + 根目录缺 LICENSE + 同一分发包里混装两个许可证文件。**商业交付前建议书面确认以 Apache-2.0（即 PyPI 分发时的表达件）为准**【待人工审核】。

### 3.3 CodeGraph：本站已在用的检索层

**GitHub：<https://github.com/colbymchenry/codegraph>**（MIT，C 语言实现，69,973 star，2026-01-18 创建，最新 release `v1.6.0`）

它在[本站上一篇 Harness 文章](/2026/09/07/Harness-Practice-With-OpenSpec-Superpowers-CodeGraph-RTK/)里已经作为「上下文工程的检索闸」出现过，这里只做对照定位，不重复展开。

关键差异：**CodeGraph 用 C 实现并预索引**，主打同步开销低；官方承认长期检索会有约 80% 上下文残留；它对外只暴露 1 个 MCP 工具 `codegraph_explore`（另 7 个能力对 agent 隐藏），理由是「一个强工具比一堆窄工具更能引导 agent 做对选择」。MIT 许可证，商业可用性最干净。

### 3.4 GitNexus：能力完整，但许可证一票否决

**GitHub：<https://github.com/abhigyanpatwari/GitNexus>**（TypeScript，47,122 star，2025-08-02 创建）

**许可证核验过程（A 级，本人完整复盘）**：

```
2026-02-03T16:50:15Z  9cd38096  docs: add PolyForm Noncommercial License 1.0.0
2026-02-03T17:24:01Z  789e7809  docs: update license copyright holder
```

关键补充：在这两个提交**之前**，仓库根目录**不存在任何 LICENSE 文件**（我拉取了父提交的目录清单，只有 `.cursor`、`.github`、`ARCHITECTURE.md`、`README.md`、`gitnexus/`、`gitnexus-mcp/` 等，**无 LICENSE**）。

所以这件事的准确表述是：**GitNexus 并非从 MIT「换」成了非商用许可证，而是长期处于无许可证状态（默认保留所有权利），到 2026-02-03 才补上一份 PolyForm Noncommercial**。这一点很重要——**如果你的团队在 2026-02-03 之前已经用了它，那段时间的法律地位本就是空白的**，不是「曾经可以商用、后来不能了」。【待人工审核：具体引入时间须由团队自查】

**许可证的三重独立确认（A 级）**。为了避免误判，我从三个独立来源交叉验证：

| 来源 | 结果 |
| --- | --- |
| GitHub `LICENSE` 文件正文 | 首行 `PolyForm Noncommercial License 1.0.0` |
| GitHub License REST API | `spdx_id: NOASSERTION`（非标准许可证） |
| npm registry `gitnexus@1.6.11` | `license: "PolyForm-Noncommercial-1.0.0"` |

三处一致，**不存在「某处写着 MIT」的歧义**。

**能力客观评价**：它是四个里最完整的——7 阶段索引（structure / parse / imports / calls / heritage / communities / processes）、KuzuDB 本地图库、7 个 MCP 工具、Claude Code PreToolUse hooks 自动增强 grep/glob、调用边带 0.3–0.9 置信度打分、`--skip-embeddings` 可跳过向量生成。官方声称用本地 transformers.js 做嵌入、索引零 LLM 开销（**B 级，本轮未能验证**）。

> **诚实的说明**：我本想实测这条「零 Token 索引」的声明，但 `npx gitnexus@latest analyze` 在我的沙箱环境里安装失败（`CODEBUDDY_BROKER_DENY`，mkdir 被运行时规则拦截）。**这是我这边的环境限制，不是 GitNexus 的缺陷**，不能据此推断它跑不起来。这条保持 B 级【待人工审核】。

**一句话**：技术上很可能是最强的，但 **PolyForm Noncommercial 1.0.0 明确禁止商业用途**。对项目而言，没有讨论余地。

---

## 四、横向对比

| 维度 | Understand-Anything | Graphify | CodeGraph | GitNexus |
| --- | --- | --- | --- | --- |
| Star（2026-09-08） | 81,750 | **115,734** | 69,973 | 47,122 |
| 许可证 | MIT | ⚠️ Apache-2.0/MIT 冲突 | MIT | ❌ 非商用 |
| 实现语言 | TypeScript | Python | **C** | TypeScript |
| 图存储 | JSON 文件 | JSON（NetworkX） | 预索引 | KuzuDB |
| 独立 CLI | ❌ 依附宿主 Agent | ✅ | ✅ | ✅ |
| 无 API key 可用 | ❌ | ✅ `--code-only` | ✅ | ✅（声明） |
| 向量/语义检索 | ✅ | 可选 embeddings | ✅ | ✅ 混合 BM25+语义 |
| MCP 工具数 | — | 10（官方声明） | 暴露 1 个 | 7 |
| 增量更新 | ✅ | ✅ | ✅ | ✅ |
| 商业可用 | ✅ | ✅（待澄清） | ✅ | ❌ |

---

## 五、Graphify 一手实测：小仓库的最优触点在哪

只有 Graphify 能在无 API key 下跑通，所以实测集中在它。

### 5.1 实验设置

自建受控语料：一个 12 文件、327 行、**11,456 字节**（其中 Python 源码 10 文件 **8,556 字节**）的订单服务，含真实跨模块调用链（api → order_service → pricing / payment / shipping / notifications → models）。环境 macOS arm64、Python 3.14.7 venv、`graphify 0.9.56`。

```bash
graphify extract ./fixture --code-only --out ./run1
```

### 5.2 实测结果（A 级）

| 指标 | 实测值 |
| --- | --- |
| 首次全量抽取耗时 | **10.6 s**（10 个代码文件） |
| 无变更时增量重跑 | **3.0 s**（对比全量 10.6 s，约 3.5×） |
| 产出节点 / 边 / 社区 | **73 / 190 / 8** |
| `graph.json` 体积 | **82,871 字节**（源码 8,556 字节的 **9.7 倍**） |
| 边置信度分布 | EXTRACTED 165（86.8%）、INFERRED 25（13.2%）、AMBIGUOUS 0 |
| `confidence_score` 取值集合 | 仅 `{0.95, 1.0}` 两档 |
| 图的 `directed` 标志 | `false` |
| 无 `source_file` 的节点 | 8 个（11.0%） |
| 内置 benchmark 给出的 token 削减 | **2.6×**（非官方宣称的 71.5×） |

### 5.3 值得注意的四个细节

**其一，71.5× 是规模的函数，不是常数。** Graphify 官网与 README 反复引用的 71.5×，语料是一份「3 个 repo + 5 篇论文 + 4 张图、约 52 文件 / 92k 词」的混合集合（**C 级**，语料我没拿到，数字也未经我复现）。在我的 12 文件 / 3650 词小语料上，同一个工具、同一条 `graphify benchmark` 命令给出的是 **2.6×**（A 级）。

原因不难理解：图遍历的固定开销（种子节点定位、BFS、结果格式化）与语料规模**弱相关**，而「朴素全文投喂」的成本与规模**强相关**。两者之比自然随规模上升。

**所以仓库越小，图谱越不划算。** 这是选型时最容易踩的坑——拿大仓库的宣传数字套自己的小项目。判断方法很简单：先跑一遍 `graphify benchmark`，看你自己仓库的真实倍数。

**其二，自然语言查询的种子节点选得很糙。** 我问 `"what is the main entry point"`，BFS 起点落在了 `svc/models.py`（种子是它的模块 docstring "Order service domain models."），最终返回 **16 个节点**——占全图 73 个节点的 **21.9%**。窄问题宽返回，省 token 的收益被摊薄了。

**其三，模块 docstring 会变成独立节点。** 12 个节点的 `file_type` 是 `rationale`、label 是整句 docstring（如 "Money calculations for orders."），通过 `rationale_for` 边挂在文件上。这是设计选择，但也正是上一条里错误种子的来源。

**其四，外部符号会污染图。** 8 个节点（11.0%）没有 `source_file`，是 `Decimal`、`Enum`、`Exception` 这类标准库符号被拉进了图里。占比不高，但查询时形态会很突兀（输出里长这样：`NODE Enum [src= loc= community=3]`）。

### 5.4 一句诚实的评价

`--code-only` 通道确实是**诚实可用**的：不需要密钥、不联网、165 条边里绝大多数是确定性 AST 事实。但 `--code-only` 模式下那 25 条 `INFERRED` 边的 `_origin` 全是 `ast`——说明**这个标签在无 LLM 参与时也会被贴上**，它标记的是「推断强度低」而非「经过模型判断」。引用 INFERRED 边时要留意这个区别。

---

## 六、选型建议

按场景给三条路径：

**要 CI 门禁 / 离线分析 / 商业交付** → **CodeGraph**。MIT 许可清白、C 实现、预索引、官方明确面向 harness 场景。代价是它为 harness 而生，缺少可视化那一层。

**要团队共享 + 可视化 + 多语言广度** → **Graphify**。`--code-only` 是真正的零门槛入口，36 语言覆盖最广，图谱是纯 JSON 产物便于 Git 管理与 CI 产出。**商业使用前先把许可证冲突书面澄清**（见 3.2 节），并在自己的仓库规模上重跑一遍 `graphify benchmark`——别直接拿 71.5× 当预期。

**要给人看、给新人 onboarding** → **Understand-Anything**。交互式面板 + 引导式学习路线 + 中文输出是这个赛道里最好的。但它是 Agent 平台插件，别指望它进 CI。

**GitNexus**：能力清单最优，许可证一票否决，不推荐用于任何商业路径。

最后一记提醒：这四个项目的 star 数在 2026 年上半年涨得极快（Graphify 四个半月 11.5 万 star）。**star 数是热度指标，不是稳定性指标**——它们的版本号都还停在 0.x / 1.x 早期。生产环境引入建议锁定具体 commit，并把许可证兼容性审查做进依赖准入流程。

---

## 附：时效性信息清单

以下信息时效性强，引用前请自行复核：

| 项目 | 时点值 | 采集时间 | 可信度 |
| --- | --- | --- | --- |
| 四个仓库 star/fork/issues | 见第一节表格 | 2026-09-08 | A（GitHub REST API） |
| GitNexus 许可证 | PolyForm Noncommercial 1.0.0 | 2026-09-08 | A（LICENSE 正文 + API） |
| GitNexus 许可证变更提交 | 9cd38096 / 789e7809，2026-02-03 | 2026-09-08 | A（commits API） |
| GitNexus npm 包声明 | `gitnexus@1.6.11`，`PolyForm-Noncommercial-1.0.0` | 2026-09-08 | A（npm registry） |
| Graphify 许可证冲突 | 见 3.2 三处对比 | 2026-09-08 | A（raw 文件 + PyPI API） |
| Graphify 版本 | PyPI 0.9.56（2026-09-07） | 2026-09-08 | A |
| Understand-Anything 仓库迁移 | Lum1104 → Egonex-AI（301） | 2026-09-08 | A |
| Graphify 实测数据 | 见 5.2 | 2026-09-08 | A（本机复现） |
| Graphify 官方 71.5× / 36 语言 / 10 MCP 工具 | 官网与 README 口径 | 2026-09-08 | B（未独立复测） |
| Understand-Anything 五阶段管道 / token 警告 | README 口径 | 2026-09-08 | B |
| CodeGraph 80% 残留 / 单工具设计 | 官方口径，见本站前文 | 2026-09-07 | B |
| GitNexus 零 Token 索引 / 7 工具 / 0.3–0.9 置信度 | README 口径 | 2026-09-08 | B（本机未跑通验证）|

复现本文实测数据的最小脚本：

```bash
# Graphify 无 key AST 抽取 + 内置基准
uv venv .venv && uv pip install --python .venv/bin/python graphifyy
.venv/bin/graphify extract <your/repo> --code-only --out ./run1
.venv/bin/graphify benchmark run1/graphify-out/graph.json
```
