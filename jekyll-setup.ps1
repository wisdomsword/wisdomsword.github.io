# =============================================================
# GitHub Pages + Jekyll 本地环境一键配置脚本 (Windows / PowerShell)
# 解决国内 gem install 卡死 / 无响应的问题
#
# 用法(在博客目录里打开 PowerShell,先允许脚本执行):
#   Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
#   .\jekyll-setup.ps1                 自动换源 -> 装环境 -> 初始化 -> 启动预览
#   .\jekyll-setup.ps1 -Init           只初始化博客文件
#   .\jekyll-setup.ps1 -NoServe        只装环境,不启动预览
#   .\jekyll-setup.ps1 -GitHubPages    装 github-pages gem(与GitHub线上环境一致,推荐)
#   .\jekyll-setup.ps1 -Mirror tsinghua  指定镜像: tsinghua/rubychina/tencent/aliyun/official
#   .\jekyll-setup.ps1 -Path D:\blog   指定博客目录(默认当前目录)
#
# Ruby 环境请用 RubyInstaller 安装: https://rubyinstaller.org/
#   安装时务必勾选运行 ridk install (选 3,装 MSYS2 开发包),否则原生扩展会编译失败
# =============================================================

param(
    [switch]$Init,          # 只初始化文件
    [switch]$NoServe,       # 不启动预览
    [switch]$BuildOnly,     # 只构建 _site
    [switch]$GitHubPages,   # 使用 github-pages gem
    [switch]$LiveReload,    # 浏览器自动刷新
    [string]$Mirror = "",   # 镜像名
    [string]$Path = (Get-Location).Path,
    [string]$GitHubUser = ""
)

$ErrorActionPreference = "Continue"

function Info($m) { Write-Host "[info]  $m" -ForegroundColor Cyan }
function Ok($m)   { Write-Host "[ ok ]  $m" -ForegroundColor Green }
function Warn($m) { Write-Host "[warn]  $m" -ForegroundColor Yellow }
function Err($m)  { Write-Host "[fail]  $m" -ForegroundColor Red }
function Title($m){ Write-Host ""; Write-Host "==> $m" -ForegroundColor White -BackgroundColor DarkBlue }

function Get-MirrorUrl($name) {
    switch ($name.ToLower()) {
        "tsinghua"  { return "https://mirrors.tuna.tsinghua.edu.cn/rubygems/" }
        "tuna"      { return "https://mirrors.tuna.tsinghua.edu.cn/rubygems/" }
        "rubychina" { return "https://gems.ruby-china.com/" }
        "china"     { return "https://gems.ruby-china.com/" }
        "tencent"   { return "https://mirrors.tencent.com/rubygems/" }
        "aliyun"    { return "https://mirrors.aliyun.com/rubygems/" }
        "official"  { return "https://rubygems.org/" }
        default     { return "" }
    }
}

# 用 UTF-8 无 BOM 写文件(避免 Jekyll 解析 BOM 出错)
function Write-Utf8File($filePath, $content) {
    $dir = Split-Path -Parent $filePath
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($filePath, $content, $enc)
}

# ---------- 0. 环境检查 ----------
Title "0/5 检查环境"
if (-not (Get-Command ruby -ErrorAction SilentlyContinue)) {
    Err "没找到 ruby,请先安装 RubyInstaller: https://rubyinstaller.org/"
    Err "安装结束时勾选 ridk install -> 输入 3 回车,装完重开 PowerShell"
    exit 1
}
Ok ("ruby   " + (ruby -v))
Ok ("gem    " + (gem -v))

# ---------- 1. 换源 ----------
Title "1/5 配置 gem 镜像源"
if ([string]::IsNullOrEmpty($Mirror)) {
    Info "正在测速挑选最快的镜像源..."
    $best = "tsinghua"; $bestT = 999.0
    foreach ($n in @("tsinghua", "rubychina", "tencent", "aliyun")) {
        $u = Get-MirrorUrl $n
        try {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            Invoke-WebRequest -Uri ($u + "specs.4.8.gz") -TimeoutSec 6 -UseBasicParsing -OutFile NUL | Out-Null
            $sw.Stop()
            $t = $sw.Elapsed.TotalSeconds
        } catch { $t = 999.0 }
        Write-Host ("        {0,-12} {1:N2}s" -f $n, $t)
        if ($t -lt $bestT) { $bestT = $t; $best = $n }
    }
    $Mirror = $best
}
$MURL = Get-MirrorUrl $Mirror
if ([string]::IsNullOrEmpty($MURL)) {
    Err "无效的镜像名: $Mirror (可选: tsinghua/rubychina/tencent/aliyun/official)"
    exit 1
}
Info "使用镜像: $Mirror  ($MURL)"

gem sources --remove https://rubygems.org/ 2>$null | Out-Null
gem sources --add $MURL 2>$null | Out-Null
Ok "当前 gem 源:"
gem sources -l | Where-Object { $_ -match "^https?://" } | ForEach-Object { Write-Host "        $_" }

if (Get-Command bundle -ErrorAction SilentlyContinue) {
    bundle config set --global mirror.https://rubygems.org $MURL 2>$null | Out-Null
}

# ---------- 2. 安装 ----------
if (-not $Init) {
    Title "2/5 安装 Jekyll(国内源通常 1-3 分钟)"
    if ($GitHubPages) {
        Info "模式: github-pages gem(与 GitHub 线上构建环境一致)"
        gem install github-pages bundler --no-document
    } else {
        Info "模式: 标准 jekyll + bundler"
        gem install jekyll bundler --no-document
    }
    if ($LASTEXITCODE -ne 0) {
        Err "安装失败。可尝试: 1) 换镜像 -Mirror rubychina  2) 直接 git push 让 GitHub 构建"
        exit 1
    }
    bundle config set --global mirror.https://rubygems.org $MURL 2>$null | Out-Null
    Ok "安装完成"
} else {
    Title "2/5 跳过安装(-Init 模式)"
}

# ---------- 3. 初始化文件 ----------
Title "3/5 初始化博客文件"
Set-Location $Path
New-Item -ItemType Directory -Path "_posts", "assets\images" -Force | Out-Null

if ([string]::IsNullOrEmpty($GitHubUser)) { $GitHubUser = "yourname" }
$siteUrl = "https://$GitHubUser.github.io"

if (-not (Test-Path "_config.yml")) {
    $cfg = @"
title: 我的博客
description: 用 GitHub Pages + Jekyll 搭建
author: $GitHubUser
theme: minima
url: "$siteUrl"
baseurl: ""

plugins:
  - jekyll-feed
  - jekyll-sitemap
  - jekyll-seo-tag

permalink: /:year/:month/:day/:title/
paginate: 10
"@
    Write-Utf8File (Join-Path $Path "_config.yml") ($cfg + "`n")
    Ok "已生成 _config.yml"
} else { Warn "_config.yml 已存在,保持不变" }

if (-not (Test-Path "index.md")) {
    $idx = @"
---
layout: home
title: 首页
---

欢迎来到我的博客,下面是最新文章。
"@
    Write-Utf8File (Join-Path $Path "index.md") ($idx + "`n")
    Ok "已生成 index.md"
}

if (-not (Test-Path "Gemfile")) {
    if ($GitHubPages) {
        $gf = @"
source "https://rubygems.org"

gem "github-pages", group: :jekyll_plugins

platforms :mingw, :x64_mingw, :mswin, :jruby do
  gem "tzinfo", ">= 1", "< 3"
  gem "tzinfo-data"
  gem "wdm", "~> 0.1.1"
end
"@
    } else {
        $gf = @"
source "https://rubygems.org"

gem "jekyll", "~> 4.3"
gem "minima", "~> 2.5"
gem "jekyll-feed"
gem "jekyll-sitemap"
gem "jekyll-seo-tag"

platforms :mingw, :x64_mingw, :mswin, :jruby do
  gem "tzinfo", ">= 1", "< 3"
  gem "tzinfo-data"
  gem "wdm", "~> 0.1.1"
end
"@
    }
    Write-Utf8File (Join-Path $Path "Gemfile") ($gf + "`n")
    Ok "已生成 Gemfile"
}

if (-not (Test-Path ".gitignore")) {
    $gi = @"
_site/
.jekyll-cache/
.jekyll-metadata
.sass-cache/
Gemfile.lock
"@
    Write-Utf8File (Join-Path $Path ".gitignore") ($gi + "`n")
    Ok "已生成 .gitignore"
}

$today = Get-Date -Format "yyyy-MM-dd"
$now   = Get-Date -Format "HH:mm:ss"
$sample = "_posts\$today-hello-world.md"
if (-not (Test-Path $sample)) {
    # 用单引号 here-string(避免反引号被当作转义符),日期用占位符再替换
    $post = @'
---
layout: post
title: "Hello World"
date: __DATE__ +0800
categories: [随笔]
tags: [GitHub, Jekyll]
---

这是第一篇文章,用 Markdown 直接写就行。

## 小标题

- 列表项
- **加粗**、`行内代码`

```bash
echo "代码块"
```
'@
    $post = $post -replace '__DATE__', "$today $now"
    Write-Utf8File (Join-Path $Path $sample) ($post + "`n")
    Ok "已生成示例文章 $sample"
}

# ---------- 4. bundle install ----------
Title "4/5 安装项目依赖 (bundle install)"
if (Get-Command bundle -ErrorAction SilentlyContinue) {
    bundle install
    if ($LASTEXITCODE -ne 0) {
        Err "bundle install 失败"
        if (-not $Init) { Err "应急方案: 删掉 Gemfile/Gemfile.lock,直接 git push 交给 GitHub 构建"; exit 1 }
        else { Warn "文件已生成,装好环境后再执行 bundle install" }
    } else { Ok "依赖安装完成" }
} else { Warn "没找到 bundler,跳过" }

# ---------- 5. 预览 ----------
Title "5/5 完成"
Ok "博客目录: $Path"
Ok "线上地址(需先建 $GitHubUser.github.io 仓库并 push): $siteUrl"

if ($BuildOnly) {
    bundle exec jekyll build
} elseif (-not $NoServe -and -not $Init) {
    $args2 = @("exec", "jekyll", "serve") + $(if ($LiveReload) { @("--livereload") } else { @() })
    Ok "即将启动本地预览: http://localhost:4000"
    Info "Ctrl+C 停止"
    & bundle @args2
} else {
    Info "手动启动: bundle exec jekyll serve"
    Info "发文流程: 在 _posts 里新建 YYYY-MM-DD-标题.md -> git add . ; git commit -m 'new post' ; git push"
}
