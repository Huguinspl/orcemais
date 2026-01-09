import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/agendamento.dart';
import '../../../models/cliente.dart';
import '../../../providers/agendamentos_provider.dart';
import '../../../providers/clients_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../services/notification_service.dart';

/// Página para criar agendamento diversos (rápido)
/// Ideal para trabalhos rápidos como cabeleireiro, manicure, etc.
class AgendamentoDiversosPage extends StatefulWidget {
  final Agendamento? agendamento;
  final DateTime? dataInicial;

  const AgendamentoDiversosPage({
    super.key,
    this.agendamento,
    this.dataInicial,
  });

  @override
  State<AgendamentoDiversosPage> createState() =>
      _AgendamentoDiversosPageState();
}

class _AgendamentoDiversosPageState extends State<AgendamentoDiversosPage> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _observacoesController = TextEditingController();

  DateTime? _dataSelecionada;
  TimeOfDay? _horaSelecionada;
  TimeOfDay? _horaFim;
  String _status = 'Confirmado'; // Padrão confirmado para agendamentos rápidos
  Cliente? _clienteSelecionado;
  bool _salvando = false;

  // Duração padrão em minutos
  int _duracaoMinutos = 30;

  // Lista de serviços rápidos predefinidos
  final List<Map<String, dynamic>> _servicosRapidos = [
    {'nome': 'Corte de Cabelo', 'duracao': 30, 'icone': Icons.content_cut},
    {'nome': 'Manicure', 'duracao': 45, 'icone': Icons.brush},
    {'nome': 'Pedicure', 'duracao': 45, 'icone': Icons.spa},
    {'nome': 'Escova', 'duracao': 40, 'icone': Icons.air},
    {'nome': 'Barba', 'duracao': 20, 'icone': Icons.face},
    {'nome': 'Sobrancelha', 'duracao': 15, 'icone': Icons.visibility},
    {'nome': 'Hidratação', 'duracao': 60, 'icone': Icons.water_drop},
    {'nome': 'Coloração', 'duracao': 90, 'icone': Icons.color_lens},
  ];

  @override
  void initState() {
    super.initState();

    if (widget.dataInicial != null) {
      _dataSelecionada = widget.dataInicial;
    } else {
      _dataSelecionada = DateTime.now();
    }

    _horaSelecionada = TimeOfDay.now();
    _atualizarHoraFim();

    final ag = widget.agendamento;
    if (ag != null) {
      final dateTime = ag.dataHora.toDate();
      _dataSelecionada = dateTime;
      _horaSelecionada = TimeOfDay.fromDateTime(dateTime);
      _status = ag.status;
      _observacoesController.text = ag.observacoes;
      _tituloController.text = ag.clienteNome ?? '';

      // Buscar cliente pelo nome
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (ag.clienteNome?.isNotEmpty == true) {
          final uid = context.read<UserProvider>().uid;
          final clientesProv = context.read<ClientsProvider>();
          await clientesProv.carregarTodos(uid);

          if (mounted) {
            final clienteEncontrado = clientesProv.clientes.where(
              (c) => c.nome == ag.clienteNome,
            );
            if (clienteEncontrado.isNotEmpty) {
              setState(() => _clienteSelecionado = clienteEncontrado.first);
            }
          }
        }
      });
    }

    // Carrega clientes
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final uid = context.read<UserProvider>().uid;
      if (context.read<ClientsProvider>().clientes.isEmpty) {
        await context.read<ClientsProvider>().carregarTodos(uid);
      }
    });
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  void _atualizarHoraFim() {
    if (_horaSelecionada != null) {
      final inicioMinutos =
          _horaSelecionada!.hour * 60 + _horaSelecionada!.minute;
      final fimMinutos = inicioMinutos + _duracaoMinutos;
      _horaFim = TimeOfDay(
        hour: (fimMinutos ~/ 60) % 24,
        minute: fimMinutos % 60,
      );
    }
  }

  void _selecionarServicoRapido(Map<String, dynamic> servico) {
    setState(() {
      _tituloController.text = servico['nome'];
      _duracaoMinutos = servico['duracao'];
      _atualizarHoraFim();
    });
  }

  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.purple.shade600,
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
      initialTime: _horaSelecionada ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              dialBackgroundColor: Colors.purple.shade50,
              hourMinuteTextColor: Colors.purple.shade700,
            ),
          ),
          child: child!,
        );
      },
    );
    if (hora != null) {
      setState(() {
        _horaSelecionada = hora;
        _atualizarHoraFim();
      });
    }
  }

  Future<void> _selecionarCliente() async {
    final clientesProv = context.read<ClientsProvider>();
    if (clientesProv.clientes.isEmpty) {
      final uid = context.read<UserProvider>().uid;
      await clientesProv.carregarTodos(uid);
    }

    if (!mounted) return;

    final selecionado = await showModalBottomSheet<Cliente>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final lista = clientesProv.clientes;
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade50, Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                    colors: [Colors.purple.shade600, Colors.purple.shade400],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Selecionar Cliente',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child:
                    lista.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 64,
                                color: Colors.purple.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Nenhum cliente cadastrado',
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
                          itemCount: lista.length,
                          itemBuilder: (_, i) {
                            final c = lista[i];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: InkWell(
                                onTap: () => Navigator.pop(context, c),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.purple.shade400,
                                              Colors.purple.shade600,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            c.nome.isNotEmpty
                                                ? c.nome[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              c.nome,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            if (c.celular.isNotEmpty)
                                              Text(
                                                c.celular,
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right,
                                        color: Colors.purple.shade400,
                                      ),
                                    ],
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

    if (selecionado != null && mounted) {
      setState(() => _clienteSelecionado = selecionado);
    }
  }

  Future<void> _salvar() async {
    if (_tituloController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Selecione um serviço ou digite o título'),
          backgroundColor: Colors.purple.shade600,
        ),
      );
      return;
    }
    if (_dataSelecionada == null || _horaSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Selecione data e hora'),
          backgroundColor: Colors.purple.shade600,
        ),
      );
      return;
    }

    setState(() => _salvando = true);

    try {
      final agProv = context.read<AgendamentosProvider>();
      final dataHora = DateTime(
        _dataSelecionada!.year,
        _dataSelecionada!.month,
        _dataSelecionada!.day,
        _horaSelecionada!.hour,
        _horaSelecionada!.minute,
      );

      // Monta observações incluindo título e duração
      final observacoesCompletas = StringBuffer();
      observacoesCompletas.writeln('[DIVERSO]');
      observacoesCompletas.writeln('Serviço: ${_tituloController.text}');
      observacoesCompletas.writeln('Duração: $_duracaoMinutos min');
      if (_horaFim != null) {
        observacoesCompletas.writeln(
          'Término previsto: ${_horaFim!.format(context)}',
        );
      }
      if (_observacoesController.text.isNotEmpty) {
        observacoesCompletas.writeln(_observacoesController.text);
      }

      final nomeCliente = _clienteSelecionado?.nome ?? _tituloController.text;

      final agendamento = Agendamento(
        id: widget.agendamento?.id ?? '',
        orcamentoId: '',
        orcamentoNumero: null,
        clienteNome: nomeCliente,
        dataHora: Timestamp.fromDate(dataHora),
        status: _status,
        observacoes: observacoesCompletas.toString().trim(),
        criadoEm: widget.agendamento?.criadoEm ?? Timestamp.now(),
        atualizadoEm: Timestamp.now(),
      );

      if (widget.agendamento != null) {
        await agProv.atualizarAgendamento(agendamento);

        // Atualiza notificação se confirmado
        if (_status == 'Confirmado') {
          await NotificationService().agendarNotificacao(agendamento);
        } else {
          await NotificationService().cancelarNotificacao(agendamento.id);
        }
      } else {
        await agProv.adicionarAgendamento(
          orcamentoId: '',
          orcamentoNumero: null,
          clienteNome: nomeCliente,
          dataHora: Timestamp.fromDate(dataHora),
          status: _status,
          observacoes: observacoesCompletas.toString().trim(),
        );

        // Notificação já é agendada automaticamente pelo provider
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.agendamento != null
                  ? 'Agendamento atualizado!'
                  : 'Agendamento criado com sucesso!',
            ),
            backgroundColor: Colors.green,
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

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.purple.shade600,
        foregroundColor: Colors.white,
        title: Text(
          widget.agendamento != null
              ? 'Editar Agendamento'
              : 'Agendamento Rápido',
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
            colors: [Colors.purple.shade50, Colors.white, Colors.white],
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade400, Colors.purple.shade600],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
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
                        Icons.flash_on,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Agendamento Rápido',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Ideal para trabalhos rápidos',
                            style: TextStyle(
                              color: Colors.white70,
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

              // Serviços Rápidos
              _buildSectionTitle('Serviço Rápido', Icons.flash_on),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _servicosRapidos.map((servico) {
                      final isSelected =
                          _tituloController.text == servico['nome'];
                      return GestureDetector(
                        onTap: () => _selecionarServicoRapido(servico),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient:
                                isSelected
                                    ? LinearGradient(
                                      colors: [
                                        Colors.purple.shade400,
                                        Colors.purple.shade600,
                                      ],
                                    )
                                    : null,
                            color: isSelected ? null : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? Colors.purple.shade400
                                      : Colors.grey.shade300,
                            ),
                            boxShadow:
                                isSelected
                                    ? [
                                      BoxShadow(
                                        color: Colors.purple.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                    : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                servico['icone'],
                                size: 18,
                                color:
                                    isSelected
                                        ? Colors.white
                                        : Colors.purple.shade600,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                servico['nome'],
                                style: TextStyle(
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : Colors.grey.shade800,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '(${servico['duracao']}min)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      isSelected
                                          ? Colors.white70
                                          : Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),

              // Título personalizado
              TextFormField(
                controller: _tituloController,
                decoration: InputDecoration(
                  hintText: 'Ou digite um serviço personalizado...',
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
                    borderSide: BorderSide(color: Colors.purple.shade600),
                  ),
                  prefixIcon: Icon(Icons.edit, color: Colors.purple.shade600),
                ),
              ),
              const SizedBox(height: 20),

              // Cliente (opcional)
              _buildSectionTitle('Cliente (Opcional)', Icons.person),
              const SizedBox(height: 12),
              InkWell(
                onTap: _selecionarCliente,
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
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.purple.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.person,
                          color: Colors.purple.shade600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _clienteSelecionado?.nome ?? 'Selecionar cliente',
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                _clienteSelecionado != null
                                    ? Colors.black87
                                    : Colors.grey.shade500,
                          ),
                        ),
                      ),
                      if (_clienteSelecionado != null)
                        IconButton(
                          onPressed: () {
                            setState(() => _clienteSelecionado = null);
                          },
                          icon: Icon(Icons.close, color: Colors.grey.shade400),
                        )
                      else
                        Icon(Icons.chevron_right, color: Colors.grey.shade400),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Data e Hora
              _buildSectionTitle('Data e Hora', Icons.calendar_today),
              const SizedBox(height: 12),
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
                              color: Colors.purple.shade600,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _dataSelecionada != null
                                  ? dateFormat.format(_dataSelecionada!)
                                  : 'Data',
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
                              color: Colors.purple.shade600,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _horaSelecionada != null
                                  ? _horaSelecionada!.format(context)
                                  : 'Hora',
                              style: TextStyle(
                                fontSize: 16,
                                color:
                                    _horaSelecionada != null
                                        ? Colors.black87
                                        : Colors.grey.shade500,
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

              // Duração e Hora Final
              Row(
                children: [
                  // Duração
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.timer, color: Colors.purple.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _duracaoMinutos,
                                isExpanded: true,
                                items:
                                    [15, 20, 30, 45, 60, 90, 120]
                                        .map(
                                          (d) => DropdownMenuItem(
                                            value: d,
                                            child: Text('$d min'),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() {
                                      _duracaoMinutos = v;
                                      _atualizarHoraFim();
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Hora Final (somente exibição)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.flag, color: Colors.purple.shade600),
                          const SizedBox(width: 12),
                          Text(
                            _horaFim != null
                                ? 'Fim: ${_horaFim!.format(context)}'
                                : 'Fim: --:--',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Status
              _buildSectionTitle('Status', Icons.flag),
              const SizedBox(height: 12),
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
                      color: Colors.purple.shade600,
                    ),
                    items:
                        ['Pendente', 'Confirmado', 'Concluido', 'Cancelado']
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
              const SizedBox(height: 20),

              // Observações
              _buildSectionTitle('Observações', Icons.notes),
              const SizedBox(height: 12),
              TextFormField(
                controller: _observacoesController,
                maxLines: 2,
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
                    borderSide: BorderSide(color: Colors.purple.shade600),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Botão Salvar
              ElevatedButton(
                onPressed: _salvando ? null : _salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade600,
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
                            Icon(Icons.flash_on),
                            SizedBox(width: 8),
                            Text(
                              'Agendar Rápido',
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
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.purple.shade600),
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
