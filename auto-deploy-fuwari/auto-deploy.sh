#!/bin/bash

# 最简单的GitHub Actions产物自动下载脚本
# 配置这4个变量即可使用

GITHUB_OWNER=""          # 你的GitHub用户名
GITHUB_REPO=""            # 仓库名
DEPLOY_DIR="/opt/1panel/www/sites/demo/index"      # 解压部署到的目录
GITHUB_TOKEN=""                 # GitHub Token (至少需要 public_repo 权限)

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOWNLOAD_DIR="$SCRIPT_DIR/downloads"    # 下载文件保存目录
STATE_FILE="$SCRIPT_DIR/last_build_id"  # 状态文件

# 创建下载目录
mkdir -p "$DOWNLOAD_DIR"

# 获取最新成功的构建ID
get_latest_build_id() {
    local auth=""
    if [ -n "$GITHUB_TOKEN" ]; then
        auth="-H \"Authorization: token $GITHUB_TOKEN\""
    fi
    
    eval "curl -s $auth \"https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/actions/runs?status=success&branch=main&per_page=1\"" | \
    jq -r '.workflow_runs[0].id'
}

# 下载并解压产物
download_artifact() {
    local build_id="$1"
    local auth=""
    if [ -n "$GITHUB_TOKEN" ]; then
        auth="-H \"Authorization: token $GITHUB_TOKEN\""
    fi
    
    echo "📦 下载构建 $build_id 的产物..."
    
    # 获取artifact ID
    local artifact_id=$(eval "curl -s $auth \"https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/actions/runs/$build_id/artifacts\"" | \
    jq -r '.artifacts[] | select(.name=="astro-site") | .id')
    
    if [ "$artifact_id" = "null" ] || [ -z "$artifact_id" ]; then
        echo "❌ 未找到构建产物"
        return 1
    fi
    
    # 下载到脚本目录
    local download_url="https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/actions/artifacts/$artifact_id/zip"
    local zip_file="$DOWNLOAD_DIR/astro-site-$build_id.zip"
    
    echo "💾 下载到: $zip_file"
    eval "curl -L $auth -o \"$zip_file\" \"$download_url\""
    
    if [ $? -eq 0 ]; then
        echo "✅ 下载完成"
        echo "📂 解压到部署目录: $DEPLOY_DIR"
        
        # 创建临时解压目录
        local temp_dir=$(mktemp -d)
        unzip -q "$zip_file" -d "$temp_dir"
        
        # 清空部署目录并复制新文件
        mkdir -p "$DEPLOY_DIR"
        rm -rf "$DEPLOY_DIR"/*
        cp -r "$temp_dir"/* "$DEPLOY_DIR"/
        chmod -R 755 "$DEPLOY_DIR"
        
        # 清理临时目录
        rm -rf "$temp_dir"
        
        echo "🎉 部署完成"
        echo "📁 下载文件保存在: $zip_file"
        echo "📁 网站部署在: $DEPLOY_DIR"
        
        # 记录这次的构建ID
        echo "$build_id" > "$STATE_FILE"
    else
        echo "❌ 下载失败"
        return 1
    fi
}

# 主逻辑
main() {
    # 检查配置
    if [ "$GITHUB_OWNER" = "your-username" ]; then
        echo "❌ 请先修改脚本中的 GITHUB_OWNER 变量"
        exit 1
    fi
    
    # 检查 GitHub Token
    if [ -z "$GITHUB_TOKEN" ]; then
        echo "❌ 需要设置 GITHUB_TOKEN"
        echo "📝 请按以下步骤创建 Token："
        echo "   1. 访问 https://github.com/settings/tokens"
        echo "   2. 点击 'Generate new token (classic)'"
        echo "   3. 选择权限: actions:read"
        echo "   4. 复制生成的 token 并设置到脚本中"
        exit 1
    fi
    
    # 检查依赖
    for cmd in curl jq unzip; do
        if ! command -v $cmd &> /dev/null; then
            echo "❌ 缺少依赖: $cmd"
            echo "安装命令: sudo apt install curl jq unzip"
            exit 1
        fi
    done
    
    echo "🔍 检查新构建..."
    
    # 获取最新构建ID
    latest_build_id=$(get_latest_build_id)
    
    if [ "$latest_build_id" = "null" ] || [ -z "$latest_build_id" ]; then
        echo "❌ 无法获取构建信息"
        exit 1
    fi
    
    # 读取上次的构建ID
    last_build_id=""
    if [ -f "$STATE_FILE" ]; then
        last_build_id=$(cat "$STATE_FILE")
    fi
    
    # 比较构建ID
    if [ "$latest_build_id" != "$last_build_id" ]; then
        echo "🆕 发现新构建: $latest_build_id"
        download_artifact "$latest_build_id"
    else
        echo "✅ 没有新构建"
    fi
}

main