part of '../create_screen.dart';

/* Экран выбора формы использует уже рассчитанные палитру и seed захвата. */
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
  Widget build(BuildContext context) => Padding(
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
        Text('ВЫБЕРИ\nСИЛУЭТ', style: Theme.of(context).textTheme.displayLarge),
        const SizedBox(height: 12),
        const Text(
          'Текстура и звуковой рельеф уже готовы. Теперь выбери, во что превратится этот отпечаток.',
        ),
        const SizedBox(height: 22),
        Expanded(
          child: _SilhouetteGrid(
            selected: selected,
            palette: palette,
            seed: seed,
            onSelected: onSelected,
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

class _SilhouetteGrid extends StatelessWidget {
  const _SilhouetteGrid({
    required this.selected,
    required this.palette,
    required this.seed,
    required this.onSelected,
  });

  final WearableKind selected;
  final List<Color> palette;
  final int seed;
  final ValueChanged<WearableKind> onSelected;

  @override
  Widget build(BuildContext context) => GridView.builder(
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
    ),
    itemCount: WearableKind.values.length,
    itemBuilder: (BuildContext context, int index) {
      final WearableKind kind = WearableKind.values[index];
      return _SilhouetteTile(
        kind: kind,
        active: kind == selected,
        wearable: Wearable(
          id: '',
          name: kind.label,
          kind: kind,
          palette: palette,
          seed: seed,
          price: 0,
          creator: '',
          likes: 0,
        ),
        onTap: () => onSelected(kind),
      );
    },
  );
}

class _SilhouetteTile extends StatelessWidget {
  const _SilhouetteTile({
    required this.kind,
    required this.active,
    required this.wearable,
    required this.onTap,
  });
  final WearableKind kind;
  final bool active;
  final Wearable wearable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
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
          Positioned.fill(child: CrystalArt(wearable: wearable)),
          Positioned(
            top: 11,
            right: 11,
            child: Icon(
              active ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: active ? AppColors.acid : Colors.white54,
            ),
          ),
          Positioned(
            left: 12,
            bottom: 11,
            child: Text(
              kind.label,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ],
      ),
    ),
  );
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
