import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../../../core/theme/app_theme.dart';
import '../../crystallizer/domain/entities/wearable.dart';
import '../../crystallizer/presentation/rendering/crystal_pattern_renderer.dart';
import 'utils/pose_coordinate_mapper.dart';

part 'widgets/ar_controls.dart';

class ArTryOnScreen extends StatefulWidget {
  const ArTryOnScreen({required this.wearable, super.key});

  final Wearable wearable;

  @override
  State<ArTryOnScreen> createState() => _ArTryOnScreenState();
}

class _ArTryOnScreenState extends State<ArTryOnScreen> {
  /*
   * Потоковая модель быстрее accurate-варианта и предназначена для камеры.
   * Детектор живёт столько же, сколько экран, чтобы не загружать модель заново.
   */
  final PoseDetector _detector = PoseDetector(
    options: PoseDetectorOptions(
      model: PoseDetectionModel.base,
      mode: PoseDetectionMode.stream,
    ),
  );
  CameraController? _camera;
  Pose? _pose;
  Size? _imageSize;
  InputImageRotation _rotation = InputImageRotation.rotation0deg;
  bool _processing = false;
  bool _cameraOperationInProgress = false;
  bool _echoMode = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  /*
   * Открывает фронтальную камеру в формате, который ML Kit принимает без
   * дорогостоящей конвертации каждого кадра в Dart.
   */
  Future<void> _initializeCamera() async {
    try {
      final List<CameraDescription> cameras = await availableCameras();
      if (cameras.isEmpty) throw StateError('Камера не найдена');
      final CameraDescription selected = cameras.firstWhere(
        (CameraDescription camera) =>
            camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final CameraController controller = CameraController(
        selected,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      await controller.initialize();
      await controller.startImageStream(
        (CameraImage image) => _detectPose(image, selected),
      );
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _camera = controller);
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  /*
   * Передаёт в ML Kit не более одного кадра одновременно. Это ограничение
   * защищает очередь platform channel от накопления кадров и роста памяти.
   */
  Future<void> _detectPose(
    CameraImage image,
    CameraDescription description,
  ) async {
    if (_processing || image.planes.isEmpty) return;
    _processing = true;
    try {
      final InputImageRotation rotation =
          InputImageRotationValue.fromRawValue(description.sensorOrientation) ??
          InputImageRotation.rotation0deg;
      final InputImageFormat? format = InputImageFormatValue.fromRawValue(
        image.format.raw,
      );
      if (format == null) return;
      final Plane plane = image.planes.first;
      final InputImage input = InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
      final List<Pose> poses = await _detector.processImage(input);
      if (mounted) {
        setState(() {
          _pose = poses.firstOrNull;
          _imageSize = Size(image.width.toDouble(), image.height.toDouble());
          _rotation = rotation;
        });
      }
    } on Object catch (error) {
      if (mounted && _error == null) setState(() => _error = '$error');
    } finally {
      _processing = false;
    }
  }

  @override
  void dispose() {
    /* Нативные ресурсы камеры и ML-модели нельзя оставлять между экранами. */
    _camera?.dispose();
    _detector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CameraController? controller = _camera;
    final bool bodyFound = _pose != null;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const ColoredBox(color: AppColors.background),
          if (controller != null && controller.value.isInitialized)
            _FullScreenCamera(controller: controller)
          else
            const Center(child: CircularProgressIndicator()),
          if (_pose != null && _imageSize != null)
            Positioned.fill(
              child: CustomPaint(
                painter: _PoseGarmentPainter(
                  pose: _pose!,
                  imageSize: _imageSize!,
                  rotation: _rotation,
                  lensDirection:
                      controller?.description.lensDirection ??
                      CameraLensDirection.front,
                  kind: widget.wearable.kind,
                  seed: widget.wearable.seed,
                  palette: widget.wearable.palette,
                  echoMode: _echoMode,
                ),
              ),
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0x88000000),
                  Colors.transparent,
                  Color(0xB8000000),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      _RoundAction(
                        icon: Icons.close_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      _StatusChip(bodyFound: bodyFound),
                    ],
                  ),
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(top: 14),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withValues(alpha: .9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.background),
                      ),
                    ),
                  const Spacer(),
                  Text(
                    bodyFound
                        ? 'ДВИГАЙСЯ — ФОРМА СЛЕДУЕТ ЗА ТОБОЙ'
                        : 'ОТОЙДИ ТАК, ЧТОБЫ ПЛЕЧИ И БЁДРА БЫЛИ В КАДРЕ',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      _TryOnAction(
                        icon: Icons.cameraswitch_outlined,
                        label: 'КАМЕРА',
                        onTap: _switchCamera,
                      ),
                      GestureDetector(
                        onTap: _capturePhoto,
                        child: Container(
                          width: 78,
                          height: 78,
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              color: AppColors.background,
                            ),
                          ),
                        ),
                      ),
                      _TryOnAction(
                        icon: Icons.graphic_eq_rounded,
                        label: 'ЭХО',
                        active: _echoMode,
                        onTap: () => setState(() => _echoMode = !_echoMode),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /*
   * Камера не умеет фотографировать во время image stream, поэтому поток позы
   * временно останавливается и обязательно запускается снова после снимка.
   */
  Future<void> _capturePhoto() async {
    if (_cameraOperationInProgress) return;
    final CameraController? controller = _camera;
    if (controller == null || !controller.value.isInitialized) return;
    _cameraOperationInProgress = true;
    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
      final XFile file = await controller.takePicture();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Кадр сохранён локально: ${file.name}')),
        );
      }
      if (mounted && controller.value.isInitialized) {
        await controller.startImageStream(
          (CameraImage image) => _detectPose(image, controller.description),
        );
      }
    } on Object catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      _cameraOperationInProgress = false;
    }
  }

  /*
   * Переключает камеру последовательно: сначала освобождает старый поток,
   * затем создаёт новый контроллер. Параллельное открытие ломает Camera2.
   */
  Future<void> _switchCamera() async {
    if (_cameraOperationInProgress) return;
    _cameraOperationInProgress = true;
    try {
      final List<CameraDescription> cameras = await availableCameras();
      if (cameras.length < 2) return;
      final CameraLensDirection current =
          _camera?.description.lensDirection ?? CameraLensDirection.front;
      final CameraDescription next = cameras.firstWhere(
        (CameraDescription camera) => camera.lensDirection != current,
      );
      final CameraController? currentController = _camera;
      if (mounted) setState(() => _camera = null);
      if (currentController?.value.isStreamingImages ?? false) {
        await currentController?.stopImageStream();
      }
      await currentController?.dispose();
      final CameraController controller = CameraController(
        next,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      await controller.initialize();
      await controller.startImageStream(
        (CameraImage image) => _detectPose(image, next),
      );
      if (mounted) setState(() => _camera = controller);
    } on Object catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      _cameraOperationInProgress = false;
    }
  }
}

class _PoseGarmentPainter extends CustomPainter {
  _PoseGarmentPainter({
    required this.pose,
    required this.imageSize,
    required this.rotation,
    required this.lensDirection,
    required this.kind,
    required this.seed,
    required this.palette,
    required this.echoMode,
  });

  final Pose pose;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection lensDirection;
  final WearableKind kind;
  final int seed;
  final List<Color> palette;
  final bool echoMode;

  static const double _minimumLandmarkConfidence = .45;
  static const double _minimumShoulderWidth = 28;

  @override
  void paint(Canvas canvas, Size size) {
    if (kind == WearableKind.sneakers) {
      _paintSneakers(canvas, size);
      return;
    }
    final PoseLandmark? leftShoulder =
        pose.landmarks[PoseLandmarkType.leftShoulder];
    final PoseLandmark? rightShoulder =
        pose.landmarks[PoseLandmarkType.rightShoulder];
    final PoseLandmark? leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final PoseLandmark? rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    if (<PoseLandmark?>[leftShoulder, rightShoulder, leftHip, rightHip].any(
      (PoseLandmark? point) =>
          point == null || point.likelihood < _minimumLandmarkConfidence,
    )) {
      return;
    }
    final Offset ls = _translate(leftShoulder!, size);
    final Offset rs = _translate(rightShoulder!, size);
    final Offset lh = _translate(leftHip!, size);
    final Offset rh = _translate(rightHip!, size);
    final bool semanticLeftIsScreenLeft = ls.dx <= rs.dx;
    final Offset screenLeftShoulder = semanticLeftIsScreenLeft ? ls : rs;
    final Offset screenRightShoulder = semanticLeftIsScreenLeft ? rs : ls;
    final Offset screenLeftHip = lh.dx <= rh.dx ? lh : rh;
    final Offset screenRightHip = lh.dx <= rh.dx ? rh : lh;
    final PoseLandmark? leftElbowLandmark = semanticLeftIsScreenLeft
        ? pose.landmarks[PoseLandmarkType.leftElbow]
        : pose.landmarks[PoseLandmarkType.rightElbow];
    final PoseLandmark? rightElbowLandmark = semanticLeftIsScreenLeft
        ? pose.landmarks[PoseLandmarkType.rightElbow]
        : pose.landmarks[PoseLandmarkType.leftElbow];
    final Offset shoulderCenter =
        (screenLeftShoulder + screenRightShoulder) / 2;
    final Offset hipCenter = (screenLeftHip + screenRightHip) / 2;
    final Offset acrossVector = screenRightShoulder - screenLeftShoulder;
    final double shoulderWidth = acrossVector.distance;
    if (shoulderWidth < _minimumShoulderWidth) return;
    final Offset across = acrossVector / shoulderWidth;
    final Offset torsoVector = hipCenter - shoulderCenter;
    final Offset down = torsoVector.distance < 1
        ? Offset(-across.dy, across.dx)
        : torsoVector / torsoVector.distance;
    final double sleeveFactor = kind == WearableKind.hoodie ? .7 : .45;
    final Offset fallbackLeftElbow =
        screenLeftShoulder -
        across * shoulderWidth * .38 +
        down * shoulderWidth * .35;
    final Offset fallbackRightElbow =
        screenRightShoulder +
        across * shoulderWidth * .38 +
        down * shoulderWidth * .35;
    final Offset detectedLeftElbow = leftElbowLandmark == null
        ? fallbackLeftElbow
        : _translate(leftElbowLandmark, size);
    final Offset detectedRightElbow = rightElbowLandmark == null
        ? fallbackRightElbow
        : _translate(rightElbowLandmark, size);
    final Offset outerLeftShoulder =
        screenLeftShoulder - across * shoulderWidth * .1;
    final Offset outerRightShoulder =
        screenRightShoulder + across * shoulderWidth * .1;
    final Offset leftSleeve = Offset.lerp(
      outerLeftShoulder,
      detectedLeftElbow,
      sleeveFactor,
    )!;
    final Offset rightSleeve = Offset.lerp(
      outerRightShoulder,
      detectedRightElbow,
      sleeveFactor,
    )!;
    final double sleeveDepth =
        shoulderWidth * (kind == WearableKind.hoodie ? .2 : .14);
    final Offset neckLeft = shoulderCenter - across * shoulderWidth * .15;
    final Offset neckRight = shoulderCenter + across * shoulderWidth * .15;
    final Offset leftHem = screenLeftHip - across * shoulderWidth * .08;
    final Offset rightHem = screenRightHip + across * shoulderWidth * .08;
    final Path garment = Path()..moveTo(neckLeft.dx, neckLeft.dy);
    if (kind == WearableKind.hoodie) {
      garment.quadraticBezierTo(
        shoulderCenter.dx - down.dx * shoulderWidth * .34,
        shoulderCenter.dy - down.dy * shoulderWidth * .34,
        neckRight.dx,
        neckRight.dy,
      );
    } else {
      garment.quadraticBezierTo(
        shoulderCenter.dx + down.dx * shoulderWidth * .1,
        shoulderCenter.dy + down.dy * shoulderWidth * .1,
        neckRight.dx,
        neckRight.dy,
      );
    }
    garment
      ..lineTo(outerRightShoulder.dx, outerRightShoulder.dy)
      ..lineTo(rightSleeve.dx, rightSleeve.dy)
      ..lineTo(
        rightSleeve.dx + down.dx * sleeveDepth,
        rightSleeve.dy + down.dy * sleeveDepth,
      )
      ..quadraticBezierTo(
        screenRightShoulder.dx + down.dx * shoulderWidth * .42,
        screenRightShoulder.dy + down.dy * shoulderWidth * .42,
        rightHem.dx,
        rightHem.dy,
      );
    if (kind == WearableKind.dress) {
      final PoseLandmark? leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
      final PoseLandmark? rightKnee =
          pose.landmarks[PoseLandmarkType.rightKnee];
      final Offset kneeCenter = leftKnee != null && rightKnee != null
          ? (_translate(leftKnee, size) + _translate(rightKnee, size)) / 2
          : hipCenter + down * torsoVector.distance * .9;
      final Offset dressCenter = Offset.lerp(hipCenter, kneeCenter, .72)!;
      garment
        ..lineTo(
          dressCenter.dx + across.dx * shoulderWidth * .62,
          dressCenter.dy + across.dy * shoulderWidth * .62,
        )
        ..quadraticBezierTo(
          dressCenter.dx,
          dressCenter.dy + shoulderWidth * .08,
          dressCenter.dx - across.dx * shoulderWidth * .62,
          dressCenter.dy - across.dy * shoulderWidth * .62,
        )
        ..lineTo(leftHem.dx, leftHem.dy);
    } else {
      garment.quadraticBezierTo(
        hipCenter.dx,
        hipCenter.dy + shoulderWidth * .04,
        leftHem.dx,
        leftHem.dy,
      );
    }
    garment
      ..quadraticBezierTo(
        screenLeftShoulder.dx + down.dx * shoulderWidth * .42,
        screenLeftShoulder.dy + down.dy * shoulderWidth * .42,
        leftSleeve.dx + down.dx * sleeveDepth,
        leftSleeve.dy + down.dy * sleeveDepth,
      )
      ..lineTo(leftSleeve.dx, leftSleeve.dy)
      ..lineTo(outerLeftShoulder.dx, outerLeftShoulder.dy)
      ..close();
    _paintCrystalGarment(canvas, garment);
    _paintGarmentSeams(
      canvas: canvas,
      neckLeft: neckLeft,
      neckRight: neckRight,
      shoulderCenter: shoulderCenter,
      outerLeftShoulder: outerLeftShoulder,
      outerRightShoulder: outerRightShoulder,
      down: down,
      shoulderWidth: shoulderWidth,
    );
  }

  /*
   * Общий рендерер гарантирует, что в AR и в карточке вещи
   * используются одинаковые палитра, seed и алгоритм принта.
   */
  void _paintCrystalGarment(Canvas canvas, Path garment) {
    final Rect bounds = garment.getBounds();
    CrystalPatternRenderer(palette: palette, seed: seed).paint(
      canvas: canvas,
      clipPath: garment,
      bounds: bounds,
      opacity: echoMode ? .86 : .72,
    );
    canvas.drawPath(
      garment,
      Paint()
        ..color = palette.first.withValues(alpha: .9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  /*
   * Горловина и плечевые швы отделяют одежду от обычной
   * цветной маски, не перекрывая при этом кристаллический принт.
   */
  void _paintGarmentSeams({
    required Canvas canvas,
    required Offset neckLeft,
    required Offset neckRight,
    required Offset shoulderCenter,
    required Offset outerLeftShoulder,
    required Offset outerRightShoulder,
    required Offset down,
    required double shoulderWidth,
  }) {
    final Paint seamPaint = Paint()
      ..color = Colors.white.withValues(alpha: .5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final Path neckline = Path()..moveTo(neckLeft.dx, neckLeft.dy);
    final double curveDirection = kind == WearableKind.hoodie ? -.34 : .1;
    neckline.quadraticBezierTo(
      shoulderCenter.dx + down.dx * shoulderWidth * curveDirection,
      shoulderCenter.dy + down.dy * shoulderWidth * curveDirection,
      neckRight.dx,
      neckRight.dy,
    );
    canvas.drawPath(neckline, seamPaint);
    canvas.drawLine(
      outerLeftShoulder,
      outerLeftShoulder + down * shoulderWidth * .16,
      seamPaint,
    );
    canvas.drawLine(
      outerRightShoulder,
      outerRightShoulder + down * shoulderWidth * .16,
      seamPaint,
    );
  }

  /* Для кед используются точки пятки, носка и лодыжки вместо торса. */
  void _paintSneakers(Canvas canvas, Size size) {
    final List<(PoseLandmarkType, PoseLandmarkType, PoseLandmarkType)> feet =
        <(PoseLandmarkType, PoseLandmarkType, PoseLandmarkType)>[
          (
            PoseLandmarkType.leftAnkle,
            PoseLandmarkType.leftHeel,
            PoseLandmarkType.leftFootIndex,
          ),
          (
            PoseLandmarkType.rightAnkle,
            PoseLandmarkType.rightHeel,
            PoseLandmarkType.rightFootIndex,
          ),
        ];
    for (final (
          PoseLandmarkType ankleType,
          PoseLandmarkType heelType,
          PoseLandmarkType toeType,
        )
        in feet) {
      final PoseLandmark? ankle = pose.landmarks[ankleType];
      final PoseLandmark? heel = pose.landmarks[heelType];
      final PoseLandmark? toe = pose.landmarks[toeType];
      if (ankle == null || heel == null || toe == null) continue;
      final Offset a = _translate(ankle, size);
      final Offset h = _translate(heel, size);
      final Offset t = _translate(toe, size);
      final Offset direction = t - h;
      final double width = math.max(18, direction.distance * .32);
      final Offset normal =
          Offset(-direction.dy, direction.dx) / math.max(direction.distance, 1);
      final Path shoe = Path()
        ..moveTo(a.dx + normal.dx * width, a.dy + normal.dy * width)
        ..lineTo(t.dx + normal.dx * width, t.dy + normal.dy * width)
        ..quadraticBezierTo(
          t.dx,
          t.dy,
          t.dx - normal.dx * width,
          t.dy - normal.dy * width,
        )
        ..lineTo(h.dx - normal.dx * width, h.dy - normal.dy * width)
        ..quadraticBezierTo(
          a.dx,
          a.dy,
          a.dx + normal.dx * width,
          a.dy + normal.dy * width,
        )
        ..close();
      _paintCrystalGarment(canvas, shoe);
    }
  }

  /*
   * Переводит координаты ML Kit в систему полноэкранного CameraPreview.
   * Масштаб BoxFit.cover учитывает обрезку кадра, а фронтальная камера — зеркало.
   */
  Offset _translate(PoseLandmark point, Size canvasSize) {
    return PoseCoordinateMapper.toPreview(
      landmark: point,
      imageSize: imageSize,
      canvasSize: canvasSize,
      rotation: rotation,
      lensDirection: lensDirection,
    );
  }

  @override
  bool shouldRepaint(covariant _PoseGarmentPainter oldDelegate) =>
      oldDelegate.pose != pose ||
      oldDelegate.echoMode != echoMode ||
      oldDelegate.kind != kind ||
      oldDelegate.lensDirection != lensDirection;
}
