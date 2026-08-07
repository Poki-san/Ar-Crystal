import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../create/presentation/create_screen.dart';
import '../../gallery/presentation/gallery_screen.dart';
import '../../market/presentation/market_screen.dart';
import '../../profile/presentation/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const List<Widget> _pages = <Widget>[
    GalleryScreen(),
    CreateScreen(),
    MarketScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.line, width: .7)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (int value) => setState(() => _index = value),
          destinations: const <NavigationDestination>[
            NavigationDestination(
              icon: Icon(Icons.grid_view_rounded),
              selectedIcon: Icon(
                Icons.grid_view_rounded,
                color: AppColors.acid,
              ),
              label: 'КОЛЛЕКЦИЯ',
            ),
            NavigationDestination(
              icon: Icon(Icons.add_circle_outline_rounded),
              selectedIcon: Icon(
                Icons.add_circle_rounded,
                color: AppColors.acid,
              ),
              label: 'СОЗДАТЬ',
            ),
            NavigationDestination(
              icon: Icon(Icons.public_rounded),
              selectedIcon: Icon(Icons.public_rounded, color: AppColors.acid),
              label: 'МАРКЕТ',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded, color: AppColors.acid),
              label: 'ПРОФИЛЬ',
            ),
          ],
        ),
      ),
    );
  }
}
