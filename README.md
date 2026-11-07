# [embed_webview](https://github.com/jixiaoyong/embed_webview)

[![pub package](https://shields.io/pub/v/embed_webview.svg?style=flat&color=brightgreen)](https://pub.dev/packages/embed_webview) ![GitHub](https://img.shields.io/github/license/jixiaoyong/embed_webview?color=brightgreen) ![support platform](https://img.shields.io/badge/support%20platform-Android%7CiOS%7CmacOS%7CWindows%7CWeb-brightgreen)

`embed_webview` 是一个可直接嵌入 Flutter 页面内部、能够根据网页内容高度**自动自适应调整尺寸（Auto Height / Wrap Content）**的高性能通用 WebView 组件。

内部通过现代 Web 标准的 `ResizeObserver` 探针与平台通道实时联动，无论异步网络图片何时加载完毕、字体何时渲染完成，或是折叠展开等动态 DOM 变更，都能平滑响应，彻底杜绝内容截断与多重滚动条冲突。

---

## 支持平台

* **Android**（基于官方 `webview_flutter_android`）
* **iOS**（基于官方 `webview_flutter_wkwebview`）
* **macOS**（原生 WKWebView，支持在 Mac 桌面端极速本地开发与调试）
* **Windows**（基于 Microsoft Edge WebView2，依托 `webview_flutter` 标准平台接口）
* **Web**（基于官方 `webview_flutter_web`）

---

## 核心特性

1. **动态高度自适应**：基于 `ResizeObserver`，精准捕获 DOM 尺寸变动并自愈。
2. **双模式支持**：
   * `EmbedWebView(htmlString)`：本地富文本/HTML 片段自适应。
   * `EmbedWebView.network(url)`：直接嵌入远程网页并动态注入探针自适应。
3. **超链接科学拦截**：内置 `NavigationDelegate`，点击网页中的 `<a href="...">` 链接时触发 `onLinkTap` 回调，默认拦截卡片内部跳转，防止用户迷失。
4. **高度平滑过渡**：内置 `AnimatedSize`（默认 200ms `easeInOut`），高度伸展时丝滑流畅，无生硬闪跳。
5. **手势穿透协调**：支持 `gestureRecognizers` 自定义手势竞争，保证在 `ListView` / `SingleChildScrollView` 中滚动流畅。
6. **零侵入设计**：不篡改用户的 HTML 标签结构与样式，完全尊重原网页 CSS。
7. **可控日志系统**：默认静默运行，可通过 `EmbedWebView.enableLogging = true` 开启调试日志。

---

## 快速上手

在 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  flutter:
    sdk: flutter
  embed_webview: ^0.1.0
```

### 1. HTML 富文本自适应嵌入

```dart
import 'package:embed_webview/embed_webview.dart';

EmbedWebView(
  '<p>Hello Flutter! <a href="https://flutter.dev">打开官网</a></p>',
  initialHeight: 80.0,
  animate: true,
  onHeightChanged: (height) {
    debugPrint("当前自适应高度: $height");
  },
  onLinkTap: (url) {
    // 拦截并在外部系统浏览器中打开
    debugPrint("点击了超链接: $url");
  },
)
```

### 2. 远程网页 URL 嵌入

```dart
EmbedWebView.network(
  'https://flutter.dev',
  onLinkTap: (url) => debugPrint('点击链接: $url'),
)
```

---

## 参数说明

| 参数 | 类型 | 默认值 | 说明 |
| :--- | :--- | :--- | :--- |
| `webViewContent` | `String?` | - | HTML 字符串（仅限默认构造函数） |
| `url` | `String?` | - | 远程网页 URL（仅限 `EmbedWebView.network`） |
| `width` | `double?` | `null` | 指定宽度，为 `null` 时自适应父级最大可用宽度 |
| `height` | `double?` | `null` | 固定高度，为 `null` 时由内部探针动态自适应撑开 |
| `initialHeight` | `double` | `80.0` | 初始预估高度，消除从 0/1px 突变的视觉跳动 |
| `animate` | `bool` | `true` | 是否启用高度自适应平滑动画 |
| `animationDuration`| `Duration` | `200ms` | 动画过渡时长 |
| `animationCurve` | `Curve` | `easeInOut` | 动画过渡插值曲线 |
| `onHeightChanged`| `ValueChanged<double>?` | `null` | 真实高度发生变化时的通知回调 |
| `onLinkTap` | `ValueChanged<String>?` | `null` | 超链接点击回调（默认拦截小卡片内跳转） |
| `gestureRecognizers`| `Set<Factory>?` | `null` | 自定义手势竞技识别器 |
| `backgroundColor`| `String?` | `null` | 自定义背景色（如 `'#ffffff'`） |

---

## 本地极速开发

因为集成了 macOS 原生支持，在 Mac 上无需启动臃肿的移动端模拟器，直接在终端中运行：

```bash
cd example
flutter run -d macos
```

---

## 许可证

```
Copyright 2022-present jixiaoyong

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
