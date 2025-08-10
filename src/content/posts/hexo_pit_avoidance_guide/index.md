---
title: Hexo 避坑指南
published: 2022-11-29
description: ''
image: './hexo.png'
tags: [Hexo]
category: '心得体会'
draft: false 
lang: ''
---

**以下内容均以 Ubuntu 举例。每一步都需要按照我的来做，除非你明白你在做什么。**

### 安装

首先准备好环境：`curl`、`Node.js`、`Git`。

#### 安装 curl

```bash
sudo apt install curl
```

#### 安装 Node.js

```bash
sudo curl -sL https://deb.nodesource.com/setup_18.x | sudo -E bash -

sudo apt-get update

sudo apt-get install -y nodejs
```

#### 安装 Git

```bash
sudo apt-get install git
```

#### 安装 Hexo 程序

以上步骤都做完后，就可以开始安装`Hexo`了。

npm install -g hexo-cli

#### 部署 Hexo

根目录新建文件夹`Hexo`，然后cd进去。

//这里不带上 npx 的话会执行不了
npx hexo init <folder>

`folder`为新建的文件夹的名称。

如果报错了，提示权限不够，那就cd进`folder`里面。

npm install
//进到 <folder> 目录里就能去掉 npx 了
hexo g

然后把站点路径改成`/Hexo/<folder>`，运行目录改成`public`。

现在，你就能访问该网站了。

### 安装主题、插件

**以下操作均要在 /Hexo/<folder> 目录进行**

1.  我建议先挑选好主题并安装。（根据主题文档操作即可）

2.  然后看看有没有什么想要的功能但主题又没有的，然后你就可以去找对应功能的插件并安装。（根据主题文档操作即可）

3.  如果你是小白，那么我建议你先大致试一下插件的功能，看看插件跟主题兼不兼容。（大佬可跳过这一步）

4.  按照自己的需求更改`/Hexo/<folder>`的`_config.yml`（Hexo 的配置文件）以及`/Hexo/<folder>/themes/主题名字`的`_config.yml`（主题的配置文件）。


### 常用命令

**最好背下来**

#### hexo g

编译更改过或新添加的文件

#### hexo g -w

当你保存文件时会自动编译

#### hexo g -f

重新编译所有文件（包括未修改的）

**此操作类似但不等于 clean & g  
你可以用另一种方法: hexo clean && hexo g**

#### hexo clean

删除所有编译出来的文件

#### npm install 插件名/主题名

安装插件/主题

#### npm uninstall 插件名/主题名

删除插件/主题