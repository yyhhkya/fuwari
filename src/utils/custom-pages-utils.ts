import { type CollectionEntry, getCollection } from "astro:content";

export type CustomPage = CollectionEntry<"spec">;

/**
 * 获取所有自定义页面
 */
export async function getCustomPages(): Promise<CustomPage[]> {
	const pages = await getCollection("spec");
	return pages.sort((a, b) => a.slug.localeCompare(b.slug));
}

/**
 * 根据slug获取自定义页面
 */
export async function getCustomPageBySlug(
	slug: string,
): Promise<CustomPage | undefined> {
	const pages = await getCustomPages();
	return pages.find((page) => page.slug === slug);
}

/**
 * 获取自定义页面的URL
 */
export function getCustomPageUrl(slug: string): string {
	return `/${slug}/`;
}

/**
 * 检查是否为自定义页面路径
 */
export function isCustomPagePath(path: string): boolean {
	// 移除开头和结尾的斜杠
	const cleanPath = path.replace(/^\/|\/$/g, "");

	// 检查是否为单级路径（不包含子路径）
	return cleanPath.length > 0 && !cleanPath.includes("/");
}

/**
 * 从路径提取页面slug
 */
export function extractSlugFromPath(path: string): string {
	return path.replace(/^\/|\/$/g, "");
}

/**
 * 获取页面导航信息（用于导航栏等）
 */
export async function getCustomPagesNavigation() {
	const pages = await getCustomPages();

	return pages.map((page) => ({
		name:
			page.data.title || page.slug.charAt(0).toUpperCase() + page.slug.slice(1),
		url: getCustomPageUrl(page.slug),
		external: false,
		icon: page.data.icon,
		description: page.data.description,
	}));
}
