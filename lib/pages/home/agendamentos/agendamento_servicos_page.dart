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
import '../../../providers/services_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../models/orcamento.dart';
import '../../../services/notification_service.dart';
import '../tabs/clientes_page.dart';
import '../tabs/novo_cliente_page.dart';
import '../tabs/servicos_page.dart';
import '../tabs/novo_servico_page.dart';
import '../orcamentos/orcamentos_page.dart';

class CurrencyInputFormatterServico extends TextInputFormatter {
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
class _ArquivoAnexoServico {
  final String nome;
  final String url;
  final String tipo; // 'image' ou 'pdf'

  _ArquivoAnexoServico({
    required this.nome,
    required this.url,
    required this.tipo,
  });
}

/// Pagina para criar/editar agendamento de serviços
/// Estilo igual a pagina de Nova Receita a Receber, mas para serviços
class AgendamentoServicosPage extends StatefulWidget {
  final Agendamento? agendamento;
  final DateTime? dataInicial;

  const AgendamentoServicosPage({
    super.key,
    this.agendamento,
    this.dataInicial,
  });

  @override
  State<AgendamentoServicosPage> createState() =>
      _AgendamentoServicosPageState();
}

class _AgendamentoServicosPageState extends State<AgendamentoServicosPage> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  final _observacoesController = TextEditingController();

  DateTime? _dataServico;
  TimeOfDay? _horaServico;
  String _status = 'Pendente';
  Cliente? _clienteSelecionado;
  Map<String, dynamic>? _servicoSelecionado;
  bool _salvando = false;

  // Lista de arquivos/fotos anexados
  final List<_ArquivoAnexoServico> _arquivosAnexados = [];
  bool _enviandoArquivo = false;

  // Campos para repetir/parcelar
  bool _repetirParcelar = false;
  int _quantidadeRepeticoes = 2;
  String _tipoRepeticao = 'mensal'; // mensal, quinzenal, semanal

  MaterialColor get _corTema => Colors.blue;

  @override
  void initState() {
    super.initState();

    // Data inicial
    if (widget.dataInicial != null) {
      _dataServico = widget.dataInicial;
      _horaServico = const TimeOfDay(hour: 10, minute: 0);
    }

    // Modo edição
    final ag = widget.agendamento;
    if (ag != null) {
      final dateTime = ag.dataHora.toDate();
      _dataServico = dateTime;
      _horaServico = TimeOfDay.fromDateTime(dateTime);
      _status = ag.status;

      // Parse das observações para extrair dados
      _parseObservacoes(ag.observacoes);

      // Carregar cliente
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (ag.clienteNome?.isNotEmpty == true) {
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
        }
      });
    }

    // Carregar clientes
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final uid = context.read<UserProvider>().uid;
      if (context.read<ClientsProvider>().clientes.isEmpty) {
        await context.read<ClientsProvider>().carregarTodos(uid);
      }
    });
  }

  void _parseObservacoes(String obs) {
    // Tentar extrair descrição
    final descMatch = RegExp(r'Descricao: (.+)').firstMatch(obs);
    if (descMatch != null) {
      _descricaoController.text = descMatch.group(1) ?? '';
    }

    // Tentar extrair valor
    final valorMatch = RegExp(r'Valor: R\$ ([\d,\.]+)').firstMatch(obs);
    if (valorMatch != null) {
      final valorStr = valorMatch
          .group(1)
          ?.replaceAll('.', '')
          .replaceAll(',', '.');
      if (valorStr != null) {
        final valor = double.tryParse(valorStr);
        if (valor != null) {
          _valorController.text =
              'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
        }
      }
    }

    // Tentar extrair observações extras (ignorar linhas padrão)
    final lines = obs.split('\n');
    final obsExtras = <String>[];
    bool ignorando = false;
    for (final line in lines) {
      if (line.startsWith('[COMPROVANTES]')) {
        ignorando = true;
        continue;
      }
      if (line.startsWith('[/COMPROVANTES]')) {
        ignorando = false;
        continue;
      }
      if (ignorando) continue;
      if (line.startsWith('[SERVICO]')) continue;
      if (line.startsWith('Descricao:')) continue;
      if (line.startsWith('Valor:')) continue;
      if (line.startsWith('Cliente:')) continue;
      if (line.startsWith('Servico:')) continue;
      if (line.startsWith('[Parcela')) continue;
      if (line.trim().isNotEmpty) {
        obsExtras.add(line);
      }
    }
    if (obsExtras.isNotEmpty) {
      _observacoesController.text = obsExtras.join('\n');
    }

    // Tentar extrair comprovantes
    final comprovantesMatch = RegExp(
      r'\[COMPROVANTES\]([\s\S]*?)\[/COMPROVANTES\]',
    ).firstMatch(obs);
    if (comprovantesMatch != null) {
      final comprovantesStr = comprovantesMatch.group(1) ?? '';
      for (final linha in comprovantesStr.split('\n')) {
        if (linha.contains('|')) {
          final partes = linha.split('|');
          if (partes.length >= 2) {
            final nome = partes[0].trim();
            final url = partes[1].trim();
            if (nome.isNotEmpty && url.isNotEmpty) {
              _arquivosAnexados.add(
                _ArquivoAnexoServico(
                  nome: nome,
                  url: url,
                  tipo: nome.toLowerCase().endsWith('.pdf') ? 'pdf' : 'image',
                ),
              );
            }
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
    final limpo = texto
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    return double.tryParse(limpo);
  }

  // ========== DATA E HORA ==========

  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataServico ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      locale: const Locale('pt', 'BR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _corTema.shade600,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.grey.shade800,
            ),
          ),
          child: child!,
        );
      },
    );
    if (data != null) {
      setState(() => _dataServico = data);
    }
  }

  Future<void> _selecionarHora() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: _horaServico ?? TimeOfDay.now(),
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
      setState(() => _horaServico = hora);
    }
  }

  // ========== CLIENTE ==========

  void _mostrarOpcoesCliente() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
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
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildOpcaoCliente(
                      icone: Icons.search,
                      titulo: 'Buscar',
                      subtitulo: 'Clientes cadastrados',
                      cor: Colors.blue,
                      onTap: () {
                        Navigator.pop(context);
                        _buscarCliente();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildOpcaoCliente(
                      icone: Icons.person_add,
                      titulo: 'Novo',
                      subtitulo: 'Criar cliente',
                      cor: Colors.green,
                      onTap: () {
                        Navigator.pop(context);
                        _criarNovoCliente();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Opção para importar da agenda
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _importarDaAgenda();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.contacts,
                          color: Colors.purple.shade700,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Importar da Agenda',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.purple.shade700,
                              ),
                            ),
                            Text(
                              'Usar contato do celular',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.purple.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.purple.shade400,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOpcaoCliente({
    required IconData icone,
    required String titulo,
    required String subtitulo,
    required MaterialColor cor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cor.shade400, cor.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: cor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icone, color: Colors.white, size: 32),
            const SizedBox(height: 12),
            Text(
              titulo,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitulo,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _buscarCliente() async {
    final cliente = await Navigator.push<Cliente>(
      context,
      MaterialPageRoute(builder: (_) => const ClientesPage(isPickerMode: true)),
    );
    if (cliente != null && mounted) {
      setState(() => _clienteSelecionado = cliente);
    }
  }

  Future<void> _criarNovoCliente() async {
    final novoCliente = await Navigator.push<Cliente>(
      context,
      MaterialPageRoute(builder: (_) => const NovoClientePage()),
    );
    if (novoCliente != null && mounted) {
      setState(() => _clienteSelecionado = novoCliente);
    }
  }

  Future<void> _importarDaAgenda() async {
    try {
      if (!await FlutterContacts.requestPermission(readonly: true)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Permissão para acessar contatos negada'),
              backgroundColor: Colors.red.shade600,
            ),
          );
        }
        return;
      }

      final contatos = await FlutterContacts.getContacts(withProperties: true);
      if (!mounted) return;

      final contatoSelecionado = await showModalBottomSheet<Contact>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Selecionar Contato',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: contatos.length,
                    itemBuilder: (context, index) {
                      final contato = contatos[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _corTema.shade100,
                          child: Text(
                            contato.displayName.isNotEmpty
                                ? contato.displayName[0].toUpperCase()
                                : '?',
                            style: TextStyle(color: _corTema.shade700),
                          ),
                        ),
                        title: Text(contato.displayName),
                        subtitle:
                            contato.phones.isNotEmpty
                                ? Text(contato.phones.first.number)
                                : null,
                        onTap: () => Navigator.pop(context, contato),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );

      if (contatoSelecionado != null && mounted) {
        setState(() {
          _clienteSelecionado = Cliente(
            id: '',
            nome: contatoSelecionado.displayName,
            celular:
                contatoSelecionado.phones.isNotEmpty
                    ? contatoSelecionado.phones.first.number
                    : '',
            telefone: '',
            email:
                contatoSelecionado.emails.isNotEmpty
                    ? contatoSelecionado.emails.first.address
                    : '',
            cpfCnpj: '',
            observacoes: '',
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao acessar contatos: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  // ========== SERVIÇO ==========

  void _mostrarOpcoesServico() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
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
                'Selecionar Serviço',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildOpcaoServico(
                      icone: Icons.list_alt,
                      titulo: 'Catálogo',
                      subtitulo: 'Serviços cadastrados',
                      cor: Colors.blue,
                      onTap: () {
                        Navigator.pop(context);
                        _buscarDoCatalogo();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildOpcaoServico(
                      icone: Icons.add_circle,
                      titulo: 'Criar Novo',
                      subtitulo: 'Cadastrar serviço',
                      cor: Colors.green,
                      onTap: () {
                        Navigator.pop(context);
                        _criarNovoServico();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildOpcaoServico(
                      icone: Icons.description,
                      titulo: 'Orçamentos',
                      subtitulo: 'De um orçamento',
                      cor: Colors.orange,
                      onTap: () {
                        Navigator.pop(context);
                        _selecionarDeOrcamento();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOpcaoServico({
    required IconData icone,
    required String titulo,
    required String subtitulo,
    required MaterialColor cor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cor.shade400, cor.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: cor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icone, color: Colors.white, size: 32),
            const SizedBox(height: 12),
            Text(
              titulo,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitulo,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _buscarDoCatalogo() async {
    final servico = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const ServicosPage(isPickerMode: true)),
    );
    if (servico != null && mounted) {
      setState(() {
        _servicoSelecionado = servico;
        // Preencher valor se o serviço tiver preço
        if (servico['preco'] != null) {
          final preco = (servico['preco'] as num).toDouble();
          _valorController.text =
              'R\$ ${preco.toStringAsFixed(2).replaceAll('.', ',')}';
        }
        // Preencher descrição se estiver vazia
        if (_descricaoController.text.isEmpty && servico['nome'] != null) {
          _descricaoController.text = servico['nome'];
        }
      });
    }
  }

  Future<void> _criarNovoServico() async {
    final novoServico = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const NovoServicoPage()),
    );
    if (novoServico != null && mounted) {
      setState(() {
        _servicoSelecionado = novoServico;
        // Preencher valor se o serviço tiver preço
        if (novoServico['preco'] != null) {
          final preco = (novoServico['preco'] as num).toDouble();
          _valorController.text =
              'R\$ ${preco.toStringAsFixed(2).replaceAll('.', ',')}';
        }
        // Preencher descrição se estiver vazia
        if (_descricaoController.text.isEmpty && novoServico['nome'] != null) {
          _descricaoController.text = novoServico['nome'];
        }
      });
    }
  }

  // Navegar para selecionar orçamento (igual à página de receita a receber)
  Future<void> _selecionarDeOrcamento() async {
    final orcamento = await Navigator.push<Orcamento>(
      context,
      MaterialPageRoute(
        builder: (_) => const OrcamentosPage(isPickerMode: true),
      ),
    );

    if (orcamento != null && mounted) {
      setState(() {
        _servicoSelecionado = {
          'nome':
              'Orçamento #${orcamento.numero.toString().padLeft(4, '0')} - ${orcamento.cliente.nome}',
          'descricao':
              'Orçamento com ${orcamento.itens.length} ${orcamento.itens.length == 1 ? 'item' : 'itens'}',
          'preco': orcamento.valorTotal,
          'tipo': 'orcamento',
          'orcamentoNumero': orcamento.numero,
        };
        // Preencher descrição com informações do orçamento
        _descricaoController.text =
            'Orçamento #${orcamento.numero.toString().padLeft(4, '0')} - ${orcamento.cliente.nome}';
        // Formata o valor corretamente
        final valorFormatado =
            'R\$ ${orcamento.valorTotal.toStringAsFixed(2).replaceAll('.', ',')}';
        _valorController.text = valorFormatado;
        // Preencher cliente do orçamento
        _clienteSelecionado = orcamento.cliente;
      });
    }
  }

  // ========== REPETIR / PARCELAR ==========

  void _mostrarConfigRepeticao() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
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
                    'Configurar Repetição',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Frequência
                  Text(
                    'Frequência',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildOpcaoFrequencia(
                          titulo: 'Semanal',
                          selecionado: _tipoRepeticao == 'semanal',
                          onTap: () {
                            setModalState(() => _tipoRepeticao = 'semanal');
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildOpcaoFrequencia(
                          titulo: 'Quinzenal',
                          selecionado: _tipoRepeticao == 'quinzenal',
                          onTap: () {
                            setModalState(() => _tipoRepeticao = 'quinzenal');
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildOpcaoFrequencia(
                          titulo: 'Mensal',
                          selecionado: _tipoRepeticao == 'mensal',
                          onTap: () {
                            setModalState(() => _tipoRepeticao = 'mensal');
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Quantidade
                  Text(
                    'Quantidade de Repetições',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          if (_quantidadeRepeticoes > 2) {
                            setModalState(() => _quantidadeRepeticoes--);
                            setState(() {});
                          }
                        },
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _corTema.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.remove, color: _corTema.shade700),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Text(
                        '$_quantidadeRepeticoes',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: _corTema.shade700,
                        ),
                      ),
                      const SizedBox(width: 24),
                      IconButton(
                        onPressed: () {
                          if (_quantidadeRepeticoes < 12) {
                            setModalState(() => _quantidadeRepeticoes++);
                            setState(() {});
                          }
                        },
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _corTema.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.add, color: _corTema.shade700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Resumo
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _corTema.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _corTema.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: _corTema.shade600),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _getDescricaoRepeticao(),
                            style: TextStyle(
                              color: _corTema.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botão confirmar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _corTema.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Confirmar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOpcaoFrequencia({
    required String titulo,
    required bool selecionado,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selecionado ? _corTema.shade600 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selecionado ? _corTema.shade600 : Colors.grey.shade300,
          ),
        ),
        child: Center(
          child: Text(
            titulo,
            style: TextStyle(
              color: selecionado ? Colors.white : Colors.grey.shade700,
              fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  String _getDescricaoRepeticao() {
    final freq =
        _tipoRepeticao == 'semanal'
            ? 'semana'
            : _tipoRepeticao == 'quinzenal'
            ? 'quinzena'
            : 'mês';
    return 'Serão criados $_quantidadeRepeticoes agendamentos, um a cada $freq';
  }

  DateTime _calcularProximaData(DateTime dataBase, String tipo, int indice) {
    switch (tipo) {
      case 'semanal':
        return dataBase.add(Duration(days: 7 * indice));
      case 'quinzenal':
        return dataBase.add(Duration(days: 15 * indice));
      case 'mensal':
      default:
        return DateTime(
          dataBase.year,
          dataBase.month + indice,
          dataBase.day,
          dataBase.hour,
          dataBase.minute,
        );
    }
  }

  // ========== ANEXOS ==========

  void _mostrarOpcoesAnexo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
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
                'Adicionar Comprovante',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildOpcaoAnexo(
                    icone: Icons.camera_alt,
                    titulo: 'Câmera',
                    cor: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      _tirarFoto();
                    },
                  ),
                  _buildOpcaoAnexo(
                    icone: Icons.photo_library,
                    titulo: 'Galeria',
                    cor: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      _escolherDaGaleria();
                    },
                  ),
                  _buildOpcaoAnexo(
                    icone: Icons.picture_as_pdf,
                    titulo: 'PDF',
                    cor: Colors.red,
                    onTap: () {
                      Navigator.pop(context);
                      _escolherPdf();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOpcaoAnexo({
    required IconData icone,
    required String titulo,
    required MaterialColor cor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: cor.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cor.shade200),
        ),
        child: Column(
          children: [
            Icon(icone, color: cor.shade600, size: 32),
            const SizedBox(height: 8),
            Text(
              titulo,
              style: TextStyle(
                color: cor.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _tirarFoto() async {
    try {
      final picker = ImagePicker();
      final imagem = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      if (imagem != null) {
        await _uploadArquivo(imagem.path, imagem.name, 'image');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao tirar foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _escolherDaGaleria() async {
    try {
      final picker = ImagePicker();
      final imagem = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (imagem != null) {
        await _uploadArquivo(imagem.path, imagem.name, 'image');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao escolher imagem: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _escolherPdf() async {
    try {
      final resultado = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (resultado != null && resultado.files.isNotEmpty) {
        final arquivo = resultado.files.first;
        if (arquivo.path != null) {
          await _uploadArquivo(arquivo.path!, arquivo.name, 'pdf');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao escolher PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadArquivo(String caminho, String nome, String tipo) async {
    setState(() => _enviandoArquivo = true);
    try {
      final uid = context.read<UserProvider>().uid;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final nomeArquivo = '${timestamp}_$nome';
      final ref = FirebaseStorage.instance.ref().child(
        'comprovantes/$uid/$nomeArquivo',
      );

      if (kIsWeb) {
        final bytes = await File(caminho).readAsBytes();
        await ref.putData(bytes);
      } else {
        await ref.putFile(File(caminho));
      }

      final url = await ref.getDownloadURL();

      setState(() {
        _arquivosAnexados.add(
          _ArquivoAnexoServico(nome: nome, url: url, tipo: tipo),
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Comprovante anexado!'),
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
          SnackBar(
            content: Text('Erro ao enviar arquivo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _enviandoArquivo = false);
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.attach_file, color: Colors.grey.shade600),
                  const SizedBox(width: 12),
                  const Text(
                    'Comprovantes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              _enviandoArquivo
                  ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(_corTema.shade600),
                    ),
                  )
                  : IconButton(
                    onPressed: _mostrarOpcoesAnexo,
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _corTema.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add,
                        color: _corTema.shade700,
                        size: 18,
                      ),
                    ),
                  ),
            ],
          ),
          if (_arquivosAnexados.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...List.generate(_arquivosAnexados.length, (index) {
              final arquivo = _arquivosAnexados[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      arquivo.tipo == 'pdf'
                          ? Icons.picture_as_pdf
                          : Icons.image,
                      color: arquivo.tipo == 'pdf' ? Colors.red : Colors.green,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        arquivo.nome,
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _removerArquivo(index),
                      icon: Icon(
                        Icons.close,
                        color: Colors.red.shade400,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ========== SALVAR ==========

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dataServico == null || _horaServico == null) {
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
        _dataServico!.year,
        _dataServico!.month,
        _dataServico!.day,
        _horaServico!.hour,
        _horaServico!.minute,
      );

      final valor = _parseMoeda(_valorController.text) ?? 0.0;

      // Monta observacoes
      final obsAgendamento = StringBuffer();
      obsAgendamento.writeln('[SERVICO]');
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
      if (_servicoSelecionado != null) {
        final nomeServico = _servicoSelecionado!['nome'] ?? '';
        obsAgendamento.writeln('Servico: $nomeServico');
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
          _clienteSelecionado?.nome ?? 'Serviço: ${_descricaoController.text}';

      if (widget.agendamento != null) {
        // Modo edicao
        final agendamentoAtualizado = Agendamento(
          id: widget.agendamento!.id,
          orcamentoId: 'agendamento_servicos',
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
              orcamentoId: 'agendamento_servicos',
              orcamentoNumero: null,
              clienteNome: clienteNome,
              dataHora: Timestamp.fromDate(dataRepetida),
              status: _status,
              observacoes: obsComParcela,
            );
          }
        } else {
          await agProv.adicionarAgendamento(
            orcamentoId: 'agendamento_servicos',
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
          mensagemSucesso = '$_quantidadeRepeticoes serviços agendados!';
        } else {
          mensagemSucesso = 'Serviço agendado com sucesso!';
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
          widget.agendamento != null ? 'Editar Agendamento' : 'Novo Serviço',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_salvando)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ),
            )
          else
            IconButton(
              onPressed: _salvar,
              icon: const Icon(Icons.check),
              tooltip: 'Salvar',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header decorativo
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [corTema.shade400, corTema.shade600],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: corTema.withOpacity(0.3),
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
                        Icons.build_circle,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.agendamento != null
                                ? 'Editar Serviço'
                                : 'Agendar Serviço',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
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
              const SizedBox(height: 24),

              // Formulário em card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
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

                    // ========== VINCULAR SERVIÇO ==========
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
                          Icon(Icons.build_circle, color: corTema.shade600),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Serviço',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _servicoSelecionado != null
                                      ? '${_servicoSelecionado!['nome'] ?? ''}'
                                      : 'Nenhum serviço selecionado',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        _servicoSelecionado != null
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                    color:
                                        _servicoSelecionado != null
                                            ? corTema.shade700
                                            : Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _mostrarOpcoesServico,
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: corTema.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.add,
                                color: corTema.shade700,
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
                          Icon(Icons.person, color: Colors.teal.shade600),
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
                                  _clienteSelecionado?.nome ??
                                      'Nenhum cliente selecionado',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        _clienteSelecionado != null
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                    color:
                                        _clienteSelecionado != null
                                            ? Colors.teal.shade700
                                            : Colors.grey.shade500,
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
                                color: Colors.teal.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.add,
                                color: Colors.teal.shade700,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ========== DESCRIÇÃO ==========
                    TextFormField(
                      controller: _descricaoController,
                      decoration: InputDecoration(
                        labelText: 'Descrição do Serviço',
                        hintText: 'Ex: Manutenção preventiva',
                        prefixIcon: Icon(
                          Icons.description,
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
                      ),
                      validator:
                          (v) =>
                              v == null || v.isEmpty
                                  ? 'Informe a descrição'
                                  : null,
                    ),
                    const SizedBox(height: 16),

                    // ========== VALOR ==========
                    TextFormField(
                      controller: _valorController,
                      decoration: InputDecoration(
                        labelText: 'Valor (R\$)',
                        hintText: 'R\$ 0,00',
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
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [CurrencyInputFormatterServico()],
                    ),
                    const SizedBox(height: 16),

                    // ========== DATA E HORA ==========
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _selecionarData,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: corTema.shade600,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Data',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          _dataServico != null
                                              ? dateFormat.format(_dataServico!)
                                              : 'Selecionar',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                _dataServico != null
                                                    ? corTema.shade700
                                                    : Colors.grey,
                                          ),
                                        ),
                                      ],
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
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    color: corTema.shade600,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Hora',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          _horaServico != null
                                              ? '${_horaServico!.hour.toString().padLeft(2, '0')}:${_horaServico!.minute.toString().padLeft(2, '0')}'
                                              : 'Selecionar',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                _horaServico != null
                                                    ? corTema.shade700
                                                    : Colors.grey,
                                          ),
                                        ),
                                      ],
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

                    // ========== STATUS ==========
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _status,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          prefixIcon: Icon(Icons.flag, color: corTema.shade600),
                          border: InputBorder.none,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Pendente',
                            child: Text('Pendente'),
                          ),
                          DropdownMenuItem(
                            value: 'Confirmado',
                            child: Text('Confirmado'),
                          ),
                          DropdownMenuItem(
                            value: 'Concluído',
                            child: Text('Concluído'),
                          ),
                          DropdownMenuItem(
                            value: 'Cancelado',
                            child: Text('Cancelado'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _status = v);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ========== OBSERVAÇÕES ==========
                    TextFormField(
                      controller: _observacoesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Observações',
                        hintText: 'Informações adicionais...',
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(bottom: 48),
                          child: Icon(Icons.notes, color: corTema.shade600),
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
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ========== COMPROVANTES ==========
                    _buildCardAnexos(),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ========== BOTÃO SALVAR ==========
              ElevatedButton(
                onPressed: _salvando ? null : _salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: corTema.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child:
                    _salvando
                        ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                        : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check),
                            const SizedBox(width: 8),
                            Text(
                              widget.agendamento != null
                                  ? 'Atualizar'
                                  : 'Agendar Serviço',
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
      ),
    );
  }
}
