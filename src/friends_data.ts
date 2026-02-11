// 友链数据类型定义
export interface Friend {
	name: string;
	url: string;
	avatar: string;
	description: string;
}

// 友链数据
export const friends: Friend[] = [
	{
		name: "Wer Blog",
		url: "https://blog.isyyo.com/",
		avatar: "https://blog.isyyo.com/favicon/logo.png",
		description: "The only way to do great is to love what you do",
	},
];
