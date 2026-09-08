# wisdomsword.github.io

**Notes from the AI engineering trenches, thinking and practice.**

Long-form write-ups on AI-assisted coding, agent harnesses, and systems design — with
numbers you can reproduce and sources you can trace.

- Live: <https://wisdomsword.github.io>
- RSS: <https://wisdomsword.github.io/feed.xml>

## Posts

| Date | Title | Lang |
| --- | --- | --- |
| 2026-09-08 | [代码知识图谱 CLI 选型评测：四个候选，一个因许可证出局](https://wisdomsword.github.io/2026/09/08/code-knowledge-graph-cli-survey/) | 中文 |
| 2026-09-08 | [代码知识图谱 CLI 研究报告（易读版 · 修订 v4）](https://wisdomsword.github.io/2026/09/08/%E4%BB%A3%E7%A0%81%E7%9F%A5%E8%AF%86%E5%9B%BE%E8%B0%B1-CLI-%E7%A0%94%E7%A9%B6%E6%8A%A5%E5%91%8A-%E6%98%93%E8%AF%BB%E7%89%88/) | 中文 |
| 2026-09-07 | [From Dujiangyan to Agent Harnesses: Six Engineering Design Principles for Long-Lived AI Systems](https://wisdomsword.github.io/2026/09/07/Dujiangyan_Harness_Engineering_Design_Principles/) | English |
| 2026-09-07 | [都江堰 → Harness 工程设计原则：数据、公式与可迁移原则](https://wisdomsword.github.io/2026/09/07/%E9%83%BD%E6%B1%9F%E5%A0%B0_Harness%E5%B7%A5%E7%A8%8B%E8%AE%BE%E8%AE%A1%E5%8E%9F%E5%88%99/) | 中文 |
| 2026-09-07 | [7 个开源项目，整合出一套治理失控的 AI 编码 Harness](https://wisdomsword.github.io/2026/09/07/Harness-Practice-With-OpenSpec-Superpowers-CodeGraph-RTK/) | 中文 |

### 1. 代码知识图谱 CLI 选型评测

*中文 · [阅读 →](https://wisdomsword.github.io/2026/09/08/code-knowledge-graph-cli-survey/)*

Understand-Anything、Graphify、CodeGraph、GitNexus 四款代码知识图谱 CLI 的横向评测。
核心发现三条：**GitNexus 的 LICENSE 是 PolyForm Noncommercial 1.0.0，商业项目直接出局**
（经 LICENSE 正文、GitHub API、npm registry 三重交叉验证）；**Graphify 存在 Apache-2.0 / MIT
双声明冲突**（同为宽松许可证，不阻断商用，但需澄清）；官方宣称的 **71.5× token 削减在小仓库上不成立**——
12 文件 / 327 行语料实测只有 **2.6×**。含 12 项一手实测指标与「别拿大仓库数字套小项目」的选型判据。

### 2. 代码知识图谱 CLI 研究报告（易读版 · 修订 v4）

*中文 · [阅读 →](https://wisdomsword.github.io/2026/09/08/%E4%BB%A3%E7%A0%81%E7%9F%A5%E8%AF%86%E5%9B%BE%E8%B0%B1-CLI-%E7%A0%94%E7%A9%B6%E6%8A%A5%E5%91%8A-%E6%98%93%E8%AF%BB%E7%89%88/)*

同一议题的一对一版本：**CodeGraph vs GitNexus**，结论是单押 CodeGraph。
CodeGraph 数据由本机 v1.6.0 实跑（`--help`、`install --print-config`、`status`）取证；
GitNexus 因许可否决未本机安装。侧重点是两款工具的部署形态差异——CodeGraph 每项目独立、
仅 stdio 传输、MCP 默认只暴露 1 个工具；GitNexus 有 HTTP 服务端、多仓库统一 registry、
17 个 MCP 工具，但被 PolyForm Noncommercial 锁死。

> 与上一篇角度不同：本篇是一对一深度比对，上一篇是四款横向扫描。两者平行，可合并。

### 3. From Dujiangyan to Agent Harnesses

*English · [read →](https://wisdomsword.github.io/2026/09/07/Dujiangyan_Harness_Engineering_Design_Principles/)*

Dujiangyan, a 2,260-year-old irrigation system, read as an evidence-graded engineering
case study — flow splitting, annual maintenance, local materials — and what it implies
for long-lived AI agent harnesses. Every figure is graded: **A** reproduced locally,
**B** taken from official docs without independent re-testing, **C** second-hand.

### 4. 都江堰 → Harness 工程设计原则

*中文 · [阅读 →](https://wisdomsword.github.io/2026/09/07/%E9%83%BD%E6%B1%9F%E5%A0%B0_Harness%E5%B7%A5%E7%A8%8B%E8%AE%BE%E8%AE%A1%E5%8E%9F%E5%88%99/)*

同一份素材的中文版：把都江堰 2,260 年的工程事实——宝瓶口宽 20 m、深滩深度、岁修制度、
鱼嘴分水比例——映射到 AI Agent Harness 的六条可迁移设计原则。

### 5. 7 个开源项目，整合出一套治理失控的 AI 编码 Harness

*中文 · [阅读 →](https://wisdomsword.github.io/2026/09/07/Harness-Practice-With-OpenSpec-Superpowers-CodeGraph-RTK/)*

七个开源项目组合成一套 AI 编码治理栈——流程、检索、生成、输出、执行五个环节各守一道闸，
附 Claude Code 与 Codex 的完整配置。

## Topics

`Harness` · `Tooling` · `#Dujiangyan` · `#Design-Principles` · `#Knowledge-Graph` · `#License` · `#GitHub` · `#English` · `#中文`

## Repository layout

```
_config.yml          site config (permalink /:year/:month/:day/:title/)
_layouts/home.html   custom homepage: hero + post grid + topics + about
_includes/header.html
assets/main.scss     design overrides on top of minima
_posts/              articles (.md or standalone .html)
```

New posts are picked up automatically — drop a dated file into `_posts/` and it appears
on the homepage. Front matter `description`, `categories`, and `tags` feed the card.

## Local build

```bash
bundle install
bundle exec jekyll serve
```

Then open <http://localhost:4000>.
