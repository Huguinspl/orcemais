import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../novo_orcamento_page.dart'; // Para usar DescontoTipo

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

class AplicarDescontoPage extends StatefulWidget {
  final double subtotal;
  const AplicarDescontoPage({super.key, required this.subtotal});

  @override
  State<AplicarDescontoPage> createState() => _AplicarDescontoPageState();
}

class _AplicarDescontoPageState extends State<AplicarDescontoPage>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  DescontoTipo _tipoSelecionado = DescontoTipo.percentual;
  double _valor = 0.0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    setState(() {
      if (_tipoSelecionado == DescontoTipo.valor) {
        // Remove formatação de moeda: "R$ 1.234,56" -> "1234.56"
        final numeros = text.replaceAll(RegExp(r'[^0-9,]'), '');
        _valor = double.tryParse(numeros.replaceAll(',', '.')) ?? 0.0;
      } else {
        _valor = double.tryParse(text.replaceAll(',', '.')) ?? 0.0;
      }
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
    return GestureDetector(
      onTap: () {
        // Fecha o teclado ao tocar fora dos campos de texto
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: const Text(
            'Aplicar Desconto',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue.shade50, Colors.white],
                ),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Card Header
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade600,
                                Colors.blue.shade400,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.discount,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Desconto',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Configure o desconto do orçamento',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Tipo de desconto
                      SegmentedButton<DescontoTipo>(
                        segments: const [
                          ButtonSegment(
                            value: DescontoTipo.percentual,
                            label: Text('Percentual'),
                            icon: Icon(Icons.percent),
                          ),
                          ButtonSegment(
                            value: DescontoTipo.valor,
                            label: Text('Valor Fixo'),
                            icon: Icon(Icons.attach_money),
                          ),
                        ],
                        selected: {_tipoSelecionado},
                        onSelectionChanged: (sel) {
                          setState(() {
                            _tipoSelecionado = sel.first;
                            _controller
                                .clear(); // Limpa o campo ao trocar de tipo
                            _valor = 0.0;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      // Campo de entrada
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextFormField(
                            controller: _controller,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters:
                                _tipoSelecionado == DescontoTipo.valor
                                    ? [
                                      FilteringTextInputFormatter.digitsOnly,
                                      CurrencyInputFormatter(),
                                    ]
                                    : null,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              labelText:
                                  _tipoSelecionado == DescontoTipo.valor
                                      ? 'Valor do desconto'
                                      : 'Percentual do desconto',
                              prefixText:
                                  _tipoSelecionado == DescontoTipo.valor
                                      ? null
                                      : null,
                              suffixText:
                                  _tipoSelecionado == DescontoTipo.percentual
                                      ? '%'
                                      : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.blue.shade600,
                                  width: 2,
                                ),
                              ),
                            ),
                            onChanged: _onChanged,
                            autofocus: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Card de resumo
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Colors.white, Colors.blue.shade50],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.receipt_long,
                                    color: Colors.blue.shade600,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Resumo',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildResumoRow(
                                'Subtotal',
                                'R\$ ${widget.subtotal.toStringAsFixed(2)}',
                                Colors.grey.shade700,
                              ),
                              const SizedBox(height: 12),
                              _buildResumoRow(
                                'Desconto',
                                '- R\$ ${desconto.toStringAsFixed(2)}',
                                Colors.red.shade600,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Divider(
                                  thickness: 1,
                                  color: Colors.blue.shade200,
                                ),
                              ),
                              _buildResumoRow(
                                'Total após desconto',
                                'R\$ ${restante.toStringAsFixed(2)}',
                                Colors.blue.shade700,
                                isBold: true,
                                fontSize: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Botões
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                side: BorderSide(
                                  color: Colors.blue.shade600,
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Cancelar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade700,
                                ),
                              ),
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
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade600,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                              ),
                              child: const Text(
                                'Aplicar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResumoRow(
    String label,
    String value,
    Color color, {
    bool isBold = false,
    double fontSize = 15,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
