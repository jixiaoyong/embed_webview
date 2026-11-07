import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:embed_webview/embed_webview.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

class MockPlatformWebViewController extends PlatformWebViewController {
  MockPlatformWebViewController(super.params) : super.implementation();

  final Map<String, void Function(JavaScriptMessage)> channels = {};
  String? lastLoadedHtml;
  LoadRequestParams? lastLoadRequestParams;
  PlatformNavigationDelegate? navigationDelegate;
  String? lastExecutedJs;

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}

  @override
  Future<void> setBackgroundColor(Color color) async {}

  @override
  Future<void> addJavaScriptChannel(
    JavaScriptChannelParams javaScriptChannelParams,
  ) async {
    channels[javaScriptChannelParams.name] =
        javaScriptChannelParams.onMessageReceived;
  }

  @override
  Future<void> loadHtmlString(String html, {String? baseUrl}) async {
    lastLoadedHtml = html;
  }

  @override
  Future<void> loadRequest(LoadRequestParams params) async {
    lastLoadRequestParams = params;
  }

  @override
  Future<void> setPlatformNavigationDelegate(
    PlatformNavigationDelegate handler,
  ) async {
    navigationDelegate = handler;
  }

  @override
  Future<void> runJavaScript(String javaScript) async {
    lastExecutedJs = javaScript;
  }
}

class MockPlatformNavigationDelegate extends PlatformNavigationDelegate {
  MockPlatformNavigationDelegate(super.params) : super.implementation();

  NavigationRequestCallback? onNavigationRequest;
  PageEventCallback? onPageStarted;
  PageEventCallback? onPageFinished;
  ProgressCallback? onProgress;
  WebResourceErrorCallback? onWebResourceError;
  HttpResponseErrorCallback? onHttpError;

  @override
  Future<void> setOnNavigationRequest(
    NavigationRequestCallback onNavigationRequest,
  ) async {
    this.onNavigationRequest = onNavigationRequest;
  }

  @override
  Future<void> setOnPageStarted(PageEventCallback onPageStarted) async {
    this.onPageStarted = onPageStarted;
  }

  @override
  Future<void> setOnPageFinished(PageEventCallback onPageFinished) async {
    this.onPageFinished = onPageFinished;
  }

  @override
  Future<void> setOnProgress(ProgressCallback onProgress) async {
    this.onProgress = onProgress;
  }

  @override
  Future<void> setOnWebResourceError(
    WebResourceErrorCallback onWebResourceError,
  ) async {
    this.onWebResourceError = onWebResourceError;
  }

  @override
  Future<void> setOnHttpError(HttpResponseErrorCallback onHttpError) async {
    this.onHttpError = onHttpError;
  }
}

class MockPlatformWebViewWidget extends PlatformWebViewWidget {
  MockPlatformWebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('mock_webview'),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        child: Container(color: Colors.transparent),
      ),
    );
  }
}

class MockWebViewPlatform extends WebViewPlatform {
  MockPlatformWebViewController? lastController;
  MockPlatformNavigationDelegate? lastNavigationDelegate;

  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    lastController = MockPlatformWebViewController(params);
    return lastController!;
  }

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) {
    lastNavigationDelegate = MockPlatformNavigationDelegate(params);
    return lastNavigationDelegate!;
  }

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) {
    return MockPlatformWebViewWidget(params);
  }
}

void main() {
  late MockWebViewPlatform mockPlatform;

  setUp(() {
    mockPlatform = MockWebViewPlatform();
    WebViewPlatform.instance = mockPlatform;
  });

  group('EmbedWebView Core & Enhanced Feature Tests', () {
    testWidgets('renders HTML mode and loads formatted HTML', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmbedWebView('<p>Test HTML</p>', initialHeight: 120.0),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EmbedWebView), findsOneWidget);
      expect(find.byKey(const Key('mock_webview')), findsOneWidget);
      expect(mockPlatform.lastController, isNotNull);
      expect(
          mockPlatform.lastController!.lastLoadedHtml, contains('Test HTML'));
      expect(mockPlatform.lastController!.channels,
          contains(WebViewUtils.channelName));

      // 验证初始高度生效
      final size = tester.getSize(find.byType(EmbedWebView));
      expect(size.height, equals(120.0));
    });

    testWidgets(
        'renders network URL mode and triggers probe injection on page finished',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmbedWebView.network('https://flutter.dev'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(mockPlatform.lastController!.lastLoadRequestParams?.uri.toString(),
          equals('https://flutter.dev'));

      // 模拟网页加载完成
      final navDelegate = mockPlatform.lastNavigationDelegate!;
      expect(navDelegate.onPageFinished, isNotNull);
      navDelegate.onPageFinished!('https://flutter.dev');

      // 验证动态注入了探针 JS
      expect(mockPlatform.lastController!.lastExecutedJs,
          contains('ResizeObserver'));
    });

    testWidgets('intercepts hyperlink clicks and notifies onLinkTap',
        (tester) async {
      String? tappedUrl;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmbedWebView(
              '<a href="https://example.com">Link</a>',
              onLinkTap: (url) => tappedUrl = url,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final navDelegate = mockPlatform.lastNavigationDelegate!;
      expect(navDelegate.onNavigationRequest, isNotNull);

      // 模拟用户点击外链
      final decision = await navDelegate.onNavigationRequest!(
        const NavigationRequest(
          url: 'https://example.com',
          isMainFrame: true,
        ),
      );

      // 验证被拦截且回调被触发
      expect(decision, equals(NavigationDecision.prevent));
      expect(tappedUrl, equals('https://example.com'));
    });

    testWidgets(
        'updates height smoothly when ResizeObserver channel reports new size',
        (tester) async {
      double? reportedHeight;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmbedWebView(
              '<p>Dynamic Height HTML</p>',
              initialHeight: 50.0,
              onHeightChanged: (h) => reportedHeight = h,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final onMessage =
          mockPlatform.lastController!.channels[WebViewUtils.channelName]!;
      onMessage(const JavaScriptMessage(message: '420.0'));

      await tester.pumpAndSettle();

      final updatedSize = tester.getSize(find.byType(EmbedWebView));
      expect(updatedSize.height, equals(420.0));
      expect(reportedHeight, equals(420.0));
    });

    testWidgets(
        'gesture coordination: scrolling works in parent SingleChildScrollView',
        (tester) async {
      final scrollController = ScrollController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                children: [
                  Container(height: 300, color: Colors.red),
                  const EmbedWebView('<p>Content</p>', initialHeight: 200),
                  Container(height: 600, color: Colors.blue),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(scrollController.offset, equals(0.0));

      // 在 EmbedWebView 区域向上拖动
      await tester.drag(find.byType(EmbedWebView), const Offset(0, -250));
      await tester.pumpAndSettle();

      // 证明手势正常驱动了外层滚动
      expect(scrollController.offset, greaterThan(0.0));
    });
  });

  group('EmbedWebView loading & error states', () {
    testWidgets('shows loadingBuilder while loading, hides it on finished',
        (tester) async {
      double? seenProgress;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmbedWebView(
              '<p>Loading test</p>',
              loadingBuilder: (context, progress) {
                seenProgress = progress;
                return const Text('Loading...');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 初始即加载态
      expect(find.text('Loading...'), findsOneWidget);
      expect(seenProgress, equals(0.0));

      final navDelegate = mockPlatform.lastNavigationDelegate!;
      expect(navDelegate.onProgress, isNotNull);
      navDelegate.onProgress!(45);
      await tester.pump();
      expect(seenProgress, equals(0.45));

      expect(navDelegate.onPageFinished, isNotNull);
      navDelegate.onPageFinished!('about:blank');
      await tester.pumpAndSettle();

      expect(find.text('Loading...'), findsNothing);
      expect(find.byKey(const Key('mock_webview')), findsOneWidget);
    });

    testWidgets(
        'shows errorBuilder and calls onWebResourceError on main-frame failure',
        (tester) async {
      WebResourceError? reportedError;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmbedWebView.network(
              'https://this-domain-does-not-exist-12345.example',
              errorBuilder: (context, error) => const Text('Load failed'),
              onWebResourceError: (error) => reportedError = error,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final navDelegate = mockPlatform.lastNavigationDelegate!;
      expect(navDelegate.onWebResourceError, isNotNull);
      navDelegate.onWebResourceError!(
        WebResourceError(
          errorCode: -2,
          description: 'net::ERR_NAME_NOT_RESOLVED',
          isForMainFrame: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Load failed'), findsOneWidget);
      expect(reportedError, isNotNull);
      expect(reportedError!.errorCode, equals(-2));
    });

    testWidgets('ignores sub-resource errors', (tester) async {
      var callbackInvoked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmbedWebView.network(
              'https://flutter.dev',
              errorBuilder: (context, error) => const Text('Load failed'),
              onWebResourceError: (_) => callbackInvoked = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      mockPlatform.lastNavigationDelegate!.onWebResourceError!(
        WebResourceError(
          errorCode: 404,
          description: 'Not Found',
          isForMainFrame: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Load failed'), findsNothing);
      expect(callbackInvoked, isFalse);
    });

    testWidgets('shows errorBuilder on HTTP error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmbedWebView.network(
              'https://flutter.dev/does-not-exist',
              errorBuilder: (context, error) => const Text('HTTP failed'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      mockPlatform.lastNavigationDelegate!.onHttpError!(
        const HttpResponseError(),
      );
      await tester.pumpAndSettle();

      expect(find.text('HTTP failed'), findsOneWidget);
    });

    testWidgets('changing URL clears the error state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmbedWebView.network(
              'https://bad.example',
              errorBuilder: (context, error) => const Text('Load failed'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      mockPlatform.lastNavigationDelegate!.onWebResourceError!(
        WebResourceError(
          errorCode: -2,
          description: 'net::ERR_NAME_NOT_RESOLVED',
          isForMainFrame: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Load failed'), findsOneWidget);

      // 换一个 URL：_loadContent 复位错误态
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmbedWebView.network(
              'https://flutter.dev',
              errorBuilder: (context, error) => const Text('Load failed'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Load failed'), findsNothing);
    });
  });
}
