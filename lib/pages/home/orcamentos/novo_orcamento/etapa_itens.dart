import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EtapaItensWidget extends StatelessWidget {
  final List<Map<String, dynamic>> itens;
  final VoidCallback onAdicionarServico;
  final VoidCallback onAdicionarPeca;
  final Function(int) onRemoverItem;

  const EtapaItensWidget({
    super.key,
    required this.itens,
    required this.onAdicionarServico,
    required this.onAdicionarPeca,
    required this.onRemoverItem,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Etapa 2: Adicione os Itens',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildActionCard(
            context: context,
            label: 'Adicionar Serviço',
            valor: 'Adicionar um novo serviço avulso',
            icon: Icons.build,
            corIcone: Colors.orange.shade700,
            onTap: onAdicionarServico,
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            context: context,
            label: 'Adicionar Peça/Material',
            valor: 'Adicionar um item do seu catálogo',
            icon: Icons.inventory_2,
            corIcone: Colors.green.shade700,
            // ✅ CORREÇÃO: Ação agora chama o onAdicionarPeca
            onTap: onAdicionarPeca,
          ),
          const SizedBox(height: 32),
          Text(
            'Itens Adicionados',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (itens.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Text(
                  'Nenhum item adicionado ainda.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: itens.length,
              itemBuilder: (context, index) {
                final item = itens[index];
                final preco = item['preco'] as double? ?? 0.0;
                final quantidade = item['quantidade'] as double? ?? 1.0;
                final totalItem = preco * quantidade;

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(
                      item['nome'] ?? 'Item sem nome',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Qtd: $quantidade'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currencyFormat.format(totalItem),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: theme.colorScheme.error,
                          ),
                          onPressed: () => onRemoverItem(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String label,
    required String valor,
    required IconData icon,
    required Color corIcone,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: CircleAvatar(
          backgroundColor: corIcone.withAlpha(26),
          child: Icon(icon, color: corIcone),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          valor,
          style: TextStyle(color: theme.textTheme.bodySmall?.color),
        ),
        trailing: const Icon(Icons.add_circle_outline, color: Colors.green),
      ),
    );
  }
}
