import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

abstract final class PoseCoordinateMapper {
  /*
   * Сопоставляет координаты ML Kit с CameraPreview, растянутым через
   * BoxFit.cover. Учитывает поворот, обрезку кадра и зеркало фронтальной камеры.
   */
  static Offset toPreview({
    required PoseLandmark landmark,
    required Size imageSize,
    required Size canvasSize,
    required InputImageRotation rotation,
    required CameraLensDirection lensDirection,
  }) {
    final bool quarterTurn =
        rotation == InputImageRotation.rotation90deg ||
        rotation == InputImageRotation.rotation270deg;
    final double sourceWidth = quarterTurn ? imageSize.height : imageSize.width;
    final double sourceHeight = quarterTurn
        ? imageSize.width
        : imageSize.height;
    double x = landmark.x;

    if (rotation == InputImageRotation.rotation270deg) {
      x = sourceWidth - x;
    } else if (!quarterTurn && lensDirection == CameraLensDirection.front) {
      x = sourceWidth - x;
    }

    final double scale = math.max(
      canvasSize.width / sourceWidth,
      canvasSize.height / sourceHeight,
    );
    final double offsetX = (canvasSize.width - sourceWidth * scale) / 2;
    final double offsetY = (canvasSize.height - sourceHeight * scale) / 2;
    return Offset(x * scale + offsetX, landmark.y * scale + offsetY);
  }
}
