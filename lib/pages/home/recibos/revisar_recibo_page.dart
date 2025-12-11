import 'dart:typed_data';
import 'package:deep_link/models/link_model.dart';
import 'package:deep_link/services/link_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/recibo.dart';
import '../../../providers/business_provider.dart';
import '../../../providers/recibos_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../utils/color_utils.dart';
import 'compartilhar_recibo_page.dart';
import 'etapa_link_web_recibo_page.dart';

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

/// Cores resolvidas para o tema do PDF
class _ResolvedColors {
  final Color primary;
  final Color onPrimary;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color tertiaryContainer;
  final Color onTertiaryContainer;
  final Color outlineVariant;
  final Color valoresBackground;
  final Color valoresText;

  _ResolvedColors({
    required this.primary,
    required this.onPrimary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.tertiaryContainer,
    required this.onTertiaryContainer,
    required this.outlineVariant,
    required this.valoresBackground,
    required this.valoresText,
  });
}

class RevisarReciboPage extends StatefulWidget {
  final Recibo recibo;
  const RevisarReciboPage({super.key, required this.recibo});

  @override
  State<RevisarReciboPage> createState() => _RevisarReciboPageState();
}

class _RevisarReciboPageState extends State<RevisarReciboPage> {
  int _abaSelecionada = 0; // 0 PDF, 1 Link Web

  Future<void> _gerarENavegar() async {
    try {
      // Mostra loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final businessProvider = context.read<BusinessProvider>();
      final userProvider = context.read<UserProvider>();
      final recibosProvider = context.read<RecibosProvider>();

      String? linkFinal;

      // Verifica se o recibo já tem um link salvo
      if (widget.recibo.link != null && widget.recibo.link!.isNotEmpty) {
        // Link já existe, usa o link existente
        linkFinal = widget.recibo.link;
        debugPrint('🔗 Link já existe, usando link existente: $linkFinal');
      } else {
        // Prepara parâmetros personalizados
        final parametrosPersonalizados = <String, dynamic>{
          'userId': userProvider.uid,
          'documentoId': widget.recibo.id,
          'tipoDocumento': 'recibo',
        };

        // Gera o link
        final link = await DeepLink.createLink(
          LinkModel(
            dominio: 'link.orcemais.com',
            titulo:
                'Recibo ${widget.recibo.numero} - ${businessProvider.nomeEmpresa}',
            slug: widget.recibo.id,
            onlyWeb: true,
            urlImage: businessProvider.logoUrl,
            urlDesktop: 'https://gestorfy-cliente.web.app',
            parametrosPersonalizados: parametrosPersonalizados,
          ),
        );

        linkFinal = link.link;

        // Salva o link no Firestore
        await recibosProvider.atualizarLink(widget.recibo.id, linkFinal);
        debugPrint('✅ Novo link gerado e salvo: $linkFinal');
      }

      // Fecha o loading
      if (mounted) Navigator.pop(context);

      // Navega para a página de compartilhar com o recibo atualizado
      if (mounted) {
        // Busca o recibo atualizado da lista
        final reciboAtualizado = recibosProvider.recibos.firstWhere(
          (r) => r.id == widget.recibo.id,
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CompartilharReciboPage(recibo: reciboAtualizado),
          ),
        );
      }
    } catch (e) {
      // Fecha o loading
      if (mounted) Navigator.pop(context);

      debugPrint('Erro ao gerar link: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar link: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final recibo = widget.recibo;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Revisar Recibo',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade600, Colors.teal.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _mostrarInfoRecibo(context, recibo, currency),
            tooltip: 'Informações do Recibo',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildAbasDeExportacao(),
          Expanded(
            child:
                _abaSelecionada == 0
                    ? _buildPdfVisualizado(currency)
                    : _buildLinkWeb(),
          ),
        ],
      ),
      bottomNavigationBar: _buildRodapeRevisao(currency),
    );
  }

  Widget _buildAbasDeExportacao() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: SegmentedButton<int>(
          segments: [
            ButtonSegment(
              value: 0,
              icon: Icon(
                Icons.picture_as_pdf_outlined,
                color:
                    _abaSelecionada == 0 ? Colors.white : Colors.teal.shade600,
              ),
              label: Text(
                'PDF',
                style: TextStyle(
                  color:
                      _abaSelecionada == 0
                          ? Colors.white
                          : Colors.teal.shade600,
                ),
              ),
            ),
            ButtonSegment(
              value: 1,
              icon: Icon(
                Icons.link,
                color:
                    _abaSelecionada == 1 ? Colors.white : Colors.teal.shade600,
              ),
              label: Text(
                'Link Web',
                style: TextStyle(
                  color:
                      _abaSelecionada == 1
                          ? Colors.white
                          : Colors.teal.shade600,
                ),
              ),
            ),
          ],
          selected: {_abaSelecionada},
          onSelectionChanged: (s) => setState(() => _abaSelecionada = s.first),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.teal.shade600;
              }
              return Colors.transparent;
            }),
            side: WidgetStateProperty.all(BorderSide.none),
          ),
        ),
      ),
    );
  }

  Widget _buildPdfVisualizado(NumberFormat currency) {
    final recibo = widget.recibo;
    final businessProvider = context.watch<BusinessProvider>();
    final csBase = Theme.of(context).colorScheme;
    final theme = businessProvider.pdfTheme;

    // Cores com override do tema salvo (igual ao orçamento)
    final cs = _ResolvedColors(
      primary: ColorUtils.fromArgbInt(theme?['primary']) ?? csBase.primary,
      onPrimary:
          ColorUtils.fromArgbInt(theme?['onPrimary']) ?? csBase.onPrimary,
      secondaryContainer:
          ColorUtils.fromArgbInt(theme?['secondaryContainer']) ??
          csBase.secondaryContainer,
      onSecondaryContainer:
          ColorUtils.fromArgbInt(theme?['onSecondaryContainer']) ??
          csBase.onSecondaryContainer,
      tertiaryContainer:
          ColorUtils.fromArgbInt(theme?['tertiaryContainer']) ??
          csBase.tertiaryContainer,
      onTertiaryContainer:
          ColorUtils.fromArgbInt(theme?['onTertiaryContainer']) ??
          csBase.onTertiaryContainer,
      outlineVariant:
          ColorUtils.fromArgbInt(theme?['outlineVariant']) ??
          csBase.outlineVariant,
      valoresBackground:
          ColorUtils.fromArgbInt(theme?['valoresBackground']) ??
          const Color(0xFFE0F2F1),
      valoresText:
          ColorUtils.fromArgbInt(theme?['valoresText']) ??
          const Color(0xFF004D40),
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
            // Cabeçalho com faixa colorida personalizada
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  (businessProvider.nomeEmpresa.isEmpty)
                      ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      )
                      : _buildHeaderRecibo(
                        businessProvider,
                        textColor: cs.onPrimary,
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
            _sectionLabelRecibo(
              'Recebido de',
              bg: cs.secondaryContainer,
              fg: cs.onSecondaryContainer,
            ),
            const SizedBox(height: 12),
            _buildClientInfoRecibo(),
            const SizedBox(height: 24),

            // Itens ou Valores Recebidos
            if (recibo.itens.isNotEmpty) ...[
              _sectionLabelRecibo(
                'Itens / Serviços',
                bg: cs.tertiaryContainer,
                fg: cs.onTertiaryContainer,
              ),
              const SizedBox(height: 16),
              _buildItensListRecibo(currency),
            ] else ...[
              _sectionLabelRecibo(
                'Valores Recebidos',
                bg: cs.tertiaryContainer,
                fg: cs.onTertiaryContainer,
              ),
              const SizedBox(height: 16),
              _buildValoresRecebidosRecibo(currency),
            ],

            const SizedBox(height: 24),
            // Caixa de totais com destaque personalizado
            Container(
              decoration: BoxDecoration(
                color: cs.valoresBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outlineVariant),
              ),
              padding: const EdgeInsets.all(16),
              child: _buildTotalsRecibo(currency),
            ),

            const SizedBox(height: 24),
            const SizedBox(height: 24),
            _buildAssinaturaSectionRecibo(businessProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildAssinaturaSectionRecibo(BusinessProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabelRecibo(
          'Assinatura',
          bg: Colors.grey.shade200,
          fg: Colors.grey.shade800,
        ),
        const SizedBox(height: 16),
        FutureBuilder<Uint8List?>(
          future: provider.getAssinaturaBytes(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            final assinaturaBytes = snap.data;
            final hasAssinatura =
                assinaturaBytes != null && assinaturaBytes.isNotEmpty;

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  if (hasAssinatura) ...[
                    Image.memory(
                      assinaturaBytes,
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 8),
                  ] else ...[
                    Container(
                      height: 60,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade400),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    provider.nomeEmpresa,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (provider.cnpj.isNotEmpty)
                    Text(
                      _Formatters.formatCpfCnpj(provider.cnpj),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLinkWeb() {
    return EtapaLinkWebReciboPage(recibo: widget.recibo);
  }

  Widget _buildHeaderRecibo(BusinessProvider provider, {Color? textColor}) {
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
                    _buildInfoLinhaRecibo(
                      Icons.phone_outlined,
                      _Formatters.formatPhone(provider.telefone),
                      color: textColor,
                    ),
                  if (provider.emailEmpresa.isNotEmpty)
                    _buildInfoLinhaRecibo(
                      Icons.email_outlined,
                      provider.emailEmpresa,
                      color: textColor,
                    ),
                  if (provider.endereco.isNotEmpty)
                    _buildInfoLinhaRecibo(
                      Icons.location_on_outlined,
                      provider.endereco,
                      color: textColor,
                    ),
                  if (provider.cnpj.isNotEmpty)
                    _buildInfoLinhaRecibo(
                      Icons.badge_outlined,
                      _Formatters.formatCpfCnpj(provider.cnpj),
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

  Widget _buildInfoLinhaRecibo(IconData icon, String text, {Color? color}) {
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

  Widget _buildClientInfoRecibo() {
    final recibo = widget.recibo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cliente:', style: Theme.of(context).textTheme.bodySmall),
        Text(
          recibo.cliente.nome,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (recibo.cliente.celular.isNotEmpty)
          _buildClientInfoRow(
            Icons.phone_android_outlined,
            _Formatters.formatPhone(recibo.cliente.celular),
          ),
        if (recibo.cliente.email.isNotEmpty)
          _buildClientInfoRow(Icons.email_outlined, recibo.cliente.email),
        if (recibo.cliente.cpfCnpj.isNotEmpty)
          _buildClientInfoRow(
            Icons.badge_outlined,
            _Formatters.formatCpfCnpj(recibo.cliente.cpfCnpj),
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

  Widget _buildItensListRecibo(NumberFormat currency) {
    final recibo = widget.recibo;

    return Column(
      children: List.generate(recibo.itens.length, (index) {
        final item = recibo.itens[index];
        final nome = item['nome'] ?? 'Item';
        final descricao = item['descricao'] as String? ?? '';
        final preco = (item['preco'] ?? 0).toDouble();
        final quantidade = (item['quantidade'] ?? 1).toDouble();
        final totalItem = preco * quantidade;

        return Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300, width: 0.5),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nome,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            if (descricao.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  descricao,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 60,
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Text(
                              'Qtd.',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              quantidade.toStringAsFixed(2),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 90,
                        alignment: Alignment.centerRight,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              currency.format(totalItem),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (index < recibo.itens.length - 1) const SizedBox(height: 10),
          ],
        );
      }),
    );
  }

  Widget _buildValoresRecebidosRecibo(NumberFormat currency) {
    final recibo = widget.recibo;
    final businessProvider = context.watch<BusinessProvider>();

    // Carregar cor personalizada
    final theme = businessProvider.pdfTheme;
    final primaryColor =
        theme != null && theme['primary'] != null
            ? Color(theme['primary'] as int)
            : Colors.teal.shade600;

    return Column(
      children: List.generate(recibo.valoresRecebidos.length, (index) {
        final valor = recibo.valoresRecebidos[index];

        return Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300, width: 0.5),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currency.format(valor.valor),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${DateFormat('dd/MM/yyyy').format(valor.data.toDate())} - ${valor.formaPagamento}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.payment, color: primaryColor, size: 24),
                ],
              ),
            ),
            if (index < recibo.valoresRecebidos.length - 1)
              const SizedBox(height: 10),
          ],
        );
      }),
    );
  }

  Widget _buildTotalsRecibo(NumberFormat currency) {
    final recibo = widget.recibo;
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 220,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (recibo.itens.isNotEmpty)
              _totalRowRecibo(
                'Subtotal Itens',
                currency.format(recibo.subtotalItens),
              ),
            if (recibo.valoresRecebidos.isNotEmpty && recibo.itens.isEmpty)
              _totalRowRecibo(
                'Total Recebido',
                currency.format(recibo.totalValoresRecebidos),
              ),
            const Divider(height: 20),
            _totalRowRecibo(
              'Valor Pago',
              currency.format(recibo.valorTotal),
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalRowRecibo(String label, String value, {bool isTotal = false}) {
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

  Widget _sectionLabelRecibo(
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
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  Widget _buildRodapeRevisao(NumberFormat currency) {
    final recibo = widget.recibo;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicador visual
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Card do total
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade600, Colors.teal.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.teal.shade700, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.shade200,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.attach_money,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Valor Total',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Text(
                  currency.format(recibo.valorTotal),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Botões de ação
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.teal.shade600, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Voltar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.teal.shade600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade600, Colors.green.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.shade200,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _gerarENavegar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Enviar Recibo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Dialog com informações do recibo
  void _mostrarInfoRecibo(
    BuildContext context,
    Recibo recibo,
    NumberFormat currency,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            contentPadding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header com gradiente
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.teal.shade600, Colors.teal.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Text(
                        'Informações do Recibo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                // Conteúdo
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        'Número',
                        '#${recibo.numero.toString().padLeft(4, '0')}',
                        Icons.tag,
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        'Cliente',
                        recibo.cliente.nome,
                        Icons.person,
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        'Data de Emissão',
                        DateFormat(
                          'dd/MM/yyyy',
                        ).format(recibo.criadoEm.toDate()),
                        Icons.calendar_today,
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        'Valor Total',
                        currency.format(recibo.valorTotal),
                        Icons.attach_money,
                      ),
                      if (recibo.itens.isNotEmpty) ...[
                        const Divider(height: 24),
                        _buildInfoRow(
                          'Itens',
                          '${recibo.itens.length} item(s)',
                          Icons.shopping_cart,
                        ),
                      ],
                      if (recibo.valoresRecebidos.isNotEmpty) ...[
                        const Divider(height: 24),
                        _buildInfoRow(
                          'Pagamentos',
                          '${recibo.valoresRecebidos.length} pagamento(s)',
                          Icons.payment,
                        ),
                      ],
                    ],
                  ),
                ),
                // Botão fechar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Fechar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Colors.teal.shade600),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
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
