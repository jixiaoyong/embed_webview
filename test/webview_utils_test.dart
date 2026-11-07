import 'package:flutter_test/flutter_test.dart';
import 'package:embed_webview/src/webview_utils.dart';

void main() {
  group('WebViewUtils Tests', () {
    test('getWebContent wraps content without tampering user styles', () {
      const content = '<h1 style="color: red; font-size: 32px;">Title</h1><p>Paragraph</p>';
      final result = WebViewUtils.getWebContent(content);

      expect(result.contains('<html'), isTrue);
      expect(result.contains('</html>'), isTrue);
      expect(result.contains('<div id="embed-container"'), isTrue);
      // 验证未篡改用户的内联样式
      expect(result.contains('color: red; font-size: 32px;'), isTrue);
      expect(result.contains('ResizeObserver'), isTrue);
      expect(result.contains(WebViewUtils.channelName), isTrue);
    });

    test('getWebContent supports custom backgroundColor if specified', () {
      const content = '<p>Styled background</p>';
      final result = WebViewUtils.getWebContent(content, backgroundColor: '#f0f0f0');

      expect(result.contains('background: #f0f0f0;'), isTrue);
    });
  });
}
