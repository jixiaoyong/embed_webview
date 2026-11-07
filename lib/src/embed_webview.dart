// ignore_for_file: deprecated_member_use_from_same_package
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'logutil.dart';
import 'web_listener/web_listener.dart';
import 'webview_utils.dart';

/// 能够内嵌在页面内部并自适应高度的通用 WebView 组件。
///
/// 支持本地 HTML 字符串渲染与远程网络 URL 加载两种模式：
/// * [EmbedWebView] 默认构造函数：用于渲染 HTML 富文本内容；
/// * [EmbedWebView.network] 命名构造函数：用于直接加载远程网页 URL。
///
/// 内部通过现代标准的 [ResizeObserver] 实时感知网页内容尺寸变化并自动调整高度，
/// 杜绝内部滚动条和内容截断。
///
/// 针对 Android、iOS、macOS、Windows 和 Web 进行了深度多端兼容性适配：
/// * 移动端/桌面端：走高效的原生平台通道通信；
/// * Web 端：走浏览器标准 HTML5 postMessage 跨窗口通信，避开未实现异常。
class EmbedWebView extends StatefulWidget {
  /// 嵌入的 HTML 字符串（在网络模式下为 null）
  final String? webViewContent;

  /// 嵌入的远程网页 URL（在 HTML 模式下为 null）
  final String? url;

  /// 指定宽度，若为 null 则自动自适应父级最大可用宽度
  final double? width;

  /// 固定高度，若为 null 则由内部探针根据实际内容高度自适应撑开
  final double? height;

  /// 初始预估高度，默认 80.0，用于减轻从 0/1px 突变到目标高度的视觉闪烁
  final double initialHeight;

  /// 是否启用高度变化的平滑过渡动画，默认 true
  final bool animate;

  /// 高度平滑过渡动画时长，默认 200 毫秒
  final Duration animationDuration;

  /// 高度平滑过渡动画曲线，默认 [Curves.easeInOut]
  final Curve animationCurve;

  /// 网页背景颜色（如 '#ffffff'）
  final String? backgroundColor;

  /// 高度发生变动时的回调通知
  final ValueChanged<double>? onHeightChanged;

  /// 超链接点击回调。
  /// 当用户在网页内点击超链接（`<a>`）时触发，并默认阻止在内嵌卡片内乱跳。
  /// 可在此处调用 `url_launcher` 在系统外部浏览器打开该链接。
  final ValueChanged<String>? onLinkTap;

  /// 手势识别器集合，用于外层滚动视图（如 ListView、CustomScrollView）的手势竞技与穿透协调
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;

  // ------------ 向下兼容历史参数 ------------
  @Deprecated('已废弃，建议直接在传入的 HTML 中定义自己的字体')
  final String? fontSize;
  @Deprecated('已废弃，建议直接在传入的 HTML 中定义自己的行高')
  final String? lineHeight;
  @Deprecated('已废弃，建议直接在传入的 HTML 中通过 CSS 控制图片样式')
  final bool forceExpandImageWidget;
  @Deprecated('已废弃，默认保持纯净包装')
  final bool needFormatContent;

  /// 全局控制是否打印内部日志，默认 false 保持静默
  static bool get enableLogging => LogUtil.enableLogging;
  static set enableLogging(bool value) => LogUtil.enableLogging = value;

  /// HTML 字符串模式构造函数
  const EmbedWebView(
    String htmlContent, {
    super.key,
    this.width,
    this.height,
    this.initialHeight = 80.0,
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 200),
    this.animationCurve = Curves.easeInOut,
    this.backgroundColor,
    this.onHeightChanged,
    this.onLinkTap,
    this.gestureRecognizers,
    this.fontSize,
    this.lineHeight,
    this.forceExpandImageWidget = false,
    this.needFormatContent = true,
  })  : webViewContent = htmlContent,
        url = null;

  /// 远程网页 URL 模式构造函数
  const EmbedWebView.network(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.initialHeight = 80.0,
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 200),
    this.animationCurve = Curves.easeInOut,
    this.backgroundColor,
    this.onHeightChanged,
    this.onLinkTap,
    this.gestureRecognizers,
    this.fontSize,
    this.lineHeight,
    this.forceExpandImageWidget = false,
    this.needFormatContent = true,
  }) : webViewContent = null;

  @override
  State<EmbedWebView> createState() => _EmbedWebViewState();
}

class _EmbedWebViewState extends State<EmbedWebView>
    with SingleTickerProviderStateMixin {
  late final WebViewController _controller;
  double _contentHeight = 80.0;
  String? _currentLoadedContent;
  bool _isFirstUrlNavigationHandled = false;
  WebMessageSubscription? _webMessageSubscription;

  bool get _isNetworkMode => widget.url != null;

  @override
  void initState() {
    super.initState();
    _contentHeight = widget.height ?? widget.initialHeight;
    _initController();
    _loadContent();
  }

  void _initController() {
    _controller = WebViewController();

    if (!kIsWeb) {
      // 原生移动端与桌面端通道支持
      _controller
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..addJavaScriptChannel(
          WebViewUtils.channelName,
          onMessageReceived: (JavaScriptMessage message) {
            final double? parsedHeight = double.tryParse(message.message);
            _handleHeightUpdate(parsedHeight);
          },
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (NavigationRequest request) {
              final String reqUrl = request.url;
              LogUtil.d("Navigation request: $reqUrl");

              // 放行初始页面加载
              if (reqUrl == 'about:blank' || reqUrl.startsWith('data:text/html')) {
                return NavigationDecision.navigate;
              }

              // 远程模式下放行首次自身 URL 载入
              if (_isNetworkMode && !_isFirstUrlNavigationHandled) {
                _isFirstUrlNavigationHandled = true;
                return NavigationDecision.navigate;
              }

              // 用户点击超链接：触发外部回调并默认拦截小卡片内跳转
              if (widget.onLinkTap != null) {
                widget.onLinkTap!(reqUrl);
              }
              return NavigationDecision.prevent;
            },
            onPageFinished: (String url) async {
              LogUtil.d("Page finished loading: $url");
              // 远程网络模式下在页面加载完成后注入动态探针脚本
              if (_isNetworkMode) {
                try {
                  await _controller.runJavaScript(WebViewUtils.dynamicProbeJs);
                } catch (e) {
                  LogUtil.e(e);
                }
              }
            },
          ),
        );
    } else {
      // Web 浏览器平台：注册标准 HTML5 postMessage 监听，避开平台未实现异常
      _webMessageSubscription = initWebMessageListener((double height) {
        _handleHeightUpdate(height);
      });
    }
  }

  void _handleHeightUpdate(double? parsedHeight) {
    if (parsedHeight != null && parsedHeight > 0) {
      if ((parsedHeight - _contentHeight).abs() > 0.5) {
        if (mounted) {
          setState(() {
            _contentHeight = parsedHeight;
          });
        }
        widget.onHeightChanged?.call(parsedHeight);
        LogUtil.d("EmbedWebView height updated: $parsedHeight");
      }
    }
  }

  void _loadContent() {
    if (_isNetworkMode) {
      final String targetUrl = widget.url!;
      if (_currentLoadedContent != targetUrl) {
        _currentLoadedContent = targetUrl;
        _isFirstUrlNavigationHandled = false;
        _controller.loadRequest(Uri.parse(targetUrl));
      }
    } else {
      final String rawHtml = widget.webViewContent ?? '';
      final String html = WebViewUtils.getWebContent(
        rawHtml,
        backgroundColor: widget.backgroundColor,
        fontSize: widget.fontSize,
        lineHeight: widget.lineHeight,
        forceExpandImageWidget: widget.forceExpandImageWidget,
        needFormatContent: widget.needFormatContent,
      );

      if (_currentLoadedContent != html) {
        _currentLoadedContent = html;
        _controller.loadHtmlString(html);
      }
    }
  }

  @override
  void didUpdateWidget(covariant EmbedWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.webViewContent != widget.webViewContent ||
        oldWidget.url != widget.url ||
        oldWidget.backgroundColor != widget.backgroundColor ||
        oldWidget.fontSize != widget.fontSize ||
        oldWidget.lineHeight != widget.lineHeight ||
        oldWidget.forceExpandImageWidget != widget.forceExpandImageWidget ||
        oldWidget.needFormatContent != widget.needFormatContent) {
      _loadContent();
    }
    if (widget.height != null && widget.height != oldWidget.height) {
      setState(() {
        _contentHeight = widget.height!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double effectiveWidth = widget.width ??
            (constraints.hasBoundedWidth
                ? constraints.maxWidth
                : MediaQuery.of(context).size.width);
        final double effectiveHeight = widget.height ?? _contentHeight;

        Widget webViewWidget = SizedBox(
          width: effectiveWidth,
          height: effectiveHeight,
          child: WebViewWidget(
            controller: _controller,
            gestureRecognizers: widget.gestureRecognizers ??
                const <Factory<OneSequenceGestureRecognizer>>{},
          ),
        );

        if (widget.animate) {
          webViewWidget = AnimatedSize(
            duration: widget.animationDuration,
            curve: widget.animationCurve,
            alignment: Alignment.topCenter,
            child: webViewWidget,
          );
        }

        return webViewWidget;
      },
    );
  }

  @override
  void dispose() {
    _webMessageSubscription?.cancel();
    super.dispose();
  }
}
