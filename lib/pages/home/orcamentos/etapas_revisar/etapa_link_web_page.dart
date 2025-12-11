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
  String _formatCnpj(String cnpj) {
    if (cnpj.isEmpty) return '';
    String numbers = cnpj.replaceAll(RegExp(r'\D'), '');
    if (numbers.length == 14) {
      return '${numbers.substring(0, 2)}.${numbers.substring(2, 5)}.${numbers.substring(5, 8)}/${numbers.substring(8, 12)}-${numbers.substring(12)}';
    } else if (numbers.length == 11) {
      return '${numbers.substring(0, 3)}.${numbers.substring(3, 6)}.${numbers.substring(6, 9)}-${numbers.substring(9)}';
    }
    return cnpj;
  }

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
      appBar: AppBar(
        title: const Text(
          'Orçamento',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        toolbarHeight: 80,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF1976D2), Color(0xFF1E88E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Card com dados do negócio
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 900),
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child:
                    businessProvider.nomeEmpresa.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : _buildBusinessHeader(context, businessProvider),
              ),
            ),
            if ((businessProvider.descricao ?? '').isNotEmpty) ...[
              Container(
                constraints: const BoxConstraints(maxWidth: 900),
                margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade100, width: 1),
                ),
                child: Text(
                  businessProvider.descricao!,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                    height: 1.6,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
            // Card principal com design moderno
            Container(
              constraints: const BoxConstraints(maxWidth: 900),
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 48,
                    offset: const Offset(0, 16),
                    spreadRadius: 0,
                  ),
                ],
                border: Border.all(color: Colors.grey.shade100, width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dados do Cliente
                  _buildSection(
                    icon: Icons.person_outline,
                    title: 'Dados do Cliente',
                    child: _buildClientInfoWeb(context),
                  ),
                  const Divider(height: 1),

                  // Itens do Orçamento
                  _buildSection(
                    icon: Icons.list_alt,
                    title: 'Itens do Orçamento',
                    child: _buildItemsListWeb(context),
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
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1976D2).withOpacity(0.1),
                      Color(0xFF1976D2).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: Color(0xFF1976D2)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildBusinessHeader(BuildContext context, BusinessProvider provider) {
    return Column(
      children: [
        FutureBuilder<Uint8List?>(
          future: provider.getLogoBytes(),
          builder: (context, snap) {
            final logoBytes = snap.data;
            Widget? logo;
            if (logoBytes != null && logoBytes.isNotEmpty) {
              logo = Image.memory(logoBytes, fit: BoxFit.contain, height: 100);
            } else if (provider.logoUrl != null &&
                provider.logoUrl!.isNotEmpty) {
              logo = Image.network(
                provider.logoUrl!,
                fit: BoxFit.contain,
                height: 100,
                loadingBuilder:
                    (context, child, loadingProgress) =>
                        loadingProgress == null
                            ? child
                            : const CircularProgressIndicator(),
                errorBuilder:
                    (_, __, ___) => Icon(
                      Icons.business,
                      size: 80,
                      color: Color(0xFF1976D2),
                    ),
              );
            }

            return logo != null
                ? Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Color(0xFF1976D2).withOpacity(0.1),
                      width: 2,
                    ),
                  ),
                  child: logo,
                )
                : const SizedBox.shrink();
          },
        ),
        const SizedBox(height: 20),
        Text(
          provider.nomeEmpresa,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1976D2),
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
        if (provider.ramo.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            provider.ramo,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Wrap(
            spacing: 24,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              if (provider.telefone.isNotEmpty)
                _buildInfoRowBusiness(Icons.phone, provider.telefone),
              if (provider.cnpj.isNotEmpty)
                _buildInfoRowBusiness(
                  Icons.badge_outlined,
                  _formatCnpj(provider.cnpj),
                ),
              if (provider.emailEmpresa.isNotEmpty)
                _buildInfoRowBusiness(Icons.email, provider.emailEmpresa),
              if (provider.endereco.isNotEmpty)
                _buildInfoRowBusiness(Icons.location_on, provider.endereco),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRowBusiness(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[800],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildClientInfoWeb(BuildContext context) {
    final cliente = widget.orcamento.cliente;

    final items = [
      if (cliente.nome.isNotEmpty)
        {'icon': Icons.person_outline, 'label': 'Nome', 'value': cliente.nome},
      if (cliente.celular.isNotEmpty)
        {
          'icon': Icons.phone_android,
          'label': 'Celular',
          'value': cliente.celular,
        },
      if (cliente.telefone.isNotEmpty)
        {'icon': Icons.phone, 'label': 'Telefone', 'value': cliente.telefone},
      if (cliente.email.isNotEmpty)
        {
          'icon': Icons.email_outlined,
          'label': 'Email',
          'value': cliente.email,
        },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 16,
        children:
            items
                .map(
                  (item) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        color: const Color(0xFF1976D2),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${item['label']}: ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        item['value'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade900,
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _buildItemsListWeb(BuildContext context) {
    return Column(
      children: List.generate(widget.orcamento.itens.length, (index) {
        final item = widget.orcamento.itens[index];
        return _buildItemWeb(index + 1, item);
      }),
    );
  }

  Widget _buildItemWeb(int numero, Map<String, dynamic> item) {
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    final nome = item['nome'] ?? '---';
    final descricao = item['descricao'];
    final quantidade = double.tryParse(item['quantidade'].toString()) ?? 1.0;
    final preco = double.tryParse(item['preco'].toString()) ?? 0.0;
    final subtotal = (quantidade * preco).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabeçalho do item
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1976D2).withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                // Número do item
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1976D2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$numero',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Nome do item
                Expanded(
                  child: Text(
                    nome,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade900,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Conteúdo do item
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Descrição (se existir)
                if (descricao != null && descricao.toString().isNotEmpty) ...[
                  Text(
                    descricao.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey.shade200, height: 1),
                  const SizedBox(height: 16),
                ],

                // Detalhes organizados em grid
                Row(
                  children: [
                    // Quantidade
                    Expanded(
                      child: _buildInfoBox(
                        label: 'Quantidade',
                        value: quantidade.toStringAsFixed(
                          quantidade.truncateToDouble() == quantidade ? 0 : 2,
                        ),
                        icon: Icons.inventory_2_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Preço unitário
                    Expanded(
                      child: _buildInfoBox(
                        label: 'Preço Unit.',
                        value: currencyFormat.format(preco),
                        icon: Icons.payments_outlined,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Rodapé com valor total
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1976D2).withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total dos Item',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  currencyFormat.format(subtotal),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade900,
            ),
          ),
        ],
      ),
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

    // Calcular custos adicionais
    double custoTotal = 0.0;
    for (var item in widget.orcamento.itens) {
      final custo = double.tryParse(item['custo'].toString()) ?? 0.0;
      custoTotal += custo;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        children: [
          // Cabeçalho
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1976D2).withOpacity(0.08),
                  const Color(0xFF1976D2).withOpacity(0.04),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.receipt_long,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Resumo Financeiro',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),
              ],
            ),
          ),

          // Conteúdo
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Subtotal
                _buildFinanceiroRowCard(
                  'Subtotal',
                  widget.orcamento.subtotal,
                  Icons.calculate_outlined,
                  Colors.grey.shade700,
                ),

                // Custos Adicionais (se houver)
                if (custoTotal > 0) ...[
                  const SizedBox(height: 10),
                  _buildFinanceiroRowCard(
                    'Custos Adicionais',
                    custoTotal,
                    Icons.build_outlined,
                    Colors.grey.shade700,
                  ),
                ],

                // Desconto (se houver)
                if (widget.orcamento.desconto > 0) ...[
                  const SizedBox(height: 10),
                  _buildFinanceiroRowCard(
                    'Desconto',
                    widget.orcamento.desconto,
                    Icons.local_offer_outlined,
                    Colors.red.shade600,
                    isNegative: true,
                  ),
                ],

                const SizedBox(height: 12),
                Divider(color: Colors.grey.shade300, thickness: 1),
                const SizedBox(height: 12),

                // Total destacado
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF1976D2).withOpacity(0.12),
                        const Color(0xFF1976D2).withOpacity(0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF1976D2).withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1976D2),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF1976D2,
                                    ).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.attach_money,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Flexible(
                              child: Text(
                                'VALOR TOTAL',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1976D2),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: Text(
                          currencyFormat.format(widget.orcamento.valorTotal),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1976D2),
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceiroRowCard(
    String label,
    double valor,
    IconData icon,
    Color cor, {
    bool isNegative = false,
  }) {
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: cor),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cor,
                ),
              ),
            ],
          ),
          Text(
            '${isNegative ? '-' : ''}${currencyFormat.format(valor)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isNegative ? Colors.red.shade600 : Colors.grey.shade900,
            ),
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
