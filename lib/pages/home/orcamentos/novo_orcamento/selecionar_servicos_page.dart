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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Adicionar Serviço/Item',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade600, Colors.green.shade400],
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
              colors: [Colors.green.shade50, Colors.white, Colors.white],
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
                            Colors.green.shade600,
                            Colors.green.shade400,
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
                              Icons.build_outlined,
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
                                  'Novo Serviço',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Preencha os dados do serviço',
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
                        label: 'Nome do Serviço/Produto *',
                        controller: _nomeController,
                        icon: Icons.work_outline,
                        corIcone: Colors.green,
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
                        corIcone: Colors.green,
                        validator:
                            (v) =>
                                (v == null || v.isEmpty || _parseMoeda(v) == 0)
                                    ? 'Informe um preço válido'
                                    : null,
                      ),
                      _buildCampoQuantidade(),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Card: Informações Adicionais
                  _buildCard(
                    title: 'Informações Adicionais',
                    icon: Icons.description_outlined,
                    children: [
                      _buildDropdownUnidades(),
                      const SizedBox(height: 16),
                      _buildCampoMoeda(
                        label: 'Custo',
                        controller: _custoController,
                        icon: Icons.paid_outlined,
                        corIcone: Colors.green,
                      ),
                      _campoTexto(
                        label: 'Descrição',
                        controller: _descricaoController,
                        icon: Icons.description_outlined,
                        corIcone: Colors.green,
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
                      onPressed: _salvarServico,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
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
                      colors: [Colors.green.shade400, Colors.green.shade600],
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
                prefixIcon: Icon(
                  Icons.pin_outlined,
                  color: Colors.green.shade600,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.green.shade600,
                    width: 2,
                  ),
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
              border: Border.all(color: Colors.green.shade200, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _incrementarQuantidade,
                    color: Colors.green.shade600,
                    splashRadius: 20,
                  ),
                ),
                Container(height: 1, width: 40, color: Colors.green.shade200),
                Expanded(
                  child: IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: _decrementarQuantidade,
                    color: Colors.red.shade400,
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
        prefixIcon: Icon(
          Icons.straighten_outlined,
          color: Colors.green.shade600,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green.shade600, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
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
          'Este serviço ficará disponível no catálogo',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        value: _salvarCatalogo,
        onChanged: (value) => setState(() => _salvarCatalogo = value ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: Colors.green.shade600,
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
