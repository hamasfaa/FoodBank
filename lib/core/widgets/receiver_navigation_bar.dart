import 'package:flutter/material.dart';
import 'package:foodbank/core/constants/app_colors.dart';

enum ReceiverNavItem { home, claims, profile }

class ReceiverNavigationBar extends StatelessWidget {
  final ReceiverNavItem currentItem;

  const ReceiverNavigationBar({super.key, required this.currentItem});

  static const Map<ReceiverNavItem, String> _routes = {
    ReceiverNavItem.home: '/receiver-home',
    ReceiverNavItem.claims: '/my-claims',
    ReceiverNavItem.profile: '/receiver-profile',
  };

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: NavigationBar(
        selectedIndex: currentItem.index,
        height: 72,
        elevation: 0,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryLight,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) =>
            _handleDestinationSelected(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.restaurant_outlined),
            selectedIcon: Icon(Icons.restaurant),
            label: 'Makanan',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Klaimku',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  void _handleDestinationSelected(BuildContext context, int index) {
    final selectedItem = ReceiverNavItem.values[index];
    if (selectedItem == currentItem) return;

    Navigator.of(context).pushReplacementNamed(_routes[selectedItem]!);
  }
}
