import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/peca_material.dart';
import 'novo_peca_material_page.dart';

class VisualizarPecaPage extends StatelessWidget {
  final PecaMaterial peca;

  const VisualizarPecaPage({super.key, required this.peca});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detalhes da Peça',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade600, Colors.orange.shade400],
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
            colors: [Colors.orange.shade50, Colors.white, Colors.white],
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
                Colors.orange,
                [
                  _buildInfoRow('Nome da Peça', peca.nome),
                  if (peca.descricao != null && peca.descricao!.isNotEmpty)
                    _buildInfoRow('Descrição', peca.descricao!),
                ],
              ),
              const SizedBox(height: 16),

              // Valores
              _buildInfoSection('Valores', Icons.attach_money, Colors.orange, [
                _buildInfoRow(
                  'Preço de Venda',
                  peca.preco != null
                      ? currencyFormat.format(peca.preco)
                      : 'Não definido',
                  valueColor:
                      peca.preco != null ? Colors.orange.shade700 : null,
                  isBold: peca.preco != null,
                ),
                if (peca.custo != null)
                  _buildInfoRow('Custo', currencyFormat.format(peca.custo)),
                if (peca.custo != null && peca.preco != null && peca.preco! > 0)
                  _buildInfoRow(
                    'Margem de Lucro',
                    currencyFormat.format(peca.preco! - (peca.custo ?? 0)),
                    valueColor: Colors.blue.shade700,
                  ),
              ]),
              const SizedBox(height: 16),

              // Identificação
              if (_temIdentificacao())
                _buildInfoSection(
                  'Identificação',
                  Icons.qr_code,
                  Colors.orange,
                  [
                    if (peca.codigoProduto != null &&
                        peca.codigoProduto!.isNotEmpty)
                      _buildInfoRow('Código do Produto', peca.codigoProduto!),
                    if (peca.codigoInterno != null &&
                        peca.codigoInterno!.isNotEmpty)
                      _buildInfoRow('Código Interno', peca.codigoInterno!),
                  ],
                ),

              if (_temIdentificacao()) const SizedBox(height: 16),

              // Detalhes do Produto
              if (_temDetalhesProduto())
                _buildInfoSection(
                  'Detalhes do Produto',
                  Icons.list_alt,
                  Colors.orange,
                  [
                    if (peca.marca != null && peca.marca!.isNotEmpty)
                      _buildInfoRow('Marca', peca.marca!),
                    if (peca.modelo != null && peca.modelo!.isNotEmpty)
                      _buildInfoRow('Modelo', peca.modelo!),
                    if (peca.unidadeMedida != null &&
                        peca.unidadeMedida!.isNotEmpty)
                      _buildInfoRow('Unidade de Medida', peca.unidadeMedida!),
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
        label: const Text('Editar Peça'),
        backgroundColor: Colors.orange.shade600,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  bool _temIdentificacao() {
    return (peca.codigoProduto != null && peca.codigoProduto!.isNotEmpty) ||
        (peca.codigoInterno != null && peca.codigoInterno!.isNotEmpty);
  }

  bool _temDetalhesProduto() {
    return (peca.marca != null && peca.marca!.isNotEmpty) ||
        (peca.modelo != null && peca.modelo!.isNotEmpty) ||
        (peca.unidadeMedida != null && peca.unidadeMedida!.isNotEmpty);
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
                  colors: [Colors.orange.shade400, Colors.orange.shade600],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.shade200,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.handyman, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              peca.nome,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color:
                    peca.preco != null
                        ? Colors.orange.shade50
                        : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      peca.preco != null
                          ? Colors.orange.shade300
                          : Colors.grey.shade300,
                ),
              ),
              child: Text(
                peca.preco != null
                    ? currencyFormat.format(peca.preco)
                    : 'Preço não definido',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color:
                      peca.preco != null
                          ? Colors.orange.shade700
                          : Colors.grey.shade600,
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
      MaterialPageRoute(builder: (_) => NovoPecaMaterialPage(peca: peca)),
    ).then((result) {
      // Se retornou com sucesso, volta para a lista
      if (result == true) {
        Navigator.pop(context);
      }
    });
  }
}
