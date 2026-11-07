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

WebMessageSubscription? createWebMessageListener({
  required void Function(double height) onHeight,
  void Function(double deltaY)? onScroll,
  void Function(String lang)? onLanguage,
}) {
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
        } else if (str.startsWith('embed_webview_lang:')) {
          final String lang = str.substring('embed_webview_lang:'.length);
          onLanguage?.call(lang);
        } else if (str.startsWith('embed_webview_scroll:')) {
          final String deltaStr = str.substring('embed_webview_scroll:'.length);
          final double? deltaY = double.tryParse(deltaStr);
          if (deltaY != null) {
            if (onScroll != null) {
              onScroll(deltaY);
            } else {
              final web.WheelEvent wheelEvent = web.WheelEvent(
                'wheel',
                web.WheelEventInit(
                  deltaY: deltaY,
                  bubbles: true,
                  cancelable: true,
                ),
              );
              web.window.dispatchEvent(wheelEvent);
            }
          }
        }
      }
    } catch (_) {}
  }).toJS;

  web.window.addEventListener('message', listener);
  return _WebMessageSubscriptionImpl(listener);
}
