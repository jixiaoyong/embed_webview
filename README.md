# embed_webview

[English](README.md) | [中文说明](README_CN.md)

[![pub package](https://shields.io/pub/v/embed_webview.svg?style=flat&color=brightgreen)](https://pub.dev/packages/embed_webview)
![GitHub](https://img.shields.io/github/license/jixiaoyong/embed_webview?color=brightgreen)
![support platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20macOS%20%7C%20Web-brightgreen)

<p align="center">
  <img src="./doc/img/screenshot.png" alt="embed_webview screenshot" width="400" />
</p>

A responsive, auto-height WebView widget for Flutter that dynamically sizes itself to fit its content using modern web ResizeObserver.

Eliminates blank space, cut-off content, and nested scrolling conflicts when embedding web content in Column, ListView, or SingleChildScrollView.

---

## Features

* **Dynamic Auto-Height**: Continuously monitors layout changes using ResizeObserver (handles async images, web fonts, and dynamic DOM expansion).
* **Dual Modes**: 
  * `EmbedWebView(html)` for raw HTML and rich-text snippets.
  * `EmbedWebView.network(url)` for remote web pages.
* **Hyperlink Interception (`onLinkTap`)**: Intercepts link clicks to prevent navigation inside the embedded card, allowing you to open them in external browsers.
* **Smooth Animation**: Built-in AnimatedSize transitions height changes smoothly without visual jumps.
* **macOS Desktop Support**: Develop and debug directly on macOS with native WKWebView.
* **Non-Intrusive**: Does not override your font sizes, colors, or layout, fully respecting your HTML and CSS.

---

## Supported Platforms

* **Android** (via `webview_flutter_android`)
* **iOS** (via `webview_flutter_wkwebview`)
* **macOS** (via `webview_flutter_wkwebview`)
* **Web** (via `webview_flutter_web`)

---

## Getting Started

Add `embed_webview` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  embed_webview: ^0.1.0
```

---

## Usage

### 1. Embedded HTML String

```dart
import 'package:embed_webview/embed_webview.dart';

EmbedWebView(
  '<p>Hello Flutter! <a href="https://flutter.dev">Visit Website</a></p>',
  initialHeight: 80.0,
  animate: true,
  onHeightChanged: (height) {
    debugPrint("Current height: $height");
  },
  onLinkTap: (url) {
    debugPrint("Clicked link: $url");
  },
)
```

### 2. Remote Web Page

```dart
EmbedWebView.network(
  'https://flutter.dev',
  onLinkTap: (url) => debugPrint("Clicked link: $url"),
)
```

---

## Parameters

| Parameter | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `webViewContent` | `String?` | - | Raw HTML string (default constructor only) |
| `url` | `String?` | - | Remote URL (named constructor `EmbedWebView.network` only) |
| `width` | `double?` | `null` | Widget width; defaults to maximum available parent width |
| `height` | `double?` | `null` | Fixed height; if `null`, height auto-adapts to content |
| `initialHeight` | `double` | `80.0` | Initial estimated height to eliminate visual jump before first render |
| `animate` | `bool` | `true` | Whether to animate height changes smoothly |
| `animationDuration` | `Duration` | `200ms` | Duration for height resize transition |
| `animationCurve` | `Curve` | `easeInOut` | Animation curve for height transition |
| `onHeightChanged` | `ValueChanged<double>?` | `null` | Callback when content height changes |
| `onLinkTap` | `ValueChanged<String>?` | `null` | Callback when a hyperlink is tapped (prevents internal navigation) |
| `gestureRecognizers` | `Set<Factory>?` | `null` | Gesture recognizers to coordinate touch events with parent scroll views |
| `backgroundColor` | `String?` | `null` | Custom background color (e.g., `'#ffffff'`) |

---

## License

Apache-2.0 License. See [LICENSE](LICENSE) for details.
