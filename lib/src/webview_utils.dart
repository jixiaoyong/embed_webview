/*
 * @description: HTML 内容包装与 ResizeObserver 探针注入工具
 * 遵循极简与单一职责原则：仅注入高度监听探针，不篡改用户的 HTML 样式、字体或排版
 * @author: jixiaoyong
 * @email: jixiaoyong1995@gmail.com
 */
class WebViewUtils {
  static const String channelName = 'EmbedWebViewHeightChannel';

  /// 纯 JS 代码探针（用于在网络 URL 页面中动态注入）
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
    if (height > 0 && window.$channelName) {
      window.$channelName.postMessage(height.toString());
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

  window.addEventListener('load', notifyHeight);
  notifyHeight();
  setTimeout(notifyHeight, 150);
  setTimeout(notifyHeight, 800);
})();
''';

  /// ResizeObserver 监听脚本标签
  /// 实时监听 #embed-container 的尺寸变化（图片加载、DOM 变动等），并通过 JavaScriptChannel 回传高度
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
