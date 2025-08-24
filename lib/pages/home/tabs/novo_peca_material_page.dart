import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../models/peca_material.dart';
import '../../../providers/pecas_provider.dart';
import '../../scanner_page.dart'; // ✅ CORREÇÃO 1: Adicionando o import da página de scanner

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

class NovoPecaMaterialPage extends StatefulWidget {
  final PecaMaterial? peca;
  const NovoPecaMaterialPage({super.key, this.peca});

  @override
  State<NovoPecaMaterialPage> createState() => _NovoPecaMaterialPageState();
}

class _NovoPecaMaterialPageState extends State<NovoPecaMaterialPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final List<String> _unidadesDeMedida = [
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
  String? _unidadeSelecionada = 'Nenhum';

  final _nomeController = TextEditingController();
  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _codigoProdutoController = TextEditingController();
  final _codigoInternoController = TextEditingController();
  final _unidadePersonalizadaController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _precoController = TextEditingController();
  final _custoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.peca != null) {
      final p = widget.peca!;
      _nomeController.text = p.nome;
      _marcaController.text = p.marca ?? '';
      _modeloController.text = p.modelo ?? '';
      _codigoProdutoController.text = p.codigoProduto ?? '';
      _codigoInternoController.text = p.codigoInterno ?? '';
      _descricaoController.text = p.descricao ?? '';
      if (p.preco != null)
        _precoController.text =
            'R\$ ${p.preco!.toStringAsFixed(2).replaceAll('.', ',')}';
      if (p.custo != null)
        _custoController.text =
            'R\$ ${p.custo!.toStringAsFixed(2).replaceAll('.', ',')}';
      if (p.unidadeMedida != null && p.unidadeMedida!.isNotEmpty) {
        if (_unidadesDeMedida.contains(p.unidadeMedida)) {
          _unidadeSelecionada = p.unidadeMedida;
        } else {
          _unidadeSelecionada = 'Outro';
          _unidadePersonalizadaController.text = p.unidadeMedida!;
        }
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _precoController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    _codigoProdutoController.dispose();
    _codigoInternoController.dispose();
    _unidadePersonalizadaController.dispose();
    _custoController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  // ✅ CORREÇÃO 2: Reintroduzindo a função para chamar a página de scanner
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

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final preco = _parseMoeda(_precoController.text) ?? 0;
      final custo = _parseMoeda(_custoController.text);
      final String unidadeFinal =
          (_unidadeSelecionada == 'Outro')
              ? _unidadePersonalizadaController.text.trim()
              : _unidadeSelecionada ?? 'Nenhum';

      final novaPeca = PecaMaterial(
        id: widget.peca?.id ?? '',
        nome: _nomeController.text.trim(),
        preco: preco,
        marca: _marcaController.text.trim(),
        modelo: _modeloController.text.trim(),
        codigoProduto: _codigoProdutoController.text.trim(),
        codigoInterno: _codigoInternoController.text.trim(),
        unidadeMedida: unidadeFinal,
        custo: custo,
        descricao: _descricaoController.text.trim(),
      );

      final provider = context.read<PecasProvider>();
      if (widget.peca == null) {
        await provider.addPeca(novaPeca);
      } else {
        await provider.atualizarPeca(widget.peca!.id, novaPeca);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Peça salva com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ocorreu um erro ao salvar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.peca != null;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Peça' : 'Nova Peça'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            children: [
              _campoTexto(
                label: 'Nome*',
                controller: _nomeController,
                icon: Icons.label_outline,
                validator: _obrigatorio,
              ),
              _buildCampoMoeda(
                label: 'Preço de venda (R\$)*',
                controller: _precoController,
                icon: Icons.attach_money,
                validator:
                    (v) =>
                        (v == null || v.isEmpty || _parseMoeda(v) == 0)
                            ? 'Preço inválido'
                            : null,
              ),
              _buildCampoMoeda(
                label: 'Custo (R\$)',
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

              // ✅ CORREÇÃO 3: Adicionando o ícone de scanner ao campo
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

              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DropdownButtonFormField<String>(
                  value: _unidadeSelecionada,
                  items:
                      _unidadesDeMedida
                          .map(
                            (u) => DropdownMenuItem<String>(
                              value: u,
                              child: Text(u),
                            ),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _unidadeSelecionada = v),
                  decoration: InputDecoration(
                    labelText: 'Unidade de medida',
                    prefixIcon: const Icon(Icons.square_foot_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              if (_unidadeSelecionada == 'Outro')
                _campoTexto(
                  label: 'Especifique a unidade*',
                  controller: _unidadePersonalizadaController,
                  icon: Icons.edit_note_outlined,
                  validator: _obrigatorio,
                ),

              _campoTexto(
                label: 'Descrição',
                controller: _descricaoController,
                icon: Icons.description_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  onPressed: _isLoading ? null : _salvar,
                  label: Text(_isLoading ? 'Salvando...' : 'Salvar'),
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

  String? _obrigatorio(String? valor) =>
      (valor == null || valor.trim().isEmpty)
          ? 'Este campo é obrigatório'
          : null;
  double? _parseMoeda(String value) {
    try {
      final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleaned.isEmpty) return 0.0;
      return int.parse(cleaned) / 100;
    } catch (e) {
      return null;
    }
  }
}
