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
    // Usamos 'watch' para que a tela seja redesenhada quando os dados do negócio chegarem.
    final businessProvider = context.watch<BusinessProvider>();

    // Carregar cores personalizadas do PDF ou usar padrão laranja
    final theme = businessProvider.pdfTheme;
    final primaryColor =
        theme != null && theme['primary'] != null
            ? Color(theme['primary'] as int)
            : Colors.orange.shade600;
    final secondaryContainerColor =
        theme != null && theme['secondaryContainer'] != null
            ? Color(theme['secondaryContainer'] as int)
            : Colors.orange.shade50;
    final tertiaryContainerColor =
        theme != null && theme['tertiaryContainer'] != null
            ? Color(theme['tertiaryContainer'] as int)
            : Colors.orange.shade100;
    final onSecondaryContainerColor =
        theme != null && theme['onSecondaryContainer'] != null
            ? Color(theme['onSecondaryContainer'] as int)
            : Colors.orange.shade900;
    final onTertiaryContainerColor =
        theme != null && theme['onTertiaryContainer'] != null
            ? Color(theme['onTertiaryContainer'] as int)
            : Colors.orange.shade900;

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
            // Mostra um indicador de carregamento enquanto os dados do negócio não chegam.
            if (businessProvider.nomeEmpresa.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              // Cabeçalho com faixa colorida personalizada
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildHeader(context, businessProvider),
              ),
              if ((businessProvider.descricao ?? '').isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  businessProvider.descricao!,
                  style: const TextStyle(color: Colors.black87),
                ),
              ],
            ],

            const Divider(height: 40, thickness: 1),
            _sectionLabel(
              'Dados do Cliente',
              bg: secondaryContainerColor,
              fg: onSecondaryContainerColor,
            ),
            const SizedBox(height: 12),
            _buildClientInfo(context),
            const SizedBox(height: 24),
            _sectionLabel(
              'Itens do Recibo',
              bg: tertiaryContainerColor,
              fg: onTertiaryContainerColor,
            ),
            const SizedBox(height: 16),
            _buildItemsList(context),
            const SizedBox(height: 24),
            // Caixa de totais com destaque personalizado
            Container(
              decoration: BoxDecoration(
                color: secondaryContainerColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withOpacity(0.3)),
              ),
              padding: const EdgeInsets.all(16),
              child: _buildTotals(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, BusinessProvider provider) {
    return FutureBuilder<Uint8List?>(
      future: provider.getLogoBytes(),
      builder: (context, snap) {
        final logoBytes = snap.data;
        Widget? logo;
        if (logoBytes != null && logoBytes.isNotEmpty) {
          logo = Image.memory(logoBytes, fit: BoxFit.contain);
        } else if (provider.logoUrl != null && provider.logoUrl!.isNotEmpty) {
          logo = Image.network(provider.logoUrl!, fit: BoxFit.contain);
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (logo != null)
              Container(
                width: 60,
                height: 60,
                margin: const EdgeInsets.only(right: 12),
                child: logo,
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.nomeEmpresa.isNotEmpty
                        ? provider.nomeEmpresa
                        : 'Minha Empresa',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (provider.telefone.isNotEmpty)
                    _buildInfoLinha(Icons.phone_outlined, provider.telefone),
                  if (provider.emailEmpresa.isNotEmpty)
                    _buildInfoLinha(
                      Icons.email_outlined,
                      provider.emailEmpresa,
                    ),
                  if (provider.endereco.isNotEmpty)
                    _buildInfoLinha(
                      Icons.location_on_outlined,
                      provider.endereco,
                    ),
                  if (provider.cnpj.isNotEmpty)
                    _buildInfoLinha(Icons.badge_outlined, provider.cnpj),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoLinha(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildClientInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cliente:',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        Text(
          widget.recibo.cliente.nome,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        if (widget.recibo.cliente.celular.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(widget.recibo.cliente.celular),
        ],
        if (widget.recibo.cliente.email.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(widget.recibo.cliente.email),
        ],
      ],
    );
  }

  Widget _buildItemsList(BuildContext context) {
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

  Widget _buildTotals(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 220,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (widget.recibo.itens.isNotEmpty)
              _totalRow(
                'Subtotal',
                currencyFormat.format(widget.recibo.subtotalItens),
              ),
            const Divider(height: 20),
            _totalRow(
              'Valor Total',
              currencyFormat.format(widget.recibo.valorTotal),
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, {required Color bg, required Color fg}) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        text,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

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
