## 0.1.0

* **架构现代化重构**：升级至 Dart 3 (`>=3.0.0`) 与 `webview_flutter: ^4.10.0+` 统一联邦架构。
* **ResizeObserver 动态高度自适应**：引入现代 Web 规范的 `ResizeObserver` 探针，彻底解决异步网络图片、字体与动态 DOM 引起的高度二次变化与截断问题。
* **双模式支持**：支持本地 HTML 富文本自适应渲染与远程网页 URL 自适应嵌入（`EmbedWebView.network`）。
* **超链接智能拦截**：内置 `NavigationDelegate`，提供 `onLinkTap` 回调，默认拦截卡片内部跳转，防止用户迷失。
* **平滑高度过渡动画**：内置 `AnimatedSize`（默认 200ms `easeInOut`）与 `initialHeight` 预估高度，消除页面从 0/1px 突变的视觉闪烁。
* **手势穿透与长列表协调**：支持 `gestureRecognizers` 自定义手势竞技识别器，解决与外层 `ListView` / `SingleChildScrollView` 的滑动冲突。
* **新增 macOS 桌面端原生支持**：通过 `webview_flutter_wkwebview` 支持 macOS 平台原生 WKWebView，支持在 Mac 桌面端极速本地开发调试。
* **Android 现代化构建升级**：示例工程适配 Gradle 8.5、AGP 8.3、Java 17 与 Android 34，真机运行畅通无阻。
* **代码治理与单一职责**：移除对原网页字号、颜色和排版的侵入式篡改，完全尊重原网页原本的 CSS 设计；内置可控日志系统（`enableLogging`）。
* **全套自动化测试**：新增针对包装工具、动态高度自适应、超链接拦截与手势滚动穿透的单元与 Widget 测试。

## 0.0.2

* optimized: change the visiblity of source code
* change the flutter sdk version

## 0.0.1

* initial: add embed_webview, a widget that displays web view content inner flutter widget. It can change its size automatically to fit the children.
