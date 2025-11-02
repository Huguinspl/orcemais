import 'package:flutter/material.dart';
import '../novo_orcamento_page.dart'; // Para usar DescontoTipo

class AplicarDescontoPage extends StatefulWidget {
  final double subtotal;
  const AplicarDescontoPage({super.key, required this.subtotal});

  @override
  State<AplicarDescontoPage> createState() => _AplicarDescontoPageState();
}

class _AplicarDescontoPageState extends State<AplicarDescontoPage> {
  final _controller = TextEditingController();
  DescontoTipo _tipoSelecionado = DescontoTipo.percentual;
  double _valor = 0.0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    setState(() {
      _valor = double.tryParse(text.replaceAll(',', '.')) ?? 0.0;
    });
  }

  double get _descontoCalculado {
    if (_tipoSelecionado == DescontoTipo.percentual) {
      return (widget.subtotal * _valor) / 100.0;
    }
    return _valor;
  }

  double get _descontoAjustado {
    final d = _descontoCalculado;
    if (d > widget.subtotal) return widget.subtotal;
    if (d < 0) return 0.0;
    return d;
  }

  @override
  Widget build(BuildContext context) {
    final desconto = _descontoAjustado;
    final restante = (widget.subtotal - desconto).clamp(0.0, double.infinity);
    return Scaffold(
      appBar: AppBar(title: const Text('Aplicar desconto'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<DescontoTipo>(
              segments: const [
                ButtonSegment(value: DescontoTipo.percentual, label: Text('%')),
                ButtonSegment(value: DescontoTipo.valor, label: Text('R\$')),
              ],
              selected: {_tipoSelecionado},
              onSelectionChanged: (sel) {
                setState(() {
                  _tipoSelecionado = sel.first;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText:
                    _tipoSelecionado == DescontoTipo.valor
                        ? 'Valor do desconto'
                        : 'Percentual do desconto',
                prefixText:
                    _tipoSelecionado == DescontoTipo.valor ? 'R\$ ' : null,
                suffixText:
                    _tipoSelecionado == DescontoTipo.percentual ? '%' : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: _onChanged,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Subtotal: R\$ ${widget.subtotal.toStringAsFixed(2)}'),
                    const SizedBox(height: 4),
                    Text('Desconto: - R\$ ${desconto.toStringAsFixed(2)}'),
                    const Divider(height: 16),
                    Text(
                      'Total após desconto: R\$ ${restante.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Row(
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
                    onPressed: () {
                      if (_valor <= 0) {
                        Navigator.pop(context);
                        return;
                      }
                      Navigator.pop(context, {
                        'tipo': _tipoSelecionado,
                        'valor': _valor,
                      });
                    },
                    child: const Text('Aplicar'),
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
