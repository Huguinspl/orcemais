import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/recibo.dart';
import '../../../providers/business_provider.dart';
import 'compartilhar_recibo_page.dart';

class RevisarReciboPage extends StatefulWidget {
  final Recibo recibo;
  const RevisarReciboPage({super.key, required this.recibo});

  @override
  State<RevisarReciboPage> createState() => _RevisarReciboPageState();
}

class _RevisarReciboPageState extends State<RevisarReciboPage> {
  int _abaSelecionada = 0; // 0 PDF, 1 Link Web

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
              colors: [Colors.orange.shade600, Colors.orange.shade400],
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
            color: Colors.orange.shade100,
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
                    _abaSelecionada == 0
                        ? Colors.white
                        : Colors.orange.shade600,
              ),
              label: Text(
                'PDF',
                style: TextStyle(
                  color:
                      _abaSelecionada == 0
                          ? Colors.white
                          : Colors.orange.shade600,
                ),
              ),
            ),
            ButtonSegment(
              value: 1,
              icon: Icon(
                Icons.link,
                color:
                    _abaSelecionada == 1
                        ? Colors.white
                        : Colors.orange.shade600,
              ),
              label: Text(
                'Link Web',
                style: TextStyle(
                  color:
                      _abaSelecionada == 1
                          ? Colors.white
                          : Colors.orange.shade600,
                ),
              ),
            ),
          ],
          selected: {_abaSelecionada},
          onSelectionChanged: (s) => setState(() => _abaSelecionada = s.first),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.orange.shade600;
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
            // Cabeçalho com faixa colorida personalizada
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _buildHeaderRecibo(businessProvider),
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
              'Dados do Cliente',
              bg: secondaryContainerColor,
              fg: onSecondaryContainerColor,
            ),
            const SizedBox(height: 12),
            _buildClientInfoRecibo(),
            const SizedBox(height: 24),

            // Itens ou Valores Recebidos
            if (recibo.itens.isNotEmpty) ...[
              _sectionLabelRecibo(
                'Itens / Serviços',
                bg: tertiaryContainerColor,
                fg: onTertiaryContainerColor,
              ),
              const SizedBox(height: 16),
              _buildItensListRecibo(currency),
            ] else ...[
              _sectionLabelRecibo(
                'Valores Recebidos',
                bg: tertiaryContainerColor,
                fg: onTertiaryContainerColor,
              ),
              const SizedBox(height: 16),
              _buildValoresRecebidosRecibo(currency),
            ],

            const SizedBox(height: 24),
            // Caixa de totais com destaque personalizado
            Container(
              decoration: BoxDecoration(
                color: secondaryContainerColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withOpacity(0.3)),
              ),
              padding: const EdgeInsets.all(16),
              child: _buildTotalsRecibo(currency),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkWeb() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.link, size: 64, color: Colors.orange.shade600),
            ),
            const SizedBox(height: 24),
            Text(
              'Link Web do Recibo',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Compartilhe este recibo através de um link que seus clientes podem visualizar online.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Esta funcionalidade estará disponível em breve.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
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

  Widget _buildHeaderRecibo(BusinessProvider provider) {
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
                    _buildInfoLinhaRecibo(
                      Icons.phone_outlined,
                      provider.telefone,
                    ),
                  if (provider.emailEmpresa.isNotEmpty)
                    _buildInfoLinhaRecibo(
                      Icons.email_outlined,
                      provider.emailEmpresa,
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoLinhaRecibo(IconData icon, String text) {
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

  Widget _buildClientInfoRecibo() {
    final recibo = widget.recibo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cliente:',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        Text(
          recibo.cliente.nome,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        if (recibo.cliente.celular.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(recibo.cliente.celular),
        ],
        if (recibo.cliente.email.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(recibo.cliente.email),
        ],
      ],
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
            : Colors.orange.shade600;

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
              'Valor Total',
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
                colors: [Colors.orange.shade600, Colors.orange.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.shade700, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.shade200,
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
                      side: BorderSide(color: Colors.orange.shade600, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Voltar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade600,
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
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => CompartilharReciboPage(recibo: recibo),
                          ),
                        );
                      },
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
                      colors: [Colors.orange.shade600, Colors.orange.shade400],
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
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Colors.orange.shade600),
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
