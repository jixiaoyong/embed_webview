// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui' as ui;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

import 'package:embed_webview/src/logutil.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Widget getEmbedWebView(String srcDoc, [double? width, double? height]) =>
    EmbedWebView4FlutterWeb(
      srcDoc: srcDoc,
      width: width,
      height: height,
    );

///
/// @author: jixiaoyong
/// @email: jixiaoyong1995@gmail.com
/// @date: 22/04/25
/// @description:
/// A widget that displays a WebView in Flutter Web.
/// The [srcDoc] property must be set to a valid HTML document.
/// example:
/// ```html
///   <div>
///   <!-- There is your code -->
///   </div>
/// ```
/// The [width] and [height] properties can be null when you want the widget to
/// size itself to the size of the WebView content.
class EmbedWebView4FlutterWeb extends StatefulWidget {
  final String srcDoc;
  final double? width;
  final double? height;

  const EmbedWebView4FlutterWeb(
      {Key? key, required this.srcDoc, this.width, this.height})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return EmbedWebView4FlutterWebState();
  }
}

class EmbedWebView4FlutterWebState extends State<EmbedWebView4FlutterWeb> {
  late html.IFrameElement _iframeElement;
  double _iframeElementHeight = 10;
  double _iframeElementWidth = 10;
  String iframeId = "MyIframeId";

  @override
  initState() {
    super.initState();

    iframeId = iframeId + DateTime.now().millisecondsSinceEpoch.toString();

    _iframeElement = html.IFrameElement()
      ..srcdoc = widget.srcDoc
      ..id = iframeId
      ..onLoad.listen((event) async {
        var body = html.querySelector("#$iframeId");
        // inspired by https://stackoverflow.com/a/28278469/8389461
        var jsIFrame = js.JsObject.fromBrowserObject(body as Object);
        var documentElement = jsIFrame["contentDocument"]["documentElement"];

        setState(() {
          _iframeElementHeight = documentElement["scrollHeight"].toDouble();
          _iframeElementWidth = documentElement["scrollWidth"].toDouble();

          LogUtil.d(
              "_iframeElementHeight: $_iframeElementHeight _iframeElementWidth: $_iframeElementWidth");
        });
      })
      ..height = "auto"
      ..width = "auto"
      ..style.border = 'none';

      // ..height = "fit-content"
      // ..width = "fit-content"
      // ..style.border = "none"
      // ..style.padding = "0"
      // ..style.color = "transparent"
      // ..style.height = "min-content"
      // // ..style.width = "fit-content"
      // // ..style.maxWidth = "fit-content"
      // // ..style.maxHeight = "fit-content"
      // ..style.margin = "0";

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      'iframeElement',
      (int viewId) => _iframeElement,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height ?? _iframeElementHeight,
      width: widget.width ?? _iframeElementWidth,
      child: HtmlElementView(
        viewType: 'iframeElement',
        onPlatformViewCreated: (id) {},
      ),
    );
  }
}
