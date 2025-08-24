import 'package:flutter/material.dart';
import '../../widgets/feature_card.dart';
import '../../../routes/app_routes.dart';

class HomeBody extends StatelessWidget {
  const HomeBody({super.key});

  void _placeholder(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(
      ctx,
    ).showSnackBar(SnackBar(content: Text('$msg (em construção)')));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Comece por aqui',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        () => Navigator.pushNamed(
                          context,
                          AppRoutes.novoOrcamento,
                        ),
                    icon: const Icon(Icons.add),
                    label: const Text('Novo Orçamento'),
                    style: _btnStyle(Colors.blueAccent),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        () =>
                            Navigator.pushNamed(context, AppRoutes.novoRecibo),
                    icon: const Icon(Icons.receipt),
                    label: const Text('Novo Recibo'),
                    style: _btnStyle(Colors.orange),
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
                onTap: () => Navigator.pushNamed(context, AppRoutes.orcamentos),
              ),
              FeatureCard(
                icon: Icons.calendar_today,
                title: 'Agendamentos',
                color: Colors.green,
                onTap:
                    () => Navigator.pushNamed(context, AppRoutes.agendamentos),
              ),
              FeatureCard(
                icon: Icons.receipt_long,
                title: 'Emitir Recibo',
                color: Colors.orange,
                onTap: () => Navigator.pushNamed(context, AppRoutes.novoRecibo),
              ),
              FeatureCard(
                icon: Icons.attach_money,
                title: 'Controle de Despesas',
                color: Colors.redAccent,
                onTap: () => Navigator.pushNamed(context, AppRoutes.despesas),
              ),
            ]),
            const SizedBox(height: 24),
            _section('Outras Tarefas', [
              FeatureCard.withCount(
                icon: Icons.receipt_outlined,
                title: 'Meus Recibos',
                count: 0,
                color: Colors.teal,
                onTap: () => Navigator.pushNamed(context, AppRoutes.recibos),
              ),
              FeatureCard(
                icon: Icons.share,
                title: 'Indique para um amigo',
                color: Colors.purple,
                onTap: () => _placeholder(context, 'Indique para um amigo'),
              ),
            ]),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  ButtonStyle _btnStyle(Color c) => ElevatedButton.styleFrom(
    backgroundColor: c,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

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
