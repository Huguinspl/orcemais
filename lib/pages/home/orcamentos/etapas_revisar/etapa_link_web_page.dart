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
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFF1976D2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.info_outline,
                        color: Color(0xFF1976D2),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
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
                ),
              ),
            ],
            // Card de Dados do Cliente
            _buildClientCard(context),
            
            // Card de Itens do Orçamento  
            _buildItensCard(context),
            
            // Container com seções restantes
            Container(
              constraints: const BoxConstraints(maxWidth: 900),
              margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
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

  Widget _buildClientCard(BuildContext context) {
    final cliente = widget.orcamento.cliente;
    
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 900),
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: Color(0xFF1976D2),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Dados do Cliente',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildClientInfoRow('Nome', cliente.nome),
                    if (cliente.celular.isNotEmpty)
                      _buildClientInfoRow('Celular', cliente.celular),
                    if (cliente.email.isNotEmpty)
                      _buildClientInfoRow('Email', cliente.email),
                    if (cliente.cpfCnpj.isNotEmpty)
                      _buildClientInfoRow('CPF/CNPJ', cliente.cpfCnpj),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClientInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItensCard(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 900),
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.list_alt,
                      color: Color(0xFF1976D2),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Itens do Orçamento',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...widget.orcamento.itens.map((item) => _buildItemCardIndividual(item)),
          ],
        ),
      ),
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

  Widget _buildItemCardIndividual(Map<String, dynamic> item) {
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    final tipo = item['tipo'] ?? 'produto';
    final nome = item['nome'] ?? '';
    final descricao = item['descricao'] ?? '';
    final quantidade = (item['quantidade'] ?? 1).toDouble();
    final preco = (item['preco'] ?? 0.0).toDouble();
    final subtotal = quantidade * preco;
    final unidade = item['unidade'] ?? 'un';

    // Ícones por tipo
    IconData iconData;
    Color iconColor;
    Color backgroundColor;

    switch (tipo.toLowerCase()) {
      case 'servico':
      case 'serviço':
        iconData = Icons.build_outlined;
        iconColor = const Color(0xFF3B82F6);
        backgroundColor = const Color(0xFF3B82F6).withOpacity(0.1);
        break;
      case 'peca':
      case 'peça':
      case 'material':
        iconData = Icons.inventory_2_outlined;
        iconColor = const Color(0xFF10B981);
        backgroundColor = const Color(0xFF10B981).withOpacity(0.1);
        break;
      case 'mao_de_obra':
      case 'mão de obra':
        iconData = Icons.engineering_outlined;
        iconColor = const Color(0xFFF59E0B);
        backgroundColor = const Color(0xFFF59E0B).withOpacity(0.1);
        break;
      default:
        iconData = Icons.shopping_bag_outlined;
        iconColor = const Color(0xFF1976D2);
        backgroundColor = const Color(0xFF1976D2).withOpacity(0.1);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho com ícone e nome
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(iconData, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nome,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      if (tipo.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _formatarTipo(tipo),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: iconColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            // Descrição (se existir)
            if (descricao.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.notes_outlined,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        descricao,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Informações de quantidade e preço
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.numbers,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Quantidade:',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${quantidade.toStringAsFixed(quantidade.truncateToDouble() == quantidade ? 0 : 2)} $unidade',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.attach_money,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Preço Unitário:',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        currencyFormat.format(preco),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 1),
            const SizedBox(height: 12),

            // Subtotal destacado
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1976D2).withOpacity(0.08),
                    const Color(0xFF1976D2).withOpacity(0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF1976D2).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1976D2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.calculate,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Subtotal:',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
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
      ),
    );
  }

  String _formatarTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'servico':
      case 'serviço':
        return 'Serviço';
      case 'peca':
      case 'peça':
        return 'Peça';
      case 'material':
        return 'Material';
      case 'mao_de_obra':
      case 'mão de obra':
        return 'Mão de Obra';
      default:
        return tipo;
    }
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
          if (custoTotal > 0) ...[
            const SizedBox(height: 12),
            _buildResumoRow(
              'Custos Adicionais',
              currencyFormat.format(custoTotal),
              color: Colors.grey.shade800,
            ),
          ],
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
