import 'web_listener_stub.dart'
    if (dart.library.js_interop) 'web_listener_web.dart';

abstract class WebMessageSubscription {
  void cancel();
}

WebMessageSubscription? initWebMessageListener(void Function(double height) onHeight) {
  return createWebMessageListener(onHeight);
}
