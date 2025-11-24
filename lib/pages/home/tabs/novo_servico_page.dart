import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/servico.dart';
import '../../../providers/services_provider.dart';
import '../../../routes/app_routes.dart';
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

    // Criar objeto de serviço temporário com os dados preenchidos
    final servicoTemp = {
      'tipo': 'servico',
      'descricao': _nomeCtrl.text.trim(),
      'detalhe': _descricaoCtrl.text.trim(),
      'preco': _parseMoeda(_precoCtrl.text) ?? 0.0,
      'custo': 0.0,
      'quantidade': 1,
      'subtotal': _parseMoeda(_precoCtrl.text) ?? 0.0,
    };

    // Navegar para novo orçamento
    Navigator.pushNamed(
      context,
      AppRoutes.novoOrcamento,
      arguments: {'servicoInicial': servicoTemp},
    );
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
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(child: Text('Serviço salvo com sucesso!')),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Erro ao salvar serviço: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(child: Text('Erro ao salvar. Tente novamente.')),
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
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.original != null;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isEditing ? 'Editar Serviço' : 'Novo Serviço',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.green.shade600, Colors.green.shade400],
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
              colors: [Colors.green.shade50, Colors.white, Colors.white],
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
                          color: Colors.green.shade100.withOpacity(0.5),
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
                                Colors.green.shade400,
                                Colors.green.shade600,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.build_outlined,
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
                                    ? 'Editar Serviço'
                                    : 'Cadastrar Novo Serviço',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Preencha os dados do serviço',
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
                      _buildDropdownUnidades(),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Card de informações adicionais
                  _buildCard(
                    title: 'Informações Adicionais',
                    subtitle: 'Opcional',
                    icon: Icons.description_outlined,
                    children: [
                      _campoTexto(
                        label: 'Descrição',
                        controller: _descricaoCtrl,
                        icon: Icons.notes,
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
                        backgroundColor: Colors.green.shade600,
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
                                    isEditing
                                        ? 'Atualizar Serviço'
                                        : 'Salvar Serviço',
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
            color: Colors.green.shade100.withOpacity(0.5),
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
                  Colors.green.shade50,
                  Colors.green.shade50.withOpacity(0.5),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.green.shade700, size: 24),
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

  // Seus helpers de widget (_buildCampoMoeda, _campoTexto, etc.)
  Widget _buildDropdownUnidades() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: _unidadeSelecionada,
        decoration: InputDecoration(
          labelText: 'Unidade de Cobrança',
          labelStyle: TextStyle(color: Colors.grey.shade700),
          prefixIcon: Icon(
            Icons.straighten_outlined,
            color: Colors.green.shade600,
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
            borderSide: BorderSide(color: Colors.green.shade600, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        items:
            _unidades
                .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                .toList(),
        onChanged: (value) => setState(() => _unidadeSelecionada = value),
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
          prefixIcon: Icon(icon, color: Colors.green.shade600),
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
            borderSide: BorderSide(color: Colors.green.shade600, width: 2),
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
              icon != null ? Icon(icon, color: Colors.green.shade600) : null,
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
            borderSide: BorderSide(color: Colors.green.shade600, width: 2),
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
}
