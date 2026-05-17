---
title: 极验v3滑动拼图验证码逆向与绕过
published: 2026-05-17T20:24:00
description: '深入解析极验(Geetest) v3滑动验证码的逆向工程，从加密算法、轨迹模拟到缺口识别的完整破解'
image: './cover.png'
tags: ['逆向', '极验']
category: '心得体会'
draft: false
pinned: false
lang: ''
---

## 前言

极验验证码（Geetest）是国内使用最广泛的行为验证码之一，其 v3 版本的滑动拼图验证码在各大网站中随处可见。本文将详细介绍其逆向分析和自动化绕过的完整流程。

> **免责声明**：本文仅用于技术研究和学习，请勿用于非法用途。验证码的目的是保护网站安全，请合理使用相关技术。

## 整体架构

极验 v3 滑动验证的核心流程可以简化为三个关键阶段，每个阶段对应一个 `w` 参数：

| 阶段 | 参数 | 说明 |
|------|------|------|
| 初始化 | `w1` | 携带配置信息，获取加密参数 `c` 和 `s` |
| 模拟行为 | `w2` | 提交鼠标轨迹、浏览器性能数据等行为信息 |
| 最终验证 | `w3` | 提交缺口位置、滑动轨迹，获取 `validate` |

这三个 `w` 参数是整个逆向的核心，它们都经过多层加密，包括 AES-CBC、RSA 和字符串混淆。

文中的 `gettype.php`、`get.php`、`ajax.php` 都是极验服务端（`api.geetest.com`）的 HTTP API 接口，返回格式为 JSONP。每个接口在协议中承担不同职责：

| 接口 | 用途 |
|------|------|
| `gettype.php` | 根据 `gt` 查询验证码类型配置，返回 JS 文件地址等信息 |
| `get.php` | 核心数据接口，用于获取加密参数 `c/s`、获取图片素材等 |
| `ajax.php` | 提交验证结果，提交 `w2`（行为数据）和 `w3`（最终结果） |

## 加密体系逆向

### 1. 自定义 Base64 编码

极验使用了一套**非标准的 Base64 编码**，字符集和位掩码都被修改过：

```python
# 极验自定义 Base64 字符集（注意包含括号）
charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789()'
pad_char = '.'  # 填充字符也是自定义的

# 位掩码（经过打乱的排列）
masks = [7274496, 9483264, 19220, 235]
```

编码过程使用 4 个掩码从 24 位数据中提取出 4 个索引值，而非标准的 6 位一组。每 3 个字节被编码为 4 个自定义字符。

### 2. AES-CBC 加密

极验使用 AES-CBC 模式，但细节上做了特殊处理：

- **密钥**：16 位随机字符串，但需要先通过 `parse_string_to_wordarray` 函数转换为 32 位整数数组，然后再转为字节
- **IV 初始化向量**：固定为 `0000000000000000`（全零）
- **填充**：PKCS7 填充

```python
def AES_O(plaintext: str, str_16: str) -> list[int]:
    key_words = parse_string_to_wordarray(str_16)
    key = b''.join(w.to_bytes(4, 'big') for w in key_words)
    iv = b'0000' * 4  # 固定 IV
    pad_len = 16 - len(plaintext) % 16
    plaintext_padded = plaintext.encode() + bytes([pad_len] * pad_len)
    cipher = AES.new(key, AES.MODE_CBC, iv)
    return list(cipher.encrypt(plaintext_padded))
```

### 3. RSA 加密

极验在 v3 中使用 RSA 加密传输 AES 密钥（即 16 位随机字符串）。公钥参数（n 和 e）硬编码在 JavaScript 中，需要从 JSBN 大整数格式中提取：

```python
# 从 JS 中提取的 RSA 公钥参数（n 的 37 个分段值）
_GEE_PUB_KEY_N = _parse_jsbn_bigint({
    0: 134982529, 1: 254232810, 2: 164556709, ...
    "t": 37, "s": 0,
})
_GEE_RSA_KEY = RSA.construct((_GEE_PUB_KEY_N, 65537))
```

### 4. 字符串混淆算法

`encrypt_string` 函数是极验对压缩后的轨迹数据做二次混淆的关键函数：

```python
def encrypt_string(e: str, t: list[int], n: str) -> str:
    s = t[0]  # 系数1
    a = t[2]  # 系数2
    _ = t[4]  # 系数3
    # 根据 c 数组和 s 字符串中的十六进制值
    # 计算插入位置: (s * c² + a * c + _) % len(e)
    # 在字符串中插入字符实现混淆
```

其中 `t` 参数就是前面阶段获取的 `c` 数组，`n` 是 `s` 字符串。这相当于一个动态的混淆器，每次验证的混淆方式都不同。

### 5. 简化版 MD5

极验使用了一个 MD5 的变体来计算 `rp` 参数，但实际效果与标准 MD5 一致：

```python
def simple_md5(message: str) -> str:
    return hashlib.md5(message.encode()).hexdigest()
```

## 数据加密流程

16 位随机种子 `str_16` 是整个加密体系的根密钥：

```
str_16 = four_random_chart() * 4  # 例如 "a1b2c3d4e5f6g7h8"
     │
     ├── RSA 加密 → 附加到 w 参数末尾
     │
     └── AES 加密密钥 → 加密 payload
              │
              └── 自定义 Base64 编码 → w 参数主体
```

## 第一阶段：w1 与初始化

流程的第一步是获取验证码配置和加密参数：

1. **获取 `gt` 和 `challenge`**：这两个值由业务服务器提供，标识了一个验证码会话
2. **调用 `gettype.php`**：获取 JS 配置信息，确认验证码类型
3. **构造 `w1`**：将配置信息（gt、challenge、API 地址等）序列化为 JSON，先用 AES 加密，再用自定义 Base64 编码，最后附上 RSA 加密的种子
4. **调用 `get.php`**：传入 `w1`，获取加密参数 `c`（数组）和 `s`（字符串）

```python
w1 = get_w1(gt, challenge, str_16)
# w1 = AES_Base64(config_json) + RSA(seed)
# 返回: c = [12, 98, 43, ...], s = "c7c3e211..."
```

## 第二阶段：w2 与行为模拟

这是最复杂的一个阶段，需要模拟真实用户的行为数据。

### 浏览器性能时间线伪造

极验会采集 `performance.timing` API 的数据来检测是否为真人操作。我们需要生成一套合理的浏览器加载时间线：

```python
timing = {
    "navigationStart": 1700000000000,  # 基准时间
    "fetchStart": ...,
    "domainLookupStart": ...,
    "connectStart": ...,
    "secureConnectionStart": ...,  # SSL 握手时间
    "requestStart": ..., "responseStart": ..., "domInteractive": ...,
    "loadEventEnd": ...,
}
```

这些时间戳需要符合真实的网络延迟规律（DNS 查询 5-15ms，TCP 连接 50-150ms，SSL 30-50ms，DOM 解析 50-200ms 等）。

### 鼠标轨迹模拟

在 w2 阶段，需要模拟鼠标从屏幕某个位置移动到滑块按钮的过程。轨迹生成采用**分段缓动算法**：

```python
def generate_realistic_trajectory(start_x, start_y, end_x, end_y, start_time):
    # 三个阶段缓动：开始快(0-30%)，中间慢(30-70%)，结束快(70-100%)
    # 加入随机抖动（±0.5px）模拟手抖
    # 随机时间间隔（3-25ms，符合人类反应速度）
    # 到达目标后悬停 50-150ms
    # 点击事件（down → focus → up，80-130ms 的点击时长）
```

轨迹数据随后被压缩和混淆处理：

1. **差分编码**：将绝对坐标转换为相对位移
2. **游程编码**：压缩连续重复的事件类型
3. **变长编码**：根据数值大小动态调整编码位数
4. **符号位分离**：坐标的符号单独编码
5. **自定义 Base64**：最终编码为字符串
6. **`encrypt_string` 混淆**：使用 c/s 参数进行二次混淆

```python
w2 = get_w2(gt, challenge, c, s, str_16)
# 包含: 时间线、轨迹、首次/末次事件、rp(MD5)、passtime 等
```

## 第三阶段：w3 与最终验证

### 图片还原

极验的滑块图片被分割成了 52 个小块并打乱顺序。还原顺序由一个硬编码的数组 `Ut` 定义：

```python
GEETEST_SHUFFLE_UT = [
    39, 38, 48, 49, 41, 40, 46, 47, 35, 34, 50, 51,
    33, 32, 28, 29, 27, 26, 36, 37, 31, 30, 44, 45,
    43, 42, 12, 13, 23, 22, 14, 15, 21, 20, 8, 9,
    25, 24, 6, 7, 3, 2, 0, 1, 11, 10, 4, 5, 19, 18, 16, 17,
]
```

每个小块的大小为 10x80 像素，图片总大小为 260x160 像素。通过这个数组可以将打乱的图片恢复到正常状态。

### 缺口检测

有两种方法检测滑块缺口位置：

**方法一（首选）：差异检测**
将还原后的 `fullbg`（带缺口完整图）与 `bg`（无缺口背景图）做像素级对比，找到差异最大的区域：

```python
diff = cv2.absdiff(fullbg, bg)
diff_gray = cv2.cvtColor(diff, cv2.COLOR_BGR2GRAY)
_, thresh = cv2.threshold(diff_gray, 30, 255, cv2.THRESH_BINARY)
# 用 55px 宽度的滑动窗口找到到差异最大的 x 位置
```

**方法二（备选）：Canny 边缘检测 + 模板匹配**
对还原后的 fullbg 和滑块图片做边缘检测，然后用模板匹配定位：

```python
fullbg_edge = cv2.Canny(fullbg_gray, 255, 255)
sl_edge = cv2.Canny(sl_gray, 255, 255)
result = cv2.matchTemplate(fullbg_edge, sl_edge, cv2.TM_CCOEFF_NORMED)
```

### w3 构造

得到缺口位置 `gap_x` 后，构造最终验证参数：

```python
w3 = get_w3(str_16, challenge, gap_x, c, s, gt)
# 包含:
# - userresponse: 根据缺口位置和 challenge 生成的响应
# - 滑动轨迹（easeOutExpo 缓动函数）
# - 浏览器性能时间线
# - rp: MD5(gt + challenge[:32] + passtime)
```

其中 `userresponse` 的计算方式比较特殊：

```python
def H(t: int, e: str) -> str:
    # t = 缺口位置 gap_x
    # e = challenge（32位字符串）
    # 从 challenge 的后两位解析出一个数值 n
    # 计算目标值 a = round(t) + n
    # 从 challenge 前 30 位字符池中随机选取字符
    # 使用 [1, 2, 5, 10, 50] 的面值组合出 a
```

这种设计让同样的缺口位置在不同 challenge 下会产生不同的 userresponse，增加了仿造的难度。

## 完整流程总结

```
1. GET https://api.geetest.com/gettype.php   → 查询验证码类型配置
2. GET https://api.geetest.com/get.php        → 传入 w1，获取 c(数组) 和 s(字符串)
3. GET https://api.geetest.com/ajax.php       → 提交 w2（轨迹 + 性能数据）
4. GET https://api.geetest.com/get.php        → 获取 bg, fullbg, slice 图片和新的 challenge
5. 下载图片 → 还原图片 → OpenCV 识别缺口位置 gap_x
6. GET https://api.geetest.com/ajax.php       → 提交 w3，返回 validate 和 seccode
```

## 关键技术要点

1. **加密协议逆向**：极验的加密并非标准实现，AES 的密钥需要先做 WordArray 转换，Base64 的字符集和位掩码都是自定义的

2. **行为仿真**：模拟真人操作的关键在于细节——鼠标轨迹的抖动、速度变化、点击时长、浏览器性能时间线都需要符合统计规律，不能过于规律

3. **图片处理**：由于图片被分割打乱，必须先还原才能做缺口检测。差异检测法比模板匹配更稳定，因为滑块图片本身带有阴影和渐变

4. **动态混淆**：c 数组和 s 字符串的引入让每次验证的加密参数都不同，即使完全相同的缺口位置也会产生不同的 w3 参数

## 常见问题

**Q: 为什么绕过了极验还是被风控？**
A: 可能是行为数据过于规律造成的。检查轨迹生成是否加入了足够的随机性，以及浏览器性能时间线是否合理。

**Q: 缺口检测不准怎么办？**
A: 优先使用 fullbg 和 bg 的差异检测（方法一），如果只有 fullbg 而没有 bg，再使用 Canny + 模板匹配（方法二）。

**Q: 极验 v4 和 v3 有什么区别？**
A: v4 引入了机器学习模型，增加了设备指纹、行为序列分析等更复杂的检测手段，破解难度大幅提升。