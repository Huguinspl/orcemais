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
        // ✅ CORREÇÃO APLICADA AQUI
        // O título agora usa o campo 'numero' e o formata com zeros à esquerda.
        title: Text(
          'Orçamento #${widget.orcamento.numero.toString().padLeft(3, '0')}',
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildAbasDeExportacao(),
          Expanded(child: _buildConteudoAba()),
        ],
      ),
      bottomNavigationBar: _buildRodapeRevisao(),
    );
  }

  Widget _buildAbasDeExportacao() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      child: SegmentedButton<int>(
        segments: const [
          ButtonSegment(
            value: 0,
            icon: Icon(Icons.picture_as_pdf_outlined),
            label: Text('PDF'),
          ),
          ButtonSegment(
            value: 1,
            icon: Icon(Icons.link),
            label: Text('Link Web'),
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
          side: const BorderSide(color: Colors.transparent),
        ),
      ),
    );
  }

  Widget _buildConteudoAba() {
    if (_abaSelecionada == 0) {
      return EtapaPdfPage(
        cliente: widget.orcamento.cliente,
        itens: widget.orcamento.itens,
        subtotal: widget.orcamento.subtotal,
        desconto: widget.orcamento.desconto,
        valorTotal: widget.orcamento.valorTotal,
      );
    } else {
      return EtapaLinkWebPage(
        cliente: widget.orcamento.cliente,
        itens: widget.orcamento.itens,
        subtotal: widget.orcamento.subtotal,
        desconto: widget.orcamento.desconto,
        valorTotal: widget.orcamento.valorTotal,
      );
    }
  }

  Widget _buildRodapeRevisao() {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    return Container(
      padding: const EdgeInsets.all(16).copyWith(top: 12, bottom: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Valor Total', style: theme.textTheme.titleMedium),
              Text(
                currencyFormat.format(widget.orcamento.valorTotal),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Voltar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
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
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Enviar Orçamento'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
