#!/usr/bin/env node

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// 获取命令行参数
const args = process.argv.slice(2);
const pageName = args[0];

if (!pageName) {
    console.error('❌ 请提供页面名称');
    console.log('用法: node scripts/new-custom-page.js <页面名称>');
    console.log('示例: node scripts/new-custom-page.js portfolio');
    process.exit(1);
}

// 验证页面名称格式
if (!/^[a-z0-9-]+$/.test(pageName)) {
    console.error('❌ 页面名称只能包含小写字母、数字和连字符');
    process.exit(1);
}

// 设置文件路径
const specDir = path.join(__dirname, '..', 'src', 'content', 'spec');
const filePath = path.join(specDir, `${pageName}.md`);

// 检查文件是否已存在
if (fs.existsSync(filePath)) {
    console.error(`❌ 页面 "${pageName}" 已存在`);
    process.exit(1);
}

// 生成页面标题（首字母大写）
const pageTitle = pageName
    .split('-')
    .map(word => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ');

// 创建文件内容模板
const template = `---
title: "${pageTitle}"
description: "${pageTitle}"
---

`;

try {
    // 确保目录存在
    if (!fs.existsSync(specDir)) {
        fs.mkdirSync(specDir, { recursive: true });
    }

    // 写入文件
    fs.writeFileSync(filePath, template, 'utf8');

    console.log('✅ 自定义页面创建成功！');
    console.log(`📄 文件位置: src/content/spec/${pageName}.md`);
    console.log(`🌐 页面路径: /${pageName}/`);

} catch (error) {
    console.error('❌ 创建文件时出错:', error.message);
    process.exit(1);
}