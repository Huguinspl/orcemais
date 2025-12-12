import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/feature_card.dart';
import '../../widgets/home_menu.dart';
import '../../../routes/app_routes.dart';
import '../../providers/user_provider.dart';
import '../../providers/agendamentos_provider.dart';
import '../../services/notification_service.dart';

class HomeBody extends StatelessWidget {
  final VoidCallback? onNotificationPressed;
  final VoidCallback? onNotificationLongPressed;
  final VoidCallback? onLogout;

  const HomeBody({
    super.key,
    this.onNotificationPressed,
    this.onNotificationLongPressed,
    this.onLogout,
  });

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
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // SliverAppBar com gradiente azul
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: Colors.blue.shade600,
            title: Row(
              children: [
                const Icon(Icons.account_circle, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Consumer<UserProvider>(
                  builder:
                      (_, u, __) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            u.nome.isNotEmpty
                                ? 'Olá, ${u.nome.split(' ').first}!'
                                : 'Olá, Usuário!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Bem-vindo de volta',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: onNotificationPressed,
                onLongPress: onNotificationLongPressed,
                tooltip: 'Notificações (Pressione longo para teste)',
                color: Colors.white,
              ),
              if (onLogout != null) HomeMenu(onLogout: onLogout!),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue.shade600, Colors.blue.shade400],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.home_rounded,
                    size: 70,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),

          // Conteúdo
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue.shade50, Colors.white, Colors.white],
                ),
              ),
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
                              colors: [
                                Colors.blue.shade400,
                                Colors.blue.shade600,
                              ],
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
                                Colors.teal.shade400,
                                Colors.teal.shade600,
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
                              () => Navigator.pushNamed(
                                context,
                                AppRoutes.orcamentos,
                              ),
                        ),
                        FeatureCard(
                          icon: Icons.receipt_outlined,
                          title: 'Recibos',
                          color: Colors.teal,
                          onTap:
                              () => Navigator.pushNamed(
                                context,
                                AppRoutes.recibos,
                              ),
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
                          icon: Icons.attach_money,
                          title: 'Controle de Despesas',
                          color: Colors.redAccent,
                          onTap:
                              () => Navigator.pushNamed(
                                context,
                                AppRoutes.despesas,
                              ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Seção Outras Tarefas
                    _modernSection(
                      title: 'Outras Tarefas',
                      subtitle: 'Ações complementares',
                      cards: [
                        FeatureCard(
                          icon: Icons.receipt_long,
                          title: 'Outras Funcionalidades',
                          color: Colors.teal,
                          onTap:
                              () => Navigator.pushNamed(
                                context,
                                AppRoutes.outrasFuncionalidades,
                              ),
                        ),
                        FeatureCard(
                          icon: Icons.share,
                          title: 'Indique para um amigo',
                          color: Colors.purple,
                          onTap:
                              () => _placeholder(
                                context,
                                'Indique para um amigo',
                              ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
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
          height: 126, // 140 * 0.9 = 126
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 43, color: Colors.white), // 48 * 0.9 = 43.2
              const SizedBox(height: 11), // 12 * 0.9 = 10.8
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14, // 16 * 0.9 = 14.4
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            // Indicador de "deslize para ver mais" apenas para seção Serviços
            if (title == 'Serviços')
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade400.withOpacity(0.2),
                      Colors.blue.shade600.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.blue.shade400.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Deslize',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: Colors.blue.shade700,
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 153, // 170 * 0.9 = 153
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
