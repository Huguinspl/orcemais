import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/agendamento.dart';
import '../../../models/receita.dart';
import '../../../providers/agendamentos_provider.dart';
import '../../../providers/transacoes_provider.dart';
import '../../../providers/user_provider.dart';

/// Página para criar/editar agendamento de despesa a pagar (despesa futura)
/// Permite criar uma nova despesa a pagar ou buscar de despesas existentes
class AgendamentoAPagarPage extends StatefulWidget {
  final Agendamento? agendamento;

  const AgendamentoAPagarPage({super.key, this.agendamento});

  @override
  State<AgendamentoAPagarPage> createState() => _AgendamentoAPagarPageState();
}

class _AgendamentoAPagarPageState extends State<AgendamentoAPagarPage> {
  bool _mostrarFormulario = false;
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  final _observacoesController = TextEditingController();

  DateTime? _dataSelecionada;
  TimeOfDay? _horaSelecionada;
  CategoriaTransacao _categoriaSelecionada = CategoriaTransacao.fornecedores;
  bool _salvando = false;
  String? _agendamentoId;

  @override
  void initState() {
    super.initState();

    // Se está editando um agendamento existente
    if (widget.agendamento != null) {
      _mostrarFormulario = true;
      _agendamentoId = widget.agendamento!.id;

      // Extrair data e hora do agendamento
      final dataHora = widget.agendamento!.dataHora.toDate();
      _dataSelecionada = dataHora;
      _horaSelecionada = TimeOfDay(
        hour: dataHora.hour,
        minute: dataHora.minute,
      );

      // Extrair informações das observações
      _parseObservacoesAgendamento(widget.agendamento!.observacoes);
    }

    // Carrega transações
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<UserProvider>().uid;
      context.read<TransacoesProvider>().carregarTransacoes(userId);
    });
  }

  /// Extrai informações das observações do agendamento para preencher os campos
  void _parseObservacoesAgendamento(String observacoes) {
    final linhas = observacoes.split('\n');

    for (final linha in linhas) {
      if (linha.startsWith('Descrição:')) {
        _descricaoController.text = linha.replaceFirst('Descrição:', '').trim();
      } else if (linha.startsWith('Valor:')) {
        _valorController.text =
            linha.replaceFirst('Valor:', '').replaceAll('R\$', '').trim();
      } else if (linha.startsWith('Categoria:')) {
        final nomeCategoria = linha.replaceFirst('Categoria:', '').trim();
        // Buscar categoria pelo nome
        try {
          _categoriaSelecionada = CategoriaTransacao.values.firstWhere(
            (cat) => cat.nome.toLowerCase() == nomeCategoria.toLowerCase(),
          );
        } catch (_) {
          // Categoria não encontrada, ignora
        }
      }
    }

    // Se não conseguiu extrair descrição, usa o clienteNome
    if (_descricaoController.text.isEmpty &&
        widget.agendamento?.clienteNome != null) {
      _descricaoController.text = widget.agendamento!.clienteNome!;
    }
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate:
          _dataSelecionada ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.red.shade600,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (data != null) {
      setState(() => _dataSelecionada = data);
    }
  }

  Future<void> _selecionarHora() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: _horaSelecionada ?? const TimeOfDay(hour: 10, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              dialBackgroundColor: Colors.red.shade50,
              hourMinuteTextColor: Colors.red.shade700,
            ),
          ),
          child: child!,
        );
      },
    );
    if (hora != null) {
      setState(() => _horaSelecionada = hora);
    }
  }

  Future<void> _salvarNovaDespesa() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dataSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Selecione a data de vencimento'),
          backgroundColor: Colors.red.shade600,
        ),
      );
      return;
    }

    setState(() => _salvando = true);

    try {
      final userId = context.read<UserProvider>().uid;
      final agProv = context.read<AgendamentosProvider>();

      final valor =
          double.tryParse(_valorController.text.replaceAll(',', '.')) ?? 0.0;

      // Combina data e hora
      final dataHora = DateTime(
        _dataSelecionada!.year,
        _dataSelecionada!.month,
        _dataSelecionada!.day,
        _horaSelecionada?.hour ?? 10,
        _horaSelecionada?.minute ?? 0,
      );

      // Monta observações para o agendamento
      final obsAgendamento = StringBuffer();
      obsAgendamento.writeln('[DESPESA A PAGAR]');
      obsAgendamento.writeln('Descrição: ${_descricaoController.text}');
      obsAgendamento.writeln(
        'Valor: R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}',
      );
      obsAgendamento.writeln('Categoria: ${_categoriaSelecionada.nome}');
      if (_observacoesController.text.isNotEmpty) {
        obsAgendamento.writeln(_observacoesController.text);
      }

      final clienteNome = 'Despesa: ${_descricaoController.text}';

      if (_agendamentoId != null) {
        // MODO EDIÇÃO: Atualizar agendamento existente
        final agendamentoAtualizado = Agendamento(
          id: _agendamentoId!,
          orcamentoId: 'despesa_a_pagar',
          orcamentoNumero: null,
          clienteNome: clienteNome,
          dataHora: Timestamp.fromDate(dataHora),
          status: widget.agendamento?.status ?? 'Pendente',
          observacoes: obsAgendamento.toString().trim(),
          criadoEm: widget.agendamento?.criadoEm ?? Timestamp.now(),
          atualizadoEm: Timestamp.now(),
        );

        await agProv.atualizarAgendamento(agendamentoAtualizado);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Despesa a pagar atualizada!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // MODO CRIAÇÃO: Criar nova transação e agendamento
        final transacoesProv = context.read<TransacoesProvider>();

        final transacao = Transacao(
          descricao: _descricaoController.text,
          valor: valor,
          tipo: TipoTransacao.despesa,
          categoria: _categoriaSelecionada,
          data: _dataSelecionada!,
          observacoes: _observacoesController.text,
          userId: userId,
          isFutura: true, // Marca como despesa a pagar
        );

        await transacoesProv.adicionarTransacao(transacao);

        // Também cria um agendamento
        await agProv.adicionarAgendamento(
          orcamentoId: 'despesa_a_pagar',
          orcamentoNumero: null,
          clienteNome: clienteNome,
          dataHora: Timestamp.fromDate(dataHora),
          status: 'Pendente',
          observacoes: obsAgendamento.toString().trim(),
        );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Despesa a pagar agendada com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        title: Text(
          widget.agendamento != null
              ? 'Editar Despesa a Pagar'
              : 'Agendamento a Pagar',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.red.shade50, Colors.white, Colors.white],
          ),
        ),
        child:
            _mostrarFormulario ? _buildFormulario(dateFormat) : _buildSelecao(),
      ),
    );
  }

  Widget _buildSelecao() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade400, Colors.red.shade600],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.call_made,
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
                        'Despesa a Pagar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Agende uma despesa futura',
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
          const SizedBox(height: 32),

          // Opção: Criar nova
          _buildOpcaoCard(
            titulo: 'Criar Nova',
            subtitulo: 'Adicionar uma nova despesa a pagar',
            icone: Icons.add_circle_outline,
            cor: Colors.red,
            onTap: () => setState(() => _mostrarFormulario = true),
          ),
          const SizedBox(height: 16),

          // Opção: Buscar existentes
          _buildOpcaoCard(
            titulo: 'Buscar Existentes',
            subtitulo: 'Ver despesas a pagar já cadastradas',
            icone: Icons.search,
            cor: Colors.orange,
            onTap: () => _mostrarDespesasExistentes(),
          ),
        ],
      ),
    );
  }

  Widget _buildOpcaoCard({
    required String titulo,
    required String subtitulo,
    required IconData icone,
    required MaterialColor cor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cor.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [cor.shade400, cor.shade600]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icone, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitulo,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: cor.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFormulario(DateFormat dateFormat) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Botão voltar
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _mostrarFormulario = false),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Voltar'),
              style: TextButton.styleFrom(foregroundColor: Colors.red.shade600),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade400, Colors.red.shade600],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.add_circle, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Text(
                  'Nova Despesa a Pagar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Descrição
          _buildSectionTitle('Descrição', Icons.description),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descricaoController,
            decoration: InputDecoration(
              hintText: 'Ex: Conta de luz, Aluguel, Fornecedor...',
              filled: true,
              fillColor: Colors.white,
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
                borderSide: BorderSide(color: Colors.red.shade600),
              ),
              prefixIcon: Icon(Icons.receipt_long, color: Colors.red.shade600),
            ),
            validator:
                (v) => v == null || v.isEmpty ? 'Informe a descrição' : null,
          ),
          const SizedBox(height: 20),

          // Valor
          _buildSectionTitle('Valor', Icons.attach_money),
          const SizedBox(height: 12),
          TextFormField(
            controller: _valorController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '0,00',
              prefixText: 'R\$ ',
              filled: true,
              fillColor: Colors.white,
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
                borderSide: BorderSide(color: Colors.red.shade600),
              ),
              prefixIcon: Icon(
                Icons.monetization_on,
                color: Colors.red.shade600,
              ),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Informe o valor' : null,
          ),
          const SizedBox(height: 20),

          // Categoria
          _buildSectionTitle('Categoria', Icons.category),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<CategoriaTransacao>(
                value: _categoriaSelecionada,
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down, color: Colors.red.shade600),
                items:
                    [
                          CategoriaTransacao.fornecedores,
                          CategoriaTransacao.salarios,
                          CategoriaTransacao.aluguel,
                          CategoriaTransacao.marketing,
                          CategoriaTransacao.equipamentos,
                          CategoriaTransacao.impostos,
                          CategoriaTransacao.utilities,
                          CategoriaTransacao.manutencao,
                        ]
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(_getCategoriaLabel(c)),
                          ),
                        )
                        .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _categoriaSelecionada = v);
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Data de Vencimento
          _buildSectionTitle('Data de Vencimento', Icons.calendar_today),
          const SizedBox(height: 12),
          InkWell(
            onTap: _selecionarData,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.red.shade600),
                  const SizedBox(width: 12),
                  Text(
                    _dataSelecionada != null
                        ? dateFormat.format(_dataSelecionada!)
                        : 'Selecionar data',
                    style: TextStyle(
                      fontSize: 16,
                      color:
                          _dataSelecionada != null
                              ? Colors.black87
                              : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Observações
          _buildSectionTitle('Observações', Icons.notes),
          const SizedBox(height: 12),
          TextFormField(
            controller: _observacoesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Anotações adicionais...',
              filled: true,
              fillColor: Colors.white,
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
                borderSide: BorderSide(color: Colors.red.shade600),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Botão Salvar
          ElevatedButton(
            onPressed: _salvando ? null : _salvarNovaDespesa,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
            ),
            child:
                _salvando
                    ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                    : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save),
                        SizedBox(width: 8),
                        Text(
                          'Salvar Despesa a Pagar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.red.shade600),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  String _getCategoriaLabel(CategoriaTransacao categoria) {
    switch (categoria) {
      case CategoriaTransacao.fornecedores:
        return 'Fornecedores';
      case CategoriaTransacao.salarios:
        return 'Salários';
      case CategoriaTransacao.aluguel:
        return 'Aluguel';
      case CategoriaTransacao.marketing:
        return 'Marketing';
      case CategoriaTransacao.equipamentos:
        return 'Equipamentos';
      case CategoriaTransacao.impostos:
        return 'Impostos';
      case CategoriaTransacao.utilities:
        return 'Utilidades (Água, Luz, etc.)';
      case CategoriaTransacao.manutencao:
        return 'Manutenção';
      default:
        return categoria.name;
    }
  }

  void _mostrarDespesasExistentes() {
    final transacoesProv = context.read<TransacoesProvider>();
    final despesasAPagar =
        transacoesProv.transacoes
            .where((t) => t.tipo == TipoTransacao.despesa && t.isFutura)
            .toList()
          ..sort((a, b) => a.data.compareTo(b.data));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final dateFormat = DateFormat('dd/MM/yyyy');
        final currencyFormat = NumberFormat.currency(
          locale: 'pt_BR',
          symbol: 'R\$',
        );

        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade600, Colors.red.shade400],
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.list, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Despesas a Pagar',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child:
                    despesasAPagar.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Nenhuma despesa a pagar',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: despesasAPagar.length,
                          itemBuilder: (_, i) {
                            final despesa = despesasAPagar[i];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.call_made,
                                    color: Colors.red.shade600,
                                  ),
                                ),
                                title: Text(
                                  despesa.descricao,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  'Vencimento: ${dateFormat.format(despesa.data)}',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                trailing: Text(
                                  currencyFormat.format(despesa.valor),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.red.shade600,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        );
      },
    );
  }
}
