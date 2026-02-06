import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/servico.dart';
import 'novo_servico_page.dart';

class VisualizarServicoPage extends StatelessWidget {
  final Servico servico;

  const VisualizarServicoPage({super.key, required this.servico});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detalhes do Serviço',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade600, Colors.green.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar',
            onPressed: () => _abrirEdicao(context),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade50, Colors.white, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              _buildHeaderCard(currencyFormat),
              const SizedBox(height: 20),

              // Informações Principais
              _buildInfoSection(
                'Informações Principais',
                Icons.info_outline,
                Colors.green,
                [
                  _buildInfoRow('Nome do Serviço', servico.titulo),
                  _buildInfoRow(
                    'Descrição',
                    servico.descricao.isNotEmpty
                        ? servico.descricao
                        : 'Não informada',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Valores
              _buildInfoSection('Valores', Icons.attach_money, Colors.green, [
                _buildInfoRow(
                  'Preço de Venda',
                  currencyFormat.format(servico.preco),
                  valueColor: Colors.green.shade700,
                  isBold: true,
                ),
                if (servico.custo != null)
                  _buildInfoRow('Custo', currencyFormat.format(servico.custo)),
                if (servico.custo != null && servico.preco > 0)
                  _buildInfoRow(
                    'Margem de Lucro',
                    currencyFormat.format(servico.preco - (servico.custo ?? 0)),
                    valueColor: Colors.blue.shade700,
                  ),
              ]),
              const SizedBox(height: 16),

              // Detalhes Adicionais
              if (_temDetalhesAdicionais())
                _buildInfoSection(
                  'Detalhes Adicionais',
                  Icons.list_alt,
                  Colors.green,
                  [
                    if (servico.duracao != null && servico.duracao!.isNotEmpty)
                      _buildInfoRow('Duração', servico.duracao!),
                    if (servico.categoria != null &&
                        servico.categoria!.isNotEmpty)
                      _buildInfoRow('Categoria', servico.categoria!),
                    if (servico.unidade != null && servico.unidade!.isNotEmpty)
                      _buildInfoRow('Unidade', servico.unidade!),
                  ],
                ),

              const SizedBox(height: 100), // Espaço para o botão
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirEdicao(context),
        icon: const Icon(Icons.edit),
        label: const Text('Editar Serviço'),
        backgroundColor: Colors.green.shade600,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  bool _temDetalhesAdicionais() {
    return (servico.duracao != null && servico.duracao!.isNotEmpty) ||
        (servico.categoria != null && servico.categoria!.isNotEmpty) ||
        (servico.unidade != null && servico.unidade!.isNotEmpty);
  }

  Widget _buildHeaderCard(NumberFormat currencyFormat) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey.shade50],
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.shade200,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.miscellaneous_services,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              servico.titulo,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Text(
                currencyFormat.format(servico.preco),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(
    String title,
    IconData icon,
    MaterialColor color,
    List<Widget> children,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color.shade700, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: valueColor ?? Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _abrirEdicao(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NovoServicoPage(original: servico)),
    ).then((result) {
      // Se retornou com sucesso (resultado não nulo), volta para a lista
      if (result != null) {
        Navigator.pop(context);
      }
    });
  }
}
