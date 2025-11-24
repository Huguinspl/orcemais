import 'package:flutter/material.dart';
import 'package:orcemais/routes/app_routes.dart';

class CatalogoPage extends StatelessWidget {
  const CatalogoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue.shade50, Colors.white, Colors.white],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'Catálogo',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Selecione o que deseja gerenciar no seu catálogo',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 32),
              _modernCard(
                context: context,
                icon: Icons.miscellaneous_services,
                iconColor: Colors.green,
                title: 'Serviços',
                subtitle: 'Gerencie os serviços oferecidos',
                onTap: () => Navigator.pushNamed(context, AppRoutes.servicos),
              ),
              const SizedBox(height: 16),
              _modernCard(
                context: context,
                icon: Icons.handyman,
                iconColor: Colors.orange,
                title: 'Peças e Materiais',
                subtitle: 'Controle seu estoque e materiais',
                onTap: () => Navigator.pushNamed(context, AppRoutes.pecasMateriais),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modernCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(20),
      shadowColor: iconColor.withOpacity(0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                iconColor.withOpacity(0.1),
                iconColor.withOpacity(0.05),
              ],
            ),
            border: Border.all(
              color: iconColor.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: iconColor),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: iconColor.withOpacity(0.5),
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
