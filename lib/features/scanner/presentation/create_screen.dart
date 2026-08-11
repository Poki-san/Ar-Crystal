import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../crystallizer/domain/entities/wearable.dart';
import '../../crystallizer/presentation/widgets/crystal_art.dart';
import '../../gallery/data/wearable_repository.dart';
import '../../item/presentation/item_detail_screen.dart';
import '../data/capture_service.dart';
import '../domain/entities/capture_result.dart';
import '../domain/entities/capture_stage.dart';

part 'painters/scanner_painters.dart';
part 'widgets/generation_views.dart';

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
  bool _isCapturing = false;

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

  List<Color> get _currentPalette => _captureResult?.palette ?? _draft.palette;

  int get _currentSeed => _captureResult?.seed ?? _draft.seed;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    unawaited(_initializeCamera());
  }

  /*
   * Инициализирует только заднюю камеру и только пока открыта вкладка создания.
   * Среднее разрешение снижает расход памяти на складных и бюджетных устройствах.
   */
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
        ResolutionPreset.medium,
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

  /*
   * Блокирует повторные нажатия до окончания фото и трёхсекундной записи.
   * Ошибка возвращает пользователя в готовое состояние без потери интерфейса.
   */
  Future<void> _capture() async {
    if (_isCapturing) return;
    final CameraController? camera = _camera;
    if (camera == null ||
        !camera.value.isInitialized ||
        camera.value.isTakingPicture) {
      setState(() => _cameraError = 'Камера ещё не готова');
      return;
    }
    _isCapturing = true;
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
    } finally {
      _isCapturing = false;
    }
  }

  /*
   * Создаёт локальный объект после анимации и только затем открывает карточку.
   * Репозиторий сохраняет результат до перехода, поэтому черновик не потеряется.
   */
  Future<void> _generate() async {
    setState(() => _stage = CaptureStage.crystallizing);
    try {
      await _controller.forward(from: 0);
      if (!mounted) return;
      final Wearable result = _createWearableFromCapture();
      await _repository.save(result);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ItemDetailScreen(wearable: result, isNew: true),
        ),
      );
      if (mounted) setState(() => _stage = CaptureStage.ready);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _stage = CaptureStage.ready;
        _cameraError = 'Не удалось сохранить предмет: $error';
      });
    }
  }

  /* Собирает доменную модель отдельно от навигации и анимации экрана. */
  Wearable _createWearableFromCapture() {
    final CaptureResult? capture = _captureResult;
    return Wearable(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'RAW ECHO',
      kind: _kind,
      palette: _currentPalette,
      seed: _currentSeed,
      price: 0,
      creator: 'YOU',
      likes: 0,
      isOwned: true,
      imagePath: capture?.imagePath,
      audioPath: capture?.audioPath,
      createdAt: DateTime.now(),
    );
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
            palette: _currentPalette,
            seed: _currentSeed,
            onSelected: (WearableKind value) => setState(() => _kind = value),
            onGenerate: _generate,
          ),
          CaptureStage.crystallizing => _CrystalizingView(
            controller: _controller,
            wearable: Wearable(
              id: _draft.id,
              name: _draft.name,
              kind: _kind,
              palette: _currentPalette,
              seed: _currentSeed,
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
