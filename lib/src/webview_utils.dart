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

  // 智能触摸手势路由与惯性抛掷系统 (Touch Gesture Routing & Fling Simulation)
  if (!window.__embedWebviewTouchAttached) {
    window.__embedWebviewTouchAttached = true;
    var touchStartX = 0;
    var touchStartY = 0;
    var touchLastScreenY = 0;
    var touchAxisLocked = null; // null | 'vertical' | 'horizontal'
    var isMultiTouch = false;
    var moveHistory = []; // [{ time: number, y: number }]

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

    function notifyTouch(msg) {
      if (window.$channelName) {
        try {
          window.$channelName.postMessage(msg);
        } catch (err) {}
      }
      if (window.parent && window.parent !== window) {
        try {
          window.parent.postMessage('embed_webview_' + msg, '*');
        } catch (err) {}
      }
    }

    window.addEventListener('touchstart', function(e) {
      if (e.touches && e.touches.length > 1) {
        isMultiTouch = true;
        moveHistory = [];
        return;
      }
      if (e.touches && e.touches.length === 1) {
        isMultiTouch = false;
        touchStartX = e.touches[0].screenX;
        touchStartY = e.touches[0].screenY;
        touchLastScreenY = touchStartY;
        touchAxisLocked = null;
        moveHistory = [{ time: performance.now(), y: touchStartY }];
      }
    }, { passive: true });

    window.addEventListener('touchmove', function(e) {
      if (isMultiTouch || !e.touches || e.touches.length !== 1) return;
      var curX = e.touches[0].screenX;
      var curY = e.touches[0].screenY;
      var now = performance.now();

      // 记录最近 100ms 轨迹用于计算松手惯性速度 (Fling velocity)
      moveHistory.push({ time: now, y: curY });
      while (moveHistory.length > 0 && now - moveHistory[0].time > 100) {
        moveHistory.shift();
      }

      // 方向解耦判定：若横向位移大于垂直位移，锁定为横向并放行给 WebView
      if (touchAxisLocked === null) {
        var dx = Math.abs(curX - touchStartX);
        var dy = Math.abs(curY - touchStartY);
        if (dx > 8 || dy > 8) {
          touchAxisLocked = (dx > dy) ? 'horizontal' : 'vertical';
        }
      }
      if (touchAxisLocked === 'horizontal') return;

      var deltaY = touchLastScreenY - curY;
      touchLastScreenY = curY;
      // 120Hz/高刷屏抗抖微噪点过滤
      if (Math.abs(deltaY) < 0.8) return;

      var isScrollable = checkScrollable(e.touches[0].target);
      if (!isScrollable) {
        notifyTouch('scroll_touch:' + deltaY.toFixed(2));
      }
    }, { passive: true });

    window.addEventListener('touchend', function(e) {
      if (isMultiTouch) {
        if (!e.touches || e.touches.length === 0) isMultiTouch = false;
        moveHistory = [];
        return;
      }
      // 计算手指脱手离开瞬时速度 (px/s)
      if (touchAxisLocked === 'vertical' && moveHistory.length >= 2) {
        var now = performance.now();
        var lastPoint = moveHistory[moveHistory.length - 1];
        // 如果最后一点距离松手超过 50ms，说明手指在松手前已停滞，不触发 fling
        if (now - lastPoint.time < 50) {
          var firstPoint = moveHistory[0];
          var dt = (lastPoint.time - firstPoint.time) / 1000.0;
          if (dt > 0.015) {
            // 手指向上甩 (curY < startY) => dy > 0 => 正向速度 (pixels 增加，向下看)
            var dy = firstPoint.y - lastPoint.y;
            var velocity = dy / dt;
            if (Math.abs(velocity) > 80) {
              notifyTouch('scroll_fling:' + velocity.toFixed(1));
            }
          }
        }
      }
      touchAxisLocked = null;
      moveHistory = [];
    }, { passive: true });

    window.addEventListener('touchcancel', function() {
      touchAxisLocked = null;
      isMultiTouch = false;
      moveHistory = [];
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
