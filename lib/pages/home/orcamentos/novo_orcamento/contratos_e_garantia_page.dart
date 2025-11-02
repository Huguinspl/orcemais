import 'package:flutter/material.dart';

class ContratosEGarantiaPage extends StatefulWidget {
  final String? condicoesIniciais;
  final String? garantiaInicial;
  const ContratosEGarantiaPage({
    super.key,
    this.condicoesIniciais,
    this.garantiaInicial,
  });

  @override
  State<ContratosEGarantiaPage> createState() => _ContratosEGarantiaPageState();
}

class _ContratosEGarantiaPageState extends State<ContratosEGarantiaPage> {
  late final TextEditingController _condCtrl;
  late final TextEditingController _garCtrl;

  @override
  void initState() {
    super.initState();
    _condCtrl = TextEditingController(text: widget.condicoesIniciais ?? '');
    _garCtrl = TextEditingController(text: widget.garantiaInicial ?? '');
  }

  @override
  void dispose() {
    _condCtrl.dispose();
    _garCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contratos e garantia'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Descreva aqui as suas condições contratuais.'),
              const SizedBox(height: 8),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _condCtrl,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    labelText: 'Condições contratuais',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Descreva aqui a garantia dos seus serviços, produtos, materiais ou equipamentos.',
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _garCtrl,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    labelText: 'Garantia',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _condCtrl.clear();
                          _garCtrl.clear();
                        });
                      },
                      child: const Text('Limpar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, {
                          'condicoes': _condCtrl.text.trim(),
                          'garantia': _garCtrl.text.trim(),
                        });
                      },
                      child: const Text('Salvar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
