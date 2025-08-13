#!/bin/bash

# 最简单的GitHub Actions产物自动下载脚本
# 配置这4个变量即可使用

GITHUB_OWNER=""          # 你的GitHub用户名
GITHUB_REPO=""            # 仓库名
DEPLOY_DIR="/opt/1panel/www/sites/demo/index"      # 解压部署到的目录
GITHUB_TOKEN=""                 # GitHub Token (至少需要 public_repo 权限)

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_FILE="$SCRIPT_DIR/last_build_id"  # 状态文件

# 检查仓库的默认分支
get_default_branch() {
    local auth=""
    if [ -n "$GITHUB_TOKEN" ]; then
        auth="-H \"Authorization: token $GITHUB_TOKEN\""
    fi
    
    echo "🔍 检查仓库默认分支..." >&2
    local response
    if [ -n "$GITHUB_TOKEN" ]; then
        response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO")
    else
        response=$(curl -s "https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO")
    fi
    
    local default_branch=$(echo "$response" | jq -r '.default_branch // "main"' 2>/dev/null)
    echo "📌 默认分支: $default_branch" >&2
    echo "$default_branch"
}

# 获取最新成功的构建ID
get_latest_build_id() {
    local branch="${1:-main}"
    local auth=""
    if [ -n "$GITHUB_TOKEN" ]; then
        auth="-H \"Authorization: token $GITHUB_TOKEN\""
    fi
    
    echo "🔍 正在查询 GitHub API..." >&2
    echo "📍 仓库: $GITHUB_OWNER/$GITHUB_REPO" >&2
    echo "🌿 分支: $branch" >&2
    
    # 构建API URL - 获取所有构建，然后本地过滤（GitHub API的branch参数有问题）
    local api_url="https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/actions/runs?per_page=20"
    echo "🌐 API URL: $api_url" >&2
    
    # 执行API请求并保存响应
    local response
    if [ -n "$GITHUB_TOKEN" ]; then
        echo "🔑 使用 GitHub Token 进行认证" >&2
        response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "$api_url")
    else
        echo "⚠️  未使用 GitHub Token（可能受到API限制）" >&2
        response=$(curl -s "$api_url")
    fi
    
    # 检查curl是否成功
    local curl_exit_code=$?
    if [ $curl_exit_code -ne 0 ]; then
        echo "❌ curl 请求失败，退出码: $curl_exit_code" >&2
        return 1
    fi
    
    # 检查是否有错误信息
    local error_message=$(echo "$response" | jq -r '.message // empty' 2>/dev/null)
    if [ -n "$error_message" ]; then
        echo "❌ GitHub API 错误: $error_message" >&2
        return 1
    fi
    
    # 显示总构建数（用于调试）
    local total_count=$(echo "$response" | jq -r '.total_count // 0' 2>/dev/null)
    echo "📊 总构建数: $total_count" >&2
    
    # 调试：显示前几个构建的详细信息
    echo "🔍 前5个构建的详细信息：" >&2
    echo "$response" | jq -r --arg branch "$branch" '.workflow_runs[0:5][] | "  - ID: \(.id), Branch: \(.head_branch), Status: \(.status), Conclusion: \(.conclusion)"' >&2
    
    # 调试：检查有多少个指定分支的构建
    local branch_count=$(echo "$response" | jq -r --arg branch "$branch" '[.workflow_runs[] | select(.head_branch == $branch)] | length')
    echo "🌿 分支 '$branch' 的构建数: $branch_count" >&2
    
    # 调试：检查有多少个成功的构建（任意分支）
    local success_count=$(echo "$response" | jq -r '[.workflow_runs[] | select(.conclusion == "success")] | length')
    echo "✅ 成功构建数（任意分支）: $success_count" >&2
    
    # 调试：检查有多少个指定分支的成功构建
    local branch_success_count=$(echo "$response" | jq -r --arg branch "$branch" '[.workflow_runs[] | select(.head_branch == $branch and .conclusion == "success")] | length')
    echo "🎯 分支 '$branch' 的成功构建数: $branch_success_count" >&2
    
    # 过滤指定分支的成功构建并获取最新的ID
    echo "🔍 执行jq过滤命令..." >&2
    
    # 方法1：尝试原始的jq命令
    local build_id=$(echo "$response" | jq -r --arg branch "$branch" '.workflow_runs[] | select(.head_branch == $branch and .conclusion == "success") | .id' | head -1)
    echo "🔍 方法1结果: '$build_id'" >&2
    
    # 如果方法1失败，尝试方法2：分步过滤
    if [ -z "$build_id" ] || [ "$build_id" = "null" ]; then
        echo "🔍 方法1失败，尝试方法2..." >&2
        # 先获取所有成功的构建ID
        local success_ids=$(echo "$response" | jq -r '.workflow_runs[] | select(.conclusion == "success") | .id')
        echo "🔍 所有成功构建ID: $success_ids" >&2
        
        # 然后检查每个ID对应的分支
        for id in $success_ids; do
            local run_branch=$(echo "$response" | jq -r --arg id "$id" '.workflow_runs[] | select(.id == ($id | tonumber)) | .head_branch')
            echo "🔍 构建 $id 的分支: $run_branch" >&2
            if [ "$run_branch" = "$branch" ]; then
                build_id="$id"
                echo "🔍 方法2找到匹配: $build_id" >&2
                break
            fi
        done
    fi
    
    echo "🔍 最终结果: '$build_id'" >&2
    
    if [ -z "$build_id" ] || [ "$build_id" = "null" ]; then
        echo "❌ 未找到成功的构建记录" >&2
        echo "💡 可能的原因：" >&2
        echo "   1. 仓库中没有 GitHub Actions 工作流" >&2
        echo "   2. 没有成功完成的构建" >&2
        echo "   3. 主分支不是 'main'（可能是 'master'）" >&2
        echo "   4. GitHub Token 权限不足" >&2
        return 1
    fi
    
    echo "✅ 找到最新构建ID: $build_id" >&2
    echo "$build_id"
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
    
    # 下载到临时文件
    local download_url="https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/actions/artifacts/$artifact_id/zip"
    local zip_file=$(mktemp --suffix=.zip)
    
    echo "💾 临时下载到: $zip_file"
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
        
        # 清理临时文件和目录
        rm -rf "$temp_dir"
        rm -f "$zip_file"
        
        echo "🎉 部署完成"
        echo "📁 网站部署在: $DEPLOY_DIR"
        echo "🗑️ 临时文件已清理"
        
        # 记录这次的构建ID
        echo "$build_id" > "$STATE_FILE"
    else
        echo "❌ 下载失败"
        # 清理失败的下载文件
        rm -f "$zip_file"
        return 1
    fi
}

# 主逻辑
main() {
    # 检查配置
    if [ "$GITHUB_OWNER" = "your-username" ] || [ -z "$GITHUB_OWNER" ]; then
        echo "❌ 请先修改脚本中的 GITHUB_OWNER 变量"
        exit 1
    fi
    
    if [ -z "$GITHUB_REPO" ]; then
        echo "❌ 请先修改脚本中的 GITHUB_REPO 变量"
        exit 1
    fi
    
    if [ -z "$DEPLOY_DIR" ]; then
        echo "❌ 请先修改脚本中的 DEPLOY_DIR 变量"
        echo "⚠️  DEPLOY_DIR 不能为空，这会导致危险的文件操作！"
        exit 1
    fi
    
    # 检查部署目录是否为根目录或系统重要目录
    case "$DEPLOY_DIR" in
        "/" | "/bin" | "/usr" | "/etc" | "/var" | "/home" | "/root")
            echo "❌ 部署目录不能是系统重要目录: $DEPLOY_DIR"
            echo "⚠️  这会导致系统文件被覆盖！"
            exit 1
            ;;
    esac
    
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
    
    # 获取默认分支
    default_branch=$(get_default_branch)
    if [ -z "$default_branch" ]; then
        echo "❌ 无法确定仓库分支"
        exit 1
    fi
    
    # 获取最新构建ID
    latest_build_id=$(get_latest_build_id "$default_branch")
    
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