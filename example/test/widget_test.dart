import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example/main.dart';
import 'package:embed_webview/embed_webview.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

class MockPlatformWebViewController extends PlatformWebViewController {
  MockPlatformWebViewController(super.params) : super.implementation();

  @override
  Future<void> runJavaScript(String javaScript) async {}

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}

  @override
  Future<void> setBackgroundColor(Color color) async {}

  @override
  Future<void> addJavaScriptChannel(
    JavaScriptChannelParams javaScriptChannelParams,
  ) async {}

  @override
  Future<void> loadHtmlString(String html, {String? baseUrl}) async {}

  @override
  Future<void> setPlatformNavigationDelegate(
    PlatformNavigationDelegate handler,
  ) async {}
}

class MockPlatformNavigationDelegate extends PlatformNavigationDelegate {
  MockPlatformNavigationDelegate(super.params) : super.implementation();

  @override
  Future<void> setOnNavigationRequest(
    NavigationRequestCallback onNavigationRequest,
  ) async {}

  @override
  Future<void> setOnPageFinished(PageEventCallback onPageFinished) async {}
}

class MockPlatformWebViewWidget extends PlatformWebViewWidget {
  MockPlatformWebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(key: Key('mock_webview'));
  }
}

class MockWebViewPlatform extends WebViewPlatform {
  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    return MockPlatformWebViewController(params);
  }

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) {
    return MockPlatformNavigationDelegate(params);
  }

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) {
    return MockPlatformWebViewWidget(params);
  }
}

void main() {
  setUp(() {
    WebViewPlatform.instance = MockWebViewPlatform();
  });

  testWidgets('Smoke test for MyHomePage layout', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            (widget.data?.contains('Embed Webview Demo') == true ||
                widget.data?.contains('自适应 WebView 演示') == true),
      ),
      findsOneWidget,
    );
    expect(find.byType(EmbedWebView), findsOneWidget);
  });
}
