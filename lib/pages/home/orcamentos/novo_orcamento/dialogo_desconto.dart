import 'package:flutter/material.dart';
import '../novo_orcamento_page.dart'; // Import necessário para o Enum DescontoTipo

class DialogoDesconto extends StatefulWidget {
  final double subtotal;
  const DialogoDesconto({super.key, required this.subtotal});

  @override
  State<DialogoDesconto> createState() => _DialogoDescontoState();
}

class _DialogoDescontoState extends State<DialogoDesconto> {
  final _controller = TextEditingController();
  DescontoTipo _tipoSelecionado = DescontoTipo.percentual;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _aplicar() {
    final valor = double.tryParse(_controller.text.replaceAll(',', '.')) ?? 0.0;
    if (valor > 0) {
      // Retorna um Map com o tipo e o valor do desconto
      Navigator.pop(context, {'tipo': _tipoSelecionado, 'valor': valor});
    } else {
      // Se não houver valor, apenas fecha o diálogo
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Aplicar Desconto'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SegmentedButton<DescontoTipo>(
            segments: const [
              ButtonSegment(value: DescontoTipo.percentual, label: Text('%')),
              ButtonSegment(value: DescontoTipo.valor, label: Text('R\$')),
            ],
            selected: {_tipoSelecionado},
            onSelectionChanged: (novaSelecao) {
              setState(() {
                _tipoSelecionado = novaSelecao.first;
              });
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Valor do Desconto',
              prefixText:
                  _tipoSelecionado == DescontoTipo.valor ? 'R\$ ' : null,
              suffixText:
                  _tipoSelecionado == DescontoTipo.percentual ? '%' : null,
              border: const OutlineInputBorder(),
            ),
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _aplicar, child: const Text('Aplicar')),
      ],
    );
  }
}
