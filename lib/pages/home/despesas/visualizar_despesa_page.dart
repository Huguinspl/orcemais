import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/receita.dart';
import 'nova_despesa_page.dart';

class VisualizarDespesaPage extends StatelessWidget {
  final Transacao despesa;

  const VisualizarDespesaPage({super.key, required this.despesa});

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
    switch (despesa.categoria) {
      case CategoriaTransacao.fornecedores:
        categoriaColor = Colors.blue;
        categoriaIcon = Icons.local_shipping_outlined;
        break;
      case CategoriaTransacao.salarios:
        categoriaColor = Colors.purple;
        categoriaIcon = Icons.people_outlined;
        break;
      case CategoriaTransacao.aluguel:
        categoriaColor = Colors.orange;
        categoriaIcon = Icons.home_outlined;
        break;
      case CategoriaTransacao.marketing:
        categoriaColor = Colors.pink;
        categoriaIcon = Icons.campaign_outlined;
        break;
      case CategoriaTransacao.equipamentos:
        categoriaColor = Colors.teal;
        categoriaIcon = Icons.computer_outlined;
        break;
      case CategoriaTransacao.impostos:
        categoriaColor = Colors.brown;
        categoriaIcon = Icons.receipt_long_outlined;
        break;
      case CategoriaTransacao.utilities:
        categoriaColor = Colors.cyan;
        categoriaIcon = Icons.lightbulb_outlined;
        break;
      case CategoriaTransacao.manutencao:
        categoriaColor = Colors.amber;
        categoriaIcon = Icons.build_outlined;
        break;
      default:
        categoriaColor = Colors.grey;
        categoriaIcon = Icons.category_outlined;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detalhes da Despesa',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade600, Colors.red.shade400],
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
            colors: [Colors.red.shade50, Colors.white, Colors.white],
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
                    colors: [Colors.red.shade500, Colors.red.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.shade300,
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.arrow_downward_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Valor Gasto',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currencyFormat.format(despesa.valor),
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

              // Informações da despesa
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
                      value: despesa.descricao,
                      iconColor: Colors.red.shade600,
                    ),
                    const Divider(height: 24),

                    // Categoria
                    _buildInfoRow(
                      icon: categoriaIcon,
                      label: 'Categoria',
                      value: despesa.categoria.nome,
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
                              despesa.categoria.nome,
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
                      value: dateFormat.format(despesa.data),
                      iconColor: Colors.blue.shade600,
                    ),
                    const Divider(height: 24),

                    // Data de criação
                    _buildInfoRow(
                      icon: Icons.access_time,
                      label: 'Criado em',
                      value: DateFormat(
                        'dd/MM/yyyy \'às\' HH:mm',
                      ).format(despesa.criadoEm),
                      iconColor: Colors.grey.shade600,
                    ),

                    // Observações (se houver)
                    if (despesa.observacoes != null &&
                        despesa.observacoes!.isNotEmpty) ...[
                      const Divider(height: 24),
                      _buildInfoRow(
                        icon: Icons.notes,
                        label: 'Observações',
                        value: despesa.observacoes!,
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
                        builder: (_) => NovaDespesaPage(transacao: despesa),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
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
