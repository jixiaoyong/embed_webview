/*
 * @description: HTML 内容包装、ResizeObserver 尺寸自适应与智能嵌套滚轮探针注入工具
 * 遵循极简与单一职责原则：注入高度监听探针与滚轮穿透监听，不篡改用户的 HTML 样式、字体或排版
 * 同时支持移动端原生通道 (JavaScriptChannel) 与 Web 浏览器端 (HTML5 postMessage) 双重通信
 * @author: jixiaoyong
 * @email: jixiaoyong1995@gmail.com
 */
class WebViewUtils {
  static const String channelName = 'EmbedWebViewHeightChannel';
  static const String webMessageType = 'embed_webview_resize';
  static const String webScrollMessageType = 'embed_webview_scroll';

  /// 纯 JS 代码探针（用于在网络 URL 页面中动态注入，或直接内嵌在 HTML 中）
  static const String dynamicProbeJs = '''
(function() {
  function notifyHeight() {
    var target = document.getElementById('embed-container') || document.body || document.documentElement;
    if (!target) return;
    var height = Math.ceil(
      target.getBoundingClientRect().height ||
      target.scrollHeight ||
      document.documentElement.scrollHeight ||
      0
    );
    if (height > 0) {
      // 1. 原生平台通道 (Android / iOS / macOS / Windows)
      if (window.$channelName) {
        window.$channelName.postMessage(height.toString());
      }
      // 2. Web 浏览器端标准 HTML5 跨窗口消息 (iframe -> 宿主窗口)
      if (window.parent && window.parent !== window) {
        try {
          window.parent.postMessage('embed_webview_resize:' + height, '*');
        } catch (e) {}
      }
    }
  }

  if (typeof ResizeObserver !== 'undefined') {
    var target = document.body || document.documentElement;
    if (target) {
      var ro = new ResizeObserver(function() {
        notifyHeight();
      });
      ro.observe(target);
    }
  }

  // 智能嵌套滚轮监听 (Nested Wheel Scroll)
  if (!window.__embedWebviewWheelAttached) {
    window.__embedWebviewWheelAttached = true;
    window.addEventListener('wheel', function(e) {
      if (!e.deltaY) return;
      var el = e.target;
      if (el && el.nodeType === 3) {
        el = el.parentElement;
      }
      var canScroll = false;
      while (el && el !== document.body && el !== document.documentElement) {
        var style = window.getComputedStyle(el);
        if (style) {
          var overflowY = style.overflowY;
          if ((overflowY === 'auto' || overflowY === 'scroll') && el.scrollHeight > el.clientHeight) {
            if (e.deltaY > 0 && el.scrollTop + el.clientHeight < el.scrollHeight - 1) {
              canScroll = true;
              break;
            }
            if (e.deltaY < 0 && el.scrollTop > 0.5) {
              canScroll = true;
              break;
            }
          }
        }
        el = el.parentElement;
      }
      if (!canScroll) {
        var msg = 'embed_webview_scroll:' + e.deltaY;
        // 1. Web 浏览器 iframe: 走 postMessage
        if (window.parent && window.parent !== window) {
          try {
            window.parent.postMessage(msg, '*');
          } catch (err) {}
        }
        // 2. 原生桌面端与移动端通道 (macOS / Windows / Android / iOS)
        if (window.$channelName) {
          try {
            window.$channelName.postMessage('scroll_wheel:' + e.deltaY);
          } catch (err) {}
        }
      }
    }, { passive: true });
  }

  // 智能触摸手势路由 (Touch Gesture Routing for Mobile)
  if (!window.__embedWebviewTouchAttached) {
    window.__embedWebviewTouchAttached = true;
    var isInsideScrollable = false;

    function checkScrollable(target) {
      var el = target;
      if (el && el.nodeType === 3) el = el.parentElement;
      while (el && el !== document.body && el !== document.documentElement) {
        var style = window.getComputedStyle(el);
        if (style) {
          var overflowY = style.overflowY;
          if ((overflowY === 'auto' || overflowY === 'scroll') && el.scrollHeight > el.clientHeight) {
            return true;
          }
        }
        el = el.parentElement;
      }
      return false;
    }

    function notifyLock(lock) {
      if (window.$channelName) {
        try {
          window.$channelName.postMessage('lock_scroll:' + lock);
        } catch (err) {}
      }
      if (window.parent && window.parent !== window) {
        try {
          window.parent.postMessage('embed_webview_lock:' + lock, '*');
        } catch (err) {}
      }
    }

    window.addEventListener('touchstart', function(e) {
      if (e.touches && e.touches.length === 1) {
        isInsideScrollable = checkScrollable(e.touches[0].target);
        if (isInsideScrollable) {
          notifyLock(true);
        }
      }
    }, { passive: true });

    window.addEventListener('touchend', function() {
      if (isInsideScrollable) {
        isInsideScrollable = false;
        notifyLock(false);
      }
    }, { passive: true });

    window.addEventListener('touchcancel', function() {
      if (isInsideScrollable) {
        isInsideScrollable = false;
        notifyLock(false);
      }
    }, { passive: true });
  }

  window.addEventListener('load', notifyHeight);
  notifyHeight();
  setTimeout(notifyHeight, 150);
  setTimeout(notifyHeight, 800);
})();
''';

  /// ResizeObserver 监听脚本标签
  static const String resizeObserverScript = '''
<script type="text/javascript">
$dynamicProbeJs
</script>
''';

  /// 将用户的 HTML 内容包裹在自适应容器和 ResizeObserver 探针中
  /// 不干预用户的内联样式、字体、颜色与排版
  static String getWebContent(
    String content, {
    String? backgroundColor,
    @Deprecated('已废弃，推荐在传入的 HTML 中定义自己的字体') String? fontSize,
    @Deprecated('已废弃，推荐在传入的 HTML 中定义自己的行高') String? lineHeight,
    @Deprecated('已废弃，推荐在传入的 HTML 中通过 CSS 控制图片样式') bool forceExpandImageWidget = false,
    bool needFormatContent = true,
  }) {
    String contentFormatted = content;
    if (content.contains('%')) {
      try {
        contentFormatted = Uri.decodeFull(content);
      } catch (_) {
        contentFormatted = content;
      }
    }

    final String bgStyle = backgroundColor != null
        ? 'background: $backgroundColor;'
        : '';

    return '''<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
  <base target="_blank" />
  <style>
    html, body {
      margin: 0;
      padding: 0;
      width: 100%;
      height: auto;
      overflow: hidden;
      $bgStyle
    }
  </style>
</head>
<body>
  <div id="embed-container" style="width: 100%; height: auto; overflow: hidden;">
    $contentFormatted
  </div>
  $resizeObserverScript
</body>
</html>''';
  }

  /// 兼容旧 API
  static String onlyWrapWithHtmlSketch(String contentFormatted) {
    return getWebContent(contentFormatted);
  }
}
