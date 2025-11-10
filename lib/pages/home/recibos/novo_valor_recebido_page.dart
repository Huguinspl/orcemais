import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../models/valor_recebido.dart';

// Classe de formatação de moeda
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    final numeros = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeros.isEmpty) return const TextEditingValue(text: 'R\$ 0,00');
    final valor = int.parse(numeros) / 100;
    final textoFormatado =
        'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
    return TextEditingValue(
      text: textoFormatado,
      selection: TextSelection.collapsed(offset: textoFormatado.length),
    );
  }
}

class NovoValorRecebidoPage extends StatefulWidget {
  const NovoValorRecebidoPage({super.key});

  @override
  State<NovoValorRecebidoPage> createState() => _NovoValorRecebidoPageState();
}

class _NovoValorRecebidoPageState extends State<NovoValorRecebidoPage> {
  final _formKey = GlobalKey<FormState>();
  final _valorController = TextEditingController();
  Timestamp? _data;
  String _forma = 'Dinheiro';
  bool _salvando = false;

  @override
  void dispose() {
    _valorController.dispose();
    super.dispose();
  }

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

  double? _parseMoeda(String value) {
    try {
      final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleaned.isEmpty) return 0.0;
      return int.parse(cleaned) / 100;
    } catch (e) {
      return null;
    }
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;
    if (_data == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecione a data.')));
      return;
    }
    
    final valor = _parseMoeda(_valorController.text);
    if (valor == null || valor == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Informe um valor válido.')));
      return;
    }
    
    setState(() => _salvando = true);
    final vr = ValorRecebido(
      data: _data!,
      valor: valor,
      formaPagamento: _forma,
    );
    Navigator.pop(context, vr);
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy');
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Valor Recebido'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Registre um pagamento recebido do cliente',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            
            // Card de Data
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade50,
                  child: Icon(
                    Icons.calendar_today,
                    color: Colors.blue.shade700,
                  ),
                ),
                title: const Text(
                  'Data do Pagamento',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  _data == null ? 'Toque para selecionar' : df.format(_data!.toDate()),
                  style: TextStyle(
                    color: _data == null ? Colors.grey : Colors.black87,
                    fontWeight: _data == null ? FontWeight.normal : FontWeight.w500,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
                onTap: _pickData,
              ),
            ),
            const SizedBox(height: 16),
            
            // Campo de Valor
            TextFormField(
              controller: _valorController,
              decoration: InputDecoration(
                labelText: 'Valor Recebido',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                CurrencyInputFormatter(),
              ],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Informe o valor';
                final valor = _parseMoeda(v);
                if (valor == null || valor == 0) {
                  return 'Informe um valor válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Dropdown de Forma de Pagamento
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Forma de Pagamento',
                prefixIcon: const Icon(Icons.payment),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              value: _forma,
              items: const [
                DropdownMenuItem(value: 'Dinheiro', child: Text('💵 Dinheiro')),
                DropdownMenuItem(value: 'Pix', child: Text('🔑 Pix')),
                DropdownMenuItem(value: 'Debito', child: Text('💳 Débito')),
                DropdownMenuItem(value: 'Credito', child: Text('💳 Crédito')),
                DropdownMenuItem(value: 'Boleto', child: Text('📄 Boleto')),
              ],
              onChanged: (v) => setState(() => _forma = v ?? 'Dinheiro'),
            ),
            const SizedBox(height: 32),
            
            // Botão de Salvar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _salvando ? null : _salvar,
                icon: _salvando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.check),
                label: Text(_salvando ? 'Salvando...' : 'Adicionar Valor'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
