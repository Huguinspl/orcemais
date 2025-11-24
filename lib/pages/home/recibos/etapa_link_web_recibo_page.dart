import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/recibo.dart';
import '../../../providers/business_provider.dart';

class EtapaLinkWebReciboPage extends StatefulWidget {
  final Recibo recibo;

  const EtapaLinkWebReciboPage({super.key, required this.recibo});

  @override
  State<EtapaLinkWebReciboPage> createState() => _EtapaLinkWebReciboPageState();
}

class _EtapaLinkWebReciboPageState extends State<EtapaLinkWebReciboPage> {
  @override
  void initState() {
    super.initState();
    // Garante que os dados do negócio sejam carregados, caso ainda não tenham sido.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BusinessProvider>().carregarDoFirestore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final businessProvider = context.watch<BusinessProvider>();
    final primaryColor = Color(0xFF1976D2);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              child:
                  businessProvider.nomeEmpresa.isEmpty
                      ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                      : _buildHeaderWeb(context, businessProvider),
            ),
            Container(
              constraints: const BoxConstraints(maxWidth: 900),
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSection(
                    icon: Icons.person_outline,
                    title: 'Dados do Cliente',
                    child: _buildClientInfoWeb(context),
                  ),
                  const Divider(height: 1),
                  _buildSection(
                    icon: Icons.list_alt,
                    title: 'Itens do Recibo',
                    child: _buildItemsListWeb(context),
                  ),
                  const Divider(height: 1),
                  _buildSection(
                    icon: Icons.receipt_long,
                    title: 'Resumo Financeiro',
                    child: _buildResumoFinanceiro(context),
                  ),
                  if (businessProvider.assinaturaUrl != null &&
                      businessProvider.assinaturaUrl!.isNotEmpty) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: _buildAssinaturaWeb(context, businessProvider),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              color: Colors.grey.shade100,
              child: Center(
                child: Column(
                  children: [
                    Text(
                      'Recibo gerado por',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      businessProvider.nomeEmpresa,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 24, color: Colors.grey.shade700),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildHeaderWeb(BuildContext context, BusinessProvider provider) {
    return FutureBuilder<Uint8List?>(
      future: provider.getLogoBytes(),
      builder: (context, snap) {
        final logoBytes = snap.data;
        Widget? logo;
        if (logoBytes != null && logoBytes.isNotEmpty) {
          logo = Image.memory(logoBytes, fit: BoxFit.contain, height: 80);
        } else if (provider.logoUrl != null && provider.logoUrl!.isNotEmpty) {
          logo = Image.network(
            provider.logoUrl!,
            fit: BoxFit.contain,
            height: 80,
          );
        }

        return Center(
          child: Column(
            children: [
              if (logo != null) ...[
                Container(
                  height: 80,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: logo,
                ),
              ],
              Text(
                provider.nomeEmpresa,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              if (provider.telefone.isNotEmpty ||
                  provider.emailEmpresa.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    if (provider.telefone.isNotEmpty)
                      _buildHeaderInfo(Icons.phone, provider.telefone),
                    if (provider.emailEmpresa.isNotEmpty)
                      _buildHeaderInfo(Icons.email, provider.emailEmpresa),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 14, color: Colors.white70)),
      ],
    );
  }

  Widget _buildClientInfoWeb(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.recibo.cliente.nome,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (widget.recibo.cliente.celular.isNotEmpty)
          _buildInfoRow(Icons.phone, widget.recibo.cliente.celular),
        if (widget.recibo.cliente.email.isNotEmpty)
          _buildInfoRow(Icons.email, widget.recibo.cliente.email),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildItemsListWeb(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    final businessProvider = context.watch<BusinessProvider>();
    final theme = businessProvider.pdfTheme;
    final primaryColor =
        theme != null && theme['primary'] != null
            ? Color(theme['primary'] as int)
            : Colors.orange.shade600;

    return Column(
      children: List.generate(widget.recibo.itens.length, (index) {
        final item = widget.recibo.itens[index];
        final nome = item['nome'] ?? 'Item';
        final descricao = item['descricao'] as String? ?? '';
        final preco = (item['preco'] ?? 0).toDouble();
        final quantidade = (item['quantidade'] ?? 1).toDouble();
        final totalItem = preco * quantidade;

        return Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: primaryColor.withOpacity(0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header do item com gradiente
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryColor.withOpacity(0.1),
                          primaryColor.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            nome,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Corpo do item
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (descricao.isNotEmpty) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.description_outlined,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  descricao,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                        // Informações em linha
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoChip(
                                icon: Icons.shopping_basket_outlined,
                                label: 'Quantidade',
                                value: quantidade.toStringAsFixed(2),
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInfoChip(
                                icon: Icons.attach_money,
                                label: 'Valor Unit.',
                                value: currencyFormat.format(preco),
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        // Total do item em destaque
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total do Item',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            Text(
                              currencyFormat.format(totalItem),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (index < widget.recibo.itens.length - 1)
              const SizedBox(height: 16),
          ],
        );
      }),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoFinanceiro(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildResumoRow(
            'Subtotal',
            currencyFormat.format(widget.recibo.subtotalItens),
            color: Colors.grey.shade800,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(thickness: 1.5),
          ),
          _buildResumoRow(
            'VALOR TOTAL',
            currencyFormat.format(widget.recibo.valorTotal),
            isBold: true,
            fontSize: 24,
            color: Color(0xFF1976D2),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 16,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildAssinaturaWeb(BuildContext context, BusinessProvider provider) {
    return FutureBuilder<Uint8List?>(
      future: provider.getAssinaturaBytes(),
      builder: (context, snap) {
        Widget? assinatura;
        if (snap.hasData && snap.data != null) {
          assinatura = Image.memory(
            snap.data!,
            height: 80,
            fit: BoxFit.contain,
          );
        } else if (provider.assinaturaUrl != null &&
            provider.assinaturaUrl!.isNotEmpty) {
          assinatura = Image.network(
            provider.assinaturaUrl!,
            height: 80,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          );
        }
        if (assinatura == null) return const SizedBox.shrink();

        return Column(
          children: [
            assinatura,
            const SizedBox(height: 8),
            Container(height: 2, width: 200, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(
              'Assinatura',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        );
      },
    );
  }
}
