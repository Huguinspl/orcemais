import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

class HomeMenu extends StatelessWidget {
  final VoidCallback onLogout;

  const HomeMenu({super.key, required this.onLogout});

  void _abrirPerfil(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.perfil);
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.menu, color: Colors.white),
      onSelected: (value) {
        if (value == 'logout') {
          onLogout();
        } else if (value == 'perfil') {
          _abrirPerfil(context);
        }
      },
      itemBuilder:
          (context) => const [
            PopupMenuItem<String>(value: 'perfil', child: Text('Meu perfil')),
            PopupMenuItem<String>(value: 'logout', child: Text('Sair')),
          ],
    );
  }
}
