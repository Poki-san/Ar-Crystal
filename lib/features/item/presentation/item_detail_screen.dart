import 'package:flutter/material.dart';

import '../../../core/models/wearable.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/crystal_art.dart';
import '../../ar_preview/presentation/ar_try_on_screen.dart';

class ItemDetailScreen extends StatefulWidget {
  const ItemDetailScreen({
    required this.wearable,
    this.isNew = false,
    super.key,
  });

  final Wearable wearable;
  final bool isNew;

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  bool _liked = false;

  void _openTryOn() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ArTryOnScreen(wearable: widget.wearable),
      ),
    );
  }

  void _showMintInfo() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(Icons.hexagon_rounded, color: AppColors.acid, size: 32),
            const SizedBox(height: 16),
            Text(
              'ГОТОВО К ЧЕКАНКЕ',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 11),
            const Text(
              'В демо-версии транзакция не отправляется. После подключения Polygon и IPFS здесь появятся комиссия сети и подтверждение кошелька.',
            ),
            const SizedBox(height: 20),
            EchoButton(
              label: 'ПОНЯТНО',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Wearable item = widget.wearable;
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            expandedHeight: MediaQuery.sizeOf(context).height * .58,
            pinned: true,
            backgroundColor: AppColors.background,
            leading: _CircleAction(
              icon: Icons.arrow_back_rounded,
              onTap: () => Navigator.pop(context),
            ),
            actions: <Widget>[
              _CircleAction(
                icon: _liked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: _liked ? AppColors.orange : null,
                onTap: () => setState(() => _liked = !_liked),
              ),
              const SizedBox(width: 8),
              _CircleAction(
                icon: Icons.ios_share_rounded,
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ссылка на объект скопирована')),
                ),
              ),
              const SizedBox(width: 12),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  CrystalArt(wearable: item, showGrid: true),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Colors.transparent,
                          Colors.transparent,
                          AppColors.background,
                        ],
                        stops: <double>[0, .72, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    bottom: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.acid,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        widget.isNew
                            ? 'ТОЛЬКО ЧТО СОЗДАНО'
                            : 'ЕДИНСТВЕННЫЙ ЭКЗЕМПЛЯР',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.background,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 46),
            sliver: SliverList.list(
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '#${item.id}  /  ${_kindName(item.kind)}',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: AppColors.acid,
                                  letterSpacing: 1.4,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.name,
                            style: Theme.of(context).textTheme.displayLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'CREATED BY ${item.creator}',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    if (item.price > 0)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Text(
                            item.price.toStringAsFixed(0),
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          const Text('USDC'),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: EchoButton(
                        label: 'ПРИМЕРИТЬ В AR',
                        icon: Icons.view_in_ar_rounded,
                        onPressed: _openTryOn,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 56,
                      height: 54,
                      child: IconButton.filled(
                        onPressed: _showMintInfo,
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surfaceSoft,
                          side: const BorderSide(color: AppColors.line),
                        ),
                        icon: Icon(
                          item.price > 0
                              ? Icons.shopping_bag_outlined
                              : Icons.hexagon_outlined,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Text(
                  'ОТПЕЧАТОК',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _InfoCard(
                        icon: Icons.texture_rounded,
                        label: 'ТЕКСТУРА',
                        value: 'ОРГАНИКА',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InfoCard(
                        icon: Icons.graphic_eq_rounded,
                        label: 'ЗВУК',
                        value: '3.0 СЕК',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InfoCard(
                        icon: Icons.auto_awesome_rounded,
                        label: 'SEED',
                        value: '${item.seed}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                Row(
                  children: <Widget>[
                    Text(
                      'ПАЛИТРА',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const Spacer(),
                    ...item.palette.map(
                      (Color color) => Container(
                        width: 30,
                        height: 30,
                        margin: const EdgeInsets.only(left: 7),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                          border: Border.all(color: Colors.white24),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(Icons.shield_outlined, color: AppColors.acid),
                      SizedBox(width: 13),
                      Expanded(
                        child: Text(
                          'Оригинальная текстура и звук обработаны локально. В объекте хранится только генеративный отпечаток.',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _kindName(WearableKind kind) => switch (kind) {
    WearableKind.tshirt => 'ФУТБОЛКА',
    WearableKind.hoodie => 'ХУДИ',
    WearableKind.dress => 'ПЛАТЬЕ',
    WearableKind.sneakers => 'КЕДЫ',
  };
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({required this.icon, required this.onTap, this.color});
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(5),
    child: IconButton.filled(
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.background.withValues(alpha: .68),
        side: const BorderSide(color: Colors.white24),
      ),
      icon: Icon(icon, color: color),
    ),
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 20, color: AppColors.acid),
        const SizedBox(height: 13),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: AppColors.muted, fontSize: 9),
        ),
        const SizedBox(height: 3),
        Text(value, style: Theme.of(context).textTheme.labelLarge),
      ],
    ),
  );
}
