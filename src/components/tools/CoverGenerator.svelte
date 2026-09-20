<script lang="ts">
import { SvelteMap } from "svelte/reactivity";
import Dropdown from "./Dropdown.svelte";

/** Iconify 单个图标的数据，全部按需从 api.iconify.design 取。 */
interface CoverIcon {
	name: string;
	body: string;
	width: number;
	height: number;
}

/* ---------------------------------------------------------------- 画板 */

interface RatioOption {
	label: string;
	value: number;
}

/** 内容层里的一块：图标盒子，或一段文字 */
interface CoverPart {
	kind: "icon" | "text";
	value: string;
	width: number;
}

const RATIOS: RatioOption[] = [
	{ label: "1:1", value: 1 },
	{ label: "4:3", value: 4 / 3 },
	{ label: "16:9", value: 16 / 9 },
	{ label: "21:9", value: 21 / 9 },
];
const BASE_HEIGHT = 600;

let ratio = $state(16 / 9);
let scale = $state(1);
let format = $state("image/png");
let filename = $state("cover");

/* ---------------------------------------------------------------- 内容 */

let leftText = $state("示例");
let rightText = $state("文本");
let fontWeight = $state(400);
let fontFamily = $state("sans");
let customFontName = $state("");
let fontVersion = $state(0);

const FONT_STACKS: Record<string, string> = {
	sans: '"Roboto", system-ui, -apple-system, "Segoe UI", "Noto Sans SC", "PingFang SC", "Microsoft YaHei", sans-serif',
	serif:
		'"Noto Serif SC", "Songti SC", "SimSun", Georgia, "Times New Roman", serif',
	mono: '"JetBrains Mono Variable", ui-monospace, SFMono-Regular, Menlo, Consolas, monospace',
};

const fontOptions = $derived([
	{ value: "sans", label: "无衬线" },
	{ value: "serif", label: "衬线" },
	{ value: "mono", label: "等宽" },
	...(customFontName ? [{ value: "custom", label: "自定义字体" }] : []),
]);

const formatOptions = [
	{ value: "image/png", label: "PNG" },
	{ value: "image/jpeg", label: "JPEG" },
	{ value: "image/webp", label: "WebP" },
];

let showIcon = $state(true);
let iconPosition = $state<"left" | "middle" | "right">("left");
let iconName = $state("lucide:image");
let iconQuery = $state("");
let searchResults = $state<string[]>([]);
let searchStatus = $state<"idle" | "loading" | "empty" | "offline" | "limited">(
	"idle",
);
/** 搜过的词缓存下来，避免来回改词重复打接口 */
const searchCache = new SvelteMap<string, string[]>();
/** 缩略图数据的加载状态，用来区分「还在加载」和「加载失败」 */
let thumbState = $state<"idle" | "loading" | "error">("idle");
let iconError = $state("");

let bgImage = $state<HTMLImageElement | null>(null);
let bgImageLabel = $state("");

/* ---------------------------------------------------------------- 样式 */

/** 字号 / 图标尺寸的滑块上下限；锁比例时按倍率收窄 */
const FONT_SIZE_MIN = 16;
const FONT_SIZE_MAX = 200;
const ICON_SIZE_MIN = 24;
const ICON_SIZE_MAX = 320;

let fontSize = $state(64);
let iconSize = $state(96);
let iconRadius = $state(28);
let gap = $state(28);

/** 锁定图标与文字的比例：拖任一滑块，另一边按比例跟着走。默认锁上 */
let lockSizes = $state(true);
/** 锁定时保存的「图标 / 文字」倍率，默认 1.5 与初始尺寸一致 */
let iconTextRatio = $state(1.5);

const RATIO_PRESETS = [1, 1.5, 2];

function clamp(value: number, min: number, max: number): number {
	return Math.min(Math.max(value, min), max);
}

/*
 * 锁比例后两个尺寸互相牵制，任一滑块都不能把另一边顶出上下限，
 * 所以可用区间要按倍率收窄 —— 否则拖到底会出现「图标停在 320、文字继续涨」。
 */
const fontBounds = $derived.by(() => {
	if (!lockSizes) {
		return { min: FONT_SIZE_MIN, max: FONT_SIZE_MAX };
	}
	const min = Math.max(FONT_SIZE_MIN, Math.ceil(ICON_SIZE_MIN / iconTextRatio));
	const max = Math.min(FONT_SIZE_MAX, Math.floor(ICON_SIZE_MAX / iconTextRatio));
	return { min, max: Math.max(min, max) };
});

const iconBounds = $derived.by(() => {
	if (!lockSizes) {
		return { min: ICON_SIZE_MIN, max: ICON_SIZE_MAX };
	}
	const min = Math.max(ICON_SIZE_MIN, Math.ceil(FONT_SIZE_MIN * iconTextRatio));
	const max = Math.min(ICON_SIZE_MAX, Math.floor(FONT_SIZE_MAX * iconTextRatio));
	return { min, max: Math.max(min, max) };
});

/** 拖滑块入口：source 是用户正在拖的那一边 */
function applySize(value: number, source: "font" | "icon"): void {
	if (!lockSizes) {
		if (source === "font") {
			fontSize = clamp(Math.round(value), FONT_SIZE_MIN, FONT_SIZE_MAX);
		} else {
			iconSize = clamp(Math.round(value), ICON_SIZE_MIN, ICON_SIZE_MAX);
		}
		return;
	}
	if (source === "font") {
		fontSize = clamp(Math.round(value), fontBounds.min, fontBounds.max);
		iconSize = clamp(Math.round(fontSize * iconTextRatio), ICON_SIZE_MIN, ICON_SIZE_MAX);
	} else {
		iconSize = clamp(Math.round(value), iconBounds.min, iconBounds.max);
		fontSize = clamp(Math.round(iconSize / iconTextRatio), FONT_SIZE_MIN, FONT_SIZE_MAX);
	}
}

function toggleLockSizes(): void {
	if (!lockSizes && fontSize > 0) {
		// 以当前尺寸为准记下倍率，锁上时画面不跳
		iconTextRatio = iconSize / fontSize;
	}
	lockSizes = !lockSizes;
	if (lockSizes) {
		applySize(fontSize, "font");
	}
}

/** 锁定时换倍率：以当前字号为基准重新套用，越界就整体缩回去 */
function setIconTextRatio(next: number): void {
	iconTextRatio = next;
	iconSize = clamp(Math.round(fontSize * next), ICON_SIZE_MIN, ICON_SIZE_MAX);
	fontSize = clamp(Math.round(iconSize / next), FONT_SIZE_MIN, FONT_SIZE_MAX);
}

let textColor = $state("#111111");
let iconColor = $state("#111111");
let iconBackground = $state(false);
let iconBgColor = $state("#ffffff");
let iconBgOpacity = $state(12);

let bgColor = $state("#ffffff");
let bgOpacity = $state(100);
let scrimColor = $state("#000000");
let scrimOpacity = $state(0);

let shadowScope = $state<"all" | "text" | "icon" | "none">("none");
let shadowColor = $state("#000000");
let shadowBlur = $state(16);
let shadowX = $state(0);
let shadowY = $state(6);
let shadowOpacity = $state(60);

/* ---------------------------------------------------------------- 界面 */

let tab = $state<"content" | "style" | "export">("content");
let canvas = $state<HTMLCanvasElement>();

const pixelSize = $derived(
	`${Math.round(BASE_HEIGHT * ratio * scale)} × ${Math.round(BASE_HEIGHT * scale)} px`,
);

/* --------------------------------------------------------- 图标渲染 */

/** 按需从 Iconify API 拉到的图标：name -> 数据（响应式，缩略图靠它渲染） */
const iconData = new SvelteMap<string, CoverIcon>();

/** 已经拿到数据的搜索结果，用来渲染缩略图；数据是分批到的，会边到边出。 */
const searchIcons = $derived(
	searchResults
		.map((name) => iconData.get(name))
		.filter((icon): icon is CoverIcon => icon !== undefined),
);
/** 已光栅化的图标：`name|color` -> Image */
const iconImages = new Map<string, HTMLImageElement>();
const iconLoading = new Set<string>();

function resolveIcon(name: string): CoverIcon | undefined {
	return iconData.get(name);
}

function buildSvgDataUri(icon: CoverIcon, color: string): string {
	const body = icon.body.replaceAll("currentColor", color);
	const svg =
		`<svg xmlns="http://www.w3.org/2000/svg" width="${icon.width}" height="${icon.height}" ` +
		`viewBox="0 0 ${icon.width} ${icon.height}">${body}</svg>`;
	return `data:image/svg+xml;charset=utf-8,${encodeURIComponent(svg)}`;
}

async function ensureIcon(name: string, color: string): Promise<void> {
	const key = `${name}|${color}`;
	if (iconImages.has(key) || iconLoading.has(key)) {
		return;
	}
	const icon = resolveIcon(name);
	if (!icon) {
		return;
	}
	iconLoading.add(key);
	const image = new Image();
	await new Promise<void>((resolve) => {
		image.onload = () => resolve();
		image.onerror = () => resolve();
		image.src = buildSvgDataUri(icon, color);
	});
	iconLoading.delete(key);
	if (image.naturalWidth > 0) {
		iconImages.set(key, image);
	}
	draw();
}

/**
 * Iconify 的 JSON 端点按图标集批量取：/prefix.json?icons=a,b,c
 * 没有 /prefix/name.json 这种单图标写法。
 *
 * 公共 API 对同一 IP 有持续限流，超了返回 429。所以缩略图绝不能一个图标
 * 一个请求 —— 按图标集归并后请求数从「结果数」降到「图标集数」。
 */
interface PrefixPayload {
	width?: number;
	height?: number;
	icons?: Record<string, { body?: string; width?: number; height?: number }>;
}

/**
 * 单次搜索最多拉多少个图标集。
 * 公共 API 的限流窗口很窄，单次搜索的请求数必须封顶；超出的结果不显示缩略图。
 */
const MAX_PREFIXES_PER_SEARCH = 16;
/** 图标集请求的并发上限 */
const PREFIX_CONCURRENCY = 3;
/** 网络请求超时，防止请求挂住时界面一直停在「加载中」 */
const REQUEST_TIMEOUT_MS = 12000;

function splitName(name: string): [string, string] | null {
	const index = name.indexOf(":");
	if (index <= 0 || index === name.length - 1) {
		return null;
	}
	return [name.slice(0, index), name.slice(index + 1)];
}

async function fetchPrefixIcons(
	prefix: string,
	shorts: string[],
): Promise<boolean> {
	try {
		const response = await fetch(
			`https://api.iconify.design/${prefix}.json?icons=${encodeURIComponent(shorts.join(","))}`,
			{ signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS) },
		);
		if (!response.ok) {
			throw new Error(String(response.status));
		}
		const payload = (await response.json()) as PrefixPayload;
		const icons = payload.icons ?? {};
		for (const short of shorts) {
			const icon = icons[short];
			if (!icon?.body) {
				continue;
			}
			iconData.set(`${prefix}:${short}`, {
				name: `${prefix}:${short}`,
				body: icon.body,
				width: icon.width ?? payload.width ?? 24,
				height: icon.height ?? payload.height ?? 24,
			});
		}
		return true;
	} catch {
		return false;
	}
}

/** 按图标集归并后批量拉取，返回是否全部成功。 */
async function loadIcons(names: string[]): Promise<boolean> {
	const byPrefix = new Map<string, string[]>();
	for (const name of names) {
		if (iconData.has(name)) {
			continue;
		}
		const parts = splitName(name);
		if (!parts) {
			continue;
		}
		const [prefix, short] = parts;
		const list = byPrefix.get(prefix);
		if (list) {
			list.push(short);
		} else {
			byPrefix.set(prefix, [short]);
		}
	}

	// 命中数多的图标集优先，被截断掉的通常是只匹配一两个图标的冷门集
	const jobs = [...byPrefix.entries()]
		.sort((a, b) => b[1].length - a[1].length)
		.slice(0, MAX_PREFIXES_PER_SEARCH);
	let ok = true;
	for (let i = 0; i < jobs.length; i += PREFIX_CONCURRENCY) {
		const batch = jobs.slice(i, i + PREFIX_CONCURRENCY);
		const results = await Promise.all(
			batch.map(([prefix, shorts]) => fetchPrefixIcons(prefix, shorts)),
		);
		if (results.some((result) => !result)) {
			ok = false;
		}
	}
	return ok;
}

/** 选中图标：先拉到数据再切换，避免画布上出现一个空图标框。 */
async function selectIcon(name: string): Promise<void> {
	if (!resolveIcon(name)) {
		await loadIcons([name]);
	}
	if (resolveIcon(name)) {
		iconName = name;
		iconError = "";
	} else {
		iconError = "获取失败：图标名不存在，或已被限流（429）";
	}
}

/* 图标全部走 Iconify 公共 API，浏览器端直接搜索，不打包任何图标数据 */
let searchToken = 0;
let searchTimer: ReturnType<typeof setTimeout> | undefined;

function onIconQueryInput(event: Event): void {
	const input = event.currentTarget as HTMLInputElement;
	iconQuery = input.value;
	if (searchTimer) {
		clearTimeout(searchTimer);
	}
	const query = iconQuery.trim();
	if (!query) {
		searchToken += 1;
		searchResults = [];
		searchStatus = "idle";
		return;
	}
	searchStatus = "loading";
	// 800ms：打字时不要每个字符都打一次接口，公共 API 的限流很容易踩到
	searchTimer = setTimeout(() => {
		void runIconSearch(query);
	}, 800);
}

/**
 * 拉缩略图数据。失败必须让界面看得见 —— 之前这里静默失败，
 * 结果就是列表停在「加载缩略图…」不动，既不报错也没法重试。
 */
async function loadThumbnails(names: string[], token: number): Promise<void> {
	if (names.length === 0) {
		thumbState = "idle";
		return;
	}
	thumbState = "loading";
	const ok = await loadIcons(names);
	if (token === searchToken) {
		thumbState = ok ? "idle" : "error";
	}
}

async function retryThumbnails(): Promise<void> {
	await loadThumbnails(searchResults, searchToken);
}

async function runIconSearch(query: string): Promise<void> {
	// 带前缀的写法按精确名称处理，例如 lucide:rocket
	if (query.includes(":")) {
		searchToken += 1;
		searchResults = [];
		searchStatus = "idle";
		thumbState = "idle";
		await selectIcon(query);
		return;
	}

	const token = ++searchToken;

	// 同一个词只搜一次，退格、来回改词都不会重复打接口
	const cached = searchCache.get(query);
	if (cached) {
		searchResults = cached;
		searchStatus = cached.length > 0 ? "idle" : "empty";
		void loadThumbnails(cached, token);
		return;
	}

	try {
		const response = await fetch(
			`https://api.iconify.design/search?query=${encodeURIComponent(query)}&limit=36`,
			{ signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS) },
		);
		if (token !== searchToken) {
			return;
		}
		if (response.status === 429) {
			searchResults = [];
			searchStatus = "limited";
			thumbState = "idle";
			return;
		}
		if (!response.ok) {
			throw new Error(String(response.status));
		}
		const payload = (await response.json()) as { icons?: string[] };
		if (token !== searchToken) {
			return;
		}
		searchResults = payload.icons ?? [];
		searchCache.set(query, searchResults);
		searchStatus = searchResults.length > 0 ? "idle" : "empty";
		await loadThumbnails(searchResults, token);
	} catch {
		if (token !== searchToken) {
			return;
		}
		searchResults = [];
		searchStatus = "offline";
		thumbState = "idle";
	}
}

/* --------------------------------------------------------- 画布绘制 */

function withAlpha(hex: string, alpha: number): string {
	const clamped = Math.max(0, Math.min(1, alpha));
	let value = hex.replace("#", "");
	if (value.length === 3) {
		value = value
			.split("")
			.map((char) => char + char)
			.join("");
	}
	const r = Number.parseInt(value.slice(0, 2), 16);
	const g = Number.parseInt(value.slice(2, 4), 16);
	const b = Number.parseInt(value.slice(4, 6), 16);
	return `rgba(${r}, ${g}, ${b}, ${clamped})`;
}

function roundedRect(
	ctx: CanvasRenderingContext2D,
	x: number,
	y: number,
	w: number,
	h: number,
	radius: number,
): void {
	const r = Math.max(0, Math.min(radius, Math.min(w, h) / 2));
	ctx.beginPath();
	ctx.roundRect(x, y, w, h, r);
}

function drawImageCover(
	ctx: CanvasRenderingContext2D,
	image: HTMLImageElement,
	w: number,
	h: number,
): void {
	const iw = image.naturalWidth || image.width;
	const ih = image.naturalHeight || image.height;
	if (!iw || !ih) {
		return;
	}
	const factor = Math.max(w / iw, h / ih);
	const dw = iw * factor;
	const dh = ih * factor;
	ctx.drawImage(image, (w - dw) / 2, (h - dh) / 2, dw, dh);
}

function applyShadow(
	ctx: CanvasRenderingContext2D,
	target: "text" | "icon",
): boolean {
	const active =
		shadowScope === "all" || (shadowScope !== "none" && shadowScope === target);
	if (!active || shadowOpacity <= 0) {
		return false;
	}
	ctx.shadowColor = withAlpha(shadowColor, shadowOpacity / 100);
	ctx.shadowBlur = shadowBlur * scale;
	ctx.shadowOffsetX = shadowX * scale;
	ctx.shadowOffsetY = shadowY * scale;
	return true;
}

function clearShadow(ctx: CanvasRenderingContext2D): void {
	ctx.shadowColor = "transparent";
	ctx.shadowBlur = 0;
	ctx.shadowOffsetX = 0;
	ctx.shadowOffsetY = 0;
}

function fontStack(): string {
	if (fontFamily === "custom" && customFontName) {
		return `"${customFontName}", ${FONT_STACKS.sans}`;
	}
	return FONT_STACKS[fontFamily] ?? FONT_STACKS.sans;
}

function draw(): void {
	const element = canvas;
	if (!element) {
		return;
	}
	const ctx = element.getContext("2d");
	if (!ctx) {
		return;
	}

	// 让 effect 依赖到字体加载状态
	void fontVersion;

	const width = Math.round(BASE_HEIGHT * ratio * scale);
	const height = Math.round(BASE_HEIGHT * scale);
	element.width = width;
	element.height = height;

	ctx.clearRect(0, 0, width, height);
	ctx.imageSmoothingEnabled = true;
	ctx.imageSmoothingQuality = "high";

	// 背景层
	ctx.save();
	ctx.globalAlpha = bgOpacity / 100;
	ctx.fillStyle = bgColor;
	ctx.fillRect(0, 0, width, height);
	if (bgImage) {
		drawImageCover(ctx, bgImage, width, height);
	}
	ctx.restore();

	if (bgImage && scrimOpacity > 0) {
		ctx.save();
		ctx.globalAlpha = scrimOpacity / 100;
		ctx.fillStyle = scrimColor;
		ctx.fillRect(0, 0, width, height);
		ctx.restore();
	}

	// 内容层：图标 + 左文字 + 右文字，按 iconPosition 排序后整体水平居中、垂直居中
	ctx.font = `${fontWeight} ${fontSize * scale}px ${fontStack()}`;
	ctx.textBaseline = "middle";
	ctx.textAlign = "left";

	const gapPx = gap * scale;
	const boxSize = showIcon ? iconSize * scale : 0;
	const centerY = height / 2;

	const textParts: CoverPart[] = [leftText, rightText]
		.filter((value) => value.length > 0)
		.map((value) => ({
			kind: "text",
			value,
			width: ctx.measureText(value).width,
		}));

	/*
	 * textBaseline="middle" 对的是 em 框中线，不是字形的视觉中线，
	 * 直接画会和图标差一点。这里按字形实际包围盒算一个统一基线，
	 * 让文字块的视觉中线落在 centerY 上，和图标同心。
	 */
	let glyphAscent = 0;
	let glyphDescent = 0;
	for (const part of textParts) {
		const metrics = ctx.measureText(part.value);
		glyphAscent = Math.max(glyphAscent, metrics.actualBoundingBoxAscent ?? 0);
		glyphDescent = Math.max(
			glyphDescent,
			metrics.actualBoundingBoxDescent ?? 0,
		);
	}
	// 墨迹中心 = 绘制Y + (descent - ascent) / 2，反过来解出绘制Y
	const textY = centerY - (glyphDescent - glyphAscent) / 2;

	const iconPart: CoverPart = { kind: "icon", value: "", width: boxSize };

	let parts: CoverPart[] = textParts;
	if (boxSize > 0) {
		if (iconPosition === "left") {
			parts = [iconPart, ...textParts];
		} else if (iconPosition === "right") {
			parts = [...textParts, iconPart];
		} else {
			// 两段文字中间：图标插在左、右两段之间
			parts = [...textParts.slice(0, 1), iconPart, ...textParts.slice(1)];
		}
	}

	const total =
		parts.reduce((sum, part) => sum + part.width, 0) +
		gapPx * Math.max(0, parts.length - 1);

	let x = (width - total) / 2;

	for (const part of parts) {
		if (part.kind === "icon") {
			const shadowed = applyShadow(ctx, "icon");
			if (iconBackground) {
				ctx.fillStyle = withAlpha(iconBgColor, iconBgOpacity / 100);
				roundedRect(
					ctx,
					x,
					centerY - boxSize / 2,
					boxSize,
					boxSize,
					(iconRadius / 100) * (boxSize / 2),
				);
				ctx.fill();
			}
			const glyph = iconImages.get(`${iconName}|${iconColor}`);
			if (glyph) {
				// 有背景盒时图标往里缩一圈当内边距；没背景盒时图标就占满整个大小
				const inset = iconBackground ? boxSize * 0.22 : 0;
				const glyphSize = boxSize - inset * 2;
				ctx.drawImage(
					glyph,
					x + inset,
					centerY - glyphSize / 2,
					glyphSize,
					glyphSize,
				);
			}
			if (shadowed) {
				clearShadow(ctx);
			}
		} else {
			const shadowed = applyShadow(ctx, "text");
			ctx.fillStyle = textColor;
			ctx.fillText(part.value, x, textY);
			if (shadowed) {
				clearShadow(ctx);
			}
		}
		x += part.width + gapPx;
	}
}

$effect(() => {
	draw();
});

/** 图标颜色变了要重新光栅化；数据还没拉过就先拉。 */
async function prepareIcon(name: string, color: string): Promise<void> {
	if (!resolveIcon(name)) {
		await loadIcons([name]);
		if (!resolveIcon(name)) {
			iconError = `图标 ${name} 加载失败，请检查名称或网络`;
			return;
		}
	}
	await ensureIcon(name, color);
}

$effect(() => {
	if (!showIcon) {
		return;
	}
	void prepareIcon(iconName, iconColor);
});

/* --------------------------------------------------------- 文件处理 */

function readImageFile(file: File): Promise<HTMLImageElement> {
	return new Promise((resolve, reject) => {
		const reader = new FileReader();
		reader.onload = () => {
			const image = new Image();
			image.onload = () => resolve(image);
			image.onerror = () => reject(new Error("image decode failed"));
			image.src = String(reader.result);
		};
		reader.onerror = () => reject(new Error("read failed"));
		reader.readAsDataURL(file);
	});
}

async function handleBackgroundFile(event: Event): Promise<void> {
	const input = event.currentTarget as HTMLInputElement;
	const file = input.files?.[0];
	if (!file) {
		return;
	}
	try {
		bgImage = await readImageFile(file);
		bgImageLabel = file.name;
		if (scrimOpacity === 0) {
			scrimOpacity = 35;
		}
	} catch {
		bgImageLabel = "图片读取失败";
	}
}

async function handleFontFile(event: Event): Promise<void> {
	const input = event.currentTarget as HTMLInputElement;
	const file = input.files?.[0];
	if (!file) {
		return;
	}
	try {
		const buffer = await file.arrayBuffer();
		const family = `CoverFont${Date.now()}`;
		const face = new FontFace(family, buffer);
		await face.load();
		document.fonts.add(face);
		customFontName = family;
		fontFamily = "custom";
		fontVersion += 1;
	} catch {
		iconError = "字体加载失败";
	}
}

function handleDrop(event: DragEvent): void {
	event.preventDefault();
	const file = event.dataTransfer?.files?.[0];
	if (!file?.type.startsWith("image/")) {
		return;
	}
	void readImageFile(file).then((image) => {
		bgImage = image;
		bgImageLabel = file.name;
		if (scrimOpacity === 0) {
			scrimOpacity = 35;
		}
	});
}

/* --------------------------------------------------------- 导出 */

const EXTENSIONS: Record<string, string> = {
	"image/png": "png",
	"image/jpeg": "jpg",
	"image/webp": "webp",
};

function download(): void {
	const element = canvas;
	if (!element) {
		return;
	}
	const type = format;
	element.toBlob(
		(blob) => {
			if (!blob) {
				return;
			}
			const url = URL.createObjectURL(blob);
			const link = document.createElement("a");
			const safeName = (filename.trim() || "cover").replace(
				/[\\/:*?"<>|]/g,
				"_",
			);
			link.href = url;
			link.download = `${safeName}.${EXTENSIONS[type] ?? "png"}`;
			link.click();
			URL.revokeObjectURL(url);
		},
		type,
		0.95,
	);
}
</script>

{#snippet switchToggle(
    checked: boolean,
    onToggle: () => void,
    label: string,
)}
    <button
        type="button"
        role="switch"
        aria-checked={checked}
        aria-label={label}
        class="relative inline-flex h-5 w-9 shrink-0 items-center rounded-full transition
            {checked ? 'bg-[var(--primary)]' : 'bg-black/20 dark:bg-white/25'}"
        onclick={onToggle}
    >
        <span
            class="inline-block h-4 w-4 rounded-full bg-white shadow-sm transition-transform
                {checked ? 'translate-x-[1.125rem]' : 'translate-x-0.5'}"
        ></span>
    </button>
{/snippet}

<div class="flex flex-col gap-4">
    <!-- 预览 -->
    <div class="card-base p-4 md:p-6">
        <div class="flex items-center justify-between mb-3">
            <span class="text-sm font-medium text-black/60 dark:text-white/60">实时预览</span>
            <span class="text-xs text-black/40 dark:text-white/40">{pixelSize}</span>
        </div>
        <!-- 预览框固定高度：canvas 尺寸随比例变化，但外层盒子不变，
             否则切比例时整个控制面板会跟着上下跳 -->
        <div class="rounded-lg overflow-hidden bg-[repeating-conic-gradient(#0000000d_0%_25%,transparent_0%_50%)] bg-[length:20px_20px] p-2 h-[420px] flex items-center justify-center">
            <canvas bind:this={canvas} class="w-full h-full object-contain"></canvas>
        </div>
    </div>

    <!-- 控制面板 -->
    <div class="card-base overflow-hidden">
        <div class="flex border-b border-[var(--line-divider)]">
            {#each [{ key: "content", label: "内容" }, { key: "style", label: "样式" }, { key: "export", label: "导出" }] as item (item.key)}
                <button
                    class="flex-1 h-11 text-sm font-medium transition
                        {tab === item.key
                            ? 'text-[var(--primary)] border-b-2 border-[var(--primary)]'
                            : 'text-black/60 dark:text-white/60 hover:text-[var(--primary)]'}"
                    onclick={() => (tab = item.key as "content" | "style" | "export")}
                >{item.label}</button>
            {/each}
        </div>

        <div class="p-4 md:p-6 flex flex-col gap-5">
            {#if tab === "content"}
                <!-- 文本 -->
                <section class="flex flex-col gap-3">
                    <h3 class="text-sm font-bold text-black/80 dark:text-white/80">文本设置</h3>
                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                        <label class="flex flex-col gap-1">
                            <span class="text-xs text-black/50 dark:text-white/50">左侧文字</span>
                            <input class="input-base" type="text" bind:value={leftText} placeholder="示例" />
                        </label>
                        <label class="flex flex-col gap-1">
                            <span class="text-xs text-black/50 dark:text-white/50">右侧文字</span>
                            <input class="input-base" type="text" bind:value={rightText} placeholder="文本" />
                        </label>
                    </div>
                    <label class="flex flex-col gap-1">
                        <span class="text-xs text-black/50 dark:text-white/50">字体粗细 <b class="text-[var(--primary)]">{fontWeight}</b></span>
                        <input type="range" min="100" max="900" step="100" bind:value={fontWeight} />
                    </label>
                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-3 items-end">
                        <div class="flex flex-col gap-1">
                            <span class="text-xs text-black/50 dark:text-white/50">字体</span>
                            <Dropdown label="字体" bind:value={fontFamily} options={fontOptions} />
                        </div>
                        <label class="btn-regular rounded-lg h-9 px-3 text-xs cursor-pointer">
                            上传字体
                            <input class="hidden" type="file" accept=".ttf,.otf,.woff,.woff2" onchange={handleFontFile} />
                        </label>
                    </div>
                </section>

                <!-- 图标 -->
                <section class="flex flex-col gap-3">
                    <div class="flex items-center gap-2.5">
                        <h3 class="text-sm font-bold text-black/80 dark:text-white/80">图标设置</h3>
                        {@render switchToggle(
                            showIcon,
                            () => (showIcon = !showIcon),
                            "显示图标",
                        )}
                    </div>
                    {#if showIcon}
                        <div class="flex flex-col gap-1">
                            <span class="text-xs text-black/50 dark:text-white/50">位置</span>
                            <div class="flex flex-wrap gap-2">
                                {#each [{ key: "left", label: "左侧" }, { key: "middle", label: "中间" }, { key: "right", label: "右侧" }] as option (option.key)}
                                    <button
                                        class="rounded-lg h-8 px-3 text-xs transition
                                            {iconPosition === option.key
                                                ? 'bg-[var(--primary)] text-white'
                                                : 'bg-[var(--btn-regular-bg)] text-black/70 dark:text-white/70 hover:bg-[var(--btn-regular-bg-hover)]'}"
                                        onclick={() => (iconPosition = option.key as "left" | "middle" | "right")}
                                    >{option.label}</button>
                                {/each}
                            </div>
                        </div>
                        <input
                            class="input-base"
                            type="text"
                            value={iconQuery}
                            oninput={onIconQueryInput}
                            placeholder="搜索图标库，或输入 lucide:rocket 精确指定"
                        />

                        {#if searchStatus === "loading"}
                            <p class="text-xs text-black/40 dark:text-white/40">搜索中…</p>
                        {:else if searchStatus === "limited"}
                            <p class="text-xs text-red-500">Iconify 请求过于频繁（429），等一会儿再搜</p>
                        {:else if searchStatus === "offline"}
                            <p class="text-xs text-red-500">无法连接 Iconify，请检查网络后重试</p>
                        {:else if searchStatus === "empty"}
                            <p class="text-xs text-black/40 dark:text-white/40">没有匹配的图标</p>
                        {/if}

                        {#if searchResults.length > 0 && searchIcons.length === 0}
                            {#if thumbState === "error"}
                                <p class="text-xs text-red-500 flex items-center gap-2">
                                    缩略图加载失败，可能是 Iconify 限流（429）
                                    <button class="underline" onclick={retryThumbnails}>重试</button>
                                </p>
                            {:else}
                                <p class="text-xs text-black/40 dark:text-white/40">加载缩略图…</p>
                            {/if}
                        {/if}

                        {#if searchIcons.length > 0}
                            <div class="max-h-40 overflow-y-auto rounded-lg p-2 bg-[var(--btn-regular-bg)] grid grid-cols-6 sm:grid-cols-8 gap-1">
                                {#each searchIcons as icon (icon.name)}
                                    <button
                                        title={icon.name}
                                        class="aspect-square rounded-md p-1.5 transition text-black/70 dark:text-white/70
                                            {iconName === icon.name
                                                ? 'bg-[var(--primary)] text-white'
                                                : 'hover:bg-[var(--btn-regular-bg-hover)]'}"
                                        onclick={() => selectIcon(icon.name)}
                                    >
                                        <svg class="w-full h-full" viewBox={`0 0 ${icon.width} ${icon.height}`} fill="currentColor">
                                            {@html icon.body}
                                        </svg>
                                    </button>
                                {/each}
                            </div>
                            <p class="text-xs text-black/40 dark:text-white/40">
                                共 {searchResults.length} 个结果
                                {#if thumbState === "error"}
                                    · <button class="underline text-red-500" onclick={retryThumbnails}>部分缩略图加载失败，重试</button>
                                {/if}
                            </p>
                        {:else if searchResults.length === 0 && searchStatus === "idle"}
                            <p class="text-xs text-black/40 dark:text-white/40">输入关键词搜索 Iconify 图标库（20 万+ 图标）</p>
                        {/if}

                        {#if iconError}<p class="text-xs text-red-500">{iconError}</p>{/if}
                        <p class="text-xs text-black/40 dark:text-white/40">当前：{iconName}</p>
                    {/if}
                </section>

                <!-- 背景 -->
                <section class="flex flex-col gap-3">
                    <h3 class="text-sm font-bold text-black/80 dark:text-white/80">背景图片</h3>
                    <label
                        class="flex flex-col items-center justify-center gap-1 rounded-lg border border-dashed border-[var(--line-color)] py-6 cursor-pointer transition hover:bg-[var(--btn-regular-bg)]"
                        ondragover={(event) => event.preventDefault()}
                        ondrop={handleDrop}
                    >
                        <span class="text-xs text-black/60 dark:text-white/60">点击或拖拽上传背景图</span>
                        {#if bgImageLabel}<span class="text-xs text-black/40 dark:text-white/40">{bgImageLabel}</span>{/if}
                        <input class="hidden" type="file" accept="image/*" onchange={handleBackgroundFile} />
                    </label>
                    {#if bgImage}
                        <button class="btn-regular rounded-lg h-8 px-3 text-xs self-start" onclick={() => { bgImage = null; bgImageLabel = ""; }}>
                            移除背景图
                        </button>
                    {/if}
                </section>
            {/if}

            {#if tab === "style"}
                <!-- 尺寸 -->
                <section class="flex flex-col gap-3">
                    <div class="flex flex-wrap items-center gap-x-3 gap-y-2">
                        <h3 class="text-sm font-bold text-black/80 dark:text-white/80">尺寸设置</h3>
                        <div class="flex items-center gap-1.5">
                            {@render switchToggle(
                                lockSizes,
                                toggleLockSizes,
                                "锁定图标与文字比例",
                            )}
                            <span class="text-xs text-black/50 dark:text-white/50">锁定比例</span>
                        </div>
                    </div>
                    {#if lockSizes}
                        <div class="flex flex-wrap items-center gap-2">
                            <span class="text-xs text-black/50 dark:text-white/50">
                                图标 / 文字 = {iconTextRatio.toFixed(2)}×
                            </span>
                            {#each RATIO_PRESETS as preset (preset)}
                                <button
                                    class="rounded-lg h-7 px-2.5 text-xs transition
                                        {iconTextRatio === preset
                                            ? 'bg-[var(--primary)] text-white'
                                            : 'bg-[var(--btn-regular-bg)] text-black/70 dark:text-white/70 hover:bg-[var(--btn-regular-bg-hover)]'}"
                                    onclick={() => setIconTextRatio(preset)}
                                >{preset}×</button>
                            {/each}
                            <span class="text-xs text-black/40 dark:text-white/40">拖任一滑块整体缩放</span>
                        </div>
                    {/if}
                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                        <label class="flex flex-col gap-1">
                            <span class="text-xs text-black/50 dark:text-white/50">字体大小 <b class="text-[var(--primary)]">{fontSize}px</b></span>
                            <input
                                type="range"
                                min={fontBounds.min}
                                max={fontBounds.max}
                                step="1"
                                value={fontSize}
                                oninput={(event) => applySize(Number(event.currentTarget.value), "font")}
                            />
                        </label>
                        <label class="flex flex-col gap-1">
                            <span class="text-xs text-black/50 dark:text-white/50">图标大小 <b class="text-[var(--primary)]">{iconSize}px</b></span>
                            <input
                                type="range"
                                min={iconBounds.min}
                                max={iconBounds.max}
                                step="1"
                                value={iconSize}
                                oninput={(event) => applySize(Number(event.currentTarget.value), "icon")}
                            />
                        </label>
                        <label class="flex flex-col gap-1">
                            <span class="text-xs text-black/50 dark:text-white/50">图标圆角 <b class="text-[var(--primary)]">{iconRadius}%</b></span>
                            <input type="range" min="0" max="50" bind:value={iconRadius} />
                        </label>
                        <label class="flex flex-col gap-1">
                            <span class="text-xs text-black/50 dark:text-white/50">间距 <b class="text-[var(--primary)]">{gap}px</b></span>
                            <input type="range" min="0" max="160" bind:value={gap} />
                        </label>
                    </div>
                </section>

                <!-- 颜色 -->
                <section class="flex flex-col gap-3">
                    <h3 class="text-sm font-bold text-black/80 dark:text-white/80">颜色设置</h3>
                    <div class="grid grid-cols-2 sm:grid-cols-3 gap-3">
                        <label class="flex flex-col gap-1">
                            <span class="text-xs text-black/50 dark:text-white/50">文字颜色</span>
                            <input class="color-input" type="color" bind:value={textColor} />
                        </label>
                        <label class="flex flex-col gap-1">
                            <span class="text-xs text-black/50 dark:text-white/50">图标颜色</span>
                            <input class="color-input" type="color" bind:value={iconColor} />
                        </label>
                        <label class="flex flex-col gap-1">
                            <span class="text-xs text-black/50 dark:text-white/50">背景颜色</span>
                            <input class="color-input" type="color" bind:value={bgColor} />
                        </label>
                    </div>
                    <div class="flex items-center gap-2.5">
                        <span class="text-xs text-black/60 dark:text-white/60">图标背景</span>
                        {@render switchToggle(
                            iconBackground,
                            () => (iconBackground = !iconBackground),
                            "图标背景",
                        )}
                    </div>
                    {#if iconBackground}
                        <div class="grid grid-cols-2 gap-3">
                            <label class="flex flex-col gap-1">
                                <span class="text-xs text-black/50 dark:text-white/50">图标背景色</span>
                                <input class="color-input" type="color" bind:value={iconBgColor} />
                            </label>
                            <label class="flex flex-col gap-1">
                                <span class="text-xs text-black/50 dark:text-white/50">图标背景不透明度 <b class="text-[var(--primary)]">{iconBgOpacity}%</b></span>
                                <input type="range" min="0" max="100" bind:value={iconBgOpacity} />
                            </label>
                        </div>
                    {/if}
                    <label class="flex flex-col gap-1">
                        <span class="text-xs text-black/50 dark:text-white/50">背景不透明度 <b class="text-[var(--primary)]">{bgOpacity}%</b></span>
                        <input type="range" min="0" max="100" bind:value={bgOpacity} />
                    </label>
                    {#if bgImage}
                        <div class="grid grid-cols-2 gap-3">
                            <label class="flex flex-col gap-1">
                                <span class="text-xs text-black/50 dark:text-white/50">图片遮罩色</span>
                                <input class="color-input" type="color" bind:value={scrimColor} />
                            </label>
                            <label class="flex flex-col gap-1">
                                <span class="text-xs text-black/50 dark:text-white/50">遮罩不透明度 <b class="text-[var(--primary)]">{scrimOpacity}%</b></span>
                                <input type="range" min="0" max="100" bind:value={scrimOpacity} />
                            </label>
                        </div>
                    {/if}
                </section>

                <!-- 阴影 -->
                <section class="flex flex-col gap-3">
                    <h3 class="text-sm font-bold text-black/80 dark:text-white/80">阴影设置</h3>
                    <div class="flex flex-wrap gap-2">
                        {#each [{ key: "none", label: "无" }, { key: "all", label: "全部" }, { key: "text", label: "文字" }, { key: "icon", label: "图标" }] as option (option.key)}
                            <button
                                class="rounded-lg h-8 px-3 text-xs transition
                                    {shadowScope === option.key
                                        ? 'bg-[var(--primary)] text-white'
                                        : 'bg-[var(--btn-regular-bg)] text-black/70 dark:text-white/70 hover:bg-[var(--btn-regular-bg-hover)]'}"
                                onclick={() => (shadowScope = option.key as "all" | "text" | "icon" | "none")}
                            >{option.label}</button>
                        {/each}
                    </div>
                    {#if shadowScope !== "none"}
                        <div class="grid grid-cols-2 gap-3">
                            <label class="flex flex-col gap-1">
                                <span class="text-xs text-black/50 dark:text-white/50">颜色</span>
                                <input class="color-input" type="color" bind:value={shadowColor} />
                            </label>
                            <label class="flex flex-col gap-1">
                                <span class="text-xs text-black/50 dark:text-white/50">不透明度 <b class="text-[var(--primary)]">{shadowOpacity}%</b></span>
                                <input type="range" min="0" max="100" bind:value={shadowOpacity} />
                            </label>
                            <label class="flex flex-col gap-1">
                                <span class="text-xs text-black/50 dark:text-white/50">模糊 <b class="text-[var(--primary)]">{shadowBlur}px</b></span>
                                <input type="range" min="0" max="80" bind:value={shadowBlur} />
                            </label>
                            <label class="flex flex-col gap-1">
                                <span class="text-xs text-black/50 dark:text-white/50">水平偏移 <b class="text-[var(--primary)]">{shadowX}px</b></span>
                                <input type="range" min="-40" max="40" bind:value={shadowX} />
                            </label>
                            <label class="flex flex-col gap-1">
                                <span class="text-xs text-black/50 dark:text-white/50">垂直偏移 <b class="text-[var(--primary)]">{shadowY}px</b></span>
                                <input type="range" min="-40" max="40" bind:value={shadowY} />
                            </label>
                        </div>
                    {/if}
                </section>
            {/if}

            {#if tab === "export"}
                <section class="flex flex-col gap-4">
                    <h3 class="text-sm font-bold text-black/80 dark:text-white/80">画板比例</h3>
                    <div class="flex flex-wrap gap-2">
                        {#each RATIOS as option (option.label)}
                            <button
                                class="rounded-lg h-8 px-3 text-xs transition
                                    {ratio === option.value
                                        ? 'bg-[var(--primary)] text-white'
                                        : 'bg-[var(--btn-regular-bg)] text-black/70 dark:text-white/70 hover:bg-[var(--btn-regular-bg-hover)]'}"
                                onclick={() => (ratio = option.value)}
                            >{option.label}</button>
                        {/each}
                    </div>

                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                        <label class="flex flex-col gap-1">
                            <span class="text-xs text-black/50 dark:text-white/50">缩放倍率 <b class="text-[var(--primary)]">{scale}x</b></span>
                            <input type="range" min="1" max="3" step="0.5" bind:value={scale} />
                        </label>
                        <div class="flex flex-col gap-1">
                            <span class="text-xs text-black/50 dark:text-white/50">格式</span>
                            <Dropdown label="格式" bind:value={format} options={formatOptions} />
                        </div>
                        <label class="flex flex-col gap-1">
                            <span class="text-xs text-black/50 dark:text-white/50">文件名</span>
                            <input class="input-base" type="text" bind:value={filename} />
                        </label>
                        <div class="flex flex-col gap-1">
                            <span class="text-xs text-black/50 dark:text-white/50">输出尺寸</span>
                            <span class="text-sm text-black/80 dark:text-white/80 h-9 flex items-center">{pixelSize}</span>
                        </div>
                    </div>

                    <button class="btn-regular rounded-lg h-10 px-4 font-medium w-full sm:w-auto" onclick={download}>
                        下载 {EXTENSIONS[format]?.toUpperCase() ?? "PNG"}
                    </button>
                </section>
            {/if}
        </div>
    </div>
</div>

<style>
    .input-base {
        @apply w-full h-9 px-3 rounded-lg text-sm transition outline-none
            bg-[var(--btn-regular-bg)] text-black/80 dark:text-white/80
            focus:ring-2 focus:ring-[var(--primary)];
    }

    .color-input {
        @apply w-full h-9 rounded-lg cursor-pointer bg-transparent border border-[var(--line-color)] p-0.5;
    }

    input[type="range"] {
        @apply w-full accent-[var(--primary)];
    }

    input[type="checkbox"] {
        @apply accent-[var(--primary)];
    }
</style>
