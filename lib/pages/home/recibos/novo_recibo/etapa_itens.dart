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
          Row(
            children: [
              Icon(Icons.shopping_cart, size: 32, color: theme.primaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Adicione os Itens',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: const Text(
                        'OBRIGATÓRIO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildActionCard(
            context: context,
            label: 'Adicionar Serviço',
            valor: 'Adicionar um novo serviço avulso',
            icon: Icons.build,
            corIcone: Colors.blue.shade700,
            onTap: onAdicionarServico,
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            context: context,
            label: 'Adicionar Produto/Peça',
            valor: 'Adicionar um item do seu catálogo',
            icon: Icons.inventory_2,
            corIcone: Colors.orange.shade700,
            onTap: onAdicionarPeca,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Itens Adicionados',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (itens.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${itens.length} ${itens.length == 1 ? 'item' : 'itens'}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade900,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (itens.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 48,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Nenhum item adicionado ainda',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Adicione pelo menos um serviço ou produto para continuar',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: itens.length,
              itemBuilder: (context, index) {
                final item = itens[index];
                final preco = double.tryParse(item['preco'].toString()) ?? 0.0;
                final quantidade =
                    double.tryParse(item['quantidade'].toString()) ?? 1.0;
                final totalItem = preco * quantidade;
                final tipo = item['tipo'] ?? 'item';

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor:
                          tipo == 'servico'
                              ? Colors.blue.shade50
                              : Colors.orange.shade50,
                      child: Icon(
                        tipo == 'servico' ? Icons.build : Icons.inventory_2,
                        size: 20,
                        color:
                            tipo == 'servico'
                                ? Colors.blue.shade700
                                : Colors.orange.shade700,
                      ),
                    ),
                    title: Text(
                      item['nome'] ?? 'Item sem nome',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Qtd: ${quantidade.toStringAsFixed(quantidade.truncateToDouble() == quantidade ? 0 : 2)}  •  ${currencyFormat.format(preco)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Total: ${currencyFormat.format(totalItem)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red.shade400,
                      ),
                      onPressed: () => onRemoverItem(index),
                      tooltip: 'Remover item',
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
          style: TextStyle(
            color: Theme.of(context).textTheme.bodySmall?.color,
            fontSize: 13,
          ),
        ),
        trailing: const Icon(Icons.add_circle_outline, color: Colors.green),
      ),
    );
  }
}
