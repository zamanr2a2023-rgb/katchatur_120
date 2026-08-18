import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/theme/app_colors.dart';

class StripeCheckoutScreen extends StatefulWidget {
  const StripeCheckoutScreen({
    super.key,
    required this.checkoutUrl,
    this.title = 'Donate with Stripe',
  });

  final String checkoutUrl;
  final String title;

  @override
  State<StripeCheckoutScreen> createState() => _StripeCheckoutScreenState();
}

class _StripeCheckoutScreenState extends State<StripeCheckoutScreen> {
  late final WebViewController _controller;
  var _loadingProgress = 0;
  var _hasError = false;
  var _handled = false;

  static const _successHost = 'bajatzu.app';
  static const _successPath = '/donate-success';
  static const _cancelPath = '/donate-cancel';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.background)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (!mounted) return;
            setState(() => _loadingProgress = progress);
          },
          onPageStarted: (url) => _handleReturnUrl(url),
          onNavigationRequest: (request) {
            _handleReturnUrl(request.url);
            return NavigationDecision.navigate;
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _loadingProgress = 100);
          },
          onWebResourceError: (_) {
            if (!mounted) return;
            setState(() => _hasError = true);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  void _handleReturnUrl(String url) {
    if (_handled) return;
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host != _successHost) return;

    if (uri.path == _successPath) {
      _handled = true;
      final sessionId = uri.queryParameters['session_id'] ?? '';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pop(('success', sessionId));
      });
      return;
    }

    if (uri.path == _cancelPath) {
      _handled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pop(('cancel', ''));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.ink,
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(('cancel', '')),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: _loadingProgress < 100
              ? LinearProgressIndicator(
                  value: _loadingProgress / 100,
                  minHeight: 2,
                  backgroundColor: AppColors.muted,
                  color: AppColors.primary,
                )
              : const SizedBox(height: 2),
        ),
      ),
      body: _hasError
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Could not load Stripe checkout. Please check your connection.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.mutedForeground),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        setState(() => _hasError = false);
                        _controller.loadRequest(Uri.parse(widget.checkoutUrl));
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : WebViewWidget(controller: _controller),
    );
  }
}
