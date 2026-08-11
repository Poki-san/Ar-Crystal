import 'dart:math' as math;

import 'package:flutter/material.dart';

class CrystalPatternRenderer {
  const CrystalPatternRenderer({required this.palette, required this.seed});

  final List<Color> palette;
  final int seed;

  /*
   * Рисует единый кристаллический паттерн внутри произвольного контура.
   * Карточки и AR используют один renderer, поэтому seed даёт одинаковый принт.
   */
  void paint({
    required Canvas canvas,
    required Path clipPath,
    required Rect bounds,
    double opacity = 1,
  }) {
    if (bounds.isEmpty || palette.isEmpty) return;
    canvas.save();
    canvas.clipPath(clipPath);
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette
              .map((Color color) => color.withValues(alpha: opacity))
              .toList(),
        ).createShader(bounds),
    );
    final math.Random random = math.Random(seed);
    final double cell = math.max(26, bounds.shortestSide / 5.2);
    for (
      double y = bounds.top - cell;
      y < bounds.bottom + cell;
      y += cell * .78
    ) {
      for (
        double x = bounds.left - cell;
        x < bounds.right + cell;
        x += cell * .86
      ) {
        final Offset center = Offset(
          x + (random.nextDouble() - .5) * cell * .55,
          y + (random.nextDouble() - .5) * cell * .55,
        );
        final int sides = 4 + random.nextInt(3);
        final Path shard = Path();
        for (int index = 0; index < sides; index++) {
          final double angle =
              math.pi * 2 * index / sides + random.nextDouble() * .35;
          final double radius = cell * (.55 + random.nextDouble() * .45);
          final Offset point =
              center +
              Offset(math.cos(angle) * radius, math.sin(angle) * radius);
          index == 0
              ? shard.moveTo(point.dx, point.dy)
              : shard.lineTo(point.dx, point.dy);
        }
        shard.close();
        canvas.drawPath(
          shard,
          Paint()
            ..color = palette[random.nextInt(palette.length)].withValues(
              alpha: opacity * (.72 + random.nextDouble() * .28),
            ),
        );
        canvas.drawPath(
          shard,
          Paint()
            ..color = Colors.white.withValues(alpha: opacity * .16)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    }
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.25, -.4),
          radius: 1.1,
          colors: <Color>[
            Colors.white.withValues(alpha: opacity * .22),
            Colors.transparent,
            Colors.black.withValues(alpha: opacity * .35),
          ],
        ).createShader(bounds)
        ..blendMode = BlendMode.softLight,
    );
    canvas.restore();
  }
}
