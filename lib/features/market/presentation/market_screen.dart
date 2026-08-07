import 'package:flutter/material.dart';

import '../../../core/models/wearable.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/crystal_art.dart';
import '../../item/presentation/item_detail_screen.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  int _filter = 0;
  static const List<String> _filters = <String>['В ТРЕНДЕ', 'НОВЫЕ', 'ДО 50'];

  @override
  Widget build(BuildContext context) {
    final List<Wearable> items = DemoWearables.market
        .where((Wearable item) => _filter != 2 || item.price <= 50)
        .toList();
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        'ECHO MARKET',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.acid,
                          letterSpacing: 2,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.search_rounded),
                      const SizedBox(width: 18),
                      const Icon(Icons.account_balance_wallet_outlined),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'НОСИ ТО,\nЧТО ЗВУЧИТ',
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  const SizedBox(height: 13),
                  const Text(
                    'Редкие цифровые формы от независимых создателей.',
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filters.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (BuildContext context, int index) {
                        final bool selected = _filter == index;
                        return ChoiceChip(
                          selected: selected,
                          onSelected: (_) => setState(() => _filter = index),
                          label: Text(_filters[index]),
                          selectedColor: AppColors.acid,
                          backgroundColor: AppColors.surface,
                          side: BorderSide(
                            color: selected ? AppColors.acid : AppColors.line,
                          ),
                          labelStyle: TextStyle(
                            color: selected
                                ? AppColors.background
                                : AppColors.text,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: .61,
              ),
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) =>
                    _MarketCard(wearable: items[index]),
                childCount: items.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketCard extends StatelessWidget {
  const _MarketCard({required this.wearable});
  final Wearable wearable;

  @override
  Widget build(BuildContext context) => GestureDetector(
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
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                CrystalArt(wearable: wearable),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.background.withValues(alpha: .55),
                    ),
                    child: const Icon(Icons.favorite_border_rounded, size: 17),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  wearable.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'BY ${wearable.creator}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.muted,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 11),
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.hexagon_outlined,
                      size: 16,
                      color: AppColors.acid,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${wearable.price.toStringAsFixed(0)} USDC',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.favorite_rounded,
                      size: 14,
                      color: AppColors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${wearable.likes}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
