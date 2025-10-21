// 自定义全局 head 代码配置
// 用于放置统计代码、SEO 标签、第三方脚本等

export interface HeadData {
	// 统计代码 (如 Google Analytics, 百度统计等)
	analytics?: string;

	// 自定义 meta 标签
	customMeta?: string;

	// 第三方脚本
	thirdPartyScripts?: string;

	// 其他自定义 head 内容
	customHead?: string;
}

// 默认配置
export const headData: HeadData = {
	// 统计代码 (如 Google Analytics, 百度统计等)
	analytics: `
    <!-- umami -->
    <script defer src="https://umami.isyyo.com/script.js" data-website-id="d3682c95-5227-4159-aa30-8ed6badf1673"></script>
    <!-- 百度统计 -->
    <script>
    var _hmt = _hmt || [];
    (function() {
      var hm = document.createElement("script");
      hm.src = "https://hm.baidu.com/hm.js?12d0f656c7436a01cad029f73d4702da";
      var s = document.getElementsByTagName("script")[0]; 
      s.parentNode.insertBefore(hm, s);
    })();
    </script>
    <!-- 必应统计 -->
    <meta name="msvalidate.01" content="3FC7E169138CD82EEBD2C94D56D2534E" />
    <!-- 谷歌统计 -->
    <!-- Google tag (gtag.js) -->
    <script async src="https://www.googletagmanager.com/gtag/js?id=G-HNTCZ055SX"></script>
    <script>
      window.dataLayer = window.dataLayer || [];
      function gtag(){dataLayer.push(arguments);}
      gtag('js', new Date());

      gtag('config', 'G-HNTCZ055SX');
    </script>
  `,

	// 自定义 meta 标签示例
	customMeta: `
    <!-- 自定义 meta 标签 -->
    <!-- <meta name="author" content="Your Name"> -->
    <!-- <meta name="keywords" content="blog, astro, fuwari"> -->
  `,

	// 第三方脚本示例
	thirdPartyScripts: `
    <!-- 第三方脚本 -->
  `,

	// 其他自定义内容
	customHead: `
    <!-- 其他自定义 head 内容 -->
  `,
};

// 获取所有启用的 head 代码
export function getAllHeadData(): string {
	const { analytics, customMeta, thirdPartyScripts, customHead } = headData;

	// 在开发环境下不加载统计代码
	const headDataArray = [
		import.meta.env.MODE === "development" ? "" : analytics,
		customMeta,
		thirdPartyScripts,
		customHead,
	];

	return headDataArray.filter(Boolean).join("\n");
}

// 获取特定类型的 head 代码
export function getHeadDataByType(type: keyof HeadData): string {
	// 在开发环境下不返回统计代码
	if (type === "analytics" && import.meta.env.MODE === "development") {
		return "";
	}
	return headData[type] || "";
}
