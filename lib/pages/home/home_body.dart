import 'package:flutter/material.dart';
import '../../widgets/feature_card.dart'; // ← cards reutilizáveis
import '../../../routes/app_routes.dart';

class HomeBody extends StatelessWidget {
  const HomeBody({super.key});

  void _onCardTap(BuildContext ctx, String a) {
    ScaffoldMessenger.of(
      ctx,
    ).showSnackBar(SnackBar(content: Text('Ação: $a (em construção)')));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder:
          (ctx, c) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      'Comece por aqui',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ---------- botões iniciais ----------
                    Row(
                      children: [
                        Expanded(
                          child: _actionButton(
                            ctx,
                            label: 'Novo Orçamento',
                            icon: Icons.add,
                            color: Colors.blueAccent,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.novoOrcamento,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _actionButton(
                            ctx,
                            label: 'Novo Recibo',
                            icon: Icons.receipt,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    _section('Serviços', [
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
                        icon: Icons.calendar_today,
                        title: 'Agendar Serviço',
                        color: Colors.green,
                        onTap: () => _onCardTap(ctx, 'Agendar Serviço'),
                      ),
                      FeatureCard(
                        icon: Icons.receipt_long,
                        title: 'Emitir Recibo',
                        color: Colors.orange,
                        onTap: () => _onCardTap(ctx, 'Emitir Recibo'),
                      ),
                      FeatureCard(
                        icon: Icons.attach_money,
                        title: 'Controle de Despesas',
                        color: Colors.redAccent,
                        onTap: () => _onCardTap(ctx, 'Controle de Despesas'),
                      ),
                    ]),

                    const SizedBox(height: 24),
                    _section('Outras Tarefas', [
                      FeatureCard.withCount(
                        icon: Icons.receipt_outlined,
                        title: 'Meus Recibos',
                        count: 0,
                        color: Colors.teal,
                        onTap: () => _onCardTap(ctx, 'Meus Recibos'),
                      ),
                      FeatureCard(
                        icon: Icons.share,
                        title: 'Indique para um amigo',
                        color: Colors.purple,
                        onTap: () => _onCardTap(ctx, 'Indique para um amigo'),
                      ),
                    ]),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  /* ---------- helpers visuais só deste arquivo ---------- */
  Widget _actionButton(
    BuildContext ctx, {
    required String label,
    required IconData icon,
    required Color color,
    void Function()? onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap ?? () => _onCardTap(ctx, label),
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _section(String title, List<Widget> cards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemBuilder: (_, i) => cards[i],
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemCount: cards.length,
          ),
        ),
      ],
    );
  }
}
