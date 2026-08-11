import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../crystallizer/domain/entities/wearable.dart';
import '../../crystallizer/presentation/widgets/crystal_art.dart';
import '../../item/presentation/item_detail_screen.dart';
import '../data/wearable_repository.dart';

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  static final WearableRepository _repository = WearableRepository();

  @override
  Widget build(BuildContext context) {
    /* revision перестраивает экран сразу после локального сохранения предмета. */
    return AnimatedBuilder(
      animation: WearableRepository.revision,
      builder: (BuildContext context, Widget? child) =>
          FutureBuilder<List<Wearable>>(
            future: _repository.loadCollection(),
            builder:
                (BuildContext context, AsyncSnapshot<List<Wearable>> snapshot) {
                  final List<Wearable> items =
                      snapshot.data ?? DemoWearables.owned;
                  return _buildCollection(items);
                },
          ),
    );
  }

  Widget _buildCollection(List<Wearable> items) {
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            sliver: SliverToBoxAdapter(
              child: _GalleryHeader(count: items.length),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
            sliver: SliverToBoxAdapter(
              child: _FeaturedCard(wearable: items.first),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 12),
            sliver: SliverToBoxAdapter(child: _SectionTitle()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: .72,
              ),
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) =>
                    _WearableCard(wearable: items[index]),
                childCount: items.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GalleryHeader extends StatelessWidget {
  const _GalleryHeader({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'ECHO / WEAR',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.acid,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                'ТВОИ\nОТГОЛОСКИ',
                style: Theme.of(context).textTheme.displayLarge,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            '$count ОБЪЕКТА',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
      ],
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.wearable});
  final Wearable wearable;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ItemDetailScreen(wearable: wearable),
        ),
      ),
      child: Container(
        height: 390,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            CrystalArt(wearable: wearable),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Colors.transparent,
                    Color(0x16000000),
                    Color(0xE8080A0B),
                  ],
                  stops: <double>[0, .55, 1],
                ),
              ),
            ),
            Positioned(
              top: 18,
              left: 18,
              child: _Tag(label: 'НОВЫЙ / 06.08.26'),
            ),
            Positioned(
              top: 18,
              right: 18,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: .55),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(Icons.arrow_outward_rounded),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          wearable.name,
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ДЕРЕВО × ГОРОДСКОЙ ШУМ',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.favorite_rounded,
                    size: 17,
                    color: AppColors.orange,
                  ),
                  const SizedBox(width: 6),
                  Text('${wearable.likes}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle();
  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: Text(
          'КОЛЛЕКЦИЯ',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      const Icon(Icons.tune_rounded, color: AppColors.muted),
    ],
  );
}

class _WearableCard extends StatelessWidget {
  const _WearableCard({required this.wearable});
  final Wearable wearable;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ItemDetailScreen(wearable: wearable),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: CrystalArt(wearable: wearable),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '#${wearable.id}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: wearable.palette.first,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    wearable.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.background.withValues(alpha: .62),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: Colors.white24),
    ),
    child: Text(label, style: Theme.of(context).textTheme.labelLarge),
  );
}
