import 'package:flutter/material.dart';

import '../rendering/crystal_pattern_renderer.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/wearable.dart';

class CrystalArt extends StatelessWidget {
  const CrystalArt({
    required this.wearable,
    this.fit = BoxFit.contain,
    this.showGrid = false,
    super.key,
  });

  final Wearable wearable;
  final BoxFit fit;
  final bool showGrid;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: CrystalPainter(wearable: wearable, showGrid: showGrid),
      size: Size.infinite,
    );
  }
}

class CrystalPainter extends CustomPainter {
  CrystalPainter({required this.wearable, required this.showGrid});

  final Wearable wearable;
  final bool showGrid;

  @override
  void paint(Canvas canvas, Size size) {
    /* Seed делает расположение граней стабильным для конкретного предмета. */
    final Rect bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF22282A), Color(0xFF090B0C)],
        ).createShader(bounds),
    );
    if (showGrid) _paintGrid(canvas, size);

    final Path garment = _garmentPath(size, wearable.kind);
    CrystalPatternRenderer(
      palette: wearable.palette,
      seed: wearable.seed,
    ).paint(canvas: canvas, clipPath: garment, bounds: bounds);
    canvas.drawPath(
      garment,
      Paint()
        ..color = wearable.palette.first.withValues(alpha: .7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
  }

  void _paintGrid(Canvas canvas, Size size) {
    final Paint grid = Paint()
      ..color = Colors.white.withValues(alpha: .1)
      ..strokeWidth = .7;
    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
  }

  /* Возвращает нормализованный 2D-силуэт выбранного кроя для карточек. */
  Path _garmentPath(Size size, WearableKind kind) {
    final double w = size.width;
    final double h = size.height;
    switch (kind) {
      case WearableKind.tshirt:
        return Path()
          ..moveTo(w * .34, h * .2)
          ..lineTo(w * .18, h * .28)
          ..lineTo(w * .08, h * .48)
          ..lineTo(w * .25, h * .56)
          ..lineTo(w * .3, h * .46)
          ..lineTo(w * .28, h * .88)
          ..quadraticBezierTo(w * .5, h * .94, w * .72, h * .88)
          ..lineTo(w * .7, h * .46)
          ..lineTo(w * .75, h * .56)
          ..lineTo(w * .92, h * .48)
          ..lineTo(w * .82, h * .28)
          ..lineTo(w * .66, h * .2)
          ..quadraticBezierTo(w * .62, h * .36, w * .5, h * .36)
          ..quadraticBezierTo(w * .38, h * .36, w * .34, h * .2)
          ..close();
      case WearableKind.hoodie:
        return Path()
          ..moveTo(w * .38, h * .12)
          ..quadraticBezierTo(w * .5, h * .02, w * .62, h * .12)
          ..lineTo(w * .68, h * .22)
          ..lineTo(w * .8, h * .28)
          ..lineTo(w * .94, h * .73)
          ..lineTo(w * .78, h * .79)
          ..lineTo(w * .68, h * .48)
          ..lineTo(w * .72, h * .91)
          ..quadraticBezierTo(w * .5, h * .97, w * .28, h * .91)
          ..lineTo(w * .32, h * .48)
          ..lineTo(w * .22, h * .79)
          ..lineTo(w * .06, h * .73)
          ..lineTo(w * .2, h * .28)
          ..lineTo(w * .32, h * .22)
          ..close();
      case WearableKind.dress:
        return Path()
          ..moveTo(w * .39, h * .14)
          ..quadraticBezierTo(w * .5, h * .24, w * .61, h * .14)
          ..lineTo(w * .68, h * .24)
          ..lineTo(w * .62, h * .49)
          ..lineTo(w * .84, h * .92)
          ..quadraticBezierTo(w * .5, h * .99, w * .16, h * .92)
          ..lineTo(w * .38, h * .49)
          ..lineTo(w * .32, h * .24)
          ..close();
      case WearableKind.sneakers:
        return Path()
          ..moveTo(w * .1, h * .58)
          ..quadraticBezierTo(w * .24, h * .42, w * .34, h * .28)
          ..lineTo(w * .55, h * .32)
          ..quadraticBezierTo(w * .66, h * .58, w * .88, h * .62)
          ..quadraticBezierTo(w * .98, h * .64, w * .92, h * .79)
          ..quadraticBezierTo(w * .52, h * .88, w * .16, h * .78)
          ..quadraticBezierTo(w * .06, h * .74, w * .1, h * .58)
          ..close();
    }
  }

  @override
  bool shouldRepaint(covariant CrystalPainter oldDelegate) =>
      oldDelegate.wearable != wearable || oldDelegate.showGrid != showGrid;
}

class EchoButton extends StatelessWidget {
  const EchoButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.secondary = false,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        backgroundColor: secondary ? AppColors.surfaceSoft : AppColors.acid,
        foregroundColor: secondary ? AppColors.text : AppColors.background,
        side: secondary
            ? const BorderSide(color: AppColors.line)
            : BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
