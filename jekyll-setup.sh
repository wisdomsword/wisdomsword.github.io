#!/usr/bin/env bash
# =============================================================
# GitHub Pages + Jekyll 本地环境一键配置脚本 (macOS / Linux)
# 解决国内 gem install 卡死 / 无响应的问题
#
# 用法:
#   ./jekyll-setup.sh                 自动选最快镜像 -> 换源 -> 装环境 -> 初始化 -> 启动预览
#   ./jekyll-setup.sh --init          只初始化博客文件,不启动预览
#   ./jekyll-setup.sh --no-serve      只装环境,不启动预览
#   ./jekyll-setup.sh --build-only    只构建到 _site/,不启动服务
#   ./jekyll-setup.sh --gh-pages      安装 github-pages gem(与GitHub线上构建环境一致,推荐)
#   ./jekyll-setup.sh --mirror NAME   手动指定镜像: tsinghua/rubychina/tencent/aliyun/official
#   ./jekyll-setup.sh --dir PATH      指定博客目录(默认当前目录)
#   ./jekyll-setup.sh --livereload    预览时开启浏览器自动刷新
#   ./jekyll-setup.sh --help          查看帮助
#
# 环境变量:
#   GITHUB_USER   你的 GitHub 用户名(用于生成 _config.yml 里的 url)
# =============================================================

set -uo pipefail

# ---------- 参数默认值 ----------
DO_INIT=1
DO_SERVE=1
DO_INSTALL=1
BUILD_ONLY=0
USE_GHP=0
MIRROR=""
SITE_DIR="$PWD"
LIVERELOAD=0
USERNAME="${GITHUB_USER:-}"

# ---------- 输出颜色 ----------
if [ -t 1 ]; then
  C_RED=$'\033[31m'; C_GRN=$'\033[32m'; C_YEL=$'\033[33m'
  C_BLU=$'\033[36m'; C_BLD=$'\033[1m'; C_END=$'\033[0m'
else
  C_RED=""; C_GRN=""; C_YEL=""; C_BLU=""; C_BLD=""; C_END=""
fi

info()  { printf '%s[info]%s  %s\n'  "$C_BLU" "$C_END" "$*"; }
ok()    { printf '%s[ ok ]%s  %s\n'  "$C_GRN" "$C_END" "$*"; }
warn()  { printf '%s[warn]%s  %s\n'  "$C_YEL" "$C_END" "$*"; }
err()   { printf '%s[fail]%s  %s\n'  "$C_RED" "$C_END" "$*" >&2; }
title() { printf '\n%s==>%s %s%s%s\n' "$C_BLD" "$C_END" "$C_BLD" "$*" "$C_END"; }

usage() {
  sed -n '2,19p' "$0" | sed 's/^#\{1,2\} \{0,1\}//'
  exit 0
}

# ---------- 参数解析 ----------
while [ $# -gt 0 ]; do
  case "$1" in
    --init)        DO_INIT=1; DO_SERVE=0; DO_INSTALL=0 ;;
    --no-serve)    DO_SERVE=0 ;;
    --build-only)  DO_SERVE=0; BUILD_ONLY=1 ;;
    --gh-pages)    USE_GHP=1 ;;
    --livereload)  LIVERELOAD=1 ;;
    --mirror)      MIRROR="${2:-}"; shift ;;
    --dir)         SITE_DIR="${2:-}"; shift ;;
    -h|--help)     usage ;;
    *)             err "未知参数: $1"; usage ;;
  esac
  shift
done

# ---------- 镜像地址表(兼容 bash 3.2,不用关联数组) ----------
mirror_url() {
  case "$1" in
    tsinghua|tuna)   echo "https://mirrors.tuna.tsinghua.edu.cn/rubygems/" ;;
    rubychina|china) echo "https://gems.ruby-china.com/" ;;
    tencent)         echo "https://mirrors.tencent.com/rubygems/" ;;
    aliyun)          echo "https://mirrors.aliyun.com/rubygems/" ;;
    official)        echo "https://rubygems.org/" ;;
    *)               echo "" ;;
  esac
}
CANDIDATES="tsinghua rubychina tencent aliyun"

# 测速挑选最快镜像
pick_mirror() {
  local best="tsinghua" best_t=999.0 name url t
  info "正在测速挑选最快的镜像源(每个最多等 6 秒)..."
  for name in $CANDIDATES; do
    url="$(mirror_url "$name")"
    t="$(curl -o /dev/null -s -m 6 -w '%{time_total}' "${url}specs.4.8.gz" 2>/dev/null || echo 999)"
    case "$t" in
      ''|*[!0-9.]*) t=999 ;;
    esac
    printf '        %-12s %ss\n' "$name" "$t"
    if awk -v a="$t" -v b="$best_t" 'BEGIN{exit !(a<b)}'; then
      best_t="$t"; best="$name"
    fi
  done
  MIRROR="$best"
  if awk -v a="$best_t" 'BEGIN{exit !(a>=6)}'; then
    warn "所有镜像测速都超时,可能网络不通,仍将使用 $MIRROR 继续尝试"
  fi
}

# ---------- 0. 环境检查 ----------
title "0/5 检查环境"
OS_NAME="$(uname -s)"
info "操作系统: $OS_NAME"

if ! command -v ruby >/dev/null 2>&1; then
  err "没找到 ruby,请先安装:"
  case "$OS_NAME" in
    Darwin) echo "    brew install ruby" ;;
    Linux)  echo "    sudo apt install ruby-full build-essential zlib1g-dev   # Ubuntu/Debian"
            echo "    sudo dnf install ruby ruby-devel @development-tools     # Fedora/CentOS" ;;
  esac
  exit 1
fi
ok "ruby  $(ruby -v | awk '{print $2}')"
ok "gem   $(gem -v)"

# macOS 系统自带 Ruby 会被 SIP 保护,必须 sudo
SUDO=""
GEM_DIR="$(gem env gemdir 2>/dev/null || echo /usr/local)"
if [ ! -w "$GEM_DIR" ]; then
  case "$OS_NAME" in
    Darwin)
      warn "检测到使用macOS系统自带Ruby(不可写目录): $GEM_DIR"
      warn "强烈建议改用 Homebrew 版本: brew install ruby,然后重开终端"
      ;;
  esac
  if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
    warn "将使用 sudo 安装(会提示输入开机密码)"
  fi
fi

# ---------- 1. 换 gem 源 ----------
title "1/5 配置 gem 镜像源"
if [ -z "$MIRROR" ]; then
  pick_mirror
fi
MURL="$(mirror_url "$MIRROR")"
if [ -z "$MURL" ]; then
  err "无效的镜像名: $MIRROR (可选: tsinghua/rubychina/tencent/aliyun/official)"
  exit 1
fi
info "使用镜像: $MIRROR  ($MURL)"

# 清掉所有旧源,只留选中的这一个
for s in $(gem sources -l 2>/dev/null | grep -E '^https?://'); do
  $SUDO gem sources --remove "$s" >/dev/null 2>&1 || true
done
$SUDO gem sources --add "$MURL" >/dev/null 2>&1
ok "当前 gem 源:"
gem sources -l | grep -E '^https?://' | sed 's/^/        /'

# bundler 走的是 Gemfile 里的 source,必须单独配镜像
if command -v bundle >/dev/null 2>&1; then
  bundle config set --global mirror.https://rubygems.org "$MURL" 2>/dev/null || true
fi

# ---------- 2. 安装 jekyll ----------
if [ "$DO_INSTALL" = "1" ]; then
  title "2/5 安装 Jekyll(国内源通常 1-3 分钟,首次可能更久)"
  if [ "$USE_GHP" = "1" ]; then
    info "模式: github-pages gem —— 版本与 GitHub 线上构建环境完全一致,本地预览=线上效果"
    $SUDO gem install github-pages bundler --no-document || {
      err "安装失败,可尝试: 1) 换个镜像重跑 --mirror rubychina  2) 直接 push 让 GitHub 帮你构建"
      exit 1
    }
  else
    info "模式: 标准 jekyll + bundler"
    $SUDO gem install jekyll bundler --no-document || {
      err "安装失败,可尝试: 1) 换个镜像重跑 --mirror rubychina  2) 直接 push 让 GitHub 帮你构建"
      exit 1
    }
  fi
  # 装完 bundler 再补一次镜像配置
  bundle config set --global mirror.https://rubygems.org "$MURL" 2>/dev/null || true
  ok "jekyll $(jekyll -v 2>/dev/null || echo '(稍后由 bundle 决定版本)')"
  ok "bundler $(bundle -v 2>/dev/null | awk '{print $3}')"
else
  title "2/5 跳过安装(--init 模式)"
fi

# ---------- 3. 初始化博客文件 ----------
cd "$SITE_DIR" || exit 1
mkdir -p _posts assets/images

if [ -z "$USERNAME" ]; then
  if git remote -v >/dev/null 2>&1; then
    USERNAME="$(git remote get-url origin 2>/dev/null | sed -E 's#.*[:/]([A-Za-z0-9_-]+)/[A-Za-z0-9_.-]+(\.git)?$#\1#')"
  fi
  [ -z "$USERNAME" ] && USERNAME="yourname"
fi
SITE_URL="https://${USERNAME}.github.io"

if [ ! -f "_config.yml" ]; then
  cat > "_config.yml" <<'EOF'
title: 我的博客
description: 用 GitHub Pages + Jekyll 搭建
author: yourname
theme: minima
url: "https://yourname.github.io"
baseurl: ""

plugins:
  - jekyll-feed
  - jekyll-sitemap
  - jekyll-seo-tag

permalink: /:year/:month/:day/:title/
paginate: 10
EOF
  # url 用真实用户名覆盖
  if [ "$USERNAME" != "yourname" ]; then
    sed -i.bak "s#https://yourname.github.io#$SITE_URL#" "_config.yml" && rm -f "_config.yml.bak"
    sed -i.bak "s#^author: yourname#author: $USERNAME#" "_config.yml" && rm -f "_config.yml.bak"
  fi
  ok "已生成 _config.yml"
else
  warn "_config.yml 已存在,保持不变"
fi

if [ ! -f "index.md" ]; then
  cat > "index.md" <<'EOF'
---
layout: home
title: 首页
---

欢迎来到我的博客,下面是最新文章。
EOF
  ok "已生成 index.md"
fi

if [ ! -f "Gemfile" ]; then
  if [ "$USE_GHP" = "1" ]; then
    cat > "Gemfile" <<'EOF'
source "https://rubygems.org"

gem "github-pages", group: :jekyll_plugins

platforms :mingw, :x64_mingw, :mswin, :jruby do
  gem "tzinfo", ">= 1", "< 3"
  gem "tzinfo-data"
  gem "wdm", "~> 0.1.1"
end
EOF
  else
    cat > "Gemfile" <<'EOF'
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
EOF
  fi
  ok "已生成 Gemfile"
fi

if [ ! -f ".gitignore" ]; then
  cat > ".gitignore" <<'EOF'
_site/
.jekyll-cache/
.jekyll-metadata
.sass-cache/
Gemfile.lock
.DS_Store
EOF
  ok "已生成 .gitignore"
fi

TODAY="$(date +%F)"
SAMPLE="_posts/${TODAY}-hello-world.md"
if [ ! -f "$SAMPLE" ]; then
  {
    echo "---"
    echo "layout: post"
    echo "title: \"Hello World\""
    echo "date: ${TODAY} $(date +%H:%M:%S) +0800"
    echo "categories: [随笔]"
    echo "tags: [GitHub, Jekyll]"
    echo "---"
    echo ""
    echo "这是第一篇文章,用 Markdown 直接写就行。"
    echo ""
    echo "## 小标题"
    echo ""
    echo "- 列表项"
    echo "- **加粗**、\`行内代码\`"
    echo ""
    echo '```bash'
    echo 'echo "代码块"'
    echo '```'
  } > "$SAMPLE"
  ok "已生成示例文章 $SAMPLE"
fi

# ---------- 4. bundle install ----------
title "4/5 安装项目依赖 (bundle install)"
info "如果你不想本地预览,随时 Ctrl+C 中断,直接 git push 交给 GitHub 构建即可"
if command -v bundle >/dev/null 2>&1; then
  if bundle install; then
    ok "依赖安装完成"
  else
    err "bundle install 失败"
    if [ "$DO_INSTALL" = "1" ]; then
      err "应急方案: 删掉 Gemfile 和 Gemfile.lock,直接 git push,让 GitHub 在线构建"
      exit 1
    else
      warn "文件已生成,稍后装好环境再执行 bundle install 即可"
    fi
  fi
else
  warn "没找到 bundler,跳过(只生成了文件,未安装依赖)"
fi

# ---------- 5. 预览 ----------
title "5/5 完成"
ok "博客目录: $SITE_DIR"
ok "线上地址(需先建 ${USERNAME}.github.io 仓库并 push): $SITE_URL"

if [ "$BUILD_ONLY" = "1" ]; then
  info "只构建模式:"
  bundle exec jekyll build
elif [ "$DO_SERVE" = "1" ]; then
  ARGS="serve"
  [ "$LIVERELOAD" = "1" ] && ARGS="serve --livereload"
  echo ""
  ok "即将启动本地预览: http://localhost:4000"
  info "修改文章后浏览器会自动刷新(需 --livereload);Ctrl+C 停止"
  echo ""
  exec bundle exec jekyll $ARGS
else
  info "未启动预览。手动启动:  bundle exec jekyll serve"
  info "发文流程: 在 _posts/ 里新建 YYYY-MM-DD-标题.md -> git add . && git commit -m 'new post' && git push"
fi
