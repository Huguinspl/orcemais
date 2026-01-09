import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/agendamento.dart';
import '../../../models/cliente.dart';
import '../../../models/orcamento.dart';
import '../../../models/receita.dart';
import '../../../providers/agendamentos_provider.dart';
import '../../../providers/clients_provider.dart';
import '../../../providers/transacoes_provider.dart';
import '../../../providers/user_provider.dart';
import '../tabs/clientes_page.dart';
import '../tabs/novo_cliente_page.dart';
import '../orcamentos/orcamentos_page.dart';

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

/// Página para criar/editar agendamento de receita a receber (receita futura)
/// Igual ao formulário de Nova Receita do Controle Financeiro,
/// mas com campo adicional de Data do Recebimento
class AgendamentoAReceberPage extends StatefulWidget {
  /// Agendamento para edição (null = criar novo)
  final Agendamento? agendamento;

  /// Se true, mostra checkbox "Salvar em Agendamento" (quando vem do Controle Financeiro)
  /// Se false, sempre salva em agendamento (quando vem da tela de Agendamentos)
  final bool fromControleFinanceiro;

  const AgendamentoAReceberPage({
    super.key,
    this.agendamento,
    this.fromControleFinanceiro = false,
  });

  /// Verifica se está em modo de edição
  bool get isEditMode => agendamento != null;

  @override
  State<AgendamentoAReceberPage> createState() =>
      _AgendamentoAReceberPageState();
}

class _AgendamentoAReceberPageState extends State<AgendamentoAReceberPage> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  final _observacoesController = TextEditingController();

  DateTime _dataTransacao = DateTime.now();
  DateTime? _dataRecebimento;
  TimeOfDay? _horaRecebimento;
  CategoriaTransacao? _categoriaSelecionada;
  bool _salvando = false;

  // Novos campos
  bool _repetirParcelar = false;
  Orcamento? _orcamentoSelecionado;
  Cliente? _clienteSelecionado;

  // Controle para salvar em agendamento (usado quando fromControleFinanceiro = true)
  bool _salvarEmAgendamento = true;

  // ID do agendamento sendo editado (null = novo)
  String? _agendamentoId;

  @override
  void initState() {
    super.initState();

    final agendamento = widget.agendamento;

    if (agendamento != null) {
      // Modo edição: carregar dados do agendamento existente
      _agendamentoId = agendamento.id;

      // Extrair data e hora do agendamento
      final dataHora = agendamento.dataHora.toDate();
      _dataRecebimento = dataHora;
      _horaRecebimento = TimeOfDay(
        hour: dataHora.hour,
        minute: dataHora.minute,
      );

      // Carregar nome do cliente se disponível
      if (agendamento.clienteNome != null &&
          agendamento.clienteNome!.isNotEmpty) {
        // Cria um cliente temporário com o nome
        _clienteSelecionado = Cliente(nome: agendamento.clienteNome!);
      }

      // Extrair informações das observações
      _parseObservacoesAgendamento(agendamento.observacoes);
    } else {
      // Modo criação: valores padrão
      _dataRecebimento = DateTime.now().add(const Duration(days: 7));
      _horaRecebimento = const TimeOfDay(hour: 10, minute: 0);
    }
  }

  /// Extrai informações das observações do agendamento para preencher os campos
  void _parseObservacoesAgendamento(String observacoes) {
    final linhas = observacoes.split('\n');

    for (final linha in linhas) {
      if (linha.startsWith('Descrição:')) {
        _descricaoController.text = linha.replaceFirst('Descrição:', '').trim();
      } else if (linha.startsWith('Valor:')) {
        _valorController.text = linha.replaceFirst('Valor:', '').trim();
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
      } else if (linha.contains('Repetir/Parcelar: Sim')) {
        _repetirParcelar = true;
      }
    }

    // Se não conseguiu extrair descrição das observações, usa o clienteNome
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

  MaterialColor get _corTema => Colors.teal;

  double? _parseMoeda(String texto) {
    if (texto.isEmpty) return null;
    // Remove R$ e espaços
    String limpo = texto.replaceAll('R\$', '').replaceAll(' ', '').trim();
    // Troca vírgula por ponto
    limpo = limpo.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(limpo);
  }

  Future<void> _selecionarDataTransacao() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataTransacao,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _corTema.shade600,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (data != null) {
      setState(() => _dataTransacao = data);
    }
  }

  Future<void> _selecionarDataRecebimento() async {
    final data = await showDatePicker(
      context: context,
      initialDate:
          _dataRecebimento ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange.shade600,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (data != null) {
      setState(() => _dataRecebimento = data);
    }
  }

  Future<void> _selecionarHoraRecebimento() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: _horaRecebimento ?? const TimeOfDay(hour: 10, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              dialBackgroundColor: Colors.orange.shade50,
              hourMinuteTextColor: Colors.orange.shade700,
            ),
          ),
          child: child!,
        );
      },
    );
    if (hora != null) {
      setState(() => _horaRecebimento = hora);
    }
  }

  List<DropdownMenuItem<CategoriaTransacao>> _getCategorias() {
    final categorias =
        CategoriaTransacao.values.where((cat) => cat.isReceita).toList();
    return categorias.map((cat) {
      return DropdownMenuItem(value: cat, child: Text(cat.nome));
    }).toList();
  }

  // Navegar para selecionar orçamento
  Future<void> _selecionarOrcamento() async {
    final orcamento = await Navigator.push<Orcamento>(
      context,
      MaterialPageRoute(
        builder: (_) => const OrcamentosPage(isPickerMode: true),
      ),
    );

    if (orcamento != null && mounted) {
      setState(() {
        _orcamentoSelecionado = orcamento;
        // Preenche os campos com dados do orçamento
        _descricaoController.text =
            'Orçamento #${orcamento.numero.toString().padLeft(4, '0')} - ${orcamento.cliente.nome}';
        // Formata o valor corretamente
        final valorFormatado =
            'R\$ ${orcamento.valorTotal.toStringAsFixed(2).replaceAll('.', ',')}';
        _valorController.text = valorFormatado;
        _clienteSelecionado = orcamento.cliente;
      });
    }
  }

  // Mostrar opções para selecionar cliente
  Future<void> _mostrarOpcoesCliente() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Selecionar Cliente',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _corTema.shade700,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Botão Clientes
                    _buildOpcaoCliente(
                      icon: Icons.people,
                      label: 'Clientes',
                      cor: Colors.blue,
                      onTap: () {
                        Navigator.pop(ctx);
                        _navegarParaClientes();
                      },
                    ),
                    // Botão Agenda
                    _buildOpcaoCliente(
                      icon: Icons.contact_phone,
                      label: 'Agenda',
                      cor: Colors.green,
                      onTap: () {
                        Navigator.pop(ctx);
                        _importarDaAgenda();
                      },
                    ),
                    // Botão Criar Novo
                    _buildOpcaoCliente(
                      icon: Icons.person_add,
                      label: 'Criar Novo',
                      cor: Colors.purple,
                      onTap: () {
                        Navigator.pop(ctx);
                        _criarNovoCliente();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }

  Widget _buildOpcaoCliente({
    required IconData icon,
    required String label,
    required MaterialColor cor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: cor.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cor.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [cor.shade400, cor.shade600]),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cor.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Navegar para página de clientes para selecionar
  Future<void> _navegarParaClientes() async {
    final cliente = await Navigator.push<Cliente>(
      context,
      MaterialPageRoute(builder: (_) => const ClientesPage(isPickerMode: true)),
    );

    if (cliente != null && mounted) {
      setState(() {
        _clienteSelecionado = cliente;
      });
    }
  }

  // Importar contato da agenda do celular
  Future<void> _importarDaAgenda() async {
    // Solicitar permissão
    if (!await FlutterContacts.requestPermission(readonly: true)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Permissão para acessar contatos negada')),
            ],
          ),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    // Buscar contatos
    try {
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      if (!mounted) return;

      if (contacts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Nenhum contato encontrado na agenda')),
              ],
            ),
            backgroundColor: Colors.blue.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }

      // Mostrar diálogo para selecionar contato
      final selectedContact = await showDialog<Contact>(
        context: context,
        builder: (ctx) => _buildContactPickerDialog(contacts),
      );

      if (selectedContact != null && mounted) {
        // Criar cliente com dados do contato
        final nome = selectedContact.displayName;
        final celular =
            selectedContact.phones.isNotEmpty
                ? selectedContact.phones.first.number
                : '';
        final email =
            selectedContact.emails.isNotEmpty
                ? selectedContact.emails.first.address
                : '';

        // Criar cliente temporário para uso local
        setState(() {
          _clienteSelecionado = Cliente(
            nome: nome,
            celular: celular,
            email: email,
          );
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Erro ao buscar contatos: $e')),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Widget _buildContactPickerDialog(List<Contact> contacts) {
    final searchController = TextEditingController();
    List<Contact> filteredContacts = contacts;

    return StatefulBuilder(
      builder: (context, setDialogState) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 500, maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade600, Colors.green.shade400],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.contact_phone,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Selecionar Contato',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Buscar contato...',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.white,
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.2),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          setDialogState(() {
                            filteredContacts =
                                contacts
                                    .where(
                                      (c) => c.displayName
                                          .toLowerCase()
                                          .contains(value.toLowerCase()),
                                    )
                                    .toList();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                // Lista de contatos
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredContacts.length,
                    itemBuilder: (ctx, index) {
                      final contact = filteredContacts[index];
                      final phone =
                          contact.phones.isNotEmpty
                              ? contact.phones.first.number
                              : 'Sem telefone';
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          child: Text(
                            contact.displayName.isNotEmpty
                                ? contact.displayName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(contact.displayName),
                        subtitle: Text(phone),
                        onTap: () => Navigator.pop(ctx, contact),
                      );
                    },
                  ),
                ),
                // Botão cancelar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Criar novo cliente
  Future<void> _criarNovoCliente() async {
    final novoCliente = await Navigator.push<Cliente>(
      context,
      MaterialPageRoute(builder: (_) => const NovoClientePage()),
    );

    // Se retornou um cliente, seleciona
    if (novoCliente != null && mounted) {
      setState(() {
        _clienteSelecionado = novoCliente;
      });
    } else if (mounted) {
      // Se não retornou, verifica se foi adicionado ao provider e pega o último
      final userProvider = context.read<UserProvider>();
      final clientsProvider = context.read<ClientsProvider>();
      await clientsProvider.carregarTodos(userProvider.uid);
      if (clientsProvider.clientes.isNotEmpty) {
        setState(() {
          _clienteSelecionado = clientsProvider.clientes.last;
        });
      }
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dataRecebimento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Selecione a data de recebimento'),
          backgroundColor: _corTema.shade600,
        ),
      );
      return;
    }

    setState(() => _salvando = true);

    try {
      final userProvider = context.read<UserProvider>();
      final userId = userProvider.uid;

      if (userId.isEmpty) {
        throw Exception('Usuário não identificado');
      }

      final valor = _parseMoeda(_valorController.text) ?? 0.0;
      final agProv = context.read<AgendamentosProvider>();

      // Combina data e hora de recebimento
      final dataHoraRecebimento = DateTime(
        _dataRecebimento!.year,
        _dataRecebimento!.month,
        _dataRecebimento!.day,
        _horaRecebimento?.hour ?? 10,
        _horaRecebimento?.minute ?? 0,
      );

      // Monta observações para o agendamento
      final obsAgendamento = StringBuffer();
      obsAgendamento.writeln('[RECEITA A RECEBER]');
      obsAgendamento.writeln('Descrição: ${_descricaoController.text}');
      obsAgendamento.writeln(
        'Valor: R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}',
      );
      if (_categoriaSelecionada != null) {
        obsAgendamento.writeln('Categoria: ${_categoriaSelecionada!.nome}');
      }
      if (_clienteSelecionado != null) {
        obsAgendamento.writeln('Cliente: ${_clienteSelecionado!.nome}');
      }
      if (_repetirParcelar) {
        obsAgendamento.writeln('Repetir/Parcelar: Sim');
      }
      if (_observacoesController.text.isNotEmpty) {
        obsAgendamento.writeln(_observacoesController.text);
      }

      final clienteNome =
          _clienteSelecionado?.nome ?? 'Receita: ${_descricaoController.text}';

      if (_agendamentoId != null) {
        // MODO EDIÇÃO: Atualizar agendamento existente
        final agendamentoAtualizado = Agendamento(
          id: _agendamentoId!,
          orcamentoId: 'receita_a_receber',
          orcamentoNumero: _orcamentoSelecionado?.numero,
          clienteNome: clienteNome,
          dataHora: Timestamp.fromDate(dataHoraRecebimento),
          status: widget.agendamento?.status ?? 'Pendente',
          observacoes: obsAgendamento.toString().trim(),
          criadoEm: widget.agendamento?.criadoEm ?? Timestamp.now(),
          atualizadoEm: Timestamp.now(),
        );

        await agProv.atualizarAgendamento(agendamentoAtualizado);

        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Receita a receber atualizada!'),
              ],
            ),
            backgroundColor: _corTema.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        // MODO CRIAÇÃO: Criar nova transação e agendamento
        // Monta observações com data de recebimento
        final obsCompletas = StringBuffer();
        obsCompletas.writeln('[RECEITA A RECEBER]');
        obsCompletas.writeln(
          'Data prevista: ${DateFormat('dd/MM/yyyy').format(_dataRecebimento!)}',
        );
        if (_clienteSelecionado != null) {
          obsCompletas.writeln('Cliente: ${_clienteSelecionado!.nome}');
        }
        if (_orcamentoSelecionado != null) {
          obsCompletas.writeln(
            'Orçamento: #${_orcamentoSelecionado!.numero.toString().padLeft(4, '0')}',
          );
        }
        if (_repetirParcelar) {
          obsCompletas.writeln('Repetir/Parcelar: Sim');
        }
        if (_observacoesController.text.isNotEmpty) {
          obsCompletas.writeln(_observacoesController.text);
        }

        final transacao = Transacao(
          descricao: _descricaoController.text,
          valor: valor,
          tipo: TipoTransacao.receita,
          categoria: _categoriaSelecionada!,
          data:
              _dataRecebimento!, // Usa a data de recebimento como data da transação futura
          observacoes: obsCompletas.toString().trim(),
          userId: userId,
          isFutura: true, // Marca como receita a receber
        );

        final sucesso = await context
            .read<TransacoesProvider>()
            .adicionarTransacao(transacao);

        if (!mounted) return;

        if (sucesso) {
          // Só adiciona em Agendamentos se:
          // - Veio da tela de Agendamentos (fromControleFinanceiro = false), OU
          // - Veio do Controle Financeiro E checkbox _salvarEmAgendamento está marcado
          if (!widget.fromControleFinanceiro || _salvarEmAgendamento) {
            await agProv.adicionarAgendamento(
              orcamentoId: 'receita_a_receber',
              orcamentoNumero: _orcamentoSelecionado?.numero,
              clienteNome: clienteNome,
              dataHora: Timestamp.fromDate(dataHoraRecebimento),
              status: 'Pendente',
              observacoes: obsAgendamento.toString().trim(),
            );
          }

          if (!mounted) return;
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    _salvarEmAgendamento || !widget.fromControleFinanceiro
                        ? 'Receita a receber adicionada!'
                        : 'Receita a receber salva (sem agendamento)',
                  ),
                ],
              ),
              backgroundColor: _corTema.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        } else {
          throw Exception('Erro ao salvar transação');
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final corTema = _corTema;
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: corTema.shade600,
        foregroundColor: Colors.white,
        title: Text(
          widget.agendamento != null
              ? 'Editar Receita a Receber'
              : 'Nova Receita a Receber',
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
            colors: [corTema.shade50, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ========== REPETIR / PARCELAR ==========
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.repeat, color: corTema.shade600),
                          const SizedBox(width: 12),
                          const Text(
                            'Repetir / Parcelar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: _repetirParcelar,
                        onChanged: (value) {
                          setState(() => _repetirParcelar = value);
                        },
                        activeColor: corTema.shade600,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ========== RECEITA DE ORÇAMENTO ==========
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.description, color: Colors.blue.shade600),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Receita de Orçamento',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _orcamentoSelecionado != null
                                  ? 'Orçamento #${_orcamentoSelecionado!.numero.toString().padLeft(4, '0')} - ${_orcamentoSelecionado!.cliente.nome}'
                                  : 'Nenhum orçamento selecionado',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    _orcamentoSelecionado != null
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                color:
                                    _orcamentoSelecionado != null
                                        ? Colors.blue.shade700
                                        : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _selecionarOrcamento,
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ========== CLIENTE ==========
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person, color: Colors.purple.shade600),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cliente',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _clienteSelecionado != null
                                  ? _clienteSelecionado!.nome
                                  : 'Nenhum cliente selecionado',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    _clienteSelecionado != null
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                color:
                                    _clienteSelecionado != null
                                        ? Colors.purple.shade700
                                        : Colors.grey.shade500,
                              ),
                            ),
                            if (_clienteSelecionado?.celular.isNotEmpty == true)
                              Text(
                                _clienteSelecionado!.celular,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _mostrarOpcoesCliente,
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add,
                            color: Colors.purple.shade700,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Título com indicador do tipo
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [corTema.shade600, corTema.shade400],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.trending_up,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dados da Receita',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Receita futura a receber',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Futura',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Descrição
                TextFormField(
                  controller: _descricaoController,
                  decoration: InputDecoration(
                    labelText: 'Descrição',
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: corTema.shade600, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Digite uma descrição';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Valor
                TextFormField(
                  controller: _valorController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CurrencyInputFormatter(),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Valor *',
                    prefixIcon: Icon(
                      Icons.attach_money,
                      color: corTema.shade600,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: corTema.shade600, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        _parseMoeda(value) == 0) {
                      return 'Informe um valor válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Categoria
                DropdownButtonFormField<CategoriaTransacao>(
                  value: _categoriaSelecionada,
                  decoration: InputDecoration(
                    labelText: 'Categoria',
                    prefixIcon: const Icon(Icons.category),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: _getCategorias(),
                  onChanged:
                      (value) => setState(() => _categoriaSelecionada = value),
                  validator: (value) {
                    if (value == null) return 'Selecione uma categoria';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Data da Transação
                ListTile(
                  leading: Icon(Icons.calendar_today, color: corTema.shade600),
                  title: const Text('Data da Transação'),
                  subtitle: Text(
                    dateFormat.format(_dataTransacao),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  tileColor: Colors.white,
                  onTap: _selecionarDataTransacao,
                ),
                const SizedBox(height: 16),

                // Data do Recebimento (campo adicional)
                ListTile(
                  leading: Icon(
                    Icons.event_available,
                    color: Colors.orange.shade600,
                  ),
                  title: Row(
                    children: [
                      const Text('Data do Recebimento'),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Previsto',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    _dataRecebimento != null
                        ? dateFormat.format(_dataRecebimento!)
                        : 'Selecionar data',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color:
                          _dataRecebimento != null
                              ? Colors.orange.shade700
                              : Colors.grey.shade500,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.orange.shade300),
                  ),
                  tileColor: Colors.orange.shade50,
                  onTap: _selecionarDataRecebimento,
                ),
                const SizedBox(height: 16),

                // Hora do Recebimento
                ListTile(
                  leading: Icon(
                    Icons.access_time,
                    color: Colors.orange.shade600,
                  ),
                  title: Row(
                    children: [
                      const Text('Hora do Recebimento'),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Previsto',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    _horaRecebimento != null
                        ? _horaRecebimento!.format(context)
                        : 'Selecionar hora',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color:
                          _horaRecebimento != null
                              ? Colors.orange.shade700
                              : Colors.grey.shade500,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.orange.shade300),
                  ),
                  tileColor: Colors.orange.shade50,
                  onTap: _selecionarHoraRecebimento,
                ),
                const SizedBox(height: 16),

                // Checkbox "Salvar em Agendamento" (apenas quando vem do Controle Financeiro)
                if (widget.fromControleFinanceiro) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: CheckboxListTile(
                      value: _salvarEmAgendamento,
                      onChanged: (v) => setState(() => _salvarEmAgendamento = v ?? true),
                      title: const Text(
                        'Salvar em Agendamento',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        _salvarEmAgendamento
                            ? 'A receita também aparecerá na aba de Agendamentos'
                            : 'A receita será salva apenas no Controle Financeiro',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
                        ),
                      ),
                      secondary: Icon(
                        _salvarEmAgendamento ? Icons.event_available : Icons.event_busy,
                        color: Colors.blue.shade600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      activeColor: Colors.blue.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Observações
                TextFormField(
                  controller: _observacoesController,
                  decoration: InputDecoration(
                    labelText: 'Observações (opcional)',
                    prefixIcon: const Icon(Icons.notes),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                // Botão salvar
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _salvando ? null : _salvar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: corTema.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        _salvando
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Text(
                              'Salvar Receita a Receber',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
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
}
