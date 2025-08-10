---
title: QQ机器人：Docker 一键部署 Koishi + NapCat 指北
published: 2025-08-06
description: ''
image: ''
tags: [QQ机器人]
category: '心得体会'
draft: false 
lang: ''
---

## 简介

想要拥有一个属于自己的 QQ 机器人吗？本教程将手把手教你使用 Docker Compose 在 Linux 服务器上快速搭建现代化的 QQ 机器人解决方案。

**Koishi** 是一个跨平台、可扩展、高性能的聊天机器人框架，拥有丰富的插件生态和直观的 Web 控制台。**NapCat** 则是新一代的 QQ 协议适配器，稳定性和兼容性都非常出色。

通过本教程，你将学会：

-   🚀 使用 Docker 快速部署 Koishi + NapCat 环境
-   ⚙️ 完成 QQ 登录和适配器配置
-   🔧 安装和管理机器人插件
-   📊 使用 Web 控制台监控和管理机器人
-   🛠️ 常见问题的排查和解决方法

## 前置要求

-   Linux 系统（Ubuntu、CentOS、Debian 等）
-   已安装 Docker 和 Docker Compose

## 安装 Docker 和 Docker Compose

如果你还没有安装 Docker，可以使用以下命令快速安装：

```bash
# 一键脚本安装 Docker 和 Docker Compose
sudo bash <(curl -sSL https://linuxmirrors.cn/docker.sh)
```

## 项目结构

首先创建项目目录结构：

```bash
mkdir koishi && cd koishi
```    

## 配置文件

创建 Docker Compose 配置文件：

```bash
nano compose/koishi.yml
```

将以下内容复制到文件中：

```yaml
services:
    napcat:
    container_name: napcat
    image: mlikiowa/napcat-docker:latest
    restart: always
    environment:
        - NAPCAT_UID=${NAPCAT_UID:-1000}
        - NAPCAT_GID=${NAPCAT_GID:-1000}
        - MODE=koishi
    ports:
        - 6099:6099
    volumes:
        - ./napcat/config:/app/napcat/config
        - ./ntqq:/app/.config/QQ
        - ./koishi:/koishi
    networks:
        - koishi_network
    mac_address: "02:42:ac:11:00:02"

    koishi:
    container_name: koishi
    image: koishijs/koishi:latest
    restart: always
    environment:
        - TZ=Asia/Shanghai
    ports:
        - 5140:5140
    volumes:
        - ./ntqq:/app/.config/QQ
        - ./koishi:/koishi
    networks:
        - koishi_network

networks:
    koishi_network:
    driver: bridge
```

## 启动服务

使用以下命令启动服务：

```bash
NAPCAT_UID=$(id -u) NAPCAT_GID=$(id -g) docker-compose -f ./compose/koishi.yml up -d
```    

## 配置应用侧

### NapCat 配置

首先配置 NapCat 以连接 QQ：

1.  **访问 NapCat WebUI**：

    http://你的服务器IP:6099/webui
        
    
2.  **QQ 登录配置**：
    
    -   在 WebUI 中扫码登录你的 QQ 账号
    -   登录成功后，NapCat 会自动生成配置文件
3.  **配置 OneBot 适配器**：
    
    -   在 NapCat 配置中启用 HTTP 和 WebSocket 服务
    -   确保端口设置为 `6099`
    -   设置正确的 access\_token（可选，用于安全验证）

### Koishi 配置

接下来配置 Koishi 连接到 NapCat：

1.  **访问 Koishi 控制台**：
    
    http://你的服务器IP:5140
        
    
2.  **安装 OneBot 适配器**：
    
    -   在插件市场搜索并安装 `adapter-onebot`
3.  **配置适配器**：
    
    -   在 Koishi 控制台的「插件配置」中找到 OneBot 适配器
    -   配置连接参数：
        
        ```yaml
        protocol: http
        selfId: "你的QQ号"
        endpoint: http://napcat:6099
        token: "你设置的access_token"  # 如果设置了的话
        ```
        
4.  **启用适配器**：
    
    -   保存配置后启用 OneBot 适配器
    -   在控制台查看连接状态，确保显示为「已连接」

### 测试连接

1.  **发送测试消息**：
    
    -   在任意 QQ 群或私聊中发送：`help`
    -   如果机器人有回复，说明配置成功
2.  **查看日志**：
    
    ```bash
    # 查看 NapCat 日志
    docker logs napcat
    
    # 查看 Koishi 日志
    docker logs koishi
    ```
    

### 5\. 高级配置（可选）

1.  **数据库配置**：
    
    -   Koishi 默认使用内存数据库
    -   生产环境建议配置 MySQL 或 PostgreSQL
2.  **插件权限管理**：
    
    -   在控制台配置用户权限
    -   设置管理员账号

## 常用命令

```bash
# 查看服务状态
docker compose -f ./compose/koishi.yml ps

# 查看日志
docker compose -f ./compose/koishi.yml logs

# 停止服务
docker compose -f ./compose/koishi.yml down

# 重启服务
docker compose -f ./compose/koishi.yml restart
```

## 注意事项

1.  **端口开放**：确保服务器防火墙开放了 5140 和 6099 端口
2.  **数据持久化**：配置文件和数据会保存在本地目录中，重启容器不会丢失
3.  **权限问题**：如果遇到权限问题，检查 `NAPCAT_UID` 和 `NAPCAT_GID` 环境变量

## 故障排除

-   如果容器启动失败，使用 `docker-compose logs` 查看详细错误信息
-   确保 Docker 服务正在运行：`sudo systemctl status docker`
-   检查端口是否被占用：`netstat -tlnp | grep :5140`

## 总结

通过以上步骤，你就成功在 Linux 上搭建了 Koishi + NapCat 环境。现在可以开始配置你的 QQ 机器人并安装各种插件来扩展功能了！