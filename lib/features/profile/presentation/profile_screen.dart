import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              'ПРОФИЛЬ',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.acid,
                letterSpacing: 2,
              ),
            ),
            const Spacer(),
            const Icon(Icons.settings_outlined),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          children: <Widget>[
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: <Color>[
                    AppColors.orange,
                    AppColors.violet,
                    AppColors.cyan,
                  ],
                ),
                border: Border.all(color: Colors.white30, width: 2),
              ),
              child: const Icon(
                Icons.blur_on_rounded,
                color: AppColors.background,
                size: 35,
              ),
            ),
            const SizedBox(width: 17),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'ALEX / ECHO',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '0x71A4...9F2C',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const Icon(Icons.qr_code_2_rounded, size: 28),
          ],
        ),
        const SizedBox(height: 28),
        const Row(
          children: <Widget>[
            Expanded(
              child: _Stat(value: '04', label: 'РАБОТЫ'),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _Stat(value: '326', label: 'ЛАЙКИ'),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _Stat(value: '02', label: 'NFT'),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.workspace_premium_rounded,
                    color: AppColors.acid,
                  ),
                  const SizedBox(width: 9),
                  Text(
                    'СЛЕДУЮЩИЙ УРОВЕНЬ',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const Spacer(),
                  const Text('4 / 10'),
                ],
              ),
              const SizedBox(height: 14),
              LinearProgressIndicator(
                value: .4,
                minHeight: 5,
                color: AppColors.acid,
                backgroundColor: AppColors.line,
                borderRadius: BorderRadius.circular(5),
              ),
              const SizedBox(height: 12),
              const Text('Создай ещё 6 объектов и получи бесплатную чеканку.'),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'ЦЕНТР УПРАВЛЕНИЯ',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        const _MenuTile(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Кошелёк',
          subtitle: 'Polygon • 84.20 USDC',
        ),
        const _MenuTile(
          icon: Icons.cloud_off_outlined,
          title: 'Офлайн-черновики',
          subtitle: '1 объект ожидает синхронизации',
        ),
        const _MenuTile(
          icon: Icons.map_outlined,
          title: 'Карта артефактов',
          subtitle: '12 отголосков рядом',
        ),
        const _MenuTile(
          icon: Icons.lock_outline_rounded,
          title: 'Приватность',
          subtitle: 'Данные обрабатываются на устройстве',
        ),
      ],
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.line),
    ),
    child: Column(
      children: <Widget>[
        Text(value, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.muted,
            fontSize: 10,
          ),
        ),
      ],
    ),
  );
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: AppColors.line),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      leading: Icon(icon, color: AppColors.acid),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
    ),
  );
}
