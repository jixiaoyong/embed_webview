import 'package:flutter/foundation.dart';

/*
 * @description: 内部日志工具，默认静默，避免污染开发者控制台
 * 可通过 EmbedWebView.enableLogging = true 开启调试日志
 * @author: jixiaoyong
 * @email: jixiaoyong1995@gmail.com
 */
class LogUtil {
  static bool enableLogging = false;

  static void d(String msg) {
    if (enableLogging) {
      debugPrint('[EmbedWebView] $msg');
    }
  }

  static void e(Object e) {
    if (enableLogging) {
      debugPrint('[EmbedWebView Error] $e');
    }
  }
}
