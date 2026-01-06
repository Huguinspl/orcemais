import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../models/cliente.dart';
import '../../../../providers/business_provider.dart';
import '../../../../providers/user_provider.dart';
import '../../../../utils/color_utils.dart';

/// Utilitário para formatação de documentos e telefones
class _Formatters {
  /// Formata CPF (XXX.XXX.XXX-XX) ou CNPJ (XX.XXX.XXX/XXXX-XX)
  static String formatCpfCnpj(String document) {
    if (document.isEmpty) return '';
    String numbers = document.replaceAll(RegExp(r'\D'), '');
    if (numbers.length == 11) {
      return '${numbers.substring(0, 3)}.${numbers.substring(3, 6)}.${numbers.substring(6, 9)}-${numbers.substring(9)}';
    } else if (numbers.length == 14) {
      return '${numbers.substring(0, 2)}.${numbers.substring(2, 5)}.${numbers.substring(5, 8)}/${numbers.substring(8, 12)}-${numbers.substring(12)}';
    }
    return document;
  }

  /// Formata telefone celular (XX) XXXXX-XXXX ou fixo (XX) XXXX-XXXX
  static String formatPhone(String phone) {
    if (phone.isEmpty) return '';
    String numbers = phone.replaceAll(RegExp(r'\D'), '');
    if (numbers.length == 11) {
      return '(${numbers.substring(0, 2)}) ${numbers.substring(2, 7)}-${numbers.substring(7)}';
    } else if (numbers.length == 10) {
      return '(${numbers.substring(0, 2)}) ${numbers.substring(2, 6)}-${numbers.substring(6)}';
    }
    return phone;
  }
}

class EtapaPdfPage extends StatefulWidget {
  final Cliente cliente;
  final List<Map<String, dynamic>> itens;
  final double subtotal;
  final double desconto;
  final double valorTotal;
  final String? metodoPagamento; // dinheiro, pix, debito, credito, boleto
  final int? parcelas; // quando crédito
  final String? laudoTecnico;
  final String? condicoesContratuais;
  final String? garantia;
  final String? informacoesAdicionais;
  final List<String>? fotos;

  const EtapaPdfPage({
    super.key,
    required this.cliente,
    required this.itens,
    required this.subtotal,
    required this.desconto,
    required this.valorTotal,
    this.metodoPagamento,
    this.parcelas,
    this.laudoTecnico,
    this.condicoesContratuais,
    this.garantia,
    this.informacoesAdicionais,
    this.fotos,
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
    final userProvider = context.watch<UserProvider>();

    // Dados com fallback para dados pessoais
    final nomeExibicao = businessProvider.getNomeExibicao(userProvider.nome);
    final emailExibicao = businessProvider.getEmailExibicao(userProvider.email);
    final documentoExibicao = businessProvider.getDocumentoExibicao(
      userProvider.cpf,
    );

    final theme = businessProvider.pdfTheme;
    // Cores com override do tema salvo - Padrão AZUL
    final cs = _ResolvedColors(
      primary:
          ColorUtils.fromArgbInt(theme?['primary']) ?? const Color(0xFF1565C0),
      onPrimary: ColorUtils.fromArgbInt(theme?['onPrimary']) ?? Colors.white,
      secondaryContainer:
          ColorUtils.fromArgbInt(theme?['secondaryContainer']) ??
          const Color(0xFFE3F2FD),
      onSecondaryContainer:
          ColorUtils.fromArgbInt(theme?['onSecondaryContainer']) ??
          const Color(0xFF0D47A1),
      tertiaryContainer:
          ColorUtils.fromArgbInt(theme?['tertiaryContainer']) ??
          const Color(0xFFBBDEFB),
      onTertiaryContainer:
          ColorUtils.fromArgbInt(theme?['onTertiaryContainer']) ??
          const Color(0xFF1565C0),
      outlineVariant:
          ColorUtils.fromArgbInt(theme?['outlineVariant']) ??
          const Color(0xFF90CAF9),
      laudoBackground:
          ColorUtils.fromArgbInt(theme?['laudoBackground']) ??
          const Color(0xFFE3F2FD),
      laudoText:
          ColorUtils.fromArgbInt(theme?['laudoText']) ??
          const Color(0xFF0D47A1),
      garantiaBackground:
          ColorUtils.fromArgbInt(theme?['garantiaBackground']) ??
          const Color(0xFFE3F2FD),
      garantiaText:
          ColorUtils.fromArgbInt(theme?['garantiaText']) ??
          const Color(0xFF1565C0),
      contratoBackground:
          ColorUtils.fromArgbInt(theme?['contratoBackground']) ??
          const Color(0xFFBBDEFB),
      contratoText:
          ColorUtils.fromArgbInt(theme?['contratoText']) ??
          const Color(0xFF0D47A1),
      fotosBackground:
          ColorUtils.fromArgbInt(theme?['fotosBackground']) ??
          const Color(0xFFE3F2FD),
      fotosText:
          ColorUtils.fromArgbInt(theme?['fotosText']) ??
          const Color(0xFF0D47A1),
      pagamentoBackground:
          ColorUtils.fromArgbInt(theme?['pagamentoBackground']) ??
          const Color(0xFFE3F2FD),
      pagamentoText:
          ColorUtils.fromArgbInt(theme?['pagamentoText']) ??
          const Color(0xFF1565C0),
      valoresBackground:
          ColorUtils.fromArgbInt(theme?['valoresBackground']) ??
          const Color(0xFFE3F2FD),
      valoresText:
          ColorUtils.fromArgbInt(theme?['valoresText']) ??
          const Color(0xFF0D47A1),
    );

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
            // Cabeçalho com faixa colorida
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildHeader(
                    context,
                    businessProvider,
                    textColor: cs.onPrimary,
                    nomeExibicao: nomeExibicao,
                    emailExibicao: emailExibicao,
                    documentoExibicao: documentoExibicao,
                  ),
                ],
              ),
            ),
            if ((businessProvider.descricao ?? '').isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                businessProvider.descricao!,
                style: const TextStyle(color: Colors.black87),
              ),
            ],
            const Divider(height: 40, thickness: 1),
            _sectionLabel(
              context,
              'Dados do Cliente',
              bg: cs.secondaryContainer,
              fg: cs.onSecondaryContainer,
            ),
            const SizedBox(height: 12),
            _buildClientInfo(context),
            const SizedBox(height: 24),
            _sectionLabel(
              context,
              'Itens do Orçamento',
              bg: cs.tertiaryContainer,
              fg: cs.onTertiaryContainer,
            ),
            const SizedBox(height: 16),
            _buildItemsList(context), // Trocamos a tabela por uma lista
            const SizedBox(height: 24),
            // Secção de pagamento para paridade com o PDF gerado
            _sectionLabel(
              context,
              'Condições de pagamento',
              bg: cs.pagamentoBackground,
              fg: cs.pagamentoText,
            ),
            const SizedBox(height: 8),
            _buildPagamentoSection(context, businessProvider),
            const SizedBox(height: 24),
            if ((widget.laudoTecnico ?? '').trim().isNotEmpty) ...[
              _sectionLabel(
                context,
                'Laudo técnico',
                bg: cs.laudoBackground,
                fg: cs.laudoText,
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Text(
                  widget.laudoTecnico!,
                  style: const TextStyle(fontSize: 13),
                  softWrap: true,
                ),
              ),
            ],
            if ((widget.condicoesContratuais ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 24),
              _sectionLabel(
                context,
                'Condições contratuais',
                bg: cs.contratoBackground,
                fg: cs.contratoText,
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Text(
                  widget.condicoesContratuais!,
                  style: const TextStyle(fontSize: 13),
                  softWrap: true,
                ),
              ),
            ],
            if ((widget.garantia ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 24),
              _sectionLabel(
                context,
                'Garantia',
                bg: cs.garantiaBackground,
                fg: cs.garantiaText,
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Text(
                  widget.garantia!,
                  style: const TextStyle(fontSize: 13),
                  softWrap: true,
                ),
              ),
            ],
            if ((widget.informacoesAdicionais ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 24),
              _sectionLabel(
                context,
                'Informações adicionais',
                bg: cs.tertiaryContainer,
                fg: cs.onTertiaryContainer,
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Text(
                  widget.informacoesAdicionais!,
                  style: const TextStyle(fontSize: 13),
                  softWrap: true,
                ),
              ),
            ],
            if (widget.fotos != null && widget.fotos!.isNotEmpty) ...[
              const SizedBox(height: 24),
              _sectionLabel(
                context,
                'Fotos do Orçamento',
                bg: cs.fotosBackground,
                fg: cs.fotosText,
              ),
              const SizedBox(height: 8),
              _buildFotosGrid(context, cs.outlineVariant),
            ],
            const SizedBox(height: 24),
            // Caixa de totais com destaque
            Container(
              decoration: BoxDecoration(
                color: cs.valoresBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outlineVariant),
              ),
              padding: const EdgeInsets.all(16),
              child: _buildTotals(context, textColor: cs.valoresText),
            ),
            const SizedBox(height: 24),
            _buildAssinaturaSection(context, businessProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildPagamentoSection(BuildContext context, BusinessProvider bp) {
    final metodo = widget.metodoPagamento?.trim() ?? '';
    final parcelas = widget.parcelas;
    if (metodo.isEmpty) {
      return Text(
        'Não informado',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
      );
    }

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

    final children = <Widget>[
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Forma de pagamento:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(label),
        ],
      ),
    ];

    if (metodo == 'pix' && bp.pixChave != null && bp.pixChave!.isNotEmpty) {
      final tipo = bp.pixTipo ?? 'chave';
      children.add(const SizedBox(height: 6));
      children.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.qr_code_2_outlined, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: SelectableText(
                'Chave Pix (${tipo}): ${bp.pixChave!}',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
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
            final preco = double.tryParse(item['preco'].toString()) ?? 0.0;
            final quantidade =
                double.tryParse(item['quantidade'].toString()) ?? 1.0;
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

  Widget _buildHeader(
    BuildContext context,
    BusinessProvider provider, {
    Color? textColor,
    required String nomeExibicao,
    required String emailExibicao,
    required String documentoExibicao,
  }) {
    return FutureBuilder<Uint8List?>(
      future: provider.getLogoBytes(),
      builder: (context, snap) {
        final logoBytes = snap.data;
        print(logoBytes?.length);
        Widget? logo;
        if (logoBytes != null && logoBytes.isNotEmpty) {
          logo = Image.memory(logoBytes, fit: BoxFit.contain);
        } else if (provider.logoUrl != null && provider.logoUrl!.isNotEmpty) {
          // Fallback: mostra via URL enquanto os bytes não chegam
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
                    nomeExibicao,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  if (provider.ramo.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        provider.ramo,
                        style: TextStyle(
                          color: textColor?.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (provider.telefone.isNotEmpty)
                    _buildInfoLinha(
                      Icons.phone_outlined,
                      provider.telefone,
                      color: textColor,
                    ),
                  if (emailExibicao.isNotEmpty)
                    _buildInfoLinha(
                      Icons.email_outlined,
                      emailExibicao,
                      color: textColor,
                    ),
                  if (provider.endereco.isNotEmpty)
                    _buildInfoLinha(
                      Icons.location_on_outlined,
                      provider.endereco,
                      color: textColor,
                    ),
                  if (documentoExibicao.isNotEmpty)
                    _buildInfoLinha(
                      Icons.badge_outlined,
                      _Formatters.formatCpfCnpj(documentoExibicao),
                      color: textColor,
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoLinha(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color ?? Colors.grey.shade700),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: color))),
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
        if (widget.cliente.celular.isNotEmpty)
          _buildClientInfoRow(
            Icons.phone_android_outlined,
            _Formatters.formatPhone(widget.cliente.celular),
          ),
        if (widget.cliente.telefone.isNotEmpty)
          _buildClientInfoRow(
            Icons.phone_outlined,
            _Formatters.formatPhone(widget.cliente.telefone),
          ),
        if (widget.cliente.email.isNotEmpty)
          _buildClientInfoRow(Icons.email_outlined, widget.cliente.email),
        if (widget.cliente.cpfCnpj.isNotEmpty)
          _buildClientInfoRow(
            Icons.badge_outlined,
            _Formatters.formatCpfCnpj(widget.cliente.cpfCnpj),
          ),
        if (widget.cliente.observacoes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Observações:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.cliente.observacoes,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildClientInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: Colors.grey.shade800)),
          ),
        ],
      ),
    );
  }

  Widget _buildTotals(BuildContext context, {Color? textColor}) {
    final color = textColor ?? Colors.black87;
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );
    double custoTotal = 0.0;
    for (var item in widget.itens) {
      final custo = double.tryParse(item['custo'].toString()) ?? 0.0;
      custoTotal += custo;
    }
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _totalRow(
              'Subtotal',
              currencyFormat.format(widget.subtotal),
              color: color,
            ),
            if (custoTotal > 0)
              _totalRow(
                'Custos Adicionais',
                currencyFormat.format(custoTotal),
                color: color,
              ),
            if (widget.desconto > 0)
              _totalRow(
                'Desconto',
                '- ${currencyFormat.format(widget.desconto)}',
                color: color,
              ),
            Divider(height: 20, color: color),
            _totalRow(
              'Valor Total',
              currencyFormat.format(widget.valorTotal),
              isTotal: true,
              color: color,
            ),
          ],
        ),
      ),
    );
  }

  // Removido: _tableHeader não é mais utilizado após migrar para lista flexível de itens.
  Widget _totalRow(
    String label,
    String value, {
    bool isTotal = false,
    Color? color,
  }) {
    final textColor = color ?? Colors.black87;
    final style = TextStyle(
      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
      fontSize: isTotal ? 16 : 14,
      color: textColor,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }

  Widget _sectionLabel(
    BuildContext context,
    String text, {
    required Color bg,
    required Color fg,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildAssinaturaSection(
    BuildContext context,
    BusinessProvider provider,
  ) {
    // Se não houver assinatura cadastrada, não exibe a seção
    if (provider.assinaturaUrl == null || provider.assinaturaUrl!.isEmpty) {
      return const SizedBox.shrink();
    }
    return FutureBuilder<Uint8List?>(
      future: provider.getAssinaturaBytes(),
      builder: (context, snap) {
        Widget? assinatura;
        if (snap.hasData && snap.data != null) {
          assinatura = Image.memory(snap.data!, fit: BoxFit.contain);
        } else if (provider.assinaturaUrl != null &&
            provider.assinaturaUrl!.isNotEmpty) {
          // Fallback por URL com pequeno cache-buster
          final url = provider.assinaturaUrl!;
          final sep = url.contains('?') ? '&' : '?';
          final busted = '$url${sep}t=${DateTime.now().millisecondsSinceEpoch}';
          assinatura = Image.network(
            busted,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          );
        }
        if (assinatura == null) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 80, child: Center(child: assinatura)),
            Container(
              height: 1,
              color: Colors.grey.shade400,
              margin: const EdgeInsets.symmetric(horizontal: 80, vertical: 8),
            ),
            Text(
              'Assinatura',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFotosGrid(BuildContext context, Color borderColor) {
    if (widget.fotos == null || widget.fotos!.isEmpty) {
      return const SizedBox.shrink();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: widget.fotos!.length,
      itemBuilder: (context, index) {
        final fotoUrl = widget.fotos![index];
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.network(
            fotoUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value:
                      loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
              );
            },
          ),
        );
      },
    );
  }
}

class _ResolvedColors {
  final Color primary;
  final Color onPrimary;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color tertiaryContainer;
  final Color onTertiaryContainer;
  final Color outlineVariant;
  final Color laudoBackground;
  final Color laudoText;
  final Color garantiaBackground;
  final Color garantiaText;
  final Color contratoBackground;
  final Color contratoText;
  final Color fotosBackground;
  final Color fotosText;
  final Color pagamentoBackground;
  final Color pagamentoText;
  final Color valoresBackground;
  final Color valoresText;

  const _ResolvedColors({
    required this.primary,
    required this.onPrimary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.tertiaryContainer,
    required this.onTertiaryContainer,
    required this.outlineVariant,
    required this.laudoBackground,
    required this.laudoText,
    required this.garantiaBackground,
    required this.garantiaText,
    required this.contratoBackground,
    required this.contratoText,
    required this.fotosBackground,
    required this.fotosText,
    required this.pagamentoBackground,
    required this.pagamentoText,
    required this.valoresBackground,
    required this.valoresText,
  });
}
