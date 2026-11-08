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

  group('EmbedWebView load & error callbacks', () {
    testWidgets('forwards onPageStarted / onProgress / onPageFinished',
        (tester) async {
      String? started;
      int? seenProgress;
      String? finished;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmbedWebView.network(
              'https://example.com',
              onPageStarted: (url) => started = url,
              onProgress: (progress) => seenProgress = progress,
              onPageFinished: (url) => finished = url,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final navDelegate = mockPlatform.lastNavigationDelegate!;
      expect(navDelegate.onPageStarted, isNotNull);
      expect(navDelegate.onProgress, isNotNull);
      expect(navDelegate.onPageFinished, isNotNull);

      navDelegate.onPageStarted!('https://example.com/a');
      expect(started, 'https://example.com/a');

      navDelegate.onProgress!(42);
      expect(seenProgress, 42);

      navDelegate.onPageFinished!('https://example.com/a');
      // onPageFinished 的回调体内部有 await（注入探针），需要冲刷微任务
      await tester.pump();
      expect(finished, 'https://example.com/a');
    });

    testWidgets('injects the height probe before onPageFinished fires',
        (tester) async {
      bool probeReady = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmbedWebView.network(
              'https://example.com',
              onPageFinished: (_) {
                probeReady =
                    mockPlatform.lastController?.lastExecutedJs != null;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      mockPlatform
          .lastNavigationDelegate!.onPageFinished!('https://example.com');
      await tester.pump();

      expect(probeReady, isTrue);
      expect(
        mockPlatform.lastController!.lastExecutedJs,
        contains('ResizeObserver'),
      );
    });

    testWidgets('forwards onWebResourceError as-is', (tester) async {
      WebResourceError? received;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmbedWebView.network(
              'https://example.com',
              onWebResourceError: (error) => received = error,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final error = WebResourceError(
        errorCode: -2,
        description: 'net::ERR_NAME_NOT_RESOLVED',
        errorType: WebResourceErrorType.hostLookup,
        isForMainFrame: true,
      );
      mockPlatform.lastNavigationDelegate!.onWebResourceError!(error);

      expect(received, same(error));
    });

    testWidgets('forwards every onHttpError without main-frame filtering',
        (tester) async {
      final List<HttpResponseError> received = <HttpResponseError>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmbedWebView.network(
              'https://example.com',
              onHttpError: received.add,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final page = HttpResponseError(
        request: WebResourceRequest(uri: Uri.parse('https://example.com')),
        response: WebResourceResponse(
          uri: Uri.parse('https://example.com'),
          statusCode: 404,
        ),
      );
      final image = HttpResponseError(
        request: WebResourceRequest(
          uri: Uri.parse('https://example.com/logo.png'),
        ),
        response: WebResourceResponse(
          uri: Uri.parse('https://example.com'),
          statusCode: 404,
        ),
      );
      mockPlatform.lastNavigationDelegate!
        ..onHttpError!(page)
        ..onHttpError!(image);

      // 库不做主框架过滤，子资源的 404 也原样上报
      expect(received, <HttpResponseError>[page, image]);
    });

    testWidgets('renders no loading or error UI of its own', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmbedWebView.network(
              'https://example.com',
              onPageStarted: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('mock_webview')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('all callbacks are optional', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: EmbedWebView.network('https://example.com')),
        ),
      );
      await tester.pumpAndSettle();

      final navDelegate = mockPlatform.lastNavigationDelegate!;
      navDelegate.onPageStarted!('https://example.com');
      navDelegate.onProgress!(10);
      navDelegate.onPageFinished!('https://example.com');

      expect(find.byKey(const Key('mock_webview')), findsOneWidget);
    });
  });
}
