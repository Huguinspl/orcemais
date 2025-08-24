import 'package:flutter/material.dart';
import 'package:gestorfy/routes/app_routes.dart';

class CatalogoPage extends StatelessWidget {
  const CatalogoPage({super.key});

  @override
  Widget build(BuildContext context) {
    Widget card({
      required IconData icon,
      required String label,
      VoidCallback? onTap,
    }) {
      return InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 28, color: Colors.blue),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /* ---------- título ---------- */
            const Text(
              'Catálogo',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            /* ---------- descrição ---------- */
            const Text(
              'Selecione o que deseja gerenciar no seu catálogo:',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),

            /* ---------- cartões ---------- */
            card(
              icon: Icons.miscellaneous_services,
              label: 'Serviços',
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.servicos);
              },
            ),
            const SizedBox(height: 16),
            card(
              icon: Icons.handyman,
              label: 'Peças e Materiais',
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.pecasMateriais);
              },
            ),
          ],
        ),
      ),
    );
  }
}
