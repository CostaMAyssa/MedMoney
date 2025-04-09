import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_web/webview_flutter_web.dart';

class PdfViewerWeb extends StatefulWidget {
  final String title;
  final String pdfAssetPath;

  const PdfViewerWeb({
    Key? key,
    required this.title,
    required this.pdfAssetPath,
  }) : super(key: key);

  @override
  State<PdfViewerWeb> createState() => _PdfViewerWebState();
}

class _PdfViewerWebState extends State<PdfViewerWeb> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    
    // Registrar o plugin Web
    WebViewPlatform.instance = WebWebViewPlatform();
    
    // Criar o controlador
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Atualizar indicador de carregamento
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
        ),
      )
      ..loadFlutterAsset(widget.pdfAssetPath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF1A1A4F),
        foregroundColor: Colors.white,
      ),
      body: WebViewWidget(controller: controller),
    );
  }
} 