import 'package:flutter/material.dart';

/*
 * Результат локального сканирования. Объект не выполняет обработку сам и
 * служит явной границей между камерой, генератором принта и экраном создания.
 */
class CaptureResult {
  const CaptureResult({
    required this.imagePath,
    required this.audioPath,
    required this.palette,
    required this.seed,
  });

  final String imagePath;
  final String audioPath;
  final List<Color> palette;
  final int seed;
}
