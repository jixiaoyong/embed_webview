import 'dart:ui' as ui;

import 'package:embed_webview/embed_webview.dart'
    show EmbedWebView, WebViewController;
import 'package:example/web_content.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

void main() {
  // 如需调试内部手势与高度，可开启日志：
  // EmbedWebView.enableLogging = true;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Embed Webview Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Embed Webview Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ScrollController _scrollController = ScrollController();
  WebViewController? _webViewController;
  double _currentHeight = 0;
  late bool _isZh;

  // 网络模式演示：默认填一个不存在的域名，方便直接看到错误卡片；
  // 改成有效地址（如 https://flutter.dev）可看到加载态
  final TextEditingController _urlController = TextEditingController(
      text: 'https://this-domain-does-not-exist-12345.example');
  String _networkUrl = 'https://this-domain-does-not-exist-12345.example';
  int _networkReloadToken = 0;
  bool _networkLoading = false;
  int _networkProgress = 0;
  String? _networkError;

  @override
  void initState() {
    super.initState();
    // 优先检测设备系统语言：中文系统默认为 zh，其它语言默认为 en
    final String deviceLang =
        ui.PlatformDispatcher.instance.locale.languageCode.toLowerCase();
    _isZh = deviceLang.startsWith('zh');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _loadNetworkUrl() {
    setState(() {
      _networkUrl = _urlController.text.trim();
      _networkReloadToken++;
      _networkLoading = true;
      _networkProgress = 0;
      _networkError = null;
    });
  }

  void _retryNetwork() {
    setState(() {
      _networkReloadToken++;
      _networkLoading = true;
      _networkProgress = 0;
      _networkError = null;
    });
  }

  void _toggleLanguage() {
    setState(() {
      _isZh = !_isZh;
    });
    final String lang = _isZh ? 'zh' : 'en';
    try {
      _webViewController?.runJavaScript(
          'if (window.setAppLanguage) { window.setAppLanguage("$lang"); }');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isZh
              ? '自适应 WebView 演示 (${_currentHeight.toStringAsFixed(1)}px)'
              : '${widget.title} (${_currentHeight.toStringAsFixed(1)}px)',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              avatar: const Icon(Icons.language, size: 16),
              label: Text(_isZh ? '中文 / EN' : 'EN / 中文'),
              onPressed: _toggleLanguage,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        child: Column(
          children: [
            Container(
              color: Colors.orange.shade100,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  _isZh
                      ? "WebView 上方的原生组件 (Flutter Native Header)"
                      : "Flutter Native Content Before WebView",
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
              child: EmbedWebView(
                webContent,
                initialHeight: 120.0,
                animate: true,
                scrollController: _scrollController,
                gestureRecognizers: {
                  Factory<OneSequenceGestureRecognizer>(
                      () => EagerGestureRecognizer()),
                },
                onWebViewCreated: (controller) {
                  _webViewController = controller;
                  // 同步初始语言至 WebView 内部
                  final String lang = _isZh ? 'zh' : 'en';
                  try {
                    controller.runJavaScript(
                        'if (window.setAppLanguage) { window.setAppLanguage("$lang"); }');
                  } catch (_) {}
                },
                onLanguageChanged: (lang) {
                  setState(() {
                    _isZh = lang == 'zh';
                  });
                },
                onHeightChanged: (newHeight) {
                  setState(() {
                    _currentHeight = newHeight;
                  });
                },
                onLinkTap: (url) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _isZh
                            ? '超链接拦截测试：点击了 -> $url'
                            : 'Hyperlink intercepted: clicked -> $url',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
            // 网络模式：库只给回调，下面这些占位 UI 全部由调用方自己画
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _isZh
                            ? '网络模式 / 加载与错误回调'
                            : 'Network Mode / Load & Error Callbacks',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _urlController,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                hintText: _isZh ? '输入 URL' : 'Enter URL',
                                isDense: true,
                              ),
                              onSubmitted: (_) => _loadNetworkUrl(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: _loadNetworkUrl,
                            child: Text(_isZh ? '加载' : 'Load'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 160,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: EmbedWebView.network(
                                _networkUrl,
                                key: ValueKey(
                                    '$_networkUrl-$_networkReloadToken'),
                                height: 160.0,
                                onPageStarted: (url) {
                                  setState(() {
                                    _networkLoading = true;
                                    _networkProgress = 0;
                                    _networkError = null;
                                  });
                                },
                                onProgress: (progress) {
                                  setState(() => _networkProgress = progress);
                                },
                                onPageFinished: (url) {
                                  setState(() => _networkLoading = false);
                                },
                                onWebResourceError: (error) {
                                  setState(() {
                                    _networkLoading = false;
                                    _networkError = _isZh
                                        ? '网络错误：${error.description}'
                                        : 'Network error: ${error.description}';
                                  });
                                },
                                onHttpError: (error) {
                                  // 库不做主框架过滤，子资源（如图片）的 404
                                  // 也会进来；只关心整页失败时自行按 uri 判断。
                                  final String? failed =
                                      error.request?.uri.toString();
                                  if (failed != null && failed != _networkUrl) {
                                    return;
                                  }
                                  setState(() {
                                    _networkLoading = false;
                                    _networkError = _isZh
                                        ? 'HTTP 错误：${error.response?.statusCode}'
                                        : 'HTTP error: ${error.response?.statusCode}';
                                  });
                                },
                              ),
                            ),
                            // 加载中占位：示例样式，全部是 Flutter 默认组件
                            if (_networkLoading)
                              Positioned.fill(
                                child: ColoredBox(
                                  color:
                                      Theme.of(context).scaffoldBackgroundColor,
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 120,
                                          child: LinearProgressIndicator(
                                            value: _networkProgress > 0
                                                ? _networkProgress / 100
                                                : null,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _isZh
                                              ? '加载中 $_networkProgress%'
                                              : 'Loading $_networkProgress%',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            // 加载失败占位：示例样式，全部是 Flutter 默认组件
                            if (_networkError != null)
                              Positioned.fill(
                                child: ColoredBox(
                                  color:
                                      Theme.of(context).scaffoldBackgroundColor,
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16),
                                          child: Text(
                                            _networkError!,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: _retryNetwork,
                                          child: Text(_isZh ? '重试' : 'Retry'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              color: Colors.blue.shade50,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      _isZh
                          ? "WebView 下方的原生长列表 (手势滑动与穿透测试区)"
                          : "Native Content Below WebView (Scroll & Gesture Test Area)",
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                  for (int i = 1; i <= 10; i++)
                    ListTile(
                      leading: CircleAvatar(
                        child: Text('$i'),
                      ),
                      title: Text(
                        _isZh
                            ? 'Flutter 原生内容条目 #$i'
                            : 'Flutter Native Item #$i',
                      ),
                      subtitle: Text(
                        _isZh
                            ? '在 WebView 卡片或普通区域滑动可平滑驱动此列表滚动'
                            : 'Scroll over WebView to smoothly drive this page',
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
