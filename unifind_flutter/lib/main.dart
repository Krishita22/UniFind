import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    WebView.platform = AndroidWebView();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final envUrl = const String.fromEnvironment('PREVIEW_URL');
    final url = envUrl.isNotEmpty
        ? envUrl
        : (Platform.isAndroid ? 'http://10.0.2.2:5173' : 'http://localhost:5173');

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(url));

    return MaterialApp(
      title: 'UniFind (WebView)',
      home: Scaffold(
        appBar: AppBar(title: const Text('UniFind (WebView)')),
        body: SafeArea(child: WebViewWidget(controller: controller)),
      ),
    );
  }
}
