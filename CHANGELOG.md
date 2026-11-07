## 0.1.0

### What's New
* **Modernized Engine**: Upgraded to Dart 3 (`>=3.0.0`) and `webview_flutter: ^4.10.0+`.
* **Dynamic Auto-Height (ResizeObserver)**: Content height adapts in real-time when images finish loading, web fonts render, or dynamic DOM changes occur.
* **macOS Desktop Support**: Added native WKWebView support on macOS for instant desktop development and hot reload.
* **Remote URL Mode**: Added `EmbedWebView.network(url)` to embed remote web pages with dynamic auto-height.
* **Hyperlink Interception (`onLinkTap`)**: Hyperlink clicks (`<a>`) can now be intercepted via `onLinkTap` instead of navigating inside the embedded card.
* **Smooth Resize Animation**: Height changes now animate smoothly (`animate: true`, default `200ms`).
* **Initial Height Estimation**: Added `initialHeight` (default `80.0`) to eliminate visual flickers during initial load.
* **Gesture Coordination**: Added `gestureRecognizers` to coordinate touch events inside `ListView` or `SingleChildScrollView`.
* **Clean and Non-Intrusive**: No longer mutates your HTML font sizes, colors, or CSS styles, respecting your original design.
* **Silent by Default**: Internal logs are controlled via `EmbedWebView.enableLogging` (disabled by default).

### Breaking Changes
* Requires Dart SDK `^3.0.0` and Flutter `>=3.19.0`.
* Deprecated invasive formatting parameters (`fontSize`, `lineHeight`, `forceExpandImageWidget`) in favor of respecting original HTML and CSS.

## 0.0.2

* Optimized visibility of source code.
* Updated Flutter SDK version constraints.

## 0.0.1

* Initial release: basic auto-height webview widget for Flutter.
