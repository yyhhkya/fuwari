---
title: 优化文章排序
published: 2025-10-14T07:54:00
description: '让Fuwari更优雅的排序文章'
image: ''
tags: ['Fuwari']
category: '心得体会'
draft: false
pinned: false
lang: ''
---

## 问题背景

默认情况下，Fuwari 使用简单的日期格式（如 `2025-10-14`）来标记文章发布时间。这种格式在同一天发布多篇文章时无法提供精确的排序，因为缺少时间信息。

## 修改 new-post.js

默认的 `scripts/new-post.js` 脚本只生成日期，我们需要修改它以包含完整的时间信息。

```javascript del={9} ins={6-7,10}
function getDate() {
	const today = new Date();
	const year = today.getFullYear();
	const month = String(today.getMonth() + 1).padStart(2, "0");
	const day = String(today.getDate()).padStart(2, "0");
	const hours = String(today.getHours()).padStart(2, "0");
	const minutes = String(today.getMinutes()).padStart(2, "0");

	return `${year}-${month}-${day}`;
	return `${year}-${month}-${day}T${hours}:${minutes}:00`;
}
```