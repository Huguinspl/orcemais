import 'package:flutter/material.dart';

class HomeNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  const HomeNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onItemTapped,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blueAccent,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Início',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.store_outlined),
          activeIcon: Icon(Icons.store),
          label: 'Meu negócio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag_outlined),
          activeIcon: Icon(Icons.shopping_bag),
          label: 'Catálogo',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_alt_outlined),
          activeIcon: Icon(Icons.people_alt),
          label: 'Clientes',
        ),
      ],
    );
  }
}
