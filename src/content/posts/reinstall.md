---
title: 一键DD脚本——快速重装纯净系统的终极解决方案
published: 2025-07-18
description: ''
image: ''
tags: [Linux]
category: '百宝箱'
draft: false 
lang: ''
---

### 什么是DD脚本？

DD（Disk Deployment）脚本是一种通过自动化命令实现快速重装系统（如Linux/Windows）的工具。它直接读取网络上的镜像文件并写入硬盘，跳过传统安装步骤，实现极简、高效的系统部署。

### 为什么推荐使用一键DD脚本？

1.  **纯净无残留**  
    直接替换原有系统，避免厂商预装软件或旧系统残留，确保环境干净。
    
2.  **支持广泛**  
    兼容主流Linux发行版（CentOS/Debian/Ubuntu等）和Windows系统。  
    适用于独立服务器、VPS、虚拟机等场景。
    
3.  **极速高效**  
    全程自动化操作，10-30分钟完成系统重装，无需人工干预。
    
4.  **自定义灵活**  
    可自由选择镜像源（如官方镜像或优化版镜像），满足个性化需求。
    

### 下载脚本（Linux）

**国外服务器：**

```bash
curl -O https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh || wget -O reinstall.sh $_
```

**国内服务器：**

```bash
curl -O https://cnb.cool/bin456789/reinstall/-/git/raw/main/reinstall.sh || wget -O reinstall.sh $_
```

### 安装

```bash
bash reinstall.sh anolis      7|8|23
                    rocky       8|9|10
                    oracle      8|9
                    almalinux   8|9|10
                    opencloudos 8|9|23
                    centos      9|10
                    fedora      41|42
                    nixos       25.05
                    debian      9|10|11|12
                    opensuse    15.6|tumbleweed
                    alpine      3.19|3.20|3.21|3.22
                    openeuler   20.03|22.03|24.03|25.03
                    ubuntu      16.04|18.04|20.04|22.04|24.04|25.04 [--minimal]
                    kali
                    arch
                    gentoo
                    aosc
                    fnos
                    redhat      --img="http://access.cdn.redhat.com/xxx.qcow2"
```

### 项目地址

[https://github.com/bin456789/reinstall](https://github.com/bin456789/reinstall)