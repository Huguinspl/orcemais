import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/recibo.dart';
import '../../../providers/business_provider.dart';
import '../../../providers/user_provider.dart';

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
    final userProvider = context.watch<UserProvider>();

    // Dados com fallback para dados pessoais
    final nomeExibicao = businessProvider.getNomeExibicao(userProvider.nome);
    final emailExibicao = businessProvider.getEmailExibicao(userProvider.email);
    final documentoExibicao = businessProvider.getDocumentoExibicao(
      userProvider.cpf,
    );

    final primaryColor = Color(0xFF1976D2);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Recibo',
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
                child: _buildBusinessHeader(
                  context,
                  businessProvider,
                  nomeExibicao: nomeExibicao,
                  emailExibicao: emailExibicao,
                  documentoExibicao: documentoExibicao,
                ),
              ),
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

  Widget _buildBusinessHeader(
    BuildContext context,
    BusinessProvider provider, {
    required String nomeExibicao,
    required String emailExibicao,
    required String documentoExibicao,
  }) {
    return Column(
      children: [
        if (provider.logoUrl != null && provider.logoUrl!.isNotEmpty) ...[
          FutureBuilder<Uint8List?>(
            future: provider.getLogoBytes(),
            builder: (context, snap) {
              // Mostra loading enquanto carrega
              if (snap.connectionState == ConnectionState.waiting) {
                return Container(
                  height: 80,
                  width: 80,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              Widget? logo;
              if (snap.hasData && snap.data != null) {
                logo = Image.memory(
                  snap.data!,
                  height: 80,
                  fit: BoxFit.contain,
                );
              } else {
                // Fallback para carregar da URL diretamente
                logo = Image.network(
                  provider.logoUrl!,
                  height: 80,
                  fit: BoxFit.contain,
                  errorBuilder:
                      (_, __, ___) => Icon(
                        Icons.business,
                        size: 80,
                        color: Color(0xFF1976D2),
                      ),
                );
              }

              return Container(
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
              );
            },
          ),
          const SizedBox(height: 20),
        ],
        Text(
          nomeExibicao,
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
                _buildInfoRow(Icons.phone, provider.telefone),
              if (emailExibicao.isNotEmpty)
                _buildInfoRow(Icons.email, emailExibicao),
              if (provider.endereco.isNotEmpty)
                _buildInfoRow(Icons.location_on, provider.endereco),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[800],
        fontWeight: FontWeight.w500,
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1976D2), Color(0xFF1E88E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
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

  Widget _buildItemsListWeb(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    return Column(
      children: List.generate(widget.recibo.itens.length, (index) {
        final item = widget.recibo.itens[index];
        return _buildItemWeb(index + 1, item, currencyFormat);
      }),
    );
  }

  Widget _buildItemWeb(
    int numero,
    Map<String, dynamic> item,
    NumberFormat currencyFormat,
  ) {
    final nome = item['nome'] ?? '---';
    final descricao = item['descricao'] as String? ?? '';
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
                if (descricao.isNotEmpty) ...[
                  Text(
                    descricao,
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
                  'Total do Item',
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

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: _buildResumoRow(
            'Subtotal',
            currencyFormat.format(widget.recibo.subtotalItens),
            color: Colors.grey.shade800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF388E3C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF2E7D32).withOpacity(0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'VALOR PAGO',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                currencyFormat.format(widget.recibo.valorTotal),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ),
      ],
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
