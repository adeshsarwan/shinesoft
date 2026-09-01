import 'package:flutter/material.dart';
import 'package:interactive_media_ads/interactive_media_ads.dart';
import 'package:shimmer/shimmer.dart';

import 'ima_controller.dart';

class ImaPlayerWidget extends StatefulWidget {
  const ImaPlayerWidget({
    super.key,
    required this.controller,
    this.height,
  });

  final ImaController controller;
  final double? height;

  @override
  State<ImaPlayerWidget> createState() => _ImaPlayerWidgetState();
}

class _ImaPlayerWidgetState extends State<ImaPlayerWidget> {
  AdDisplayContainer? _container;

  @override
  void initState() {
    super.initState();
    _container = AdDisplayContainer(
      onContainerAdded: widget.controller.setContainer,
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.white.withValues(alpha: 0.1),
      highlightColor: Colors.white.withValues(alpha: 0.24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(color: Colors.black),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 14,
              width: 180,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 10,
              width: 220,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 48,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final child = Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: Colors.black)),
        if (_container != null)
          Positioned.fill(child: _container!),
        if (widget.controller.isLoadingAd)
          Positioned.fill(child: _buildLoadingPlaceholder()),
      ],
    );

    if (widget.height == null) {
      return SizedBox.expand(child: child);
    }

    return SizedBox(height: widget.height, child: child);
  }
}
