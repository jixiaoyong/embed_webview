import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'web_listener.dart';

class _WebMessageSubscriptionImpl implements WebMessageSubscription {
  final JSFunction _listener;

  _WebMessageSubscriptionImpl(this._listener);

  @override
  void cancel() {
    web.window.removeEventListener('message', _listener);
  }
}

WebMessageSubscription? createWebMessageListener(void Function(double height) onHeight) {
  final JSFunction listener = ((web.MessageEvent event) {
    try {
      final JSAny? data = event.data;
      if (data != null) {
        final String str = data.dartify()?.toString() ?? '';
        if (str.startsWith('embed_webview_resize:')) {
          final String heightStr = str.substring('embed_webview_resize:'.length);
          final double? h = double.tryParse(heightStr);
          if (h != null && h > 0) {
            onHeight(h);
          }
        }
      }
    } catch (_) {}
  }).toJS;

  web.window.addEventListener('message', listener);
  return _WebMessageSubscriptionImpl(listener);
}
