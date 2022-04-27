import 'package:embed_webview/embed_webview.dart' show EmbedWebView;
import 'package:example/web_content.dart';
import 'package:flutter/material.dart';

/*
 * @Author: jixiaoyong
 * @Date: 22/04/27
 * @LastEditors: jixiaoyong
 * @LastEditTime: 22/04/27
 * @FilePath: /embed_webview/example/lib/main.dart
 * @Description: 
 * 
 * @Email: jixiaoyong1995@gmail.com
 * Copyright (c) 2022 by jixiaoyong, All Rights Reserved. 
 */
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Embed Webview Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Embed Webview'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        child: Column(
          children: [
            Container(
              color: Colors.orange.shade200,
              height: 100,
              child: const Center(
                child: Text(
                  "This is a text before the webview.",
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(0.0),
              child: EmbedWebView(WebContent),
            ),
            Container(
              color: Colors.blue.shade200,
              height: 100,
              child: const Center(
                child: Text(
                  "This is a text after the webview.",
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
