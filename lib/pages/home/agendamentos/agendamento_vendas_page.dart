import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/agendamento.dart';
import '../../../models/cliente.dart';
import '../../../providers/agendamentos_provider.dart';
import '../../../providers/clients_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../services/notification_service.dart';
import '../tabs/clientes_page.dart';
import '../tabs/novo_cliente_page.dart';
import '../tabs/pecas_materiais_page.dart';
import '../tabs/novo_peca_material_page.dart';

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

/// Arquivo de comprovante anexado
class _ArquivoAnexoVenda {
  final String nome;
  final String url;
  final String tipo; // 'image' ou 'pdf'

  _ArquivoAnexoVenda({
    required this.nome,
    required this.url,
    required this.tipo,
  });
}

/// Pagina para criar/editar agendamento de vendas
/// Estilo igual a pagina de Nova Receita a Receber, mas para vendas
class AgendamentoVendasPage extends StatefulWidget {
  final Agendamento? agendamento;
  final DateTime? dataInicial;

  const AgendamentoVendasPage({super.key, this.agendamento, this.dataInicial});

  @override
  State<AgendamentoVendasPage> createState() => _AgendamentoVendasPageState();
}

class _AgendamentoVendasPageState extends State<AgendamentoVendasPage> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  final _observacoesController = TextEditingController();

  DateTime? _dataVenda;
  TimeOfDay? _horaVenda;
  String _status = 'Pendente';
  Cliente? _clienteSelecionado;
  Map<String, dynamic>? _produtoSelecionado;
  bool _salvando = false;

  // Lista de arquivos/fotos anexados
  final List<_ArquivoAnexoVenda> _arquivosAnexados = [];
  bool _enviandoArquivo = false;

  // Campos para repetir/parcelar
  bool _repetirParcelar = false;
  int _quantidadeRepeticoes = 2;
  String _tipoRepeticao = 'mensal'; // mensal, quinzenal, semanal

  MaterialColor get _corTema => Colors.orange;

  @override
  void initState() {
    super.initState();

    // Data inicial
    if (widget.dataInicial != null) {
      _dataVenda = widget.dataInicial;
      _horaVenda = const TimeOfDay(hour: 10, minute: 0);
    } else {
      _dataVenda = DateTime.now();
      _horaVenda = const TimeOfDay(hour: 10, minute: 0);
    }

    final ag = widget.agendamento;
    if (ag != null) {
      final dateTime = ag.dataHora.toDate();
      _dataVenda = dateTime;
      _horaVenda = TimeOfDay.fromDateTime(dateTime);
      _status = ag.status;

      // Parse observacoes para extrair dados
      _parseObservacoesAgendamento(ag.observacoes);

      // Buscar cliente pelo nome
      if (ag.clienteNome?.isNotEmpty == true) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final uid = context.read<UserProvider>().uid;
          final clientesProv = context.read<ClientsProvider>();
          await clientesProv.carregarTodos(uid);

          if (mounted) {
            setState(() {
              _clienteSelecionado = clientesProv.clientes.firstWhere(
                (c) => c.nome == ag.clienteNome,
                orElse:
                    () => Cliente(
                      id: '',
                      nome: ag.clienteNome ?? '',
                      celular: '',
                      telefone: '',
                      email: '',
                      cpfCnpj: '',
                      observacoes: '',
                    ),
              );
            });
          }
        });
      }
    }

    // Carrega clientes
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final uid = context.read<UserProvider>().uid;
      if (context.read<ClientsProvider>().clientes.isEmpty) {
        await context.read<ClientsProvider>().carregarTodos(uid);
      }
    });
  }

  void _parseObservacoesAgendamento(String observacoes) {
    // Remove secao de comprovantes antes de processar
    var obsLimpa = observacoes.replaceAll(
      RegExp(r'\[COMPROVANTES\].*?\[/COMPROVANTES\]', dotAll: true),
      '',
    );

    final linhas = obsLimpa.split('\n');

    for (final linha in linhas) {
      if (linha.trim().isEmpty) continue;
      if (linha.startsWith('[VENDA]')) continue;
      if (linha.startsWith('[COMPROVANTES]')) continue;
      if (linha.startsWith('[/COMPROVANTES]')) continue;

      // Ignora URLs de comprovantes
      if (linha.contains('|') && linha.contains('http')) continue;

      if (linha.startsWith('Descricao:')) {
        _descricaoController.text = linha.replaceFirst('Descricao:', '').trim();
      } else if (linha.startsWith('Valor:')) {
        _valorController.text = linha.replaceFirst('Valor:', '').trim();
      }
    }

    // Buscar comprovantes
    final matchComprovantes = RegExp(
      r'\[COMPROVANTES\](.*?)\[/COMPROVANTES\]',
      dotAll: true,
    ).firstMatch(observacoes);
    if (matchComprovantes != null) {
      final comprovantesStr = matchComprovantes.group(1) ?? '';
      final linhasComp = comprovantesStr.split('\n');
      for (final linhaComp in linhasComp) {
        if (linhaComp.contains('|') && linhaComp.contains('http')) {
          final partes = linhaComp.split('|');
          if (partes.length >= 2) {
            final nome = partes[0].trim();
            final url = partes[1].trim();
            final tipo = nome.toLowerCase().endsWith('.pdf') ? 'pdf' : 'image';
            _arquivosAnexados.add(
              _ArquivoAnexoVenda(nome: nome, url: url, tipo: tipo),
            );
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  double? _parseMoeda(String texto) {
    if (texto.isEmpty) return null;
    String limpo = texto.replaceAll('R\$', '').replaceAll(' ', '').trim();
    limpo = limpo.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(limpo);
  }

  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataVenda ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
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
      setState(() => _dataVenda = data);
    }
  }

  Future<void> _selecionarHora() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: _horaVenda ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              dialBackgroundColor: _corTema.shade50,
              hourMinuteTextColor: _corTema.shade700,
            ),
          ),
          child: child!,
        );
      },
    );
    if (hora != null) {
      setState(() => _horaVenda = hora);
    }
  }

  // ========== METODOS DE PRODUTO/MATERIAL ==========

  Future<void> _mostrarOpcoesProduto() async {
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
                  'Selecionar Produto/Material',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildOpcaoProduto(
                      icon: Icons.inventory_2,
                      label: 'Catálogo',
                      cor: Colors.purple,
                      onTap: () {
                        Navigator.pop(ctx);
                        _buscarDoCatalogo();
                      },
                    ),
                    _buildOpcaoProduto(
                      icon: Icons.add_box,
                      label: 'Criar Novo',
                      cor: Colors.orange,
                      onTap: () {
                        Navigator.pop(ctx);
                        _criarNovoProduto();
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

  Widget _buildOpcaoProduto({
    required IconData icon,
    required String label,
    required MaterialColor cor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 100,
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

  Future<void> _buscarDoCatalogo() async {
    final produto = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => const PecasMateriaisPage(isPickerMode: true),
      ),
    );

    if (produto != null && mounted) {
      setState(() {
        _produtoSelecionado = produto;
        final nomeProduto = produto['nome'] ?? '';
        final unidade = produto['unidadeMedida'] ?? produto['unidade'] ?? '';
        _descricaoController.text =
            '$nomeProduto${unidade.isNotEmpty && unidade != 'Nenhum' ? ' ($unidade)' : ''}';
        final preco = produto['preco'] ?? 0.0;
        final valorFormatado =
            'R\$ ${preco.toStringAsFixed(2).replaceAll('.', ',')}';
        _valorController.text = valorFormatado;
      });
    }
  }

  Future<void> _criarNovoProduto() async {
    final novaPeca = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NovoPecaMaterialPage()),
    );

    if (novaPeca != null && mounted) {
      // Se retornou uma peça, usa ela
      final produto = {
        'nome': novaPeca.nome,
        'preco': novaPeca.preco,
        'marca': novaPeca.marca,
        'modelo': novaPeca.modelo,
        'unidadeMedida': novaPeca.unidadeMedida,
      };
      setState(() {
        _produtoSelecionado = produto;
        final nomeProduto = produto['nome'] ?? '';
        final unidade = produto['unidadeMedida'] ?? '';
        _descricaoController.text =
            '$nomeProduto${unidade.isNotEmpty && unidade != 'Nenhum' ? ' ($unidade)' : ''}';
        final preco = produto['preco'] ?? 0.0;
        final valorFormatado =
            'R\$ ${preco.toStringAsFixed(2).replaceAll('.', ',')}';
        _valorController.text = valorFormatado;
      });
    }
  }

  // ========== METODOS DE CLIENTE ==========

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
                    _buildOpcaoCliente(
                      icon: Icons.people,
                      label: 'Clientes',
                      cor: Colors.blue,
                      onTap: () {
                        Navigator.pop(ctx);
                        _navegarParaClientes();
                      },
                    ),
                    _buildOpcaoCliente(
                      icon: Icons.contact_phone,
                      label: 'Agenda',
                      cor: Colors.green,
                      onTap: () {
                        Navigator.pop(ctx);
                        _importarDaAgenda();
                      },
                    ),
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

  Future<void> _importarDaAgenda() async {
    if (!await FlutterContacts.requestPermission(readonly: true)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Permissao para acessar contatos negada')),
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

      final selectedContact = await showDialog<Contact>(
        context: context,
        builder: (ctx) => _buildContactPickerDialog(contacts),
      );

      if (selectedContact != null && mounted) {
        final nome = selectedContact.displayName;
        final celular =
            selectedContact.phones.isNotEmpty
                ? selectedContact.phones.first.number
                : '';
        final email =
            selectedContact.emails.isNotEmpty
                ? selectedContact.emails.first.address
                : '';

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

  Future<void> _criarNovoCliente() async {
    final novoCliente = await Navigator.push<Cliente>(
      context,
      MaterialPageRoute(builder: (_) => const NovoClientePage()),
    );

    if (novoCliente != null && mounted) {
      setState(() {
        _clienteSelecionado = novoCliente;
      });
    } else if (mounted) {
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

  // ========== METODOS DE REPETIR/PARCELAR ==========

  void _mostrarConfigRepeticao() {
    int tempQuantidade = _quantidadeRepeticoes;
    String tempTipo = _tipoRepeticao;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      'Configurar Repetição',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _corTema.shade700,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Frequência:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildOpcaoFrequencia(
                          label: 'Semanal',
                          selecionado: tempTipo == 'semanal',
                          onTap:
                              () => setModalState(() => tempTipo = 'semanal'),
                        ),
                        const SizedBox(width: 12),
                        _buildOpcaoFrequencia(
                          label: 'Quinzenal',
                          selecionado: tempTipo == 'quinzenal',
                          onTap:
                              () => setModalState(() => tempTipo = 'quinzenal'),
                        ),
                        const SizedBox(width: 12),
                        _buildOpcaoFrequencia(
                          label: 'Mensal',
                          selecionado: tempTipo == 'mensal',
                          onTap: () => setModalState(() => tempTipo = 'mensal'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Quantidade de vezes:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        IconButton(
                          onPressed:
                              tempQuantidade > 2
                                  ? () => setModalState(() => tempQuantidade--)
                                  : null,
                          icon: const Icon(Icons.remove_circle_outline),
                          color: _corTema.shade600,
                          iconSize: 32,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: _corTema.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _corTema.shade200),
                          ),
                          child: Text(
                            '$tempQuantidade',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _corTema.shade700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed:
                              tempQuantidade < 24
                                  ? () => setModalState(() => tempQuantidade++)
                                  : null,
                          icon: const Icon(Icons.add_circle_outline),
                          color: _corTema.shade600,
                          iconSize: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _getDescricaoRepeticao(tempTipo, tempQuantidade),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() => _repetirParcelar = false);
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _quantidadeRepeticoes = tempQuantidade;
                                _tipoRepeticao = tempTipo;
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _corTema.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Confirmar'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOpcaoFrequencia({
    required String label,
    required bool selecionado,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selecionado ? _corTema.shade600 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selecionado ? _corTema.shade600 : Colors.grey.shade300,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selecionado ? Colors.white : Colors.grey.shade700,
                fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getDescricaoRepeticao(String tipo, int quantidade) {
    final periodo =
        tipo == 'semanal'
            ? 'semanas'
            : (tipo == 'quinzenal' ? 'quinzenas' : 'meses');
    return 'Total: $quantidade vendas ao longo de $quantidade $periodo';
  }

  DateTime _calcularProximaData(DateTime dataBase, String tipo, int indice) {
    switch (tipo) {
      case 'semanal':
        return dataBase.add(Duration(days: 7 * indice));
      case 'quinzenal':
        return dataBase.add(Duration(days: 15 * indice));
      case 'mensal':
      default:
        return DateTime(dataBase.year, dataBase.month + indice, dataBase.day);
    }
  }

  // ========== METODOS DE COMPROVANTES ==========

  void _mostrarOpcoesAnexo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Adicionar Comprovante',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildOpcaoAnexo(
                    icone: Icons.camera_alt,
                    label: 'Camera',
                    cor: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      _capturarFoto();
                    },
                  ),
                  _buildOpcaoAnexo(
                    icone: Icons.photo_library,
                    label: 'Galeria',
                    cor: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      _selecionarDaGaleria();
                    },
                  ),
                  _buildOpcaoAnexo(
                    icone: Icons.attach_file,
                    label: 'Arquivo',
                    cor: Colors.orange,
                    onTap: () {
                      Navigator.pop(context);
                      _selecionarArquivo();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOpcaoAnexo({
    required IconData icone,
    required String label,
    required MaterialColor cor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cor.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icone, color: cor.shade600, size: 32),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: cor.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _capturarFoto() async {
    try {
      final picker = ImagePicker();
      final foto = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      if (foto != null) {
        await _adicionarArquivo(foto.path, foto.name, 'image');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao capturar foto: $e')));
      }
    }
  }

  Future<void> _selecionarDaGaleria() async {
    try {
      final picker = ImagePicker();
      final imagens = await picker.pickMultiImage(imageQuality: 70);
      for (final img in imagens) {
        await _adicionarArquivo(img.path, img.name, 'image');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao selecionar imagens: $e')),
        );
      }
    }
  }

  Future<void> _selecionarArquivo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'doc', 'docx'],
        allowMultiple: true,
      );
      if (result != null) {
        for (final file in result.files) {
          if (file.path != null) {
            final tipo =
                file.extension?.toLowerCase() == 'pdf' ? 'pdf' : 'image';
            await _adicionarArquivo(file.path!, file.name, tipo);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao selecionar arquivo: $e')),
        );
      }
    }
  }

  Future<void> _adicionarArquivo(String path, String nome, String tipo) async {
    setState(() => _enviandoArquivo = true);
    try {
      final userId = context.read<UserProvider>().uid;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = 'vendas/$userId/comprovantes/${timestamp}_$nome';

      final ref = FirebaseStorage.instance.ref().child(storagePath);

      String url;
      if (kIsWeb) {
        final bytes = await File(path).readAsBytes();
        await ref.putData(bytes);
        url = await ref.getDownloadURL();
      } else {
        await ref.putFile(File(path));
        url = await ref.getDownloadURL();
      }

      setState(() {
        _arquivosAnexados.add(
          _ArquivoAnexoVenda(nome: nome, url: url, tipo: tipo),
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar arquivo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _enviandoArquivo = false);
      }
    }
  }

  void _removerArquivo(int index) {
    setState(() {
      _arquivosAnexados.removeAt(index);
    });
  }

  Widget _buildCardAnexos() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: _corTema.shade600),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Comprovantes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              if (_enviandoArquivo)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  onPressed: _mostrarOpcoesAnexo,
                  icon: Icon(Icons.add_circle, color: _corTema.shade600),
                  tooltip: 'Adicionar comprovante',
                ),
            ],
          ),
          if (_arquivosAnexados.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Nenhum comprovante anexado',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              ),
            )
          else ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _arquivosAnexados.length,
                itemBuilder: (context, index) {
                  final arquivo = _arquivosAnexados[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child:
                                arquivo.tipo == 'image'
                                    ? Image.network(
                                      arquivo.url,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (_, __, ___) => Icon(
                                            Icons.image,
                                            color: Colors.grey.shade400,
                                            size: 40,
                                          ),
                                    )
                                    : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.picture_as_pdf,
                                          color: Colors.red.shade400,
                                          size: 40,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'PDF',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removerArquivo(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 8),
          InkWell(
            onTap: _mostrarOpcoesAnexo,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _corTema.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _corTema.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, color: _corTema.shade600, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Adicionar foto ou arquivo',
                    style: TextStyle(
                      color: _corTema.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== SALVAR ==========

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dataVenda == null || _horaVenda == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Text('Defina data e hora'),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() => _salvando = true);

    try {
      final agProv = context.read<AgendamentosProvider>();
      final dataHora = DateTime(
        _dataVenda!.year,
        _dataVenda!.month,
        _dataVenda!.day,
        _horaVenda!.hour,
        _horaVenda!.minute,
      );

      final valor = _parseMoeda(_valorController.text) ?? 0.0;

      // Monta observacoes
      final obsAgendamento = StringBuffer();
      obsAgendamento.writeln('[VENDA]');
      if (_descricaoController.text.isNotEmpty) {
        obsAgendamento.writeln('Descricao: ${_descricaoController.text}');
      }
      if (valor > 0) {
        obsAgendamento.writeln(
          'Valor: R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}',
        );
      }
      if (_clienteSelecionado != null) {
        obsAgendamento.writeln('Cliente: ${_clienteSelecionado!.nome}');
      }
      if (_produtoSelecionado != null) {
        final nomeProduto = _produtoSelecionado!['nome'] ?? '';
        final marca = _produtoSelecionado!['marca'] ?? '';
        final modelo = _produtoSelecionado!['modelo'] ?? '';
        obsAgendamento.writeln('Produto: $nomeProduto');
        if (marca.toString().isNotEmpty)
          obsAgendamento.writeln('Marca: $marca');
        if (modelo.toString().isNotEmpty)
          obsAgendamento.writeln('Modelo: $modelo');
      }
      if (_observacoesController.text.isNotEmpty) {
        obsAgendamento.writeln(_observacoesController.text);
      }
      // Adiciona URLs dos comprovantes
      if (_arquivosAnexados.isNotEmpty) {
        obsAgendamento.writeln('[COMPROVANTES]');
        for (final arquivo in _arquivosAnexados) {
          obsAgendamento.writeln('${arquivo.nome}|${arquivo.url}');
        }
        obsAgendamento.writeln('[/COMPROVANTES]');
      }

      final clienteNome =
          _clienteSelecionado?.nome ?? 'Venda: ${_descricaoController.text}';

      if (widget.agendamento != null) {
        // Modo edicao
        final agendamentoAtualizado = Agendamento(
          id: widget.agendamento!.id,
          orcamentoId: '',
          orcamentoNumero: null,
          clienteNome: clienteNome,
          dataHora: Timestamp.fromDate(dataHora),
          status: _status,
          observacoes: obsAgendamento.toString().trim(),
          criadoEm: widget.agendamento!.criadoEm,
          atualizadoEm: Timestamp.now(),
        );

        await agProv.atualizarAgendamento(agendamentoAtualizado);

        if (_status == 'Confirmado') {
          await NotificationService().agendarNotificacao(agendamentoAtualizado);
        } else {
          await NotificationService().cancelarNotificacao(
            agendamentoAtualizado.id,
          );
        }
      } else {
        // Modo criacao
        final notificationService = NotificationService();
        if (!notificationService.isInitialized) {
          await notificationService.initialize();
        }
        if (!notificationService.permissionGranted) {
          await notificationService.requestPermission();
        }

        // Se repetir/parcelar está ativo, criar múltiplos agendamentos
        if (_repetirParcelar && _quantidadeRepeticoes > 1) {
          for (int i = 0; i < _quantidadeRepeticoes; i++) {
            final dataRepetida = _calcularProximaData(
              dataHora,
              _tipoRepeticao,
              i,
            );
            final obsComParcela =
                '${obsAgendamento.toString().trim()}\n[Parcela ${i + 1}/$_quantidadeRepeticoes]';

            await agProv.adicionarAgendamento(
              orcamentoId: '',
              orcamentoNumero: null,
              clienteNome: clienteNome,
              dataHora: Timestamp.fromDate(dataRepetida),
              status: _status,
              observacoes: obsComParcela,
            );
          }
        } else {
          await agProv.adicionarAgendamento(
            orcamentoId: '',
            orcamentoNumero: null,
            clienteNome: clienteNome,
            dataHora: Timestamp.fromDate(dataHora),
            status: _status,
            observacoes: obsAgendamento.toString().trim(),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context);
        String mensagemSucesso;
        if (widget.agendamento != null) {
          mensagemSucesso = 'Agendamento atualizado!';
        } else if (_repetirParcelar && _quantidadeRepeticoes > 1) {
          mensagemSucesso = '$_quantidadeRepeticoes vendas agendadas!';
        } else {
          mensagemSucesso = 'Venda agendada com sucesso!';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(mensagemSucesso),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
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

  // ========== BUILD ==========

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
          widget.agendamento != null ? 'Editar Agendamento' : 'Nova Venda',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [corTema.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ========== REPETIR / PARCELAR ==========
                    InkWell(
                      onTap: () {
                        if (!_repetirParcelar) {
                          setState(() => _repetirParcelar = true);
                          _mostrarConfigRepeticao();
                        } else {
                          setState(() => _repetirParcelar = false);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
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
                                  onChanged: (v) {
                                    if (v) {
                                      setState(() => _repetirParcelar = true);
                                      _mostrarConfigRepeticao();
                                    } else {
                                      setState(() => _repetirParcelar = false);
                                    }
                                  },
                                  activeColor: corTema.shade600,
                                ),
                              ],
                            ),
                            if (_repetirParcelar) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: corTema.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 16,
                                      color: corTema.shade600,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '$_quantidadeRepeticoes x ${_tipoRepeticao == 'semanal'
                                          ? 'Semanal'
                                          : _tipoRepeticao == 'quinzenal'
                                          ? 'Quinzenal'
                                          : 'Mensal'}',
                                      style: TextStyle(
                                        color: corTema.shade700,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: _mostrarConfigRepeticao,
                                      child: Icon(
                                        Icons.edit,
                                        size: 16,
                                        color: corTema.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ========== VINCULAR PRODUTO/MATERIAL ==========
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
                          Icon(
                            Icons.inventory_2,
                            color: Colors.purple.shade600,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Venda de Produto/Material',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _produtoSelecionado != null
                                      ? '${_produtoSelecionado!['nome'] ?? ''}${_produtoSelecionado!['marca'] != null && _produtoSelecionado!['marca'].toString().isNotEmpty ? ' - ${_produtoSelecionado!['marca']}' : ''}'
                                      : 'Nenhum produto selecionado',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        _produtoSelecionado != null
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                    color:
                                        _produtoSelecionado != null
                                            ? Colors.purple.shade700
                                            : Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _mostrarOpcoesProduto,
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
                          Icon(Icons.person, color: Colors.blue.shade600),
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
                                            ? Colors.blue.shade700
                                            : Colors.grey.shade500,
                                  ),
                                ),
                                if (_clienteSelecionado?.celular.isNotEmpty ==
                                    true)
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

                    // ========== COMPROVANTES ==========
                    _buildCardAnexos(),
                    const SizedBox(height: 24),

                    // Titulo com indicador do tipo
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
                            Icons.shopping_cart,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dados da Venda',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Agende uma venda futura',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Descricao
                    TextFormField(
                      controller: _descricaoController,
                      decoration: InputDecoration(
                        labelText: 'Descricao',
                        prefixIcon: const Icon(Icons.description),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: corTema.shade600,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Digite uma descricao';
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
                          borderSide: BorderSide(
                            color: corTema.shade600,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            _parseMoeda(value) == 0) {
                          return 'Informe um valor valido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Data e Hora
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
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
                                  Icon(
                                    Icons.calendar_today,
                                    color: corTema.shade600,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _dataVenda != null
                                          ? dateFormat.format(_dataVenda!)
                                          : 'Data',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color:
                                            _dataVenda != null
                                                ? Colors.black87
                                                : Colors.grey.shade500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: _selecionarHora,
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
                                  Icon(
                                    Icons.access_time,
                                    color: corTema.shade600,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _horaVenda != null
                                          ? _horaVenda!.format(context)
                                          : 'Hora',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color:
                                            _horaVenda != null
                                                ? Colors.black87
                                                : Colors.grey.shade500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _status,
                          isExpanded: true,
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: corTema.shade600,
                          ),
                          items:
                              [
                                    'Pendente',
                                    'Confirmado',
                                    'Concluido',
                                    'Cancelado',
                                  ]
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Row(
                                        children: [
                                          Icon(
                                            _getStatusIcon(s),
                                            color: _getStatusColor(s),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(s),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _status = v);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Observacoes
                    TextFormField(
                      controller: _observacoesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Observacoes',
                        prefixIcon: const Icon(Icons.notes),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: corTema.shade600,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Botao Salvar
                    ElevatedButton(
                      onPressed: _salvando ? null : _salvar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: corTema.shade600,
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
                              : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.save),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.agendamento != null
                                        ? 'Atualizar'
                                        : 'Salvar Agendamento',
                                    style: const TextStyle(
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Pendente':
        return Icons.pending_outlined;
      case 'Confirmado':
        return Icons.check_circle_outline;
      case 'Concluido':
        return Icons.done_all;
      case 'Cancelado':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pendente':
        return Colors.orange;
      case 'Confirmado':
        return Colors.blue;
      case 'Concluido':
        return Colors.green;
      case 'Cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
