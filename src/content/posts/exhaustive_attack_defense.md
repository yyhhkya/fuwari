---
title: Ubuntu SSH暴力破解审查、预防
published: 2024-08-04
description: ''
image: ''
tags: [Ubuntu, Linux]
category: '心得体会'
draft: false 
lang: ''
---

`/var/log/auth.log`是记录身份验证和授权相关事件的日志文件。这个文件通常包含了用户登录尝试（成功或失败）、SSH活动、sudo使用以及PAM（Pluggable Authentication Modules，可插拔认证模块）相关的活动等信息。

本脚本通过分析log日志检查服务器是否被暴力破解

已集成一些暴力破解预防手段

## 脚本仓库

[https://github.com/yyhhkya/Exhaustive\_attack\_defense](https://github.com/yyhhkya/Exhaustive_attack_defense)