## 0.3.0

### What's New
* **Load & Error Callbacks**: `EmbedWebView` / `EmbedWebView.network` now forward the platform delegate events verbatim: `onPageStarted`, `onProgress` (0-100, raw platform value), `onPageFinished`, `onWebResourceError` and `onHttpError`. The widget renders no loading or error UI of its own - callers decide what to show and where.
* **Raw Error Reporting**: `onHttpError` reports every HTTP 4xx/5xx the platform reports, including sub-resources on Android (where a single 404 image also triggers it). No main-frame filtering is applied, so no real failure is ever swallowed; filter by `request?.uri` if you only care about the page itself.

### Breaking Changes
* **Deprecated parameters removed**: `fontSize`, `lineHeight`, `forceExpandImageWidget` and `needFormatContent` are gone from both `EmbedWebView` constructors and from `WebViewUtils.getWebContent`. They had no effect on rendering; declare styles in your own HTML/CSS instead.

#### 新增特性
* **加载与错误回调**：`EmbedWebView` / `EmbedWebView.network` 新增 `onPageStarted`、`onProgress`（0-100 原生值）、`onPageFinished`、`onWebResourceError`、`onHttpError` 五个透传回调。组件自身不渲染任何加载态或错误态 UI，展示方式与位置完全由调用方决定。
* **错误原样上报**：`onHttpError` 上报平台报告的每一条 HTTP 4xx/5xx，包括 Android 上的子资源（如一张图片返回 404）。组件不做主框架过滤，因此不会吞掉真实错误；只关心页面本身时，调用方可按 `request?.uri` 自行过滤。

#### 破坏性变更
* **移除废弃参数**：`fontSize`、`lineHeight`、`forceExpandImageWidget`、`needFormatContent` 已从两个构造函数与 `WebViewUtils.getWebContent` 中删除。这些参数本就不参与渲染，样式请直接写在自定义 HTML/CSS 中。

## 0.2.1

### Bug Fixes
* **Web Touch Scrolling**: The injected probe sends touch drags as `embed_webview_scroll_touch:<deltaY>`, but the Web message listener only handled `resize` / `lang` / `scroll` / `scroll_fling` and silently dropped it. Dragging inside a non-scrollable embed on a touch device therefore did not move the parent page (only the fling on release worked). The missing branch is now handled with the same semantics as the wheel branch.

#### 修复
* **Web 端触摸滚动失效**：注入探针发出的触摸拖动消息为 `embed_webview_scroll_touch:<deltaY>`，而 Web 端监听器只处理了 `resize` / `lang` / `scroll` / `scroll_fling` 四种前缀，触摸消息被静默丢弃，导致触屏设备上在不可滚动区域内拖动时外层页面不跟手（仅松手甩出的惯性生效）。现已补齐该分支，语义与滚轮分支一致。

## 0.2.0

### What's New
* **Smart Gesture & Scroll Routing**: Added `scrollController` integration with native fling / inertia deceleration, viewport jitter elimination, and inner scroll protection.
* **Desktop Wheel Passthrough**: Automatically routes mouse wheels to parent `ScrollController` on macOS and Windows.
* **Web Standards**: Native postMessage listener for smooth cross-window sizing and scrolling on Web.
* **Controller Callback**: Added `onWebViewCreated` to access `WebViewController` for direct JavaScript execution.

#### 新增特性
* **多端智能手势与滚动穿透路由**：支持 `scrollController` 联动，实现原生级抛掷惯性滑行 (Fling)、屏幕绝对物理坐标防抖与内部二级滚动保护。
* **桌面端鼠标滚轮穿透**：macOS / Windows 桌面端卡片普通区域滚轮自动通过 `pointerScroll` 平滑联动外层滚动。
* **Web 端标准通信**：基于标准 HTML5 postMessage 监听跨窗口通信，全功能支持自适应与穿透。
* **控制器就绪回调**：新增 `onWebViewCreated`，方便直接执行自定义 JavaScript 交互与双向通信。

## 0.1.0

### What's New
* **Modernized Engine**: Upgraded to Dart 3 (`>=3.0.0`) and `webview_flutter: ^4.10.0+`.
* **Dynamic Auto-Height (ResizeObserver)**: Content height adapts in real-time with `ResizeObserver` when images finish loading, web fonts render, or dynamic DOM changes occur.
* **macOS Desktop Support**: Added native WKWebView support on macOS for instant desktop development and hot reload.
* **Remote URL Mode**: Added `EmbedWebView.network(url)` to embed remote web pages with dynamic auto-height.
* **Hyperlink Interception (`onLinkTap`)**: Hyperlink clicks (`<a>`) can now be intercepted via `onLinkTap` instead of navigating inside the embedded card.
* **Smooth Resize Animation**: Height changes now animate smoothly (`animate: true`, default `200ms`).
* **Initial Height Estimation**: Added `initialHeight` (default `80.0`) to eliminate visual flickers during initial load.
* **Gesture Coordination**: Added `gestureRecognizers` to coordinate touch events inside `ListView` or `SingleChildScrollView`.
* **Clean and Non-Intrusive**: No longer mutates your HTML font sizes, colors, or CSS styles, respecting your original design.
* **Silent by Default**: Internal logs are controlled via `EmbedWebView.enableLogging` (disabled by default).

#### 新增特性
* **现代化架构**：升级至 Dart 3 (`>=3.0.0`) 与 `webview_flutter: ^4.10.0+` 统一联邦架构。
* **动态高度自适应**：引入现代 Web 标准的 `ResizeObserver` 探针，彻底解决网络图片异步加载、字体渲染及动态 DOM 导致的高度截断问题。
* **macOS 桌面支持**：新增 macOS 原生 WKWebView 支持，支持在 Mac 桌面端秒级启动与热重载调试。
* **远程网页双模式**：支持本地 HTML 富文本自适应与远程网页 URL 自适应嵌入（`EmbedWebView.network`）。
* **超链接智能拦截 (`onLinkTap`)**：内置 `NavigationDelegate`，提供 `onLinkTap` 回调，默认拦截卡片内部跳转，防止用户迷失。
* **平滑高度过渡动画**：内置 `AnimatedSize`（默认 200ms `easeInOut`），高度自适应展开平滑流畅，消除视觉突兀。
* **初始预估高度**：新增 `initialHeight`（默认 80.0），消除首帧加载时的视觉跳动。
* **手势穿透协调**：支持 `gestureRecognizers` 自定义手势识别器，解决在长列表中嵌入时的滑动阻滞问题。
* **零侵入设计**：移除对原网页字号、颜色和排版的侵入式篡改，完全尊重原网页原本的 CSS 设计。
* **可控日志系统**：内部日志改由全局静态开关 `EmbedWebView.enableLogging` 控制，默认保持绝对静默。

### Breaking Changes
* Requires Dart SDK `^3.0.0` and Flutter `>=3.19.0`.
* Deprecated invasive formatting parameters (`fontSize`, `lineHeight`, `forceExpandImageWidget`) in favor of respecting original HTML and CSS.

#### 破坏性变更
* 要求 Dart SDK `^3.0.0` 与 Flutter `>=3.19.0`。
* 废弃强行覆盖字号与样式的旧参数（`fontSize`、`lineHeight`、`forceExpandImageWidget`），样式改由原网页自身 CSS 控制。

## 0.0.2

* Optimized visibility of source code.
* Updated Flutter SDK version constraints.

* 优化源代码可见性。
* 更新 Flutter SDK 版本约束。

## 0.0.1

* Initial release: basic auto-height webview widget for Flutter.

* 初始版本：Flutter 页面内嵌自适应高度 WebView 组件。
