import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../models/orcamento.dart';
import '../../../../providers/business_provider.dart';

class EtapaLinkWebPage extends StatefulWidget {
  final Orcamento orcamento;

  const EtapaLinkWebPage({super.key, required this.orcamento});

  @override
  State<EtapaLinkWebPage> createState() => _EtapaLinkWebPageState();
}

class _EtapaLinkWebPageState extends State<EtapaLinkWebPage> {
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
                    title: 'Itens do Orçamento',
                    child: _buildItemsListWeb(context),
                  ),
                  const Divider(height: 1),
                  _buildSection(
                    icon: Icons.receipt_long,
                    title: 'Resumo Financeiro',
                    child: _buildResumoFinanceiro(context),
                  ),
                  const Divider(height: 1),
                  if (widget.orcamento.metodoPagamento != null &&
                      widget.orcamento.metodoPagamento!.isNotEmpty) ...[
                    _buildSection(
                      icon: Icons.payment,
                      title: 'Forma de Pagamento',
                      child: _buildPagamentoWeb(context, businessProvider),
                    ),
                    const Divider(height: 1),
                  ],
                  if ((widget.orcamento.laudoTecnico ?? '')
                      .trim()
                      .isNotEmpty) ...[
                    _buildSection(
                      icon: Icons.engineering,
                      title: 'Laudo Técnico',
                      child: _buildTextSection(widget.orcamento.laudoTecnico!),
                    ),
                    const Divider(height: 1),
                  ],
                  if ((widget.orcamento.condicoesContratuais ?? '')
                      .trim()
                      .isNotEmpty) ...[
                    _buildSection(
                      icon: Icons.description,
                      title: 'Condições Contratuais',
                      child: _buildTextSection(
                        widget.orcamento.condicoesContratuais!,
                      ),
                    ),
                    const Divider(height: 1),
                  ],
                  if ((widget.orcamento.garantia ?? '').trim().isNotEmpty) ...[
                    _buildSection(
                      icon: Icons.verified_user,
                      title: 'Garantia',
                      child: _buildTextSection(widget.orcamento.garantia!),
                    ),
                    const Divider(height: 1),
                  ],
                  if ((widget.orcamento.informacoesAdicionais ?? '')
                      .trim()
                      .isNotEmpty) ...[
                    _buildSection(
                      icon: Icons.info_outline,
                      title: 'Informações Adicionais',
                      child: _buildTextSection(
                        widget.orcamento.informacoesAdicionais!,
                      ),
                    ),
                    const Divider(height: 1),
                  ],
                  if (widget.orcamento.fotos != null &&
                      widget.orcamento.fotos!.isNotEmpty) ...[
                    _buildSection(
                      icon: Icons.photo_library,
                      title: 'Fotos',
                      child: _buildFotosGridWeb(context),
                    ),
                    const Divider(height: 1),
                  ],
                  if (businessProvider.assinaturaUrl != null &&
                      businessProvider.assinaturaUrl!.isNotEmpty) ...[
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
                      'Orçamento gerado por',
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
          widget.orcamento.cliente.nome,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (widget.orcamento.cliente.celular.isNotEmpty)
          _buildInfoRow(Icons.phone, widget.orcamento.cliente.celular),
        if (widget.orcamento.cliente.email.isNotEmpty)
          _buildInfoRow(Icons.email, widget.orcamento.cliente.email),
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

    return Column(
      children:
          widget.orcamento.itens.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final nome = item['nome'] as String? ?? 'Item';
            final descricao = item['descricao'] as String? ?? '';
            final preco = double.tryParse(item['preco'].toString()) ?? 0.0;
            final quantidade =
                double.tryParse(item['quantidade'].toString()) ?? 1.0;
            final totalItem = preco * quantidade;

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                border:
                    index < widget.orcamento.itens.length - 1
                        ? Border(
                          bottom: BorderSide(color: Colors.grey.shade200),
                        )
                        : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nome,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (descricao.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            descricao,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'Qtd: ${quantidade.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              currencyFormat.format(totalItem),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildPagamentoWeb(BuildContext context, BusinessProvider bp) {
    final metodo = widget.orcamento.metodoPagamento?.trim() ?? '';
    final parcelas = widget.orcamento.parcelas;

    String label;
    switch (metodo) {
      case 'dinheiro':
        label = 'Dinheiro';
        break;
      case 'pix':
        label = 'Pix';
        break;
      case 'debito':
        label = 'Débito';
        break;
      case 'credito':
        label =
            'Crédito' + ((parcelas ?? 1) > 1 ? ' em ${parcelas}x' : ' à vista');
        break;
      case 'boleto':
        label = 'Boleto';
        break;
      default:
        label = metodo;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        if (metodo == 'pix' &&
            bp.pixChave != null &&
            bp.pixChave!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.qr_code_2, color: Colors.grey.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: SelectableText(
                    'Chave Pix (${bp.pixTipo ?? 'chave'}): ${bp.pixChave!}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextSection(String text) {
    return Text(text, style: const TextStyle(fontSize: 15, height: 1.5));
  }

  Widget _buildFotosGridWeb(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: widget.orcamento.fotos!.length,
      itemBuilder: (context, index) {
        final fotoUrl = widget.orcamento.fotos![index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            fotoUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey.shade200,
                child: const Center(child: CircularProgressIndicator()),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey.shade200,
                child: const Icon(
                  Icons.broken_image,
                  size: 48,
                  color: Colors.grey,
                ),
              );
            },
          ),
        );
      },
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
            currencyFormat.format(widget.orcamento.subtotal),
            color: Colors.grey.shade800,
          ),
          if (widget.orcamento.desconto > 0) ...[
            const SizedBox(height: 12),
            _buildResumoRow(
              'Desconto',
              '- ${currencyFormat.format(widget.orcamento.desconto)}',
              color: const Color(0xFF10B981),
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(thickness: 1.5),
          ),
          _buildResumoRow(
            'VALOR TOTAL',
            currencyFormat.format(widget.orcamento.valorTotal),
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
}
