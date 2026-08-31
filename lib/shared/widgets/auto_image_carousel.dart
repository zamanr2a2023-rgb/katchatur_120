import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AutoImageCarousel extends StatefulWidget {
  const AutoImageCarousel({
    super.key,
    required this.images,
    required this.height,
    this.autoInterval = const Duration(seconds: 8),
    this.showDots = true,
  });

  final List<String> images;
  final double height;
  final Duration autoInterval;
  final bool showDots;

  @override
  State<AutoImageCarousel> createState() => _AutoImageCarouselState();
}

class _AutoImageCarouselState extends State<AutoImageCarousel> {
  int _index = 0;
  late final PageController _pageController;
  Timer? _autoTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.images.length > 1) {
      _startAutoPlay();
    }
  }

  @override
  void didUpdateWidget(covariant AutoImageCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.autoInterval != widget.autoInterval ||
        oldWidget.images.length != widget.images.length) {
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    _autoTimer?.cancel();
    if (widget.images.length <= 1) return;

    _autoTimer = Timer.periodic(widget.autoInterval, (_) {
      if (!mounted || !_pageController.hasClients) return;
      final next = (_index + 1) % widget.images.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  void _onPageChanged(int i) {
    setState(() => _index = i);
    _startAutoPlay();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return SizedBox(height: widget.height);
    }

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, i) {
              return Image.asset(
                widget.images[i],
                width: double.infinity,
                fit: BoxFit.cover,
              );
            },
          ),
          if (widget.showDots && widget.images.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.images.length,
                  (i) {
                    final active = i == _index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 14 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.background.withValues(
                          alpha: active ? 0.95 : 0.5,
                        ),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: active
                            ? null
                            : [
                                BoxShadow(
                                  color: AppColors.ink.withValues(alpha: 0.25),
                                  blurRadius: 2,
                                ),
                              ],
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
