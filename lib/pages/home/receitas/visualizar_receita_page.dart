import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/receita.dart';
import 'nova_receita_page.dart';

class VisualizarReceitaPage extends StatelessWidget {
  final Transacao receita;

  const VisualizarReceitaPage({super.key, required this.receita});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Cor e ícone baseado na categoria
    Color categoriaColor;
    IconData categoriaIcon;
    switch (receita.categoria) {
      case CategoriaTransacao.vendas:
        categoriaColor = Colors.blue;
        categoriaIcon = Icons.shopping_cart_outlined;
        break;
      case CategoriaTransacao.servicos:
        categoriaColor = Colors.purple;
        categoriaIcon = Icons.build_outlined;
        break;
      case CategoriaTransacao.investimentos:
        categoriaColor = Colors.orange;
        categoriaIcon = Icons.trending_up;
        break;
      default:
        categoriaColor = Colors.grey;
        categoriaIcon = Icons.category_outlined;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detalhes da Receita',
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
              // Card principal com valor
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade500, Colors.green.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.shade300,
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.arrow_upward_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Valor Recebido',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currencyFormat.format(receita.valor),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Informações da receita
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Descrição
                    _buildInfoRow(
                      icon: Icons.description_outlined,
                      label: 'Descrição',
                      value: receita.descricao,
                      iconColor: Colors.green.shade600,
                    ),
                    const Divider(height: 24),

                    // Categoria
                    _buildInfoRow(
                      icon: categoriaIcon,
                      label: 'Categoria',
                      value: receita.categoria.nome,
                      iconColor: categoriaColor,
                      valueWidget: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: categoriaColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: categoriaColor, width: 1.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              categoriaIcon,
                              size: 16,
                              color: categoriaColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              receita.categoria.nome,
                              style: TextStyle(
                                color: categoriaColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 24),

                    // Data
                    _buildInfoRow(
                      icon: Icons.calendar_today,
                      label: 'Data',
                      value: dateFormat.format(receita.data),
                      iconColor: Colors.blue.shade600,
                    ),
                    const Divider(height: 24),

                    // Data de criação
                    _buildInfoRow(
                      icon: Icons.access_time,
                      label: 'Criado em',
                      value: DateFormat(
                        'dd/MM/yyyy \'às\' HH:mm',
                      ).format(receita.criadoEm),
                      iconColor: Colors.grey.shade600,
                    ),

                    // Observações (se houver)
                    if (receita.observacoes != null &&
                        receita.observacoes!.isNotEmpty) ...[
                      const Divider(height: 24),
                      _buildInfoRow(
                        icon: Icons.notes,
                        label: 'Observações',
                        value: receita.observacoes!,
                        iconColor: Colors.amber.shade600,
                        isMultiline: true,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Botão de editar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NovaReceitaPage(transacao: receita),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    Widget? valueWidget,
    bool isMultiline = false,
  }) {
    return Row(
      crossAxisAlignment:
          isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              valueWidget ??
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}
