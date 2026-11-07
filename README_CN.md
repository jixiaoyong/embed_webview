# embed_webview

[English](README.md) | [中文说明](README_CN.md)

[![pub package](https://shields.io/pub/v/embed_webview.svg?style=flat&color=brightgreen)](https://pub.dev/packages/embed_webview)
![GitHub](https://img.shields.io/github/license/jixiaoyong/embed_webview?color=brightgreen)
![support platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20macOS%20%7C%20Web-brightgreen)

`embed_webview` 是一个可直接嵌入 Flutter 页面内部、能够根据网页内容高度**自动自适应调整尺寸（Auto Height / Wrap Content）**的通用 WebView 组件。

内部通过现代 Web 标准的 ResizeObserver 实时感知内容尺寸变动，彻底解决异步网络图片加载、字体渲染完成、动态 DOM 展开等场景下的内容截断与内外多重滚动条冲突问题。

---

## 核心特性

* **动态高度自适应**：通过现代 Web 标准的 `ResizeObserver` 实时监听内容高（自适应网络图片加载、Web 字体渲染及 DOM 动态展开）。
* **双模式支持**：
  * `EmbedWebView(html)`：本地 HTML/富文本片段渲染。
  * `EmbedWebView.network(url)`：直接嵌入远程网页并动态注入探针自适应。
* **多端智能手势与滚动穿透路由 (`scrollController`)**：
  * **原生级抛掷惯性滑行 (Fling)**：离屏瞬间精准测速并触发 Flutter 原生 `goBallistic`，使 WebView 区域的滑行获得与宿主列表 100% 一致的物理惯性减速与边界弹性回弹体验（Bouncing / Clamping）。
  * **物理绝对坐标防抖阻尼**：采用不受视口位移污染的屏幕绝对物理坐标 `screenY`，结合 `applyUserOffset` 原生物理阻尼，彻底消除移动端滑动发抖撕扯。
  * **内部二级滚动隔离保护**：内嵌网页内的子滚动区域（如 `<div style="overflow-y: scroll">`）优先消费手势，绝不被外层 Flutter 列表打断或判定伪取消。
  * **横纵手势智能解耦**：滑动初段自动识别方向，水平拖拽放行给 WebView 内部（如横向轮播图、宽表格、代码高亮），纵向拖拽平滑驱动外层列表。
  * **桌面端鼠标滚轮穿透**：macOS / Windows 桌面端卡片普通区域接收到滚轮时，通过 `pointerScroll` 原生物理阻尼穿透联动外层滚动。
* **超链接智能拦截 (`onLinkTap`)**：点击链接触发回调并在外部处理，防止在小卡片内迷失跳转。
* **平滑过渡动画**：内置 `AnimatedSize`，高度展开或收起时平滑过渡，无视觉跳动。
* **控制器就绪回调 (`onWebViewCreated`)**：提供 `WebViewController` 实例访问，方便直接执行自定义 JavaScript 交互与双向通信。
* **全平台支持**：支持 Android、iOS、macOS、Windows 以及 Web。
* **无侵入设计**：不暴力篡改网页的字体大小、颜色与排版，充分尊重原网页 CSS。

---

## 支持平台

* **Android**（基于官方 `webview_flutter_android`）
* **iOS**（基于官方 `webview_flutter_wkwebview`）
* **macOS**（基于官方 `webview_flutter_wkwebview`）
* **Web**（基于官方 `webview_flutter_web` 与标准 HTML5 postMessage）
* **Windows**（基于 `webview_flutter_windows` 或兼容引擎）

---

## 快速上手

在 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  flutter:
    sdk: flutter
  embed_webview: ^0.2.0
```

---

## 使用示例

### 1. HTML 富文本自适应嵌入

```dart
import 'package:embed_webview/embed_webview.dart';

EmbedWebView(
  '<p>你好 Flutter！<a href="https://flutter.dev">打开官网</a></p>',
  initialHeight: 80.0,
  animate: true,
  onHeightChanged: (height) {
    debugPrint("当前自适应高度: $height");
  },
  onLinkTap: (url) {
    debugPrint("点击了超链接: $url");
  },
)
```

### 2. 嵌入在可滚动长页面中（智能手势与滚轮穿透）

只需传入 `scrollController`，插件内部自动协调手势竞技场，实现零配置的丝滑物理阻尼、抛掷惯性滑行与鼠标滚轮联动：

```dart
final ScrollController _scrollController = ScrollController();

SingleChildScrollView(
  controller: _scrollController,
  child: Column(
    children: [
      Text('WebView 上方的原生组件'),
      EmbedWebView(
        htmlContent,
        scrollController: _scrollController, // 自动协调手势穿透与 Fling 抛掷惯性
        onLinkTap: (url) => launchUrl(Uri.parse(url)),
      ),
      Text('WebView 下方的原生长列表'),
    ],
  ),
)
```

### 3. 远程网页 URL 嵌入

```dart
EmbedWebView.network(
  'https://flutter.dev',
  onLinkTap: (url) => debugPrint("点击超链接: $url"),
)
```

保存并运行项目：

| 中文界面 (Chinese Mode) | 英文界面 (English Mode) |
| :---: | :---: |
| <img src="./doc/img/screenshot_zh.png" width="360" alt="Chinese Demo" /> | <img src="./doc/img/screenshot_en.png" width="360" alt="English Demo" /> |

---

## 参数说明

| 参数 | 类型 | 默认值 | 说明 |
| :--- | :--- | :--- | :--- |
| `webViewContent` | `String?` | - | HTML 字符串内容（仅限默认构造函数） |
| `url` | `String?` | - | 远程网页 URL（仅限 `EmbedWebView.network` 构造函数） |
| `scrollController` | `ScrollController?` | `null` | 可选的外层滚动控制器；传入后自动激活平滑手势穿透、滚轮联动与原生 Fling 惯性滑行 |
| `width` | `double?` | `null` | 指定宽度，为 `null` 时自适应父容器最大可用宽度 |
| `height` | `double?` | `null` | 固定高度，为 `null` 时由内部探针动态自适应撑开 |
| `initialHeight` | `double` | `80.0` | 初始预估高度，消除首帧加载时的视觉跳动 |
| `animate` | `bool` | `true` | 是否启用高度自适应平滑动画 |
| `animationDuration` | `Duration` | `200ms` | 动画过渡时长 |
| `animationCurve` | `Curve` | `easeInOut` | 动画过渡插值曲线 |
| `onHeightChanged` | `ValueChanged<double>?` | `null` | 真实高度发生变化时的通知回调 |
| `onLinkTap` | `ValueChanged<String>?` | `null` | 超链接点击回调（默认拦截小卡片内跳转） |
| `onWebViewCreated` | `ValueChanged<WebViewController>?` | `null` | 控制器就绪回调，提供 `WebViewController` 实例以便执行自定义 JS 与通道通信 |
| `onLanguageChanged` | `ValueChanged<String>?` | `null` | 网页内部触发语言切换时的通知回调 |
| `gestureRecognizers` | `Set<Factory>?` | `null` | 自定义手势识别器集合；传入 `scrollController` 且此项为 `null` 时自动缺省配置 `EagerGestureRecognizer` |
| `backgroundColor` | `String?` | `null` | 自定义背景色（如 `'#ffffff'`） |

---

## 许可证

Apache-2.0 许可证。详情请参阅 [LICENSE](LICENSE)。
