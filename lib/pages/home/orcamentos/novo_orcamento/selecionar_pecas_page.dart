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
  const SelecionarPecasPage({super.key});

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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Peça/Material'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Preencha os dados do item para este orçamento',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              _campoTexto(
                label: 'Nome da Peça/Material *',
                controller: _nomeController,
                icon: Icons.label_outline,
                validator:
                    (v) => v == null || v.isEmpty ? 'Campo obrigatório' : null,
              ),
              _buildCampoMoeda(
                label: 'Preço *',
                controller: _precoController,
                icon: Icons.attach_money,
                validator:
                    (v) =>
                        (v == null || v.isEmpty || _parseMoeda(v) == 0)
                            ? 'Informe um preço válido'
                            : null,
              ),

              // Adicione o campo de quantidade se desejar que o usuário o edite aqui
              const SizedBox(height: 24),
              Text(
                'Mais informações (Opcional)',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.black54,
                ),
              ),
              const Divider(height: 24),

              _buildCampoMoeda(
                label: 'Custo',
                controller: _custoController,
                icon: Icons.paid_outlined,
              ),
              _campoTexto(
                label: 'Marca',
                controller: _marcaController,
                icon: Icons.store_outlined,
              ),
              _campoTexto(
                label: 'Modelo',
                controller: _modeloController,
                icon: Icons.style_outlined,
              ),

              // ✅ MUDANÇA 3: Adicionar o ícone de scanner ao campo
              _campoTexto(
                label: 'Código do produto',
                controller: _codigoProdutoController,
                icon: Icons.qr_code_2,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner_outlined),
                  onPressed: _escanearCodigoDeBarras,
                  tooltip: 'Escanear código',
                ),
              ),
              _campoTexto(
                label: 'Código Interno',
                controller: _codigoInternoController,
                icon: Icons.tag,
              ),
              _buildDropdownUnidades(),
              if (_unidadeSelecionada == 'Outro')
                _campoTexto(
                  label: 'Especifique a unidade',
                  controller: _unidadePersonalizadaController,
                  icon: Icons.edit_note_outlined,
                ),

              _campoTexto(
                label: 'Descrição',
                controller: _descricaoController,
                icon: Icons.description_outlined,
                maxLines: 3,
              ),

              CheckboxListTile(
                title: const Text('Salvar para uso futuro no catálogo'),
                value: _salvarCatalogo,
                onChanged:
                    (value) => setState(() => _salvarCatalogo = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_shopping_cart),
                  onPressed: _salvarPeca,
                  label: const Text('Adicionar ao Orçamento'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
          prefixIcon: const Icon(Icons.straighten_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCampoMoeda({
    required String label,
    required TextEditingController controller,
    required IconData icon,
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
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
          prefixIcon: icon != null ? Icon(icon) : null,
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}
