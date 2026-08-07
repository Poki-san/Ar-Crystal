import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../../../core/models/wearable.dart';
import '../../../core/theme/app_theme.dart';

class ArTryOnScreen extends StatefulWidget {
  const ArTryOnScreen({required this.wearable, super.key});

  final Wearable wearable;

  @override
  State<ArTryOnScreen> createState() => _ArTryOnScreenState();
}

class _ArTryOnScreenState extends State<ArTryOnScreen> {
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
  bool _echoMode = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
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
        (CameraImage image) => _processFrame(image, selected),
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

  Future<void> _processFrame(
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

  Future<void> _capturePhoto() async {
    final CameraController? controller = _camera;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      await controller.stopImageStream();
      final XFile file = await controller.takePicture();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Кадр сохранён локально: ${file.name}')),
        );
      }
      await controller.startImageStream(
        (CameraImage image) => _processFrame(image, controller.description),
      );
    } on Object catch (error) {
      if (mounted) setState(() => _error = '$error');
    }
  }

  Future<void> _switchCamera() async {
    final List<CameraDescription> cameras = await availableCameras();
    if (cameras.length < 2) return;
    final CameraLensDirection current =
        _camera?.description.lensDirection ?? CameraLensDirection.front;
    final CameraDescription next = cameras.firstWhere(
      (CameraDescription camera) => camera.lensDirection != current,
    );
    await _camera?.dispose();
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
      (CameraImage image) => _processFrame(image, next),
    );
    if (mounted) setState(() => _camera = controller);
  }
}

class _FullScreenCamera extends StatelessWidget {
  const _FullScreenCamera({required this.controller});
  final CameraController controller;

  @override
  Widget build(BuildContext context) => SizedBox.expand(
    child: FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: controller.value.previewSize?.height ?? 1,
        height: controller.value.previewSize?.width ?? 1,
        child: CameraPreview(controller),
      ),
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.bodyFound});
  final bool bodyFound;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.background.withValues(alpha: .65),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: Colors.white24),
    ),
    child: Row(
      children: <Widget>[
        Icon(
          Icons.circle,
          size: 8,
          color: bodyFound ? AppColors.acid : AppColors.orange,
        ),
        const SizedBox(width: 7),
        Text(
          bodyFound ? 'ТЕЛО НАЙДЕНО' : 'ИЩЕМ ТЕЛО',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _PoseGarmentPainter extends CustomPainter {
  _PoseGarmentPainter({
    required this.pose,
    required this.imageSize,
    required this.rotation,
    required this.palette,
    required this.echoMode,
  });

  final Pose pose;
  final Size imageSize;
  final InputImageRotation rotation;
  final List<Color> palette;
  final bool echoMode;

  @override
  void paint(Canvas canvas, Size size) {
    final PoseLandmark? leftShoulder =
        pose.landmarks[PoseLandmarkType.leftShoulder];
    final PoseLandmark? rightShoulder =
        pose.landmarks[PoseLandmarkType.rightShoulder];
    final PoseLandmark? leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final PoseLandmark? rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    if (<PoseLandmark?>[
      leftShoulder,
      rightShoulder,
      leftHip,
      rightHip,
    ].any((PoseLandmark? point) => point == null || point.likelihood < .45)) {
      return;
    }
    final Offset ls = _translate(leftShoulder!, size);
    final Offset rs = _translate(rightShoulder!, size);
    final Offset lh = _translate(leftHip!, size);
    final Offset rh = _translate(rightHip!, size);
    final Offset shoulderVector = rs - ls;
    final double sleeve = shoulderVector.distance * .18;
    final Offset normal =
        Offset(-shoulderVector.dy, shoulderVector.dx) /
        math.max(shoulderVector.distance, 1);
    final Path garment = Path()
      ..moveTo(ls.dx - shoulderVector.dx * .12, ls.dy - shoulderVector.dy * .12)
      ..lineTo(
        ls.dx - shoulderVector.dx * .2 - normal.dx * sleeve,
        ls.dy - shoulderVector.dy * .2 - normal.dy * sleeve,
      )
      ..lineTo(lh.dx - shoulderVector.dx * .12, lh.dy - shoulderVector.dy * .12)
      ..quadraticBezierTo(
        (lh.dx + rh.dx) / 2,
        (lh.dy + rh.dy) / 2 + sleeve * .25,
        rh.dx + shoulderVector.dx * .12,
        rh.dy + shoulderVector.dy * .12,
      )
      ..lineTo(
        rs.dx + shoulderVector.dx * .2 - normal.dx * sleeve,
        rs.dy + shoulderVector.dy * .2 - normal.dy * sleeve,
      )
      ..lineTo(rs.dx + shoulderVector.dx * .12, rs.dy + shoulderVector.dy * .12)
      ..quadraticBezierTo(
        (ls.dx + rs.dx) / 2,
        (ls.dy + rs.dy) / 2 + sleeve * .3,
        ls.dx - shoulderVector.dx * .12,
        ls.dy - shoulderVector.dy * .12,
      )
      ..close();
    final Rect bounds = garment.getBounds();
    canvas.drawPath(
      garment,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette,
        ).createShader(bounds),
    );
    canvas.save();
    canvas.clipPath(garment);
    final Paint shard = Paint()
      ..color = Colors.white.withValues(alpha: echoMode ? .32 : .18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final double step = math.max(22, bounds.width / 7);
    for (double x = bounds.left - bounds.height; x < bounds.right; x += step) {
      canvas.drawLine(
        Offset(x, bounds.bottom),
        Offset(x + bounds.height, bounds.top),
        shard,
      );
    }
    canvas.restore();
    canvas.drawPath(
      garment,
      Paint()
        ..color = palette.first.withValues(alpha: .9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  Offset _translate(PoseLandmark point, Size canvasSize) {
    double sourceWidth = imageSize.width;
    double sourceHeight = imageSize.height;
    double x = point.x;
    double y = point.y;
    if (rotation == InputImageRotation.rotation90deg) {
      final double oldX = x;
      x = imageSize.height - y;
      y = oldX;
      sourceWidth = imageSize.height;
      sourceHeight = imageSize.width;
    } else if (rotation == InputImageRotation.rotation270deg) {
      final double oldX = x;
      x = y;
      y = imageSize.width - oldX;
      sourceWidth = imageSize.height;
      sourceHeight = imageSize.width;
    } else if (rotation == InputImageRotation.rotation180deg) {
      x = imageSize.width - x;
      y = imageSize.height - y;
    }
    final double scale = math.max(
      canvasSize.width / sourceWidth,
      canvasSize.height / sourceHeight,
    );
    final double offsetX = (canvasSize.width - sourceWidth * scale) / 2;
    final double offsetY = (canvasSize.height - sourceHeight * scale) / 2;
    return Offset(
      canvasSize.width - (x * scale + offsetX),
      y * scale + offsetY,
    );
  }

  @override
  bool shouldRepaint(covariant _PoseGarmentPainter oldDelegate) =>
      oldDelegate.pose != pose || oldDelegate.echoMode != echoMode;
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton.filled(
    onPressed: onTap,
    style: IconButton.styleFrom(
      backgroundColor: AppColors.background.withValues(alpha: .68),
      side: const BorderSide(color: Colors.white24),
    ),
    icon: Icon(icon),
  );
}

class _TryOnAction extends StatelessWidget {
  const _TryOnAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(
      children: <Widget>[
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? AppColors.acid
                : AppColors.background.withValues(alpha: .65),
            border: Border.all(color: active ? AppColors.acid : Colors.white24),
          ),
          child: Icon(
            icon,
            color: active ? AppColors.background : Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 9),
        ),
      ],
    ),
  );
}
