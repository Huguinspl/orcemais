import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../models/cliente.dart';
import '../../../../providers/business_provider.dart';

class EtapaPdfPage extends StatefulWidget {
  final Cliente cliente;
  final List<Map<String, dynamic>> itens;
  final double subtotal;
  final double desconto;
  final double valorTotal;

  const EtapaPdfPage({
    super.key,
    required this.cliente,
    required this.itens,
    required this.subtotal,
    required this.desconto,
    required this.valorTotal,
  });

  @override
  State<EtapaPdfPage> createState() => _EtapaPdfPageState();
}

class _EtapaPdfPageState extends State<EtapaPdfPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BusinessProvider>().carregarDoFirestore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final businessProvider = context.watch<BusinessProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (businessProvider.nomeEmpresa.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              _buildHeader(context, businessProvider),
            const Divider(height: 40, thickness: 1),
            _buildClientInfo(context),
            const SizedBox(height: 24),
            Text(
              'Itens do Orçamento',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildItemsList(context), // Trocamos a tabela por uma lista
            const SizedBox(height: 24),
            _buildTotals(context),
          ],
        ),
      ),
    );
  }

  // ✅ CORREÇÃO: O método foi refeito para usar um layout flexível que mostra a descrição.
  Widget _buildItemsList(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    return Column(
      children: [
        // Cabeçalho da lista
        Row(
          children: [
            const Expanded(
              flex: 5,
              child: Text(
                'Descrição',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const Expanded(
              flex: 2,
              child: Text(
                'Qtd.',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        const Divider(thickness: 1, height: 16),
        // Itens
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.itens.length,
          itemBuilder: (context, index) {
            final item = widget.itens[index];
            final nome = item['nome'] as String? ?? 'Item';
            final descricao = item['descricao'] as String? ?? '';
            final preco = item['preco'] as double? ?? 0.0;
            final quantidade = item['quantidade'] as double? ?? 1.0;
            final totalItem = preco * quantidade;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nome,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        // Exibe a descrição se ela não estiver vazia
                        if (descricao.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              descricao,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      quantidade.toStringAsFixed(2),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      currencyFormat.format(totalItem),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          },
          separatorBuilder: (context, index) => const Divider(),
        ),
      ],
    );
  }

  // --- O restante do seu código (helpers, etc.) permanece o mesmo ---

  Widget _buildHeader(BuildContext context, BusinessProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                provider.nomeEmpresa,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (provider.telefone.isNotEmpty)
                _buildInfoLinha(Icons.phone_outlined, provider.telefone),
              if (provider.emailEmpresa.isNotEmpty)
                _buildInfoLinha(Icons.email_outlined, provider.emailEmpresa),
              if (provider.endereco.isNotEmpty)
                _buildInfoLinha(Icons.location_on_outlined, provider.endereco),
              if (provider.cnpj.isNotEmpty)
                _buildInfoLinha(Icons.badge_outlined, provider.cnpj),
            ],
          ),
        ),
        const Icon(Icons.business, size: 50, color: Colors.grey),
      ],
    );
  }

  Widget _buildInfoLinha(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildClientInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cliente:', style: Theme.of(context).textTheme.bodySmall),
        Text(
          widget.cliente.nome,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (widget.cliente.celular.isNotEmpty) Text(widget.cliente.celular),
        if (widget.cliente.email.isNotEmpty) Text(widget.cliente.email),
      ],
    );
  }

  Widget _buildTotals(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );
    double custoTotal = 0.0;
    for (var item in widget.itens) {
      final custo = item['custo'] as double? ?? 0.0;
      custoTotal += custo;
    }
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _totalRow('Subtotal', currencyFormat.format(widget.subtotal)),
            if (custoTotal > 0)
              _totalRow('Custos Adicionais', currencyFormat.format(custoTotal)),
            if (widget.desconto > 0)
              _totalRow(
                'Desconto',
                '- ${currencyFormat.format(widget.desconto)}',
              ),
            const Divider(height: 20),
            _totalRow(
              'Valor Total',
              currencyFormat.format(widget.valorTotal),
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Padding _tableHeader(String text, {TextAlign alignment = TextAlign.left}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          text,
          textAlign: alignment,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
  Widget _totalRow(String label, String value, {bool isTotal = false}) {
    final style = TextStyle(
      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
      fontSize: isTotal ? 16 : 14,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }
}
