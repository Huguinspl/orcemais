import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../../models/recibo.dart';
import '../../../providers/business_provider.dart';
import '../../../utils/recibo_pdf_generator.dart';
import 'compartilhar_recibo_page.dart';

class RevisarReciboPage extends StatefulWidget {
  final Recibo recibo;
  const RevisarReciboPage({super.key, required this.recibo});

  @override
  State<RevisarReciboPage> createState() => _RevisarReciboPageState();
}

class _RevisarReciboPageState extends State<RevisarReciboPage> {
  int _abaSelecionada = 0; // 0 PDF, 1 Detalhes

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final recibo = widget.recibo;
    return Scaffold(
      appBar: AppBar(
        title: Text('Recibo #${recibo.numero.toString().padLeft(4, '0')}'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildAbasDeExportacao(),
          Expanded(
            child:
                _abaSelecionada == 0
                    ? _buildPdfPreview()
                    : _buildDetalhes(currency),
          ),
        ],
      ),
      bottomNavigationBar: _buildRodapeRevisao(currency),
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
            icon: Icon(Icons.list_alt),
            label: Text('Detalhes'),
          ),
        ],
        selected: {_abaSelecionada},
        onSelectionChanged: (s) => setState(() => _abaSelecionada = s.first),
      ),
    );
  }

  Widget _buildPdfPreview() {
    final business = context.read<BusinessProvider>();
    return PdfPreview(
      canChangePageFormat: false,
      canChangeOrientation: false,
      build: (format) => ReciboPdfGenerator.generate(widget.recibo, business),
      pdfFileName:
          'recibo_${widget.recibo.numero.toString().padLeft(4, '0')}.pdf',
    );
  }

  Widget _buildDetalhes(NumberFormat currency) {
    final recibo = widget.recibo;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Cliente: ${recibo.cliente.nome}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (recibo.itens.isNotEmpty) ...[
          const Text('Itens / Serviços'),
          const SizedBox(height: 8),
          ...recibo.itens.map(
            (i) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(i['nome'] ?? 'Item'),
              subtitle: Text(
                'Qtd: ${i['quantidade'] ?? 1}  Preço: ${currency.format((i['preco'] ?? 0).toDouble())}',
              ),
            ),
          ),
        ] else ...[
          const Text('Valores Recebidos'),
          const SizedBox(height: 8),
          ...recibo.valoresRecebidos.map(
            (v) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(currency.format(v.valor)),
              subtitle: Text(
                DateFormat('dd/MM/yyyy').format(v.data.toDate()) +
                    ' - ' +
                    v.formaPagamento,
              ),
            ),
          ),
        ],
        const Divider(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Valor Total', style: Theme.of(context).textTheme.titleMedium),
            Text(
              currency.format(recibo.valorTotal),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRodapeRevisao(NumberFormat currency) {
    final recibo = widget.recibo;
    final theme = Theme.of(context);
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
                currency.format(recibo.valorTotal),
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
                        builder: (_) => CompartilharReciboPage(recibo: recibo),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Enviar Recibo'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
