import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../core/models/wearable.dart';
import '../../../core/storage/wearable_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/crystal_art.dart';
import '../../item/presentation/item_detail_screen.dart';
import '../data/capture_service.dart';

enum CaptureStage { ready, recording, choose, crystallizing }

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen>
    with SingleTickerProviderStateMixin {
  CaptureStage _stage = CaptureStage.ready;
  WearableKind _kind = WearableKind.tshirt;
  late final AnimationController _controller;
  final CaptureService _captureService = CaptureService();
  final WearableRepository _repository = WearableRepository();
  CameraController? _camera;
  CaptureResult? _captureResult;
  String? _cameraError;

  static const Wearable _draft = Wearable(
    id: 'NEW',
    name: 'RAW ECHO',
    kind: WearableKind.tshirt,
    palette: <Color>[Color(0xFFD8FF63), Color(0xFF306859), Color(0xFFFF6B3D)],
    seed: 91,
    price: 0,
    creator: 'YOU',
    likes: 0,
    isOwned: true,
  );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    unawaited(_initializeCamera());
  }

  Future<void> _initializeCamera() async {
    try {
      final List<CameraDescription> cameras = await availableCameras();
      if (cameras.isEmpty) throw StateError('Камера не найдена');
      final CameraDescription selected = cameras.firstWhere(
        (CameraDescription camera) =>
            camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final CameraController controller = CameraController(
        selected,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _camera = controller);
    } on Object catch (error) {
      if (mounted) setState(() => _cameraError = error.toString());
    }
  }

  @override
  void dispose() {
    _camera?.dispose();
    _captureService.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    final CameraController? camera = _camera;
    if (camera == null || !camera.value.isInitialized) {
      setState(() => _cameraError = 'Камера ещё не готова');
      return;
    }
    setState(() => _stage = CaptureStage.recording);
    try {
      final CaptureResult result = await _captureService.capture(camera);
      if (mounted) {
        setState(() {
          _captureResult = result;
          _stage = CaptureStage.choose;
        });
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _stage = CaptureStage.ready;
          _cameraError = 'Не удалось выполнить захват: $error';
        });
      }
    }
  }

  void _generate() {
    setState(() => _stage = CaptureStage.crystallizing);
    _controller.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      final CaptureResult? capture = _captureResult;
      final Wearable result = Wearable(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'RAW ECHO',
        kind: _kind,
        palette: capture?.palette ?? _draft.palette,
        seed: capture?.seed ?? _draft.seed,
        price: 0,
        creator: 'YOU',
        likes: 0,
        isOwned: true,
        imagePath: capture?.imagePath,
        audioPath: capture?.audioPath,
        createdAt: DateTime.now(),
      );
      _repository.save(result).then((_) {
        if (!mounted) return;
        Navigator.of(context)
            .push(
              MaterialPageRoute<void>(
                builder: (_) => ItemDetailScreen(wearable: result, isNew: true),
              ),
            )
            .then((_) {
              if (mounted) setState(() => _stage = CaptureStage.ready);
            });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: switch (_stage) {
          CaptureStage.ready || CaptureStage.recording => _ScannerView(
            stage: _stage,
            onCapture: _capture,
            camera: _camera,
            error: _cameraError,
          ),
          CaptureStage.choose => _ChooseView(
            selected: _kind,
            palette: _captureResult?.palette ?? _draft.palette,
            seed: _captureResult?.seed ?? _draft.seed,
            onSelected: (WearableKind value) => setState(() => _kind = value),
            onGenerate: _generate,
          ),
          CaptureStage.crystallizing => _CrystalizingView(
            controller: _controller,
            wearable: Wearable(
              id: _draft.id,
              name: _draft.name,
              kind: _kind,
              palette: _captureResult?.palette ?? _draft.palette,
              seed: _captureResult?.seed ?? _draft.seed,
              price: 0,
              creator: 'YOU',
              likes: 0,
            ),
          ),
        },
      ),
    );
  }
}

class _ScannerView extends StatelessWidget {
  const _ScannerView({
    required this.stage,
    required this.onCapture,
    required this.camera,
    required this.error,
  });
  final CaptureStage stage;
  final VoidCallback onCapture;
  final CameraController? camera;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final bool recording = stage == CaptureStage.recording;
    return Stack(
      key: const ValueKey<String>('scanner'),
      fit: StackFit.expand,
      children: <Widget>[
        _CameraTexture(camera: camera),
        Positioned.fill(child: CustomPaint(painter: _ScannerOverlayPainter())),
        Positioned(
          top: 20,
          left: 20,
          right: 20,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'НОВЫЙ ОТГОЛОСОК',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.acid,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      recording ? 'НЕ ДВИГАЙСЯ' : 'НАЙДИ ФАКТУРУ',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
              _RoundIcon(icon: Icons.flash_off_rounded),
              const SizedBox(width: 9),
              _RoundIcon(icon: Icons.help_outline_rounded),
            ],
          ),
        ),
        if (error != null)
          Positioned(
            left: 24,
            right: 24,
            top: 90,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: .9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.background),
              ),
            ),
          ),
        Positioned(
          left: 34,
          right: 34,
          bottom: 105,
          child: Column(
            children: <Widget>[
              if (recording)
                const _SoundMeter()
              else
                Text(
                  'НАВЕДИ КАМЕРУ НА ДЕРЕВО, КАМЕНЬ ИЛИ ТКАНЬ',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: Colors.white70),
                ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: recording ? null : onCapture,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 84,
                  height: 84,
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: recording ? AppColors.orange : Colors.white,
                      width: 2,
                    ),
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: recording ? AppColors.orange : AppColors.acid,
                    ),
                    child: Icon(
                      recording ? Icons.mic_rounded : Icons.camera_alt_rounded,
                      color: AppColors.background,
                      size: 29,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                recording ? 'ЗВУК  •  3 СЕК' : 'ЗАХВАТИТЬ',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CameraTexture extends StatelessWidget {
  const _CameraTexture({required this.camera});
  final CameraController? camera;

  @override
  Widget build(BuildContext context) {
    final CameraController? controller = camera;
    if (controller != null && controller.value.isInitialized) {
      return Center(
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.value.previewSize?.height ?? 1,
              height: controller.value.previewSize?.width ?? 1,
              child: CameraPreview(controller),
            ),
          ),
        ),
      );
    }
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF354F43),
            Color(0xFF182620),
            Color(0xFF6E3D29),
            Color(0xFF111313),
          ],
          stops: <double>[0, .34, .7, 1],
        ),
      ),
      child: CustomPaint(painter: _OrganicTexturePainter()),
    );
  }
}

class _OrganicTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    for (int i = 0; i < 14; i++) {
      paint.color = (i.isEven ? AppColors.acid : AppColors.orange).withValues(
        alpha: .05 + (i % 4) * .018,
      );
      final Path p = Path()..moveTo(-20, size.height * (i / 14));
      for (double x = 0; x <= size.width + 40; x += 34) {
        p.quadraticBezierTo(
          x + 17,
          size.height * (i / 14) + (i.isEven ? 22 : -20),
          x + 34,
          size.height * (i / 14),
        );
      }
      canvas.drawPath(p, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint line = Paint()
      ..color = Colors.white.withValues(alpha: .16)
      ..strokeWidth = .8;
    for (int i = 1; i < 4; i++) {
      canvas.drawLine(
        Offset(size.width * i / 4, 110),
        Offset(size.width * i / 4, size.height - 230),
        line,
      );
      canvas.drawLine(
        Offset(20, 110 + (size.height - 340) * i / 4),
        Offset(size.width - 20, 110 + (size.height - 340) * i / 4),
        line,
      );
    }
    final Paint corners = Paint()
      ..color = AppColors.acid
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final Rect rect = Rect.fromLTRB(
      20,
      110,
      size.width - 20,
      size.height - 230,
    );
    const double l = 28;
    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.top + l)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.left + l, rect.top),
      corners,
    );
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - l, rect.bottom)
        ..lineTo(rect.right, rect.bottom)
        ..lineTo(rect.right, rect.bottom - l),
      corners,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      color: AppColors.background.withValues(alpha: .5),
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white24),
    ),
    child: Icon(icon, size: 19),
  );
}

class _SoundMeter extends StatelessWidget {
  const _SoundMeter();
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List<Widget>.generate(
      18,
      (int i) => Container(
        width: 3,
        height: 8 + ((i * 13) % 25).toDouble(),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: i < 13 ? AppColors.orange : Colors.white38,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    ),
  );
}

class _ChooseView extends StatelessWidget {
  const _ChooseView({
    required this.selected,
    required this.palette,
    required this.seed,
    required this.onSelected,
    required this.onGenerate,
  });
  final WearableKind selected;
  final List<Color> palette;
  final int seed;
  final ValueChanged<WearableKind> onSelected;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    const List<(WearableKind, String)> options = <(WearableKind, String)>[
      (WearableKind.tshirt, 'ФУТБОЛКА'),
      (WearableKind.hoodie, 'ХУДИ'),
      (WearableKind.dress, 'ПЛАТЬЕ'),
      (WearableKind.sneakers, 'КЕДЫ'),
    ];
    return Padding(
      key: const ValueKey<String>('choose'),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '02 / ФОРМА',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.acid,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'ВЫБЕРИ\nСИЛУЭТ',
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: 12),
          const Text(
            'Текстура и звуковой рельеф уже готовы. Теперь выбери, во что превратится этот отпечаток.',
          ),
          const SizedBox(height: 22),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: options.length,
              itemBuilder: (BuildContext context, int index) {
                final (WearableKind kind, String label) = options[index];
                final bool active = kind == selected;
                final Wearable preview = Wearable(
                  id: '',
                  name: label,
                  kind: kind,
                  palette: palette,
                  seed: seed,
                  price: 0,
                  creator: '',
                  likes: 0,
                );
                return GestureDetector(
                  onTap: () => onSelected(kind),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active ? AppColors.acid : AppColors.line,
                        width: active ? 2 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: <Widget>[
                        Positioned.fill(child: CrystalArt(wearable: preview)),
                        Positioned(
                          top: 11,
                          right: 11,
                          child: Icon(
                            active
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            color: active ? AppColors.acid : Colors.white54,
                          ),
                        ),
                        Positioned(
                          left: 12,
                          bottom: 11,
                          child: Text(
                            label,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          EchoButton(
            label: 'ЗАПУСТИТЬ КРИСТАЛЛИЗАЦИЮ',
            icon: Icons.auto_awesome_rounded,
            onPressed: onGenerate,
          ),
        ],
      ),
    );
  }
}

class _CrystalizingView extends StatelessWidget {
  const _CrystalizingView({required this.controller, required this.wearable});
  final AnimationController controller;
  final Wearable wearable;

  String _status(double value) {
    if (value < .25) return 'ПРОЯВЛЯЕМ СЕМЕНА';
    if (value < .67) return 'РАСТИМ ПОЛИГОНЫ';
    if (value < .88) return 'НАКЛАДЫВАЕМ ЗВУК';
    return 'ЗАКАЛЯЕМ ФОРМУ';
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    key: const ValueKey<String>('crystal'),
    animation: controller,
    builder: (BuildContext context, Widget? child) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                '03 / ГЕНЕРАЦИЯ',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.acid,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              Text('${(controller.value * 100).round()}%'),
            ],
          ),
          const SizedBox(height: 34),
          Expanded(
            child: Opacity(
              opacity: .2 + controller.value * .8,
              child: Transform.scale(
                scale: .72 + controller.value * .28,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: CrystalArt(wearable: wearable, showGrid: true),
                ),
              ),
            ),
          ),
          const SizedBox(height: 26),
          Text(
            _status(controller.value),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 14),
          LinearProgressIndicator(
            value: controller.value,
            minHeight: 3,
            color: AppColors.acid,
            backgroundColor: AppColors.line,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 10),
          Text(
            'ТВОЙ ЗВУК ФОРМИРУЕТ РЕЛЬЕФ',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    ),
  );
}
