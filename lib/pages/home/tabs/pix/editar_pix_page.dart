import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/business_provider.dart';

class EditarPixPage extends StatefulWidget {
  const EditarPixPage({super.key});

  @override
  State<EditarPixPage> createState() => _EditarPixPageState();
}

class _EditarPixPageState extends State<EditarPixPage> {
  final _formKey = GlobalKey<FormState>();
  String _tipo = 'cpf';
  final _chaveCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final prov = context.read<BusinessProvider>();
    if (prov.pixTipo != null) {
      _tipo = prov.pixTipo!;
    }
    if (prov.pixChave != null) {
      _chaveCtrl.text = prov.pixChave!;
    }
  }

  @override
  void dispose() {
    _chaveCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<BusinessProvider>().salvarPix(
      tipo: _tipo,
      chave: _chaveCtrl.text.trim(),
    );
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chave Pix'), centerTitle: true),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Tipo da chave',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _tipoChip('cpf'),
                _tipoChip('cnpj'),
                _tipoChip('email'),
                _tipoChip('celular'),
                _tipoChip('aleatoria'),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _chaveCtrl,
              decoration: const InputDecoration(
                labelText: 'Chave',
                border: OutlineInputBorder(),
              ),
              validator:
                  (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Informe a chave'
                          : null,
            ),
          ],
        ),
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
                onPressed: _salvar,
                child: const Text('Salvar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tipoChip(String tipo) {
    final selected = _tipo == tipo;
    return ChoiceChip(
      label: Text(tipo.toUpperCase()),
      selected: selected,
      onSelected: (_) => setState(() => _tipo = tipo),
    );
  }
}
