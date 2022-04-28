/*
 * @Author: jixiaoyong
 * @Date: 22/04/27
 * @LastEditors: jixiaoyong
 * @LastEditTime: 22/04/28
 * @FilePath: \embed_webview\lib\src\embed_webview.dart
 * @Description: 
 * 
 * @Email: jixiaoyong1995@gmail.com
 * Copyright (c) 2022 by jixiaoyong, All Rights Reserved. 
 */

import 'package:flutter/material.dart';

import 'embed_webview_stub.dart';
import 'logutil.dart';
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
// ignore: must_be_immutable
class EmbedWebView extends StatefulWidget {
  String webViewContent = "";
  final double? width;
  final double? height;
  final String? fontSize;
  final String? backgroundColor;
  final String? lineHeight;
  final bool forceExpandImageWidget;
  // whether to add style on web content
  final bool needFormatContent;

  /// A widget that displays a WebView in Flutter Web.
  /// The [srcDoc] property must be set to a valid HTML document.
  /// example:
  /// ```html
  ///   <div>
  ///   <!-- There is your code -->
  ///   </div>
  /// ```
  /// @param [webViewContent]: web view content
  ///   页面间传递中文需要用Uri.encodeComponent转换，
  ///   否则就报Invalid argument(s): Illegal percent encoding in URI异常
  /// @param [width]: the width of the webview, if null, the width will be as wide as it can be
  /// @param [height] the hight of this webview, if null , the height will be as high as it can be
  /// @param [fontSize]: 网页文本的字体大小，如"4vw"，不指定则用默认的大小
  /// @param [backgroundColor] 网页的背景颜色，格式为#RRGGBB，默认白色
  /// @param [forceExpandImageWidget]: force expand image widget's width and height to fit the screen
  /// @param [needFormatContent]: whether to add style on web content, if you want
  ///   to set [fontSize]/[backgroundColor]/[lineHeight]/[forceExpandImageWidget]
  ///   you should set this to true. If you just want to show your web content,
  ///   then you should set this to false.
  EmbedWebView(this.webViewContent,
      {Key? key,
      this.width,
      this.height,
      this.fontSize,
      this.backgroundColor,
      this.lineHeight,
      this.forceExpandImageWidget = false,
      this.needFormatContent = true})
      : super(key: key);

  @override
  State<EmbedWebView> createState() => _EmbedWebViewState();
}

class _EmbedWebViewState extends State<EmbedWebView> {
  // the width this widget can use, usually is [widget.width] or the width of the screen
  double? _widgetMaxWidth;
  double? _screenheightPx;

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

    _screenheightPx = widget.height == null
        ? null
        : widget.height! * (MediaQuery.of(context).devicePixelRatio);

    // format the web view content
    var webViewContentHtml = WebViewUtils.getWebContent(
        widget.webViewContent, widthPx.toInt(),
        fontSize: widget.fontSize,
        backgroundColor: widget.backgroundColor,
        forceExpandImageWidget: widget.forceExpandImageWidget,
        lineHeight: widget.lineHeight,
        needFormatContent: widget.needFormatContent);

    LogUtil.d("build webViewContentHtml:$webViewContentHtml");
    LogUtil.d("width $_widgetMaxWidth  , height $_screenheightPx");
    return ConstrainedBox(
      constraints: BoxConstraints(
          maxHeight: widget.height ?? MediaQuery.of(context).size.height),
      child: SingleChildScrollView(
        child: GestureDetector(
            onHorizontalDragUpdate: (value) {},
            child: SizedBox(
              width: _widgetMaxWidth,
              height: widget.height,
              child: getEmbedWebViewAuto(
                  webViewContentHtml, widthPx, _screenheightPx),
            )),
      ),
    );
  }
}
