import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../utils/wompi_redirect_utils.dart';

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
              final status = parseWompiPaymentStatus(widget.redirectUrl, url);
              final uri = Uri.tryParse(url);
              final transactionId =
                  uri?.queryParameters['id'] ??
                  uri?.queryParameters['transaction_id'];
              // Close WebView and return to app
              Navigator.of(context).pop({
                'status': status,
                'transactionId': transactionId,
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            // No UI feedback here to avoid flashing errors during checkout.
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
