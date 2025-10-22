---
title: Fuwari搭建指北
published: 2025-10-22T12:59:00
description: '想要拥有一个加载速度快、设计优雅的静态博客？Fuwari或许正是你需要的解决方案。'
image: ''
tags: ['Astro', 'Fuwari']
category: '心得体会'
draft: false
pinned: false
lang: ''
---

## 环境准备

在开始之前，请确保你的系统满足以下要求：

- Node.js >= 20
- pnpm >= 9
- Git

### 安装 Node.js

1. 访问 [Node.js 官网](https://nodejs.org/)，下载并安装 Node.js LTS 版本
2. 安装完成后，打开终端，验证安装：
   ```bash
   node --version
   ```

### 安装 pnpm

在终端中执行以下命令安装 pnpm：

```bash
npm install -g pnpm
```

验证安装：
```bash
pnpm --version
```

## 安装 Fuwari

1. 克隆项目仓库：
   ```bash
   git clone https://github.com/yyhhkya/fuwari.git
   cd fuwari
   ```

2. 安装依赖：
   ```bash
   pnpm install
   ```

3. 启动开发服务器：
   ```bash
   pnpm dev
   ```

现在你可以在浏览器中访问 `http://localhost:4321` 查看博客了。

## 配置修改

### 基本配置

主要配置文件位于 `src/config.ts`，你需要修改以下内容：

- 网站标题、描述
- 作者信息
- 社交媒体链接
- 评论系统配置
- 导航菜单设置

### 自定义样式

你可以通过修改以下文件来自定义网站样式：

- `src/styles/variables.styl` - 主题颜色等变量
- `src/styles/main.css` - 全局样式
- `src/styles/markdown.css` - 文章内容样式

### 创建文章

使用以下命令创建新文章：

```bash
pnpm new-post <文章标题>
```

文章将在 `src/content/posts` 目录下创建，使用 Markdown 格式编写。

### 创建自定义页面

使用以下命令创建自定义页面：

```bash
pnpm new-page <页面名称>
```

页面将在 `src/content/spec` 目录下创建，使用 Markdown 格式编写。

## 部署方案

### GitHub Pages 部署

1. 在 GitHub 仓库设置中启用 GitHub Pages
2. 配置 GitHub Actions 工作流（项目已内置）
3. 推送代码后会自动构建并部署

### 服务器部署

1. 配置 `auto-deploy-fuwari/auto-deploy.sh` 脚本中的服务器信息
2. 在服务器上设置好 nginx 配置
3. GitHub Actions 构建完成后会自动部署到服务器

## 功能说明

Fuwari 二开版包含以下主要功能：

- 🎨 明暗主题切换
- 🔍 内置搜索功能
- 📝 Markdown 和 MDX 支持
- 🏷️ 标签和分类系统
- 💬 Giscus 评论系统
- 📱 响应式设计
- 🔝 文章置顶
- 🔗 友链管理
- 📊 统计代码集成
- 🚀 自动部署

## 常见问题

1. **构建失败怎么办？**
   - 检查 Node.js 版本是否符合要求
   - 确保使用 pnpm 安装依赖
   - 查看 GitHub Actions 日志定位具体错误

2. **如何修改友链？**
   - 编辑 `src/friends_data.ts` 文件
   - 按照已有格式添加或修改友链信息

3. **如何添加统计代码？**
   - 在 `src/head_data.ts` 中添加统计代码
   - 支持百度统计、Google Analytics 等

## 结语

Fuwari 提供了一个现代化、功能完善的博客解决方案。通过本教程的指引，你应该已经能够成功搭建并运行自己的博客。如果在使用过程中遇到问题，欢迎查阅 [项目文档](https://github.com/yyhhkya/fuwari) 或提交 Issue。
