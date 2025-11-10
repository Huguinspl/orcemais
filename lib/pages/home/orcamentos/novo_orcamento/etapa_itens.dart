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

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue.shade50, Colors.white, Colors.white],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header moderno
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade600, Colors.blue.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.list_alt_outlined,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Etapa 2: Itens',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Adicione serviços e peças ao orçamento',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildActionCard(
              context: context,
              label: 'Adicionar Serviço',
              valor: 'Adicionar um novo serviço avulso',
              icon: Icons.build_outlined,
              corIcone: Colors.green,
              onTap: onAdicionarServico,
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              context: context,
              label: 'Adicionar Peça/Material',
              valor: 'Adicionar um item do seu catálogo',
              icon: Icons.inventory_2_outlined,
              corIcone: Colors.orange,
              onTap: onAdicionarPeca,
            ),
            const SizedBox(height: 32),

            // Seção de itens adicionados
            Row(
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  color: Colors.blue.shade700,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Itens Adicionados',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(width: 8),
                if (itens.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.blue.shade600],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${itens.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (itens.isEmpty)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inventory_outlined,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum item adicionado ainda',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Use os botões acima para adicionar serviços\nou peças ao orçamento',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                    ],
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
                  final preco =
                      double.tryParse(item['preco'].toString()) ?? 0.0;
                  final quantidade =
                      double.tryParse(item['quantidade'].toString()) ?? 1.0;
                  final totalItem = preco * quantidade;
                  final isServico =
                      item['tipo'] == 'servico' || !item.containsKey('tipo');

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              isServico
                                  ? Colors.green.shade50
                                  : Colors.orange.shade50,
                              Colors.white,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors:
                                      isServico
                                          ? [
                                            Colors.green.shade400,
                                            Colors.green.shade600,
                                          ]
                                          : [
                                            Colors.orange.shade400,
                                            Colors.orange.shade600,
                                          ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isServico
                                            ? Colors.green
                                            : Colors.orange)
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                isServico ? Icons.build : Icons.inventory_2,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['nome'] ?? 'Item sem nome',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.shopping_basket_outlined,
                                        size: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Qtd: $quantidade',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Icon(
                                        Icons.payments_outlined,
                                        size: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        currencyFormat.format(totalItem),
                                        style: TextStyle(
                                          color:
                                              isServico
                                                  ? Colors.green.shade700
                                                  : Colors.orange.shade700,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: Colors.red.shade400,
                              ),
                              onPressed: () => onRemoverItem(index),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String label,
    required String valor,
    required IconData icon,
    required MaterialColor corIcone,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [corIcone.shade50, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [corIcone.shade400, corIcone.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: corIcone.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      valor,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.add_circle_outline,
                color: corIcone.shade600,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
