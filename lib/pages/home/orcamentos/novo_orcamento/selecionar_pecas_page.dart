import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../scanner_page.dart'; // ✅ MUDANÇA 1: Importar a página de scanner

// Classe de formatação de moeda
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');
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

class SelecionarPecasPage extends StatefulWidget {
  final String? textoBotao; // Texto customizável para o botão

  const SelecionarPecasPage({super.key, this.textoBotao});

  @override
  State<SelecionarPecasPage> createState() => _SelecionarPecasPageState();
}

class _SelecionarPecasPageState extends State<SelecionarPecasPage> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _precoController = TextEditingController();
  final _quantidadeController = TextEditingController(text: '1,000');
  final _custoController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _codigoProdutoController = TextEditingController();
  final _codigoInternoController = TextEditingController();
  final _unidadePersonalizadaController = TextEditingController();

  String? _unidadeSelecionada = 'Nenhum';
  bool _salvarCatalogo = false;

  final List<String> _unidades = [
    'Nenhum',
    'Unidade (un)',
    'Metro (m)',
    'Metro quadrado (m²)',
    'Metros cúbico (m³)',
    'Kilômetro (km)',
    'Quilômetro quadrado (km²)',
    'Centímetro (cm)',
    'Milímetro (mm)',
    'Hectares',
    'Litro (L)',
    'Mililitro (mL)',
    'Grama (g)',
    'Quilograma (kg)',
    'Minuto (min)',
    'Hora (hr)',
    'Dia',
    'Semana',
    'Mês',
    'Ano',
    'Outro',
  ];

  @override
  void dispose() {
    _nomeController.dispose();
    _precoController.dispose();
    _quantidadeController.dispose();
    _custoController.dispose();
    _descricaoController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    _codigoProdutoController.dispose();
    _codigoInternoController.dispose();
    _unidadePersonalizadaController.dispose();
    super.dispose();
  }

  // ✅ MUDANÇA 2: Adicionar a função para chamar a página de scanner
  Future<void> _escanearCodigoDeBarras() async {
    final codigoEscaneado = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ScannerPage()),
    );

    if (codigoEscaneado != null && mounted) {
      setState(() {
        _codigoProdutoController.text = codigoEscaneado;
      });
    }
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

  void _salvarPeca() {
    if (_formKey.currentState?.validate() ?? false) {
      final String unidadeFinal =
          (_unidadeSelecionada == 'Outro')
              ? _unidadePersonalizadaController.text.trim()
              : _unidadeSelecionada ?? 'Nenhum';

      final peca = {
        'nome': _nomeController.text.trim(),
        'preco': _parseMoeda(_precoController.text) ?? 0.0,
        'quantidade':
            double.tryParse(_quantidadeController.text.replaceAll(',', '.')) ??
            1.0,
        'unidade': unidadeFinal,
        'custo': _parseMoeda(_custoController.text) ?? 0.0,
        'descricao': _descricaoController.text.trim(),
        'salvarNoCatalogo': _salvarCatalogo,
        'marca': _marcaController.text.trim(),
        'modelo': _modeloController.text.trim(),
        'codigoProduto': _codigoProdutoController.text.trim(),
        'codigoInterno': _codigoInternoController.text.trim(),
      };
      Navigator.pop(context, peca);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Adicionar Peça/Material',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade600, Colors.orange.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.shade50, Colors.white, Colors.white],
          ),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header card
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.shade600,
                          Colors.orange.shade400,
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
                            Icons.inventory_2_outlined,
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
                                'Nova Peça/Material',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Preencha os dados do item',
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

                // Card: Informações Principais
                _buildCard(
                  title: 'Informações Principais',
                  icon: Icons.info_outline,
                  children: [
                    _campoTexto(
                      label: 'Nome da Peça/Material *',
                      controller: _nomeController,
                      icon: Icons.label_outline,
                      corIcone: Colors.orange,
                      validator:
                          (v) =>
                              v == null || v.isEmpty
                                  ? 'Campo obrigatório'
                                  : null,
                    ),
                    _buildCampoMoeda(
                      label: 'Preço *',
                      controller: _precoController,
                      icon: Icons.attach_money,
                      corIcone: Colors.orange,
                      validator:
                          (v) =>
                              (v == null || v.isEmpty || _parseMoeda(v) == 0)
                                  ? 'Informe um preço válido'
                                  : null,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Card: Detalhes do Produto
                _buildCard(
                  title: 'Detalhes do Produto',
                  icon: Icons.description_outlined,
                  children: [
                    _buildCampoMoeda(
                      label: 'Custo',
                      controller: _custoController,
                      icon: Icons.paid_outlined,
                      corIcone: Colors.orange,
                    ),
                    _campoTexto(
                      label: 'Marca',
                      controller: _marcaController,
                      icon: Icons.store_outlined,
                      corIcone: Colors.orange,
                    ),
                    _campoTexto(
                      label: 'Modelo',
                      controller: _modeloController,
                      icon: Icons.style_outlined,
                      corIcone: Colors.orange,
                    ),
                    _campoTexto(
                      label: 'Código do produto',
                      controller: _codigoProdutoController,
                      icon: Icons.qr_code_2,
                      corIcone: Colors.orange,
                      suffixIcon: IconButton(
                        icon: Icon(
                          Icons.qr_code_scanner_outlined,
                          color: Colors.orange.shade600,
                        ),
                        onPressed: _escanearCodigoDeBarras,
                        tooltip: 'Escanear código',
                      ),
                    ),
                    _campoTexto(
                      label: 'Código Interno',
                      controller: _codigoInternoController,
                      icon: Icons.tag,
                      corIcone: Colors.orange,
                    ),
                    _buildDropdownUnidades(),
                    if (_unidadeSelecionada == 'Outro')
                      _campoTexto(
                        label: 'Especifique a unidade',
                        controller: _unidadePersonalizadaController,
                        icon: Icons.edit_note_outlined,
                        corIcone: Colors.orange,
                      ),
                    _campoTexto(
                      label: 'Descrição',
                      controller: _descricaoController,
                      icon: Icons.description_outlined,
                      corIcone: Colors.orange,
                      maxLines: 3,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildCheckboxSalvarCatalogo(),
                const SizedBox(height: 24),

                // Botão de adicionar
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _salvarPeca,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_shopping_cart, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          widget.textoBotao ?? 'Adicionar ao Orçamento',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade400, Colors.orange.shade600],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  // O restante do arquivo (helpers) não precisa de alterações
  Widget _buildDropdownUnidades() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        value: _unidadeSelecionada,
        items:
            _unidades
                .map(
                  (unidade) =>
                      DropdownMenuItem(value: unidade, child: Text(unidade)),
                )
                .toList(),
        onChanged: (value) => setState(() => _unidadeSelecionada = value),
        decoration: InputDecoration(
          labelText: 'Unidade de medida',
          prefixIcon: Icon(
            Icons.straighten_outlined,
            color: Colors.orange.shade600,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.orange.shade600, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCheckboxSalvarCatalogo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: CheckboxListTile(
        title: const Text(
          'Salvar para uso futuro no catálogo',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          'Esta peça ficará disponível no catálogo',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        value: _salvarCatalogo,
        onChanged: (value) => setState(() => _salvarCatalogo = value ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: Colors.orange.shade600,
      ),
    );
  }

  Widget _buildCampoMoeda({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    MaterialColor? corIcone,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          CurrencyInputFormatter(),
        ],
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: corIcone?.shade600),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: corIcone?.shade600 ?? Colors.blue,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _campoTexto({
    required String label,
    required TextEditingController controller,
    IconData? icon,
    Widget? suffixIcon,
    MaterialColor? corIcone,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon:
              icon != null ? Icon(icon, color: corIcone?.shade600) : null,
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: corIcone?.shade600 ?? Colors.blue,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}
