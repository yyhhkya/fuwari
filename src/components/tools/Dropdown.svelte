<script lang="ts">
/**
 * 自绘下拉框。
 *
 * 为什么不用原生 <select>：展开后的弹层是浏览器/系统渲染的 widget，CSS 只能改
 * option 的底色，高亮条（系统蓝）、圆角、内边距一律控制不了。
 *
 * 为什么用 popover 而不是普通绝对定位：
 *   1. 外层 .card-base 是 overflow:hidden，absolute 会被裁掉；
 *   2. 页面有 .onload-animation / swup transition，祖先一旦带 transform，
 *      就会成为 position:fixed 的包含块并照样裁剪它 —— 光靠 fixed 定位是错的。
 * 用 popover="manual" 把弹层提升到 top layer，既不受祖先 transform 影响，
 * 也不受 overflow 裁剪。开合与外部点击关闭都由自己控制（不用 auto，否则
 * 点触发器时 light-dismiss 会先关掉、再被 onclick 打开，导致关不掉）。
 */
interface Option {
	value: string;
	label: string;
}

interface Props {
	options: Option[];
	value: string;
	label: string;
}

let { options, value = $bindable(), label }: Props = $props();

let open = $state(false);
let activeIndex = $state(-1);
let trigger = $state<HTMLButtonElement>();
let popup = $state<HTMLDivElement>();
let popupStyle = $state("");

const uid = $props.id();
const current = $derived(options.find((option) => option.value === value));

function supportsPopover(el: HTMLElement): el is HTMLElement & {
	showPopover: () => void;
	hidePopover: () => void;
} {
	return typeof (el as HTMLElement).showPopover === "function";
}

function updatePosition(): void {
	const el = trigger;
	if (!el) {
		return;
	}
	const rect = el.getBoundingClientRect();
	const gap = 6;
	const estimated = Math.min(options.length * 38 + 12, 300);
	const flipUp =
		window.innerHeight - rect.bottom < estimated + 12 && rect.top > estimated;

	popupStyle = flipUp
		? `left:${rect.left}px; bottom:${window.innerHeight - rect.top + gap}px; width:${rect.width}px;`
		: `left:${rect.left}px; top:${rect.bottom + gap}px; width:${rect.width}px;`;
}

function openList(): void {
	activeIndex = Math.max(
		0,
		options.findIndex((option) => option.value === value),
	);
	open = true;
}

function closeList(): void {
	open = false;
}

function choose(index: number): void {
	const option = options[index];
	if (!option) {
		return;
	}
	value = option.value;
	closeList();
	trigger?.focus();
}

function onTriggerKeydown(event: KeyboardEvent): void {
	if (!open) {
		if (
			event.key === "Enter" ||
			event.key === " " ||
			event.key === "ArrowDown"
		) {
			event.preventDefault();
			openList();
		}
		return;
	}
	if (event.key === "Escape") {
		event.preventDefault();
		closeList();
		return;
	}
	if (event.key === "ArrowDown") {
		event.preventDefault();
		activeIndex = Math.min(options.length - 1, activeIndex + 1);
		return;
	}
	if (event.key === "ArrowUp") {
		event.preventDefault();
		activeIndex = Math.max(0, activeIndex - 1);
		return;
	}
	if (event.key === "Enter") {
		event.preventDefault();
		choose(activeIndex);
	}
}

function onDocumentPointerDown(event: PointerEvent): void {
	if (!open) {
		return;
	}
	const target = event.target as Node | null;
	if (target && !trigger?.contains(target) && !popup?.contains(target)) {
		closeList();
	}
}

$effect(() => {
	const el = popup;
	if (!el) {
		return;
	}
	if (!supportsPopover(el)) {
		el.style.display = open ? "block" : "none";
		return;
	}
	if (open) {
		updatePosition();
		if (!el.matches(":popover-open")) {
			el.showPopover();
		}
		const reposition = () => updatePosition();
		window.addEventListener("scroll", reposition, true);
		window.addEventListener("resize", reposition);
		return () => {
			window.removeEventListener("scroll", reposition, true);
			window.removeEventListener("resize", reposition);
		};
	}
	if (el.matches(":popover-open")) {
		el.hidePopover();
	}
});
</script>

<svelte:document onpointerdown={onDocumentPointerDown} />

<button
    bind:this={trigger}
    type="button"
    class="flex h-9 w-full cursor-pointer items-center justify-between gap-2 rounded-lg px-3 text-left text-sm font-medium transition
        bg-[var(--btn-regular-bg)] text-black/80 hover:bg-[var(--btn-regular-bg-hover)] dark:text-white/80
        focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--primary)]"
    aria-haspopup="listbox"
    aria-expanded={open}
    aria-label={label}
    onclick={() => (open ? closeList() : openList())}
    onkeydown={onTriggerKeydown}
>
    <span class="truncate">{current?.label ?? ""}</span>
    <svg
        class="h-4 w-4 shrink-0 text-black/35 transition-transform dark:text-white/40 {open ? 'rotate-180' : ''}"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        stroke-width="2.5"
        stroke-linecap="round"
        stroke-linejoin="round"
        aria-hidden="true"
    >
        <path d="m6 9 6 6 6-6" />
    </svg>
</button>

<div
    bind:this={popup}
    id={`${uid}-list`}
    popover="manual"
    role="listbox"
    aria-label={label}
    class="popup"
    style={popupStyle}
>
    {#each options as option, index (option.value)}
        <button
            type="button"
            role="option"
            aria-selected={option.value === value}
            class="option"
            class:active={index === activeIndex}
            onmouseenter={() => (activeIndex = index)}
            onclick={() => choose(index)}
        >
            <span class="truncate">{option.label}</span>
            {#if option.value === value}
                <svg
                    class="h-3.5 w-3.5 shrink-0"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="3"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    aria-hidden="true"
                >
                    <path d="M20 6 9 17l-5-5" />
                </svg>
            {/if}
        </button>
    {/each}
</div>

<style>
    .popup {
        @apply w-auto max-h-[300px] overflow-y-auto rounded-xl border p-1
            bg-[var(--float-panel-bg)] border-[var(--line-color)] shadow-xl dark:shadow-none;
        /* 覆盖 popover 的 UA 默认定位（position:fixed; inset:0; margin:auto） */
        margin: 0;
        inset: auto;
    }

    .option {
        @apply flex h-9 w-full cursor-pointer items-center justify-between gap-2 rounded-lg px-3
            text-left text-sm transition text-black/80 dark:text-white/80;
    }

    .option.active {
        @apply bg-[var(--btn-plain-bg-hover)];
    }

    /* 选中项用主题色标出来，而不是系统的蓝条 */
    .option[aria-selected="true"] {
        @apply font-medium text-[var(--primary)];
    }
</style>
