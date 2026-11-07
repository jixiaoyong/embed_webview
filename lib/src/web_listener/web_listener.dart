import 'web_listener_stub.dart'
    if (dart.library.js_interop) 'web_listener_web.dart';

abstract class WebMessageSubscription {
  void cancel();
}

WebMessageSubscription? initWebMessageListener({
  required void Function(double height) onHeight,
  void Function(double deltaY)? onScroll,
  void Function(double velocity)? onFling,
  void Function(String lang)? onLanguage,
}) {
  return createWebMessageListener(
    onHeight: onHeight,
    onScroll: onScroll,
    onFling: onFling,
    onLanguage: onLanguage,
  );
}
