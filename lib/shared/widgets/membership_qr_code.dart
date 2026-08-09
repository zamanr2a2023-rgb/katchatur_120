import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Deterministic decorative QR placeholder (prototype only).
class MembershipQrCode extends StatelessWidget {
  const MembershipQrCode({super.key, required this.value});

  final String value;
  static const int grid = 25;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(painter: _QrPainter(value: value)),
    );
  }
}

class _QrPainter extends CustomPainter {
  _QrPainter({required this.value});

  final String value;

  int _u32(int n) => n & 0xFFFFFFFF;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / MembershipQrCode.grid;
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.card);

    final cells = _pattern(value);
    for (var i = 0; i < cells.length; i++) {
      final r = i ~/ MembershipQrCode.grid;
      final c = i % MembershipQrCode.grid;
      final finder = _isFinder(r, c);
      final fill = finder ? _finderFill(r, c) : cells[i];
      if (!fill) continue;

      final ring = ((r % 7) - 3).abs() > ((c % 7) - 3).abs()
          ? ((r % 7) - 3).abs()
          : ((c % 7) - 3).abs();
      final corner = finder && ring <= 1;

      canvas.drawRect(
        Rect.fromLTWH(c * cell, r * cell, cell, cell),
        Paint()..color = corner ? AppColors.primary : AppColors.ink,
      );
    }
  }

  List<bool> _pattern(String seed) {
    final cells = <bool>[];
    var h = 7;
    for (var i = 0; i < seed.length; i++) {
      h = _u32(h * 31 + seed.codeUnitAt(i));
    }
    for (var i = 0; i < MembershipQrCode.grid * MembershipQrCode.grid; i++) {
      h = _u32(h * 1664525 + 1013904223);
      cells.add(((h >> 16) & 1) == 1);
    }
    return cells;
  }

  bool _isFinder(int r, int c) {
    const zones = [
      [0, 0],
      [0, MembershipQrCode.grid - 7],
      [MembershipQrCode.grid - 7, 0],
    ];
    return zones.any(
      (z) => r >= z[0] && r < z[0] + 7 && c >= z[1] && c < z[1] + 7,
    );
  }

  bool _finderFill(int r, int c) {
    const zones = [
      [0, 0],
      [0, MembershipQrCode.grid - 7],
      [MembershipQrCode.grid - 7, 0],
    ];
    for (final z in zones) {
      if (r >= z[0] && r < z[0] + 7 && c >= z[1] && c < z[1] + 7) {
        final dr = r - z[0];
        final dc = c - z[1];
        final ring =
            (dr - 3).abs() > (dc - 3).abs() ? (dr - 3).abs() : (dc - 3).abs();
        return ring == 3 || ring <= 1;
      }
    }
    return false;
  }

  @override
  bool shouldRepaint(covariant _QrPainter oldDelegate) =>
      oldDelegate.value != value;
}
