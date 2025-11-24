import 'package:flutter/material.dart';
import 'package:orcemais/routes/app_routes.dart';

class OutrasFuncionalidadesPage extends StatelessWidget {
  const OutrasFuncionalidadesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.teal.shade50, Colors.white, Colors.white],
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
                'Outras Funcionalidades',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Ferramentas adicionais para seu negócio',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 32),
              _modernCard(
                context: context,
                icon: Icons.checklist_rounded,
                iconColor: Colors.teal,
                title: 'Check List',
                subtitle: 'Organize suas tarefas e atividades',
                onTap: () => Navigator.pushNamed(context, AppRoutes.checklists),
              ),
              const SizedBox(height: 16),
              _modernCard(
                context: context,
                icon: Icons.analytics_outlined,
                iconColor: Colors.purple,
                title: 'Relatórios',
                subtitle: 'Análises e estatísticas do negócio',
                onTap: () => _placeholder(context, 'Relatórios em breve'),
              ),
              const SizedBox(height: 16),
              _modernCard(
                context: context,
                icon: Icons.notifications_active_outlined,
                iconColor: Colors.amber,
                title: 'Lembretes',
                subtitle: 'Configure notificações importantes',
                onTap: () => _placeholder(context, 'Lembretes em breve'),
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
              colors: [iconColor.withOpacity(0.1), iconColor.withOpacity(0.05)],
            ),
            border: Border.all(color: iconColor.withOpacity(0.3), width: 1.5),
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

  void _placeholder(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.teal.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
