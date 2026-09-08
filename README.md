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

### 2. From Dujiangyan to Agent Harnesses

*English · [read →](https://wisdomsword.github.io/2026/09/07/Dujiangyan_Harness_Engineering_Design_Principles/)*

Dujiangyan, a 2,260-year-old irrigation system, read as an evidence-graded engineering
case study — flow splitting, annual maintenance, local materials — and what it implies
for long-lived AI agent harnesses. Every figure is graded: **A** reproduced locally,
**B** taken from official docs without independent re-testing, **C** second-hand.

### 3. 都江堰 → Harness 工程设计原则

*中文 · [阅读 →](https://wisdomsword.github.io/2026/09/07/%E9%83%BD%E6%B1%9F%E5%A0%B0_Harness%E5%B7%A5%E7%A8%8B%E8%AE%BE%E8%AE%A1%E5%8E%9F%E5%88%99/)*

Same source material, Chinese version: mapping 2,260 years of Dujiangyan engineering
facts — the 20 m Bottle-Neck channel, deep-scour depths, the annual maintenance system,
the Fish-Mouth flow split — onto six transferable design principles for AI harnesses.

### 4. 7 个开源项目，整合出一套治理失控的 AI 编码 Harness

*中文 · [阅读 →](https://wisdomsword.github.io/2026/09/07/Harness-Practice-With-OpenSpec-Superpowers-CodeGraph-RTK/)*

Seven open-source projects combined into a governance stack for AI coding — one gate
each for flow, retrieval, generation, output, and execution. Includes full Claude Code
and Codex configuration.

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
