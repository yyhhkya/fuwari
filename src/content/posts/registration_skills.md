---
title: 备案技巧 根据访客来源屏蔽管局检查
published: 2022-12-03
description: ''
image: ''
tags: [备案]
category: '心得体会'
draft: false 
lang: ''
---

## 前言

备案过程过于麻烦，像博客不能有评论、友链之类的。

## 原理

在备案通过前几分钟，会有一个来自 `*.beian.miit.gov.cn` 的访问，由此判断管局审核都是在备案后台打开网站链接进行审核的。以前的备案都是通过管局IP的检测，而来路比IP要容易还可靠。

## 教程

Nginx 可使用如下配置：

```php
if ($http_referer ~* "beian.miit.gov.cn") {
    rewrite / /block_beian.html break;
}
```

然后 `block_beian.html` 页面要不能有其他内容，还要有备案号。例如，页面就居中“Hello World”，底部居中 `备案号` ，完全符合所有要求。
