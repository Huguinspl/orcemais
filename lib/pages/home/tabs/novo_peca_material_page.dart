import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../models/peca_material.dart';
import '../../../providers/pecas_provider.dart';
import '../../../routes/app_routes.dart';
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

  void _usarParaOrcamento() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Preencha os campos obrigatórios primeiro'),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    // Criar objeto temporário com os dados preenchidos
    final pecaTemp = {
      'tipo': 'peca',
      'descricao': _nomeController.text.trim(),
      'detalhe': _descricaoController.text.trim(),
      'preco': _parseMoeda(_precoController.text) ?? 0.0,
      'custo': _parseMoeda(_custoController.text) ?? 0.0,
      'quantidade': 1,
      'subtotal': _parseMoeda(_precoController.text) ?? 0.0,
    };

    // Navegar para novo orçamento
    Navigator.pushNamed(
      context,
      AppRoutes.novoOrcamento,
      arguments: {'servicoInicial': pecaTemp},
    );
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
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(child: Text('Peça salva com sucesso!')),
            ],
          ),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Ocorreu um erro ao salvar: $e')),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.peca != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Editar Peça' : 'Nova Peça',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.orange.shade600, Colors.orange.shade400],
            ),
          ),
        ),
        elevation: 0,
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header moderno
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.shade100.withOpacity(0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.shade400,
                              Colors.orange.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.handyman,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing
                                  ? 'Editar Peça/Material'
                                  : 'Cadastrar Nova Peça',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Preencha os dados da peça',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Card de campos principais
                _buildCard(
                  title: 'Informações Principais',
                  icon: Icons.info_outline,
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
                  ],
                ),
                const SizedBox(height: 16),

                // Card de detalhes do produto
                _buildCard(
                  title: 'Detalhes do Produto',
                  subtitle: 'Opcional',
                  icon: Icons.inventory_2_outlined,
                  children: [
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
                    _campoTexto(
                      label: 'Código do produto',
                      controller: _codigoProdutoController,
                      icon: Icons.qr_code_2,
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
                    ),
                    _buildDropdownUnidades(),
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
                  ],
                ),
                const SizedBox(height: 32),

                // Botões de ação
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _salvar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: _isLoading ? 0 : 4,
                    ),
                    child:
                        _isLoading
                            ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Salvando...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                            : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  isEditing ? 'Atualizar Peça' : 'Salvar Peça',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                  ),
                ),
                const SizedBox(height: 12),

                // Botão "Usar para Orçamento"
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _usarParaOrcamento,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue.shade600,
                      side: BorderSide(color: Colors.blue.shade600, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: Colors.blue.shade50,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 24,
                          color: Colors.blue.shade600,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Usar para Orçamento',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    String? subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.shade100.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.shade50,
                  Colors.orange.shade50.withOpacity(0.5),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.orange.shade700, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownUnidades() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: _unidadeSelecionada,
        items:
            _unidadesDeMedida
                .map((u) => DropdownMenuItem<String>(value: u, child: Text(u)))
                .toList(),
        onChanged: (v) => setState(() => _unidadeSelecionada = v),
        decoration: InputDecoration(
          labelText: 'Unidade de medida',
          labelStyle: TextStyle(color: Colors.grey.shade700),
          prefixIcon: Icon(
            Icons.square_foot_outlined,
            color: Colors.orange.shade600,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.orange.shade600, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
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
          labelStyle: TextStyle(color: Colors.grey.shade700),
          prefixIcon: Icon(icon, color: Colors.orange.shade600),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.orange.shade600, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
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
          labelStyle: TextStyle(color: Colors.grey.shade700),
          prefixIcon:
              icon != null ? Icon(icon, color: Colors.orange.shade600) : null,
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.orange.shade600, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
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
