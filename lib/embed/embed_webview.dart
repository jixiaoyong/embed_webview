/*
 * @Author: jixiaoyong
 * @Date: 22/04/27
 * @LastEditors: jixiaoyong
 * @LastEditTime: 22/04/27
 * @FilePath: /embed_webview/lib/embed/embed_webview.dart
 * @Description: 
 * 
 * @Email: jixiaoyong1995@gmail.com
 * Copyright (c) 2022 by jixiaoyong, All Rights Reserved. 
 */
import 'dart:convert';
import 'dart:io';

import 'package:embed_webview/embed/logutil.dart';
import 'package:flutter/material.dart';

import 'embed_webview_stub.dart';
import 'webview_utils.dart';

/*
* @description: 能够嵌套在页面内部的WebView
*
* 使用：
* EmbedWebView(webViewContent),
*
* @author: jixiaoyong
* @email: jixiaoyong1995@gmail.com
* @date: 2021/11/30
*/
class EmbedWebView extends StatefulWidget {
  String webViewContent = "";
  double? width;
  double? maxHeight = 0;
  String? fontSize;
  String? backgroundColor;
  String? lineHeight;
  bool forceExpandImageWidget;

  /// A widget that displays a WebView in Flutter Web.
  /// The [srcDoc] property must be set to a valid HTML document.
  /// example:
  /// ```html
  /// <!DOCTYPE html>
  /// <html>
  ///   <head>
  ///     <meta charset="utf-8">
  ///     <title>
  ///     </title>
  ///   </head>
  ///
  ///   <body>
  ///   </body>
  ///
  /// </html>
  /// ```
  /// @param [webViewContent]: web view content
  ///   页面间传递中文需要用Uri.encodeComponent转换，
  ///   否则就报Invalid argument(s): Illegal percent encoding in URI异常
  /// @param [width]: the width of the webview, if null, the width will be as wide as it can be
  /// @param [maxHeight] 最大高度，超出则滑动WebView,没有则不限制高度
  /// @param [fontSize]: 网页文本的字体大小，如"4vw"，不指定则用默认的大小
  /// @param [backgroundColor] 网页的背景颜色，格式为#RRGGBB，默认白色
  /// @param [forceExpandImageWidget]: force expand image widget's width and height to fit the screen
  EmbedWebView(this.webViewContent,
      {this.width,
      this.maxHeight,
      this.fontSize,
      this.backgroundColor,
      this.lineHeight,
      this.forceExpandImageWidget = false}) {
    if (webViewContent.isNotEmpty) {
      webViewContent = Uri.encodeComponent(webViewContent);
    }
  }

  @override
  State<EmbedWebView> createState() => _EmbedWebViewState();
}

class _EmbedWebViewState extends State<EmbedWebView> {
  // the width this widget can use, usually is [widget.width] or the width of the screen
  double? _widgetMaxWidth;
  double _screenMaxHeightPx = double.infinity;

  @override
  void initState() {
    _widgetMaxWidth = widget.width;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // listener after widget rander finish
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      if (_widgetMaxWidth == null ||
          (widget.width == null && _widgetMaxWidth != context.size?.width)) {
        setState(() {
          _widgetMaxWidth = widget.width ?? context.size?.width;
          LogUtil.d(
              "context.size ${context.size}, _widgetMaxWidth $_widgetMaxWidth");
        });
      }
    });

    // the width of this widget, use the _widgetMaxWidth if it is not null
    // otherwise use the screen width
    var widthPx = (_widgetMaxWidth ?? MediaQuery.of(context).size.width) *
        MediaQuery.of(context).devicePixelRatio;
    var maxHeight = widget.maxHeight;
    _screenMaxHeightPx = maxHeight == null
        ? _screenMaxHeightPx
        : maxHeight * MediaQuery.of(context).devicePixelRatio;

    // format the web view content
    var webViewContentHtml = WebViewUtils.getWebContent(
        widget.webViewContent, widthPx.toInt(),
        fontSize: widget.fontSize,
        backgroundColor: widget.backgroundColor,
        forceExpandImageWidget: widget.forceExpandImageWidget,
        lineHeight: widget.lineHeight);

    LogUtil.d("build webViewContentHtml:$webViewContentHtml");
    LogUtil.d("width $_widgetMaxWidth  , height $_screenMaxHeightPx");
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: _screenMaxHeightPx),
      child: SingleChildScrollView(
        child: GestureDetector(
            onHorizontalDragUpdate: (value) {},
            child: SizedBox(
              width: _widgetMaxWidth,
              child: getEmbedWebViewAuto(
                webViewContentHtml,
                widthPx,
              ),
            )),
      ),
    );
  }
}
