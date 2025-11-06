import 'package:flutter/material.dart';
import '../../widgets/feature_card.dart';
import '../../../routes/app_routes.dart';

class HomeBody extends StatelessWidget {
  const HomeBody({super.key});

  void _placeholder(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text('$msg (em construção)'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

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
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Título de boas-vindas moderno
              Text(
                'Comece por aqui',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Escolha uma ação rápida',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 24),

              // Botões de ação principais com cards elevados
              Row(
                children: [
                  Expanded(
                    child: _modernActionCard(
                      context: context,
                      icon: Icons.add_circle_outline,
                      label: 'Novo\nOrçamento',
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.blue.shade600],
                      ),
                      onTap:
                          () => Navigator.pushNamed(
                            context,
                            AppRoutes.novoOrcamento,
                          ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _modernActionCard(
                      context: context,
                      icon: Icons.receipt_long_outlined,
                      label: 'Novo\nRecibo',
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.shade400,
                          Colors.orange.shade600,
                        ],
                      ),
                      onTap:
                          () => Navigator.pushNamed(
                            context,
                            AppRoutes.novoRecibo,
                          ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Seção Serviços
              _modernSection(
                title: 'Serviços',
                subtitle: 'Gerencie seu negócio',
                cards: [
                  FeatureCard(
                    icon: Icons.description_outlined,
                    title: 'Orçamentos',
                    color: Colors.blueAccent,
                    onTap:
                        () =>
                            Navigator.pushNamed(context, AppRoutes.orcamentos),
                  ),
                  FeatureCard(
                    icon: Icons.calendar_today,
                    title: 'Agendamentos',
                    color: Colors.green,
                    onTap:
                        () => Navigator.pushNamed(
                          context,
                          AppRoutes.agendamentos,
                        ),
                  ),
                  FeatureCard(
                    icon: Icons.receipt_long,
                    title: 'Emitir Recibo',
                    color: Colors.orange,
                    onTap:
                        () =>
                            Navigator.pushNamed(context, AppRoutes.novoRecibo),
                  ),
                  FeatureCard(
                    icon: Icons.attach_money,
                    title: 'Controle de Despesas',
                    color: Colors.redAccent,
                    onTap:
                        () => Navigator.pushNamed(context, AppRoutes.despesas),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Seção Outras Tarefas
              _modernSection(
                title: 'Outras Tarefas',
                subtitle: 'Ações complementares',
                cards: [
                  FeatureCard.withCount(
                    icon: Icons.receipt_outlined,
                    title: 'Meus Recibos',
                    count: 0,
                    color: Colors.teal,
                    onTap:
                        () => Navigator.pushNamed(context, AppRoutes.recibos),
                  ),
                  FeatureCard(
                    icon: Icons.share,
                    title: 'Indique para um amigo',
                    color: Colors.purple,
                    onTap: () => _placeholder(context, 'Indique para um amigo'),
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Card de ação moderna com gradiente e elevação
  Widget _modernActionCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(20),
      shadowColor: Colors.black.withOpacity(0.2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Seção moderna com título e subtítulo
  Widget _modernSection({
    required String title,
    required String subtitle,
    required List<Widget> cards,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (_, i) => cards[i],
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemCount: cards.length,
          ),
        ),
      ],
    );
  }
}
