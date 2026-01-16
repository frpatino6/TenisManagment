import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// WebView screen for Wompi payment
///
/// Opens Wompi checkout in an in-app WebView to avoid Safari popup blocking issues
class WompiWebViewScreen extends StatefulWidget {
  final String checkoutUrl;
  final String redirectUrl;

  const WompiWebViewScreen({
    super.key,
    required this.checkoutUrl,
    required this.redirectUrl,
  });

  @override
  State<WompiWebViewScreen> createState() => _WompiWebViewScreenState();
}

class _WompiWebViewScreenState extends State<WompiWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            // Check if we've been redirected to the success URL
            if (url.contains(widget.redirectUrl)) {
              // Close WebView and return to app
              Navigator.of(context).pop(true);
            }
          },
          onWebResourceError: (WebResourceError error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al cargar Wompi: ${error.description}'),
                backgroundColor: Colors.red,
              ),
            );
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pago Wompi'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
