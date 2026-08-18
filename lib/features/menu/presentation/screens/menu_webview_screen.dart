import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/theme/app_colors.dart';

class MenuWebViewScreen extends StatefulWidget {
  const MenuWebViewScreen({
    super.key,
    required this.url,
    this.title = 'Our Menu',
  });

  final String url;
  final String title;

  @override
  State<MenuWebViewScreen> createState() => _MenuWebViewScreenState();
}

class _MenuWebViewScreenState extends State<MenuWebViewScreen> {
  late final WebViewController _controller;
  var _loadingProgress = 0;
  var _hasError = false;

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
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _hasError = false;
              _loadingProgress = 0;
            });
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
      ..loadRequest(Uri.parse(widget.url));
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
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
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
                      'Could not load the menu. Please check your connection.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.mutedForeground),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        setState(() => _hasError = false);
                        _controller.loadRequest(Uri.parse(widget.url));
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
