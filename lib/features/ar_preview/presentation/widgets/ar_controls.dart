part of '../ar_try_on_screen.dart';

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
      mainAxisSize: MainAxisSize.min,
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
