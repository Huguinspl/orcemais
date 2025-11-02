import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/business_provider.dart';
import '../../tabs/pix/editar_pix_page.dart';

enum MetodoPagamento { dinheiro, pix, debito, credito, boleto }

class FormasPagamentoPage extends StatefulWidget {
  final MetodoPagamento? metodoInicial;
  final int? parcelasIniciais;
  const FormasPagamentoPage({
    super.key,
    this.metodoInicial,
    this.parcelasIniciais,
  });

  @override
  State<FormasPagamentoPage> createState() => _FormasPagamentoPageState();
}

class _FormasPagamentoPageState extends State<FormasPagamentoPage> {
  MetodoPagamento _metodo = MetodoPagamento.pix;
  int _parcelas = 1;

  @override
  void initState() {
    super.initState();
    _metodo = widget.metodoInicial ?? MetodoPagamento.pix;
    _parcelas = widget.parcelasIniciais ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    final bp = context.watch<BusinessProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Formas de pagamento'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Selecione a forma de pagamento:'),
          const SizedBox(height: 8),
          ..._metodosRadios(),
          const SizedBox(height: 16),
          if (_metodo == MetodoPagamento.pix) _pixCard(context, bp),
          if (_metodo == MetodoPagamento.credito) _parcelamentoCard(context),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _aplicar,
                child: const Text('Aplicar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _metodosRadios() {
    return [
      _radioTile(MetodoPagamento.dinheiro, 'Dinheiro', Icons.attach_money),
      _radioTile(MetodoPagamento.pix, 'Pix', Icons.qr_code_2_outlined),
      _radioTile(MetodoPagamento.debito, 'Débito', Icons.credit_card),
      _radioTile(MetodoPagamento.credito, 'Crédito', Icons.credit_card_rounded),
      _radioTile(MetodoPagamento.boleto, 'Boleto', Icons.receipt_long_outlined),
    ];
  }

  Widget _radioTile(MetodoPagamento value, String label, IconData icon) {
    return RadioListTile<MetodoPagamento>(
      value: value,
      groupValue: _metodo,
      onChanged: (v) => setState(() => _metodo = v!),
      title: Row(
        children: [
          Icon(icon, color: Colors.blueAccent),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }

  Widget _pixCard(BuildContext context, BusinessProvider bp) {
    final pixInfo =
        (bp.pixTipo != null && bp.pixChave != null)
            ? 'Chave (${bp.pixTipo}): ${bp.pixChave}'
            : 'Nenhuma chave cadastrada';
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.qr_code_2_outlined)),
        title: const Text('Chave Pix'),
        subtitle: Text(pixInfo),
        trailing: const Icon(Icons.edit_outlined),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditarPixPage()),
          );
          if (mounted) setState(() {});
        },
      ),
    );
  }

  Widget _parcelamentoCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Condições de pagamento (Crédito)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Parcelas:'),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: _parcelas,
                  onChanged: (v) => setState(() => _parcelas = v ?? 1),
                  items:
                      List.generate(12, (i) => i + 1)
                          .map(
                            (e) => DropdownMenuItem<int>(
                              value: e,
                              child: Text('${e}x'),
                            ),
                          )
                          .toList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _aplicar() {
    String resumo;
    switch (_metodo) {
      case MetodoPagamento.dinheiro:
        resumo = 'Dinheiro';
        break;
      case MetodoPagamento.pix:
        resumo = 'Pix';
        break;
      case MetodoPagamento.debito:
        resumo = 'Débito';
        break;
      case MetodoPagamento.credito:
        resumo = 'Crédito em ${_parcelas}x';
        break;
      case MetodoPagamento.boleto:
        resumo = 'Boleto';
        break;
    }
    Navigator.pop(context, {
      'metodo': _metodo.name,
      'parcelas': _metodo == MetodoPagamento.credito ? _parcelas : null,
      'resumo': resumo,
    });
  }
}
