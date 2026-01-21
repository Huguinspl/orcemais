import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../models/agendamento.dart';
import '../../../providers/agendamentos_provider.dart';
import 'agendamento_a_pagar_page.dart';
import 'agendamento_a_receber_page.dart';
import 'agendamento_diversos_page.dart';
import 'agendamento_vendas_page.dart';
import 'novo_agendamento_page.dart';

class AgendamentosPage extends StatefulWidget {
  const AgendamentosPage({super.key});

  @override
  State<AgendamentosPage> createState() => _AgendamentosPageState();
}

class _AgendamentosPageState extends State<AgendamentosPage>
    with SingleTickerProviderStateMixin {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
    Future.microtask(
      () => context.read<AgendamentosProvider>().carregarAgendamentos(),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<Agendamento> _getAgendamentosForDay(
    DateTime day,
    List<Agendamento> agendamentos,
  ) {
    return agendamentos.where((agendamento) {
      final agendamentoDate = agendamento.dataHora.toDate();
      return isSameDay(agendamentoDate, day);
    }).toList();
  }

  Future<void> _abrirFormulario({
    Agendamento? agendamento,
    DateTime? dataInicial,
  }) async {
    // Se for edição de agendamento existente, abre a página correspondente ao tipo
    if (agendamento != null) {
      Widget pagina;

      // Verifica o tipo do agendamento pelo orcamentoId
      switch (agendamento.orcamentoId) {
        case 'receita_a_receber':
          pagina = AgendamentoAReceberPage(agendamento: agendamento);
          break;
        case 'despesa_a_pagar':
          pagina = AgendamentoAPagarPage(agendamento: agendamento);
          break;
        case 'agendamento_diversos':
          pagina = AgendamentoDiversosPage(agendamento: agendamento);
          break;
        case 'agendamento_vendas':
          pagina = AgendamentoVendasPage(agendamento: agendamento);
          break;
        default:
          // Agendamento padrão (de orçamento) ou tipo desconhecido
          pagina = NovoAgendamentoPage(
            agendamento: agendamento,
            dataInicial: dataInicial,
          );
          break;
      }

      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => pagina));
    } else {
      // Novo agendamento: abre card de seleção de tipo (igual Nova Transação)
      await _mostrarCardNovoAgendamento(dataInicial: dataInicial);
    }
  }

  /// Exibe um card bottom sheet para selecionar o tipo de agendamento
  Future<void> _mostrarCardNovoAgendamento({DateTime? dataInicial}) async {
    final tipo = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Novo Agendamento',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selecione o tipo de agendamento',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),

                  // Agendamentos de Trabalho
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.work_outline,
                              size: 16,
                              color: Colors.blue.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Agendamentos de Trabalho',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Botão Serviços
                            Expanded(
                              child: _buildTipoAgendamentoButton(
                                tipo: 'servicos',
                                titulo: 'Serviços',
                                subtitulo: 'Agendamento de serviços',
                                icone: Icons.build_circle,
                                cor: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Botão Vendas
                            Expanded(
                              child: _buildTipoAgendamentoButton(
                                tipo: 'vendas',
                                titulo: 'Vendas',
                                subtitulo: 'Agendamento de vendas',
                                icone: Icons.shopping_cart,
                                cor: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Agendamentos Financeiros
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 16,
                              color: Colors.green.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Agendamentos Financeiros',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Botão A Receber
                            Expanded(
                              child: _buildTipoAgendamentoButton(
                                tipo: 'a_receber',
                                titulo: 'A Receber',
                                subtitulo: 'Receita futura',
                                icone: Icons.call_received,
                                cor: Colors.teal,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Botão A Pagar
                            Expanded(
                              child: _buildTipoAgendamentoButton(
                                tipo: 'a_pagar',
                                titulo: 'A Pagar',
                                subtitulo: 'Despesa futura',
                                icone: Icons.call_made,
                                cor: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Agendamento Rápido
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.flash_on,
                              size: 16,
                              color: Colors.purple.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Agendamento Rápido',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Card Diversos (largura total)
                        _buildTipoAgendamentoButtonFull(
                          tipo: 'diversos',
                          titulo: 'Diversos',
                          subtitulo:
                              'Agendamento rápido para trabalhos rápidos',
                          icone: Icons.event_available,
                          cor: Colors.purple,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
    );

    // Se selecionou um tipo, abre a página correspondente
    if (tipo != null && mounted) {
      Widget pagina;

      switch (tipo) {
        case 'servicos':
          pagina = NovoAgendamentoPage(dataInicial: dataInicial);
          break;
        case 'vendas':
          pagina = AgendamentoVendasPage(dataInicial: dataInicial);
          break;
        case 'a_receber':
          pagina = const AgendamentoAReceberPage();
          break;
        case 'a_pagar':
          pagina = const AgendamentoAPagarPage();
          break;
        case 'diversos':
          pagina = AgendamentoDiversosPage(dataInicial: dataInicial);
          break;
        default:
          pagina = NovoAgendamentoPage(dataInicial: dataInicial);
      }

      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => pagina));
    }
  }

  Widget _buildTipoAgendamentoButton({
    required String tipo,
    required String titulo,
    required String subtitulo,
    required IconData icone,
    required MaterialColor cor,
  }) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, tipo),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [cor.shade400, cor.shade600],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: cor.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icone, color: Colors.white, size: 40),
            const SizedBox(height: 10),
            Text(
              titulo,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitulo,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipoAgendamentoButtonFull({
    required String tipo,
    required String titulo,
    required String subtitulo,
    required IconData icone,
    required MaterialColor cor,
  }) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, tipo),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [cor.shade400, cor.shade600],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: cor.withOpacity(0.3),
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
              child: Icon(icone, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitulo,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white70,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _mudarStatus(Agendamento ag) async {
    final statusConfig = {
      'Pendente': {'cor': Colors.orange, 'icone': Icons.pending_outlined},
      'Confirmado': {'cor': Colors.blue, 'icone': Icons.check_circle_outline},
      'Concluido': {'cor': Colors.green, 'icone': Icons.done_all},
      'Cancelado': {'cor': Colors.red, 'icone': Icons.cancel_outlined},
    };

    final novo = await showDialog<String>(
      context: context,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade50, Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.teal.shade400, Colors.teal.shade600],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_calendar,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Alterar Status',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  ...statusConfig.entries.map((entry) {
                    final status = entry.key;
                    final config = entry.value;
                    final cor = config['cor'] as MaterialColor;
                    final isSelected = status == ag.status;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        gradient:
                            isSelected
                                ? LinearGradient(
                                  colors: [cor.shade100, cor.shade50],
                                )
                                : null,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? cor : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: RadioListTile<String>(
                        title: Row(
                          children: [
                            Icon(
                              config['icone'] as IconData,
                              color: cor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              status,
                              style: TextStyle(
                                fontWeight:
                                    isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                color:
                                    isSelected
                                        ? cor.shade900
                                        : Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                        value: status,
                        groupValue: ag.status,
                        activeColor: cor,
                        onChanged: (v) => Navigator.pop(context, v),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
    );

    if (novo != null && novo != ag.status) {
      await context.read<AgendamentosProvider>().atualizarStatus(ag.id, novo);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Status alterado para $novo'),
              ],
            ),
            backgroundColor: Colors.teal.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _confirmarExclusao(Agendamento ag) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade50, Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red.shade400, Colors.red.shade600],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Excluir Agendamento',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ag.orcamentoId == 'receita_a_receber'
                        ? 'Deseja excluir o agendamento "${ag.clienteNome}"?'
                        : ag.orcamentoId == 'despesa_a_pagar'
                        ? 'Deseja excluir o agendamento "${ag.clienteNome}"?'
                        : 'Deseja excluir o agendamento do orçamento #${ag.orcamentoNumero?.toString().padLeft(4, '0') ?? '--'}?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey.shade700,
                            side: BorderSide(color: Colors.grey.shade300),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Excluir'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );

    if (confirmar == true) {
      await context.read<AgendamentosProvider>().excluirAgendamento(ag.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Agendamento excluído com sucesso'),
              ],
            ),
            backgroundColor: Colors.teal.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  MaterialColor _getStatusColor(String status) {
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

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('HH:mm');
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Agendamentos',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade600, Colors.teal.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AgendamentosProvider>().carregarAgendamentos();
            },
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade50, Colors.white, Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Consumer<AgendamentosProvider>(
              builder: (_, provider, __) {
                if (provider.isLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      // Card do calendário
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: TableCalendar(
                              firstDay: DateTime.utc(2020, 1, 1),
                              lastDay: DateTime.utc(2100, 12, 31),
                              focusedDay: _focusedDay,
                              selectedDayPredicate:
                                  (day) => isSameDay(_selectedDay, day),
                              calendarFormat: _calendarFormat,
                              startingDayOfWeek: StartingDayOfWeek.monday,
                              locale: 'pt_BR',
                              eventLoader:
                                  (day) => _getAgendamentosForDay(
                                    day,
                                    provider.agendamentos,
                                  ),
                              onDaySelected: (selectedDay, focusedDay) {
                                setState(() {
                                  _selectedDay = selectedDay;
                                  _focusedDay = focusedDay;
                                });
                                // Apenas atualiza a seleção para mostrar os agendamentos do dia
                                // O botão flutuante (+) é usado para criar novos agendamentos
                              },
                              onFormatChanged: (format) {
                                setState(() {
                                  _calendarFormat = format;
                                });
                              },
                              onPageChanged: (focusedDay) {
                                _focusedDay = focusedDay;
                              },
                              calendarStyle: CalendarStyle(
                                selectedDecoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.teal.shade400,
                                      Colors.teal.shade600,
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                todayDecoration: BoxDecoration(
                                  color: Colors.teal.shade200,
                                  shape: BoxShape.circle,
                                ),
                                markerDecoration: const BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                                markersMaxCount: 3,
                                outsideDaysVisible: false,
                              ),
                              headerStyle: HeaderStyle(
                                formatButtonVisible: true,
                                titleCentered: true,
                                formatButtonShowsNext: false,
                                formatButtonDecoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.teal.shade100,
                                      Colors.teal.shade50,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                formatButtonTextStyle: TextStyle(
                                  color: Colors.teal.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Lista de agendamentos do dia selecionado
                      if (_selectedDay != null) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.event_note,
                                color: Colors.teal.shade600,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Agendamentos - ${DateFormat('dd/MM/yyyy').format(_selectedDay!)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._buildAgendamentosList(
                          _getAgendamentosForDay(
                            _selectedDay!,
                            provider.agendamentos,
                          ),
                          dateFormat,
                        ),
                        const SizedBox(height: 80),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.shade300.withOpacity(0.5),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _abrirFormulario(),
          backgroundColor: Colors.teal.shade600,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Novo Agendamento',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAgendamentosList(
    List<Agendamento> agendamentos,
    DateFormat dateFormat,
  ) {
    if (agendamentos.isEmpty) {
      return [
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.teal.shade200, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(Icons.event_busy, size: 64, color: Colors.teal.shade300),
                const SizedBox(height: 16),
                Text(
                  'Nenhum agendamento',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Não há agendamentos para este dia',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return agendamentos.map((ag) {
      final statusColor = _getStatusColor(ag.status);
      final statusIcon = _getStatusIcon(ag.status);

      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () => _abrirFormulario(agendamento: ag),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, statusColor.shade50],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Indicador de horário
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [statusColor.shade400, statusColor.shade600],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.access_time, color: Colors.white, size: 20),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(ag.dataHora.toDate()),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Informações
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ag.orcamentoId == 'receita_a_receber'
                              ? 'Receita a Receber'
                              : ag.orcamentoId == 'despesa_a_pagar'
                              ? 'Despesa a Pagar'
                              : ag.orcamentoId.isEmpty || ag.orcamentoId == ''
                              ? (ag.observacoes.contains('[DIVERSO]')
                                  ? 'Agendamento Rápido'
                                  : ag.observacoes.contains('[VENDA]')
                                  ? 'Agendamento de Venda'
                                  : 'Agendamento de Serviço')
                              : 'Orçamento #${ag.orcamentoNumero?.toString().padLeft(4, '0') ?? '--'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ag.clienteNome ?? 'Cliente não informado',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Badge de status
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                statusColor.shade100,
                                statusColor.shade200,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: statusColor.shade300,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                statusIcon,
                                size: 16,
                                color: statusColor.shade700,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                ag.status,
                                style: TextStyle(
                                  color: statusColor.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Menu de ações
                  PopupMenuButton(
                    icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (value) {
                      if (value == 'status') _mudarStatus(ag);
                      if (value == 'excluir') _confirmarExclusao(ag);
                    },
                    itemBuilder:
                        (_) => [
                          PopupMenuItem(
                            value: 'status',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_calendar,
                                  color: Colors.teal.shade600,
                                ),
                                const SizedBox(width: 12),
                                const Text('Alterar status'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'excluir',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  color: Colors.red.shade600,
                                ),
                                const SizedBox(width: 12),
                                const Text('Excluir'),
                              ],
                            ),
                          ),
                        ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}
