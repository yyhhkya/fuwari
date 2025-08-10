# 🍥 Fuwari 魔改版 - 自动部署增强版

![Node.js >= 20](https://img.shields.io/badge/node.js-%3E%3D20-brightgreen) 
![pnpm >= 9](https://img.shields.io/badge/pnpm-%3E%3D9-blue) 
![Auto Deploy](https://img.shields.io/badge/Auto%20Deploy-✅-success)

基于 [Fuwari](https://github.com/saicaca/fuwari) 的魔改版本，增加了 GitHub Actions 自动构建和外部服务器自动部署功能。

## 🌟 新增特性

- ✅ **GitHub Actions 自动构建** - 推送代码后自动构建静态网站
- ✅ **外部服务器自动部署** - 使用脚本自动下载构建产物并部署到服务器

## 🚀 快速开始

```bash
git clone <your-repo-url>
cd fuwari
pnpm install
pnpm dev
```

访问 `http://localhost:4321` 查看你的博客。

## 🔧 自动部署配置

### 1. 配置部署脚本

编辑 `auto-deploy-fuwari/auto-deploy.sh` 文件：

```bash
GITHUB_OWNER="your-username"          # 你的GitHub用户名
GITHUB_REPO="your-repo-name"          # 仓库名
DEPLOY_DIR="/path/to/your/website"    # 网站部署目录
GITHUB_TOKEN="your-github-token"     # GitHub Token
```

### 2. 创建 GitHub Token

1. 访问 [GitHub Settings > Personal access tokens](https://github.com/settings/tokens)
2. 点击 "Generate new token (classic)"
3. 选择权限：`actions:read`
4. 复制生成的 token 并设置到脚本中

### 3. 设置定时任务

在服务器上设置 cron 定时任务：

```bash
# 每5分钟检查一次
*/5 * * * * /path/to/auto-deploy-fuwari/auto-deploy.sh >> /var/log/auto-deploy.log 2>&1
```

## 📝 使用说明

### 创建新文章

```bash
pnpm new-post <filename>
```

### 部署流程

1. 本地编写文章 → 2. `git push` → 3. GitHub Actions 自动构建 → 4. 服务器脚本自动部署

## 🛠️ 常用命令

| 命令                       | 说明                                    |
|:---------------------------|:---------------------------------------|
| `pnpm dev`                 | 启动开发服务器                         |
| `pnpm build`               | 构建生产版本                           |
| `pnpm new-post <filename>` | 创建新文章                             |

## 📄 许可证

本项目基于 MIT 许可证开源。

---

**快速部署，专注写作！** 🚀