import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/orcamento.dart';
import 'etapas_revisar/etapa_pdf_page.dart';
import 'etapas_revisar/etapa_link_web_page.dart';
import 'etapas_revisar/compartilhar_orcamento.dart';

class RevisarOrcamentoPage extends StatefulWidget {
  final Orcamento orcamento;

  const RevisarOrcamentoPage({super.key, required this.orcamento});

  @override
  State<RevisarOrcamentoPage> createState() => _RevisarOrcamentoPageState();
}

class _RevisarOrcamentoPageState extends State<RevisarOrcamentoPage> {
  int _abaSelecionada = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Orçamento #${widget.orcamento.numero.toString().padLeft(3, '0')}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.blue.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            tooltip: 'Informações do orçamento',
            onPressed: () {
              _mostrarInfoOrcamento();
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white, Colors.white],
          ),
        ),
        child: Column(
          children: [
            _buildAbasDeExportacao(),
            Expanded(child: _buildConteudoAba()),
          ],
        ),
      ),
      bottomNavigationBar: _buildRodapeRevisao(),
    );
  }

  Widget _buildAbasDeExportacao() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SegmentedButton<int>(
        segments: [
          ButtonSegment(
            value: 0,
            icon: Icon(
              Icons.picture_as_pdf_outlined,
              color: _abaSelecionada == 0 ? Colors.white : Colors.blue.shade700,
            ),
            label: Text(
              'PDF',
              style: TextStyle(
                color:
                    _abaSelecionada == 0 ? Colors.white : Colors.blue.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ButtonSegment(
            value: 1,
            icon: Icon(
              Icons.link,
              color: _abaSelecionada == 1 ? Colors.white : Colors.blue.shade700,
            ),
            label: Text(
              'Link Web',
              style: TextStyle(
                color:
                    _abaSelecionada == 1 ? Colors.white : Colors.blue.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        selected: {_abaSelecionada},
        onSelectionChanged: (Set<int> novaSelecao) {
          setState(() {
            _abaSelecionada = novaSelecao.first;
          });
        },
        style: SegmentedButton.styleFrom(
          backgroundColor: Colors.transparent,
          selectedBackgroundColor: Colors.blue.shade700,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildConteudoAba() {
    if (_abaSelecionada == 0) {
      return Column(
        children: [
          if (widget.orcamento.metodoPagamento != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.blue.shade500],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade200.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.payments_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _pagamentoResumo(widget.orcamento),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Expanded(
            child: EtapaPdfPage(
              cliente: widget.orcamento.cliente,
              itens: widget.orcamento.itens,
              subtotal: widget.orcamento.subtotal,
              desconto: widget.orcamento.desconto,
              valorTotal: widget.orcamento.valorTotal,
              metodoPagamento: widget.orcamento.metodoPagamento,
              parcelas: widget.orcamento.parcelas,
              laudoTecnico: widget.orcamento.laudoTecnico,
              condicoesContratuais: widget.orcamento.condicoesContratuais,
              garantia: widget.orcamento.garantia,
              informacoesAdicionais: widget.orcamento.informacoesAdicionais,
              fotos: widget.orcamento.fotos,
            ),
          ),
        ],
      );
    } else {
      return EtapaLinkWebPage(orcamento: widget.orcamento);
    }
  }

  String _pagamentoResumo(Orcamento o) {
    final m = o.metodoPagamento;
    if (m == null) return '';
    switch (m) {
      case 'credito':
        final p = o.parcelas ?? 1;
        return 'Forma de pagamento: Crédito em ${p}x';
      case 'debito':
        return 'Forma de pagamento: Débito';
      case 'pix':
        return 'Forma de pagamento: Pix';
      case 'dinheiro':
        return 'Forma de pagamento: Dinheiro';
      case 'boleto':
        return 'Forma de pagamento: Boleto';
      default:
        return 'Forma de pagamento: $m';
    }
  }

  void _mostrarInfoOrcamento() {
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.blue.shade400],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.info_outline, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Informações',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildInfoRow(
                    'Número',
                    '#${widget.orcamento.numero.toString().padLeft(3, '0')}',
                  ),
                  const Divider(height: 20),
                  _buildInfoRow('Cliente', widget.orcamento.cliente.nome),
                  const Divider(height: 20),
                  _buildInfoRow(
                    'Data de criação',
                    dateFormat.format(widget.orcamento.dataCriacao.toDate()),
                  ),
                  const Divider(height: 20),
                  _buildInfoRow(
                    'Subtotal',
                    currencyFormat.format(widget.orcamento.subtotal),
                  ),
                  if (widget.orcamento.desconto > 0) ...[
                    const Divider(height: 20),
                    _buildInfoRow(
                      'Desconto',
                      currencyFormat.format(widget.orcamento.desconto),
                    ),
                  ],
                  const Divider(height: 20),
                  _buildInfoRow(
                    'Valor Total',
                    currencyFormat.format(widget.orcamento.valorTotal),
                    isTotal: true,
                  ),
                  if (widget.orcamento.metodoPagamento != null) ...[
                    const Divider(height: 20),
                    _buildInfoRow(
                      'Pagamento',
                      _pagamentoResumo(
                        widget.orcamento,
                      ).replaceAll('Forma de pagamento: ', ''),
                    ),
                  ],
                  const Divider(height: 20),
                  _buildInfoRow(
                    'Status',
                    widget.orcamento.status,
                    isStatus: true,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  'Fechar',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isTotal = false,
    bool isStatus = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color:
                  isTotal
                      ? Colors.blue.shade700
                      : isStatus
                      ? _getStatusColor(value)
                      : Colors.grey.shade800,
              fontSize: isTotal ? 16 : 14,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'rascunho':
        return Colors.grey.shade600;
      case 'enviado':
        return Colors.blue.shade600;
      case 'aprovado':
        return Colors.green.shade600;
      case 'recusado':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  Widget _buildRodapeRevisao() {
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    return Container(
      padding: const EdgeInsets.all(20).copyWith(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicador visual
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Total
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade50,
                    Colors.blue.shade100.withOpacity(0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade200, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade700,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.attach_money,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Valor Total',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    currencyFormat.format(widget.orcamento.valorTotal),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Botões
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.blue.shade700, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_back, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Voltar',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade600, Colors.green.shade500],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.shade300.withOpacity(0.5),
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
                                (_) => CompartilharOrcamentoPage(
                                  orcamento: widget.orcamento,
                                ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.send, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Enviar Orçamento',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
