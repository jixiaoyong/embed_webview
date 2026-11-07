import 'package:embed_webview/embed_webview.dart' show EmbedWebView;
import 'package:example/web_content.dart';
import 'package:flutter/material.dart';

void main() {
  // 可选：开启 EmbedWebView 内部调试日志
  EmbedWebView.enableLogging = true;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Embed Webview Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Embed Webview Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double _currentHeight = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.title} (Height: ${_currentHeight.toStringAsFixed(1)}px)'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: Colors.orange.shade200,
              height: 80,
              child: const Center(
                child: Text(
                  "Text before webview (Flutter native)",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: EmbedWebView(
                webContent,
                initialHeight: 80.0,
                animate: true,
                onHeightChanged: (newHeight) {
                  setState(() {
                    _currentHeight = newHeight;
                  });
                },
                onLinkTap: (url) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Interception: clicked hyperlink -> $url'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
            Container(
              color: Colors.blue.shade200,
              height: 80,
              child: const Center(
                child: Text(
                  "Text after webview (Flutter native)",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
