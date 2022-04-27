/*
 * @Author: jixiaoyong
 * @Date: 22/04/27
 * @LastEditors: jixiaoyong
 * @LastEditTime: 22/04/27
 * @FilePath: /embed_webview/lib/embed/logutil.dart
 * @Description: log util
 * 
 * @Email: jixiaoyong1995@gmail.com
 * Copyright (c) 2022 by jixiaoyong, All Rights Reserved. 
 */
import 'package:flutter/material.dart';

class LogUtil {
  static void d(String msg) {
    debugPrint(msg);
  }

  static void e(Object e) {
    debugPrint(e.toString());
  }
}
