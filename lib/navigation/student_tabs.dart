import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

class StudentTabs extends StatelessWidget {
  const StudentTabs({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _goBranch,
        destinations: const [
          NavigationDestination(
            icon: Icon(LucideIcons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.bot),
            label: 'AI Teacher',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.fileText),
            label: 'Mock Tests',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.library),
            label: 'Resources',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.user),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
