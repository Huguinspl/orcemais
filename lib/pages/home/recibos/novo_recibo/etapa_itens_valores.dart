import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/valor_recebido.dart';

class EtapaItensValoresWidget extends StatelessWidget {
  final List<Map<String, dynamic>> itens;
  final List<ValorRecebido> valores;
  final VoidCallback onAdicionarServico;
  final VoidCallback onAdicionarPeca;
  final VoidCallback onAdicionarValor;
  final Function(int) onRemoverItem;
  final Function(int) onRemoverValor;

  const EtapaItensValoresWidget({
    super.key,
    required this.itens,
    required this.valores,
    required this.onAdicionarServico,
    required this.onAdicionarPeca,
    required this.onAdicionarValor,
    required this.onRemoverItem,
    required this.onRemoverValor,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Calcular totais
    double subtotalItens = 0;
    for (final item in itens) {
      final preco = (item['preco'] ?? 0).toDouble();
      final qtd = (item['quantidade'] ?? 1).toDouble();
      subtotalItens += preco * qtd;
    }
    final totalValores = valores.fold<double>(0, (sum, v) => sum + v.valor);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.teal.shade50, Colors.white, Colors.white],
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
                    colors: [Colors.teal.shade600, Colors.teal.shade400],
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
                        color: Colors.white.withValues(alpha: 0.2),
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
                            'Etapa 2: Itens e Valores',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Adicione itens e registre pagamentos',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
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

            // ==================== SEÇÃO DE ITENS ====================
            _buildSectionHeader(
              icon: Icons.shopping_cart_outlined,
              title: 'Itens do Recibo',
              subtitle:
                  '${itens.length} ${itens.length == 1 ? 'item' : 'itens'} • ${currencyFormat.format(subtotalItens)}',
              color: Colors.teal,
            ),
            const SizedBox(height: 12),

            // Botões para adicionar itens
            Row(
              children: [
                Expanded(
                  child: _buildAddButton(
                    label: 'Serviço',
                    icon: Icons.build_outlined,
                    onTap: onAdicionarServico,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAddButton(
                    label: 'Peça/Material',
                    icon: Icons.inventory_2_outlined,
                    onTap: onAdicionarPeca,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Lista de itens
            if (itens.isEmpty)
              _buildEmptyState(
                icon: Icons.add_shopping_cart,
                message: 'Nenhum item adicionado',
                hint: 'Adicione serviços ou peças acima',
              )
            else
              ...itens.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return _buildItemCard(item, index, currencyFormat);
              }),

            const SizedBox(height: 32),

            // ==================== SEÇÃO DE VALORES ====================
            _buildSectionHeader(
              icon: Icons.attach_money,
              title: 'Valores Recebidos',
              subtitle:
                  '${valores.length} ${valores.length == 1 ? 'pagamento' : 'pagamentos'} • ${currencyFormat.format(totalValores)}',
              color: Colors.green,
              isOptional: true,
            ),
            const SizedBox(height: 12),

            // Botão para adicionar valor
            _buildAddButton(
              label: 'Adicionar Pagamento',
              icon: Icons.add_card,
              onTap: onAdicionarValor,
              fullWidth: true,
              color: Colors.green,
            ),
            const SizedBox(height: 16),

            // Lista de valores
            if (valores.isEmpty)
              _buildEmptyState(
                icon: Icons.payments_outlined,
                message: 'Nenhum pagamento registrado',
                hint: 'Opcional: registre os valores recebidos',
                isOptional: true,
              )
            else
              ...valores.asMap().entries.map((entry) {
                final index = entry.key;
                final valor = entry.value;
                return _buildValorCard(
                  valor,
                  index,
                  currencyFormat,
                  dateFormat,
                );
              }),

            const SizedBox(height: 24),

            // Resumo financeiro
            if (itens.isNotEmpty || valores.isNotEmpty)
              _buildResumoFinanceiro(
                subtotalItens,
                totalValores,
                currencyFormat,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    bool isOptional = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  if (isOptional) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Opcional',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool fullWidth = false,
    Color color = Colors.teal,
  }) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String hint,
    bool isOptional = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hint,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item, int index, NumberFormat nf) {
    final nome = item['nome'] ?? 'Item';
    final preco = (item['preco'] ?? 0).toDouble();
    final quantidade = (item['quantidade'] ?? 1).toDouble();
    final total = preco * quantidade;
    final tipo = item['tipo'] ?? 'servico';
    final isServico = tipo == 'servico';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors:
                      isServico
                          ? [Colors.blue.shade400, Colors.blue.shade600]
                          : [Colors.orange.shade400, Colors.orange.shade600],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isServico ? Icons.build : Icons.inventory_2,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nome,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${quantidade.toStringAsFixed(quantidade.truncateToDouble() == quantidade ? 0 : 2)} x ${nf.format(preco)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        nf.format(total),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.teal.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => onRemoverItem(index),
              icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
              tooltip: 'Remover item',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValorCard(
    ValorRecebido valor,
    int index,
    NumberFormat nf,
    DateFormat df,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.payments, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nf.format(valor.valor),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        df.format(valor.data.toDate()),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (valor.formaPagamento.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Icon(
                          Icons.payment,
                          size: 12,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          valor.formaPagamento,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => onRemoverValor(index),
              icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
              tooltip: 'Remover valor',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoFinanceiro(
    double subtotalItens,
    double totalValores,
    NumberFormat nf,
  ) {
    final saldo = subtotalItens - totalValores;
    final saldoPositivo = saldo > 0;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: Colors.grey.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Resumo Financeiro',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildResumoRow(
              'Subtotal dos Itens',
              nf.format(subtotalItens),
              Colors.grey.shade700,
            ),
            const SizedBox(height: 8),
            _buildResumoRow(
              'Total Recebido',
              nf.format(totalValores),
              Colors.green.shade600,
            ),
            const Divider(height: 24),
            _buildResumoRow(
              saldoPositivo ? 'Saldo a Receber' : 'Saldo Excedente',
              nf.format(saldo.abs()),
              saldoPositivo ? Colors.orange.shade600 : Colors.green.shade600,
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoRow(
    String label,
    String valor,
    Color color, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            color: Colors.grey.shade600,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          valor,
          style: TextStyle(
            fontSize: isBold ? 18 : 15,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
