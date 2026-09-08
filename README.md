# wisdomsword.github.io

**Notes from the AI engineering trenches, thinking and practice.**

Long-form write-ups on AI-assisted coding, agent harnesses, and systems design — with
numbers you can reproduce and sources you can trace.

- Live: <https://wisdomsword.github.io>
- RSS: <https://wisdomsword.github.io/feed.xml>

## Posts

| Date | Title | Lang |
| --- | --- | --- |
| 2026-09-07 | [From Dujiangyan to Agent Harnesses: Six Engineering Design Principles for Long-Lived AI Systems](https://wisdomsword.github.io/2026/09/07/Dujiangyan_Harness_Engineering_Design_Principles/) | English |
| 2026-09-07 | [都江堰 → Harness 工程设计原则：数据、公式与可迁移原则](https://wisdomsword.github.io/2026/09/07/%E9%83%BD%E6%B1%9F%E5%A0%B0_Harness%E5%B7%A5%E7%A8%8B%E8%AE%BE%E8%AE%A1%E5%8E%9F%E5%88%99/) | 中文 |
| 2026-09-07 | [7 个开源项目，整合出一套治理失控的 AI 编码 Harness](https://wisdomsword.github.io/2026/09/07/Harness-Practice-With-OpenSpec-Superpowers-CodeGraph-RTK/) | 中文 |

### 1. From Dujiangyan to Agent Harnesses

*English · [read →](https://wisdomsword.github.io/2026/09/07/Dujiangyan_Harness_Engineering_Design_Principles/)*

Dujiangyan, a 2,260-year-old irrigation system, read as an evidence-graded engineering
case study — flow splitting, annual maintenance, local materials — and what it implies
for long-lived AI agent harnesses. Every figure is graded: **A** reproduced locally,
**B** taken from official docs without independent re-testing, **C** second-hand.

### 2. 都江堰 → Harness 工程设计原则

*中文 · [阅读 →](https://wisdomsword.github.io/2026/09/07/%E9%83%BD%E6%B1%9F%E5%A0%B0_Harness%E5%B7%A5%E7%A8%8B%E8%AE%BE%E8%AE%A1%E5%8E%9F%E5%88%99/)*

Same source material, Chinese version: mapping 2,260 years of Dujiangyan engineering
facts — the 20 m Bottle-Neck channel, deep-scour depths, the annual maintenance system,
the Fish-Mouth flow split — onto six transferable design principles for AI harnesses.

### 3. 7 个开源项目，整合出一套治理失控的 AI 编码 Harness

*中文 · [阅读 →](https://wisdomsword.github.io/2026/09/07/Harness-Practice-With-OpenSpec-Superpowers-CodeGraph-RTK/)*

Seven open-source projects combined into a governance stack for AI coding — one gate
each for flow, retrieval, generation, output, and execution. Includes full Claude Code
and Codex configuration.

## Topics

`Harness` · `#Dujiangyan` · `#Design-Principles` · `#GitHub` · `#English` · `#中文`

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
