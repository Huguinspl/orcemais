import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/valor_recebido.dart';

class NovoValorRecebidoPage extends StatefulWidget {
  const NovoValorRecebidoPage({super.key});

  @override
  State<NovoValorRecebidoPage> createState() => _NovoValorRecebidoPageState();
}

class _NovoValorRecebidoPageState extends State<NovoValorRecebidoPage> {
  final _formKey = GlobalKey<FormState>();
  Timestamp? _data;
  double? _valor;
  String _forma = 'Dinheiro';
  bool _salvando = false;

  Future<void> _pickData() async {
    final agora = DateTime.now();
    final data = await showDatePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
      initialDate: _data?.toDate() ?? agora,
    );
    if (data == null) return;
    setState(() => _data = Timestamp.fromDate(data));
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;
    if (_data == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecione a data.')));
      return;
    }
    _formKey.currentState!.save();
    setState(() => _salvando = true);
    final vr = ValorRecebido(
      data: _data!,
      valor: _valor!,
      formaPagamento: _forma,
    );
    Navigator.pop(context, vr);
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy');
    return Scaffold(
      appBar: AppBar(title: const Text('Valor Recebido')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              title: const Text('Data'),
              subtitle: Text(
                _data == null ? 'Selecionar' : df.format(_data!.toDate()),
              ),
              trailing: const Icon(Icons.calendar_month),
              onTap: _pickData,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Valor (R\$)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator:
                  (v) => (v == null || v.isEmpty) ? 'Informe o valor' : null,
              onSaved:
                  (v) => _valor = double.tryParse(v!.replaceAll(',', '.')) ?? 0,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Forma de Pagamento',
              ),
              value: _forma,
              items: const [
                DropdownMenuItem(value: 'Credito', child: Text('Crédito')),
                DropdownMenuItem(value: 'Debito', child: Text('Débito')),
                DropdownMenuItem(value: 'Boleto', child: Text('Boleto')),
                DropdownMenuItem(value: 'Pix', child: Text('Pix')),
                DropdownMenuItem(value: 'Dinheiro', child: Text('Dinheiro')),
              ],
              onChanged: (v) => setState(() => _forma = v ?? 'Dinheiro'),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _salvando ? null : _salvar,
                icon: const Icon(Icons.save),
                label: Text(_salvando ? 'Salvando...' : 'Salvar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
