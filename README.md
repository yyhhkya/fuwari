# 🍥 Fuwari 二开版

![Node.js >= 20](https://img.shields.io/badge/node.js-%3E%3D20-brightgreen) 
![pnpm >= 9](https://img.shields.io/badge/pnpm-%3E%3D9-blue) 

这是一个基于 [Fuwari](https://github.com/saicaca/fuwari) 的二次开发版本，在原有功能基础上新增了许多功能，更适合中国宝宝体质~

## ✨ 关于 Fuwari

Fuwari 是一个基于 Astro 构建的现代化静态博客主题，具有以下特点：

- 🚀 基于 Astro 4.0 构建，性能卓越
- 🎨 现代化设计，支持明暗主题切换
- 📱 完全响应式设计，移动端友好
- 🔍 内置搜索功能
- 📝 支持 Markdown 和 MDX
- 🏷️ 标签和分类系统
- 💬 评论系统集成

## 🌟 二开新增特性

在原版 Fuwari 基础上，本版本新增了以下功能：

- ✅ **GitHub Actions 自动构建** - 推送代码后自动构建静态网站
- ✅ **外部服务器自动部署** - 使用脚本自动下载构建产物并部署到服务器
- ✅ **自定义页面创建** - 新增 new-page 命令，快速创建自定义页面
- ✅ **友链配置系统** - 通过 `friends_data.ts` 轻松管理友情链接
- ✅ **全局头部配置** - 通过 `head_data.ts` 统一管理统计代码和SEO标签
- ✅ **Giscus评论组件** - 通过 `GiscusComments.astro` 提供现代化评论系统
- ✅ **文章置顶功能** - 支持文章置顶显示，重要内容优先展示
- ✅ **优雅的文章排序** - 支持精确时间戳排序，确保文章按发布时间准确排列
- ✅ **导航菜单增强** - 支持二级菜单配置，桌面端悬停展开，移动端点击切换

## 🎯 项目特色

- **零配置部署** - 一次配置，终身使用
- **快速发布** - 从写作到上线只需一次 git push
- **稳定可靠** - 基于成熟的 Astro 框架和 GitHub Actions
- **易于维护** - 清晰的项目结构和完善的文档

## 🚀 快速开始

### 环境要求

- Node.js >= 20
- pnpm >= 9

### 安装和运行

```bash
git clone https://github.com/yyhhkya/fuwari.git
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

### 创建自定义页面

```bash
pnpm new-page <filename>
```

### Giscus评论组件 (`src/components/GiscusComments.astro`)

基于 GitHub Discussions 的现代化评论系统组件：

* 支持明暗主题自动切换
* 兼容 Astro 客户端导航和 swup 页面切换
* 自动处理组件生命周期和内存清理
* 支持多语言和自定义配置

**配置说明：**

```
使用前需要修改第25行的仓库配置：
script.setAttribute('data-repo', 'your-username/your-repo'); // 修改为你的GitHub仓库
script.setAttribute('data-repo-id', 'your-repo-id');         // 修改为你的仓库ID
script.setAttribute('data-category-id', 'your-category-id'); // 修改为你的分类ID
```

请访问 [Giscus官网](https://giscus.app/zh-CN) 获取你的仓库配置信息。

### 友链配置 (`src/friends_data.ts`)

用于配置友情链接数据，支持添加、修改和删除友链：

```typescript
export interface Friend {
  name: string;        // 友链名称
  url: string;         // 友链地址
  avatar: string;      // 头像链接
  description: string; // 描述信息
}
```

### 全局头部配置 (`src/head_data.ts`)

用于配置网站的全局头部代码，包括统计代码、SEO标签等：

- `analytics` - 统计代码（Google Analytics、百度统计等）
- `customMeta` - 自定义 meta 标签
- `thirdPartyScripts` - 第三方脚本
- `customHead` - 其他自定义头部内容

### 文章置顶设置

在文章的 frontmatter 中添加 `pinned: true` 即可将文章置顶：

```yaml
---
title: "重要公告"
date: 2024-01-01
pinned: true
---
```

置顶文章将在首页和归档页面优先显示，并带有置顶标识。

### 二级菜单配置 (`src/config.ts`)

在导航栏配置中支持二级菜单，可以创建下拉菜单结构：

```typescript
export const navBarConfig: NavBarConfig = {
  links: [
    LinkPreset.Home,
    LinkPreset.Archive,
    LinkPreset.About,
    {
      name: '其他',
      url: '#',  // 父级菜单使用 # 作为占位符
      children: [
        {
          name: '常用脚本',
          url: '/scripts/',
          external: false
        },
        {
          name: '用药感受',
          url: '/sleep/',
          external: false
        },
      ]
    }
  ]
}
```

**配置说明：**
- `name` - 菜单显示名称
- `url` - 链接地址（父级菜单建议使用 `#`）
- `children` - 子菜单数组
- `external` - 是否为外部链接

**功能特性：**
- 桌面端：鼠标悬停展开二级菜单
- 移动端：点击切换二级菜单显示/隐藏
- 支持无限层级嵌套
- 自动适应内容宽度

## 🛠️ 常用命令

| 命令                         | 说明      |
|:-------------------------- |:------- |
| `pnpm dev`                 | 启动开发服务器 |
| `pnpm build`               | 构建生产版本  |
| `pnpm preview`             | 预览构建结果  |
| `pnpm new-post <filename>` | 创建新文章   |
| `pnpm new-page <filename>` | 创建自定义页面 |

## 🙏 致谢

感谢 [Fuwari](https://github.com/saicaca/fuwari) 原作者提供的优秀基础框架。

---

**基于 Fuwari 二开，让博客发布更简单！** 🚀




