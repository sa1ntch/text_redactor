import 'package:flutter/material.dart';

class AppMenuItem {
  const AppMenuItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class AppMenu extends StatelessWidget {
  const AppMenu({
    super.key,
    required this.compact,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final bool compact;
  final List<AppMenuItem> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: Text(
              'Разделы',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          for (var index = 0; index < destinations.length; index++)
            ListTile(
              leading: Icon(destinations[index].icon),
              title: Text(destinations[index].label),
              selected: index == selectedIndex,
              selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              onTap: () => onSelected(index),
            ),
        ],
      );
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: NavigationRail(
        minWidth: 88,
        minExtendedWidth: 244,
        extended: true,
        backgroundColor: Colors.white,
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelected,
        labelType: NavigationRailLabelType.none,
        destinations: [
          for (final destination in destinations)
            NavigationRailDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.icon),
              label: Text(destination.label),
            ),
        ],
      ),
    );
  }
}
