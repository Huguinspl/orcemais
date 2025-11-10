import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../models/servico.dart';
import '../../../../providers/services_provider.dart';

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

class SelecionarServicosPage extends StatefulWidget {
  final String? textoBotao; // Texto customizável para o botão
  
  const SelecionarServicosPage({super.key, this.textoBotao});

  @override
  State<SelecionarServicosPage> createState() => _SelecionarServicosPageState();
}

class _SelecionarServicosPageState extends State<SelecionarServicosPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _precoController = TextEditingController();
  final _quantidadeController = TextEditingController(text: '1,000');
  final _custoController = TextEditingController();
  final _descricaoController = TextEditingController();
  String? _unidadeSelecionada;
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
    super.dispose();
  }

  void _incrementarQuantidade() {
    double atual =
        double.tryParse(_quantidadeController.text.replaceAll(',', '.')) ?? 1.0;
    setState(() {
      atual += 1;
      _quantidadeController.text = atual
          .toStringAsFixed(3)
          .replaceAll('.', ',');
    });
  }

  void _decrementarQuantidade() {
    double atual =
        double.tryParse(_quantidadeController.text.replaceAll(',', '.')) ?? 1.0;
    if (atual > 1) {
      setState(() {
        atual -= 1;
        _quantidadeController.text = atual
            .toStringAsFixed(3)
            .replaceAll('.', ',');
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

  // ✅ CORREÇÃO: A função _salvarServico agora também salva no catálogo
  Future<void> _salvarServico() async {
    if (_formKey.currentState?.validate() ?? false) {
      // 1. Verifica se a opção de salvar no catálogo foi marcada
      if (_salvarCatalogo) {
        // Cria um objeto Servico com os dados do formulário
        final servicoParaCatalogo = Servico(
          titulo: _nomeController.text.trim(),
          preco: _parseMoeda(_precoController.text) ?? 0.0,
          descricao: _descricaoController.text.trim(),
          unidade: _unidadeSelecionada,
          custo: _parseMoeda(_custoController.text),
        );

        // Usa o provider para salvar o serviço no Firestore
        // 'listen: false' é usado porque só estamos executando uma ação
        try {
          await context.read<ServicesProvider>().adicionarServico(
            servicoParaCatalogo,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '"${servicoParaCatalogo.titulo}" salvo no catálogo!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao salvar no catálogo: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      // 2. Prepara os dados para retornar à página de orçamento (isso não muda)
      final itemParaOrcamento = {
        'nome': _nomeController.text.trim(),
        'preco': _parseMoeda(_precoController.text) ?? 0.0,
        'quantidade':
            double.tryParse(_quantidadeController.text.replaceAll(',', '.')) ??
            1.0,
        'unidade': _unidadeSelecionada ?? 'Nenhum',
        'custo': _parseMoeda(_custoController.text) ?? 0.0,
        'descricao': _descricaoController.text.trim(),
        'salvarNoCatalogo': _salvarCatalogo,
      };

      // 3. Fecha a tela e envia os dados do item de volta para o orçamento
      if (mounted) {
        Navigator.pop(context, itemParaOrcamento);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Serviço/Item'),
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
                label: 'Nome do Serviço/Produto *',
                controller: _nomeController,
                icon: Icons.work_outline,
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
              _buildCampoQuantidade(),

              const SizedBox(height: 24),
              Text(
                'Mais informações (Opcional)',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.black54,
                ),
              ),
              const Divider(height: 24),

              _buildDropdownUnidades(),
              const SizedBox(height: 16),
              _buildCampoMoeda(
                label: 'Custo',
                controller: _custoController,
                icon: Icons.paid_outlined,
              ),
              _campoTexto(
                label: 'Descrição',
                controller: _descricaoController,
                icon: Icons.description_outlined,
                maxLines: 3,
              ),

              _buildCheckboxSalvarCatalogo(),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_shopping_cart),
                  onPressed: _salvarServico,
                  label: Text(widget.textoBotao ?? 'Adicionar ao Orçamento'),
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

  // --- O restante do seu código (os helpers de widget) não precisa de alterações ---
  Widget _buildCampoQuantidade() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextFormField(
              controller: _quantidadeController,
              decoration: InputDecoration(
                labelText: 'Quantidade',
                prefixIcon: const Icon(Icons.pin_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 58,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _incrementarQuantidade,
                    color: Colors.green,
                    splashRadius: 20,
                  ),
                ),
                Container(height: 1, width: 40, color: Colors.grey.shade200),
                Expanded(
                  child: IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: _decrementarQuantidade,
                    color: Colors.red,
                    splashRadius: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownUnidades() {
    return DropdownButtonFormField<String>(
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
    );
  }

  Widget _buildCheckboxSalvarCatalogo() {
    return CheckboxListTile(
      title: const Text('Salvar para uso futuro no catálogo'),
      value: _salvarCatalogo,
      onChanged: (value) => setState(() => _salvarCatalogo = value ?? false),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      activeColor: Theme.of(context).colorScheme.primary,
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
}
