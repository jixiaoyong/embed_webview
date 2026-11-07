## 0.1.0

### What's New / 新增特性
* **Modernized Engine / 现代化架构**: Upgraded to Dart 3 (`>=3.0.0`) and `webview_flutter: ^4.10.0+`. / 升级至 Dart 3 与 `webview_flutter 4.x` 联邦架构。
* **Dynamic Auto-Height / 动态高度自适应**: Content height adapts in real-time with `ResizeObserver` when images finish loading, web fonts render, or dynamic DOM changes occur. / 引入现代 Web 标准的 `ResizeObserver` 探针，彻底解决网络图片加载、字体渲染及动态 DOM 导致的高度截断问题。
* **macOS Desktop Support / 新增 macOS 桌面支持**: Added native WKWebView support on macOS for instant desktop development and hot reload. / 支持 macOS 原生 WKWebView，可在 Mac 桌面端秒级启动与热重载调试。
* **Remote URL Mode / 远程网页双模式**: Added `EmbedWebView.network(url)` to embed remote web pages with dynamic auto-height. / 支持本地 HTML 富文本与远程 URL 双模式嵌入，动态注入探针自适应。
* **Hyperlink Interception / 超链接智能拦截 (`onLinkTap`)**: Hyperlink clicks (`<a>`) can now be intercepted via `onLinkTap` instead of navigating inside the embedded card. / 内置 `NavigationDelegate`，提供 `onLinkTap` 回调，默认拦截卡片内部跳转，防止用户迷失。
* **Smooth Resize Animation / 平滑高度动画**: Height changes now animate smoothly (`animate: true`, default `200ms`). / 内置 `AnimatedSize`，高度自适应展开平滑流畅，消除视觉突兀。
* **Initial Height Estimation / 预估高度**: Added `initialHeight` (default `80.0`) to eliminate visual flickers during initial load. / 新增初始预估高度，消除首帧加载跳动。
* **Gesture Coordination / 手势穿透协调**: Added `gestureRecognizers` to coordinate touch events inside `ListView` or `SingleChildScrollView`. / 开放 `gestureRecognizers`，解决在长列表中嵌入时的滑动阻滞问题。
* **Clean and Non-Intrusive / 零侵入设计**: No longer mutates your HTML font sizes, colors, or CSS styles, respecting your original design. / 移除强行篡改字号与颜色的侵入式逻辑，完全尊重原网页原本的 CSS 设计。
* **Silent by Default / 可控日志系统**: Internal logs are controlled via `EmbedWebView.enableLogging` (disabled by default). / 内部日志改由全局开关控制，默认保持绝对静默。

### Breaking Changes / 破坏性变更
* Requires Dart SDK `^3.0.0` and Flutter `>=3.19.0`. / 要求 Dart SDK `^3.0.0` 与 Flutter `>=3.19.0`。
* Deprecated invasive formatting parameters (`fontSize`, `lineHeight`, `forceExpandImageWidget`) in favor of respecting original HTML and CSS. / 废弃强行覆盖字号与样式的旧参数，改由原网页自身 CSS 控制。

## 0.0.2

* Optimized visibility of source code. / 优化源代码可见性。
* Updated Flutter SDK version constraints. / 更新 Flutter SDK 版本约束。

## 0.0.1

* Initial release: basic auto-height webview widget for Flutter. / 初始版本：Flutter 页面内嵌自适应高度 WebView 组件。
