import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/servico.dart';
import '../../../providers/services_provider.dart';
import 'package:provider/provider.dart';

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

class NovoServicoPage extends StatefulWidget {
  final Servico? original;

  const NovoServicoPage({super.key, this.original});

  @override
  State<NovoServicoPage> createState() => _NovoServicoPageState();
}

class _NovoServicoPageState extends State<NovoServicoPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _nomeCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _duracaoCtrl = TextEditingController();
  final _categoriaCtrl = TextEditingController();
  final _precoCtrl = TextEditingController();

  String? _unidadeSelecionada;

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
  ];

  @override
  void initState() {
    super.initState();
    if (widget.original != null) {
      final s = widget.original!;
      _nomeCtrl.text = s.titulo;
      _descricaoCtrl.text = s.descricao;
      _duracaoCtrl.text = s.duracao ?? '';
      _categoriaCtrl.text = s.categoria ?? '';
      _unidadeSelecionada = s.unidade ?? 'Nenhum';

      if (s.preco > 0) {
        _precoCtrl.text =
            'R\$ ${s.preco.toStringAsFixed(2).replaceAll('.', ',')}';
      }
    }
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _descricaoCtrl.dispose();
    _precoCtrl.dispose();
    _duracaoCtrl.dispose();
    _categoriaCtrl.dispose();
    super.dispose();
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

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final servico = Servico(
        id: widget.original?.id ?? '',
        titulo: _nomeCtrl.text.trim(),
        descricao: _descricaoCtrl.text.trim(),
        preco: _parseMoeda(_precoCtrl.text) ?? 0,
        unidade: _unidadeSelecionada,
        duracao: _duracaoCtrl.text.trim(),
        categoria: _categoriaCtrl.text.trim(),
      );

      final provider = context.read<ServicesProvider>();
      if (widget.original == null) {
        await provider.adicionarServico(servico);
      } else {
        await provider.atualizarServico(servico);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Serviço salvo com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Erro ao salvar serviço: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao salvar. Tente novamente.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.original != null;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Serviço' : 'Novo Serviço'),
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
                'Preencha os dados do serviço para seu catálogo',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 24),

              // --- CAMPOS PRINCIPAIS ---
              _campoTexto(
                label: 'Nome do serviço*',
                controller: _nomeCtrl,
                icon: Icons.work_outline,
                validator: _obrigatorio,
              ),
              _buildCampoMoeda(
                label: 'Preço (R\$)*',
                controller: _precoCtrl,
                icon: Icons.attach_money,
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      _parseMoeda(value) == 0) {
                    return 'Informe um preço válido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),
              Text(
                'Mais informações (Opcional)',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.black54,
                ),
              ),
              const Divider(height: 24),

              // --- CAMPOS OPCIONAIS ---
              _buildDropdownUnidades(),
              const SizedBox(height: 16),
              _campoTexto(
                label: 'Descrição',
                controller: _descricaoCtrl,
                icon: Icons.description_outlined,
                maxLines: 4,
              ),
              _campoTexto(
                label: 'Duração (ex: 1h, 30min)',
                controller: _duracaoCtrl,
                icon: Icons.timer_outlined,
              ),
              _campoTexto(
                label: 'Categoria (ex: Instalação)',
                controller: _categoriaCtrl,
                icon: Icons.category_outlined,
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  onPressed: _isLoading ? null : _salvar,
                  label: Text(_isLoading ? 'Salvando...' : 'Salvar Serviço'),
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

  // Seus helpers de widget (_buildCampoMoeda, _campoTexto, etc.)
  Widget _buildDropdownUnidades() {
    return DropdownButtonFormField<String>(
      value: _unidadeSelecionada,
      decoration: InputDecoration(
        labelText: 'Unidade de Cobrança',
        prefixIcon: const Icon(Icons.straighten_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      items:
          _unidades
              .map((u) => DropdownMenuItem(value: u, child: Text(u)))
              .toList(),
      onChanged: (value) => setState(() => _unidadeSelecionada = value),
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
}
