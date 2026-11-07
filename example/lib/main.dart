import 'dart:ui' as ui;

import 'package:embed_webview/embed_webview.dart'
    show EmbedWebView, HttpResponseError, WebResourceError, WebViewController;
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
      _networkError = null;
    });
  }

  void _retryNetwork() {
    setState(() {
      _networkReloadToken++;
      _networkError = null;
    });
  }

  String _describeError(Object error) {
    if (error is WebResourceError) {
      return '${error.description} (code ${error.errorCode})';
    }
    if (error is HttpResponseError) {
      return 'HTTP ${error.response?.statusCode ?? 'error'}';
    }
    return error.toString();
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
            // 网络模式：加载态与错误态演示（默认不存在的域名，直接看错误卡片）
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
                            ? '网络模式 / 加载与错误演示'
                            : 'Network Mode / Loading & Error Demo',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
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
                      EmbedWebView.network(
                        _networkUrl,
                        key: ValueKey('$_networkUrl-$_networkReloadToken'),
                        initialHeight: 160.0,
                        loadingBuilder: (context, progress) => Container(
                          color: Colors.grey.shade100,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 8),
                              Text(
                                _isZh
                                    ? '加载中 ${(progress * 100).toInt()}%'
                                    : 'Loading ${(progress * 100).toInt()}%',
                              ),
                            ],
                          ),
                        ),
                        errorBuilder: (context, error) => Container(
                          color: Colors.red.shade50,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.cloud_off,
                                size: 36,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isZh ? '页面加载失败' : 'Page failed to load',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 4.0,
                                ),
                                child: Text(
                                  _describeError(error),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              const SizedBox(height: 8),
                              FilledButton.icon(
                                onPressed: _retryNetwork,
                                icon: const Icon(Icons.refresh, size: 16),
                                label: Text(_isZh ? '重试' : 'Retry'),
                              ),
                            ],
                          ),
                        ),
                        onWebResourceError: (error) {
                          setState(() {
                            _networkError = _describeError(error);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _isZh
                                    ? '加载失败：$_networkError'
                                    : 'Load failed: $_networkError',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
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
