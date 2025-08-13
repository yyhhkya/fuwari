import { getImage } from "astro:assets";
import rss from "@astrojs/rss";
import { getSortedPosts } from "@utils/content-utils";
import { url } from "@utils/url-utils";
import type { APIContext, ImageMetadata } from "astro";
import MarkdownIt from "markdown-it";
import { parse as htmlParser } from "node-html-parser";
import sanitizeHtml from "sanitize-html";
import { siteConfig } from "@/config";

const parser = new MarkdownIt();

// get dynamic import of images as a map collection
const imagesGlob = import.meta.glob<{ default: ImageMetadata }>(
	"/src/content/posts/**/*.{jpeg,jpg,png,gif,webp}", // add more image formats if needed
);

function stripInvalidXmlChars(str: string): string {
	return str.replace(
		// biome-ignore lint/suspicious/noControlCharactersInRegex: https://www.w3.org/TR/xml/#charsets
		/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F\uFDD0-\uFDEF\uFFFE\uFFFF]/g,
		"",
	);
}

export async function GET(context: APIContext) {
	if (!context.site) {
		throw Error("site not set");
	}

	const blog = await getSortedPosts();
	const feed = [];

	for (const post of blog) {
		const content =
			typeof post.body === "string" ? post.body : String(post.body || "");
		const cleanedContent = stripInvalidXmlChars(content);

		// convert markdown to html string
		const body = parser.render(cleanedContent);
		// convert html string to DOM-like structure
		const html = htmlParser.parse(body);
		// hold all img tags in variable images
		const images = html.querySelectorAll("img");

		for (const img of images) {
			const src = img.getAttribute("src");
			if (!src) continue;

			// Relative paths that are optimized by Astro build
			if (src.startsWith("./")) {
				// remove prefix of `./`
				const prefixRemoved = src.replace("./", "");
				// create prefix absolute path from root dir
				const imagePathPrefix = `/src/content/posts/${post.slug}/${prefixRemoved}`;

				// call the dynamic import and return the module
				const imagePath = await imagesGlob[imagePathPrefix]?.()?.then(
					(res) => res.default,
				);

				if (imagePath) {
					const optimizedImg = await getImage({ src: imagePath });
					// set the correct path to the optimized image
					img.setAttribute(
						"src",
						context.site + optimizedImg.src.replace("/", ""),
					);
				}
			} else if (src.startsWith("/")) {
				// images starting with `/` is the public dir
				img.setAttribute("src", context.site + src.replace("/", ""));
			}
			// For absolute URLs (http/https), leave them as is
		}

		feed.push({
			title: post.data.title,
			pubDate: post.data.published,
			description: post.data.description || "",
			link: url(`/posts/${post.slug}/`),
			// sanitize the new html string with corrected image paths
			content: sanitizeHtml(html.toString(), {
				allowedTags: sanitizeHtml.defaults.allowedTags.concat(["img"]),
			}),
		});
	}

	return rss({
		title: siteConfig.title,
		description: siteConfig.subtitle || "No description",
		site: context.site ?? "https://fuwari.vercel.app",
		items: feed,
		customData: `<language>${siteConfig.lang}</language>`,
	});
}
