import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../models/agendamento.dart';
import '../../../models/receita.dart';
import '../../../providers/agendamentos_provider.dart';
import '../../../providers/transacoes_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../routes/app_routes.dart';
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

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _statusScrollController = ScrollController();
  String _filtroSelecionado = 'Todos';
  String _termoBusca = '';

  final List<String> _status = [
    'Todos',
    'Pendente',
    'Confirmado',
    'Concluido',
    'Cancelado',
  ];

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

    _searchController.addListener(() {
      setState(() {
        _termoBusca = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _statusScrollController.dispose();
    super.dispose();
  }

  // Método para alternar status via swipe
  void _mudarStatusPorSwipe(DragEndDetails details) {
    final velocidade = details.primaryVelocity ?? 0;
    final indexAtual = _status.indexOf(_filtroSelecionado);

    if (velocidade < -300) {
      // Swipe para esquerda -> próximo status
      if (indexAtual < _status.length - 1) {
        final novoIndex = indexAtual + 1;
        setState(() {
          _filtroSelecionado = _status[novoIndex];
        });
        _rolarParaStatus(novoIndex);
      }
    } else if (velocidade > 300) {
      // Swipe para direita -> status anterior
      if (indexAtual > 0) {
        final novoIndex = indexAtual - 1;
        setState(() {
          _filtroSelecionado = _status[novoIndex];
        });
        _rolarParaStatus(novoIndex);
      }
    }
  }

  // Método para rolar a barra de filtros até o status selecionado
  void _rolarParaStatus(int index) {
    const double larguraChip = 120.0;
    final double posicaoAlvo = index * larguraChip;

    _statusScrollController.animateTo(
      posicaoAlvo,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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
                                icone: Icons.call_made,
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
                                icone: Icons.call_received,
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
    // Verifica se é um agendamento de despesa a pagar
    if (ag.orcamentoId == 'despesa_a_pagar') {
      await _mudarStatusDespesaAPagar(ag);
      return;
    }

    // Verifica se é um agendamento de receita a receber
    if (ag.orcamentoId == 'receita_a_receber') {
      await _mudarStatusReceitaAReceber(ag);
      return;
    }

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

  /// Método especial para alterar status de agendamentos de despesa a pagar
  /// - "Pago" = marca como Concluido + salva despesa no controle financeiro
  /// - "Reagendar" = cria novo agendamento 24h depois
  Future<void> _mudarStatusDespesaAPagar(Agendamento ag) async {
    // Config especial para despesa a pagar
    final statusConfig = {
      'Pendente': {
        'cor': Colors.orange,
        'icone': Icons.pending_outlined,
        'label': 'Pendente',
      },
      'Pago': {
        'cor': Colors.green,
        'icone': Icons.payments_outlined,
        'label': 'Pago',
      },
      'Reagendar': {
        'cor': Colors.blue,
        'icone': Icons.event_repeat,
        'label': 'Reagendar',
      },
      'Cancelado': {
        'cor': Colors.red,
        'icone': Icons.cancel_outlined,
        'label': 'Cancelado',
      },
    };

    // Mapear status atual para exibição
    String statusAtualExibicao = ag.status;
    if (ag.status == 'Confirmado') {
      statusAtualExibicao = 'Pago';
    } else if (ag.status == 'Concluido') {
      statusAtualExibicao = 'Pago';
    }

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
                      Icons.payments,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Despesa a Pagar',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ag.clienteNome ?? 'Despesa',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ...statusConfig.entries.map((entry) {
                    final statusKey = entry.key;
                    final config = entry.value;
                    final cor = config['cor'] as MaterialColor;
                    final label = config['label'] as String;
                    final isSelected = statusAtualExibicao == statusKey;

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
                      child: ListTile(
                        leading: Icon(
                          config['icone'] as IconData,
                          color: cor,
                          size: 28,
                        ),
                        title: Text(
                          label,
                          style: TextStyle(
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            color:
                                isSelected
                                    ? cor.shade900
                                    : Colors.grey.shade800,
                          ),
                        ),
                        subtitle:
                            statusKey == 'Pago'
                                ? Text(
                                  'Marca como pago e registra despesa',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                )
                                : statusKey == 'Reagendar'
                                ? Text(
                                  'Adia para 24h depois',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                )
                                : null,
                        trailing:
                            isSelected
                                ? Icon(Icons.check_circle, color: cor, size: 24)
                                : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onTap: () => Navigator.pop(context, statusKey),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
    );

    if (novo == null) return;

    if (novo == 'Pago') {
      // Marca como Concluido e salva despesa
      await _marcarDespesaComoPaga(ag);
    } else if (novo == 'Reagendar') {
      // Reagenda para 24h depois
      await _reagendarDespesa(ag);
    } else if (novo == 'Pendente' && ag.status != 'Pendente') {
      await context.read<AgendamentosProvider>().atualizarStatus(
        ag.id,
        'Pendente',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Status alterado para Pendente'),
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
      }
    } else if (novo == 'Cancelado' && ag.status != 'Cancelado') {
      await context.read<AgendamentosProvider>().atualizarStatus(
        ag.id,
        'Cancelado',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Despesa cancelada'),
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
      }
    }
  }

  /// Marca a despesa como paga e salva no controle financeiro como despesa REAL (não futura)
  Future<void> _marcarDespesaComoPaga(Agendamento ag) async {
    // Extrair valor e categoria das observações
    double valor = 0;
    String descricao = ag.clienteNome ?? 'Despesa';
    CategoriaTransacao categoria = CategoriaTransacao.outros;

    final linhas = ag.observacoes.split('\n');
    for (final linha in linhas) {
      if (linha.startsWith('Valor:')) {
        final valorStr = linha.replaceFirst('Valor:', '').trim();
        // Parse do valor no formato R$ X.XXX,XX
        String limpo =
            valorStr.replaceAll('R\$', '').replaceAll(' ', '').trim();
        limpo = limpo.replaceAll('.', '').replaceAll(',', '.');
        valor = double.tryParse(limpo) ?? 0;
      } else if (linha.startsWith('Descrição:')) {
        descricao = linha.replaceFirst('Descrição:', '').trim();
      } else if (linha.startsWith('Categoria:')) {
        final nomeCategoria = linha.replaceFirst('Categoria:', '').trim();
        // Buscar categoria pelo nome
        try {
          categoria = CategoriaTransacao.values.firstWhere(
            (cat) => cat.name.toLowerCase() == nomeCategoria.toLowerCase(),
            orElse: () => CategoriaTransacao.outros,
          );
        } catch (_) {
          categoria = CategoriaTransacao.outros;
        }
      }
    }

    // Se não encontrou descrição nas observações, usa clienteNome
    if (descricao.isEmpty || descricao == 'Despesa') {
      descricao = ag.clienteNome ?? 'Despesa agendada';
    }

    try {
      // Obter userId do UserProvider
      final userProvider = context.read<UserProvider>();
      final userId = userProvider.uid;

      if (userId == null || userId.isEmpty) {
        throw Exception('Usuário não autenticado');
      }

      // Criar transação de DESPESA REAL (isFutura: false) no controle financeiro
      final transacao = Transacao(
        descricao: descricao,
        valor: valor,
        tipo: TipoTransacao.despesa,
        categoria: categoria,
        data: DateTime.now(),
        observacoes: 'Pago via agendamento de despesa',
        userId: userId,
        isFutura: false, // DESPESA REAL, não futura!
      );

      final transacoesProvider = context.read<TransacoesProvider>();
      await transacoesProvider.adicionarTransacao(transacao);

      // Atualizar status do agendamento para Concluido
      await context.read<AgendamentosProvider>().atualizarStatus(
        ag.id,
        'Concluido',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Despesa paga e registrada como despesa real${valor > 0 ? ' (R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')})' : ''}',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Erro ao registrar despesa: $e')),
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
      }
    }
  }

  /// Reagenda a despesa para 24h depois
  Future<void> _reagendarDespesa(Agendamento ag) async {
    try {
      // Nova data = data atual do agendamento + 24h
      final novaDataHora = ag.dataHora.toDate().add(const Duration(hours: 24));

      final agendamentosProvider = context.read<AgendamentosProvider>();

      // Criar novo agendamento com parâmetros nomeados
      await agendamentosProvider.adicionarAgendamento(
        orcamentoId: ag.orcamentoId,
        orcamentoNumero: ag.orcamentoNumero,
        clienteNome: ag.clienteNome,
        dataHora: Timestamp.fromDate(novaDataHora),
        status: 'Pendente',
        observacoes: ag.observacoes,
      );

      // Marcar o agendamento antigo como Concluido (ou pode excluir se preferir)
      await agendamentosProvider.atualizarStatus(ag.id, 'Concluido');

      if (mounted) {
        final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.event_repeat, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Despesa reagendada para ${dateFormat.format(novaDataHora)}',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.blue.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Erro ao reagendar despesa: $e')),
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
      }
    }
  }

  /// Mostra diálogo de mudança de status para receita a receber
  Future<void> _mudarStatusReceitaAReceber(Agendamento ag) async {
    // Status especial para receitas a receber:
    // - Pendente: Aguardando recebimento
    // - Recebido: Marca como recebido e salva no controle financeiro
    // - Reagendar: Adia para 24h depois
    // - Cancelado: Cancela a receita

    final statusConfig = {
      'Pendente': {
        'cor': Colors.orange,
        'icone': Icons.pending_outlined,
        'label': 'Pendente',
      },
      'Recebido': {
        'cor': Colors.green,
        'icone': Icons.payments_outlined,
        'label': 'Recebido',
      },
      'Reagendar': {
        'cor': Colors.blue,
        'icone': Icons.event_repeat,
        'label': 'Reagendar',
      },
      'Cancelado': {
        'cor': Colors.red,
        'icone': Icons.cancel_outlined,
        'label': 'Cancelado',
      },
    };

    // Mapear status atual para exibição
    String statusAtualExibicao;
    if (ag.status == 'Concluido') {
      statusAtualExibicao = 'Recebido';
    } else {
      statusAtualExibicao = ag.status;
    }

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
                  colors: [Colors.green.shade50, Colors.white],
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
                        colors: [Colors.green.shade400, Colors.green.shade600],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Receita a Receber',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ag.clienteNome ?? 'Receita',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ...statusConfig.entries.map((entry) {
                    final statusKey = entry.key;
                    final config = entry.value;
                    final cor = config['cor'] as MaterialColor;
                    final label = config['label'] as String;
                    final isSelected = statusAtualExibicao == statusKey;

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
                      child: ListTile(
                        leading: Icon(
                          config['icone'] as IconData,
                          color: cor,
                          size: 28,
                        ),
                        title: Text(
                          label,
                          style: TextStyle(
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            color:
                                isSelected
                                    ? cor.shade900
                                    : Colors.grey.shade800,
                          ),
                        ),
                        subtitle:
                            statusKey == 'Recebido'
                                ? Text(
                                  'Marca como recebido e registra receita',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                )
                                : statusKey == 'Reagendar'
                                ? Text(
                                  'Adia para 24h depois',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                )
                                : null,
                        trailing:
                            isSelected
                                ? Icon(Icons.check_circle, color: cor, size: 24)
                                : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onTap: () => Navigator.pop(context, statusKey),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
    );

    if (novo == null) return;

    if (novo == 'Recebido') {
      // Marca como Concluido e salva receita
      await _marcarReceitaComoRecebida(ag);
    } else if (novo == 'Reagendar') {
      // Reagenda para 24h depois
      await _reagendarReceita(ag);
    } else if (novo == 'Pendente' && ag.status != 'Pendente') {
      await context.read<AgendamentosProvider>().atualizarStatus(
        ag.id,
        'Pendente',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Status alterado para Pendente'),
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
      }
    } else if (novo == 'Cancelado' && ag.status != 'Cancelado') {
      await context.read<AgendamentosProvider>().atualizarStatus(
        ag.id,
        'Cancelado',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Receita cancelada'),
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
      }
    }
  }

  /// Marca a receita como recebida e salva no controle financeiro como receita REAL (não futura)
  Future<void> _marcarReceitaComoRecebida(Agendamento ag) async {
    // Extrair valor e categoria das observações
    double valor = 0;
    String descricao = ag.clienteNome ?? 'Receita';
    CategoriaTransacao categoria = CategoriaTransacao.outros;

    final linhas = ag.observacoes.split('\n');
    for (final linha in linhas) {
      if (linha.startsWith('Valor:')) {
        final valorStr = linha.replaceFirst('Valor:', '').trim();
        // Parse do valor no formato R$ X.XXX,XX
        String limpo =
            valorStr.replaceAll('R\$', '').replaceAll(' ', '').trim();
        limpo = limpo.replaceAll('.', '').replaceAll(',', '.');
        valor = double.tryParse(limpo) ?? 0;
      } else if (linha.startsWith('Descrição:')) {
        descricao = linha.replaceFirst('Descrição:', '').trim();
      } else if (linha.startsWith('Categoria:')) {
        final nomeCategoria = linha.replaceFirst('Categoria:', '').trim();
        // Buscar categoria pelo nome
        try {
          categoria = CategoriaTransacao.values.firstWhere(
            (cat) => cat.name.toLowerCase() == nomeCategoria.toLowerCase(),
            orElse: () => CategoriaTransacao.outros,
          );
        } catch (_) {
          categoria = CategoriaTransacao.outros;
        }
      }
    }

    // Se não encontrou descrição nas observações, usa clienteNome
    if (descricao.isEmpty || descricao == 'Receita') {
      descricao = ag.clienteNome ?? 'Receita agendada';
    }

    try {
      // Obter userId do UserProvider
      final userProvider = context.read<UserProvider>();
      final userId = userProvider.uid;

      if (userId == null || userId.isEmpty) {
        throw Exception('Usuário não autenticado');
      }

      // Criar transação de RECEITA REAL (isFutura: false) no controle financeiro
      final transacao = Transacao(
        descricao: descricao,
        valor: valor,
        tipo: TipoTransacao.receita,
        categoria: categoria,
        data: DateTime.now(),
        observacoes: 'Recebido via agendamento de receita',
        userId: userId,
        isFutura: false, // RECEITA REAL, não futura!
      );

      final transacoesProvider = context.read<TransacoesProvider>();
      await transacoesProvider.adicionarTransacao(transacao);

      // Atualizar status do agendamento para Concluido
      await context.read<AgendamentosProvider>().atualizarStatus(
        ag.id,
        'Concluido',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Receita recebida e registrada como receita real${valor > 0 ? ' (R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')})' : ''}',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Erro ao registrar receita: $e')),
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
      }
    }
  }

  /// Reagenda a receita para 24h depois
  Future<void> _reagendarReceita(Agendamento ag) async {
    try {
      // Nova data = data atual do agendamento + 24h
      final novaDataHora = ag.dataHora.toDate().add(const Duration(hours: 24));

      final agendamentosProvider = context.read<AgendamentosProvider>();

      // Criar novo agendamento com parâmetros nomeados
      await agendamentosProvider.adicionarAgendamento(
        orcamentoId: ag.orcamentoId,
        orcamentoNumero: ag.orcamentoNumero,
        clienteNome: ag.clienteNome,
        dataHora: Timestamp.fromDate(novaDataHora),
        status: 'Pendente',
        observacoes: ag.observacoes,
      );

      // Marcar o agendamento antigo como Concluido
      await agendamentosProvider.atualizarStatus(ag.id, 'Concluido');

      if (mounted) {
        final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.event_repeat, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Receita reagendada para ${dateFormat.format(novaDataHora)}',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.blue.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Erro ao reagendar receita: $e')),
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
      body: GestureDetector(
        onHorizontalDragEnd: _mudarStatusPorSwipe,
        child: FadeTransition(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildSearchBar(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.calendar_month,
                            color: Colors.teal.shade700,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Seus Agendamentos',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'Organize sua agenda',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
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

                        // Calcular contagem de status
                        final Map<String, int> contagemStatus = {};
                        contagemStatus['Todos'] = provider.agendamentos.length;
                        for (var status in _status) {
                          if (status == 'Todos') continue;
                          contagemStatus[status] =
                              provider.agendamentos
                                  .where(
                                    (ag) =>
                                        ag.status.toLowerCase() ==
                                        status.toLowerCase(),
                                  )
                                  .length;
                        }

                        // Filtrar agendamentos
                        final listaFiltrada =
                            provider.agendamentos.where((ag) {
                              final filtroStatus =
                                  _filtroSelecionado == 'Todos' ||
                                  ag.status.toLowerCase() ==
                                      _filtroSelecionado.toLowerCase();
                              final filtroBusca =
                                  _termoBusca.isEmpty ||
                                  (ag.clienteNome?.toLowerCase().contains(
                                        _termoBusca.toLowerCase(),
                                      ) ??
                                      false) ||
                                  (ag.observacoes.toLowerCase().contains(
                                    _termoBusca.toLowerCase(),
                                  ));
                              return filtroStatus && filtroBusca;
                            }).toList();

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
                                      startingDayOfWeek:
                                          StartingDayOfWeek.monday,
                                      locale: 'pt_BR',
                                      eventLoader:
                                          (day) => _getAgendamentosForDay(
                                            day,
                                            listaFiltrada,
                                          ),
                                      onDaySelected: (selectedDay, focusedDay) {
                                        setState(() {
                                          _selectedDay = selectedDay;
                                          _focusedDay = focusedDay;
                                        });
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
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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

                              // Barra de filtros de status (abaixo do calendário)
                              _buildStatusFilterBar(contagemStatus),

                              // Lista de agendamentos
                              // Se um status específico estiver selecionado, mostra todos desse status
                              // Se "Todos" estiver selecionado, mostra apenas os do dia selecionado
                              if (_filtroSelecionado != 'Todos') ...[
                                // Mostra todos os agendamentos do status selecionado
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getStatusIcon(_filtroSelecionado),
                                        color: _getStatusColor(
                                          _filtroSelecionado,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Agendamentos $_filtroSelecionado${_termoBusca.isNotEmpty ? ' (filtrado)' : ''}',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              _getStatusColor(
                                                _filtroSelecionado,
                                              ).shade100,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          '${listaFiltrada.length}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color:
                                                _getStatusColor(
                                                  _filtroSelecionado,
                                                ).shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Ordenar por data (mais recentes primeiro)
                                ..._buildAgendamentosList(
                                  listaFiltrada..sort(
                                    (a, b) => b.dataHora.compareTo(a.dataHora),
                                  ),
                                  dateFormat,
                                ),
                                const SizedBox(height: 80),
                              ] else if (_selectedDay != null) ...[
                                // Mostra apenas os do dia selecionado
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
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
                                    listaFiltrada,
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
                ],
              ),
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Buscar por cliente ou descrição...',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            prefixIcon: Icon(Icons.search, color: Colors.teal.shade600),
            suffixIcon:
                _termoBusca.isNotEmpty
                    ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey.shade600),
                      onPressed: () {
                        _searchController.clear();
                      },
                      tooltip: 'Limpar busca',
                    )
                    : null,
            filled: false,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusFilterBar(Map<String, int> contagem) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      height: 50,
      child: ListView.builder(
        controller: _statusScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _status.length,
        itemBuilder: (context, index) {
          final status = _status[index];
          final selecionado = _filtroSelecionado == status;

          // Ícones e cores por status
          IconData icone;
          MaterialColor cor;
          switch (status.toLowerCase()) {
            case 'todos':
              icone = Icons.dashboard;
              cor = Colors.purple;
              break;
            case 'pendente':
              icone = Icons.pending_outlined;
              cor = Colors.orange;
              break;
            case 'confirmado':
              icone = Icons.check_circle_outline;
              cor = Colors.blue;
              break;
            case 'concluido':
              icone = Icons.done_all;
              cor = Colors.green;
              break;
            case 'cancelado':
              icone = Icons.cancel_outlined;
              cor = Colors.red;
              break;
            default:
              icone = Icons.info_outline;
              cor = Colors.grey;
          }

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Material(
              elevation: selecionado ? 4 : 0,
              borderRadius: BorderRadius.circular(25),
              child: InkWell(
                borderRadius: BorderRadius.circular(25),
                onTap: () {
                  setState(() {
                    _filtroSelecionado = status;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient:
                        selecionado
                            ? LinearGradient(
                              colors: [cor.shade400, cor.shade600],
                            )
                            : null,
                    color: selecionado ? null : Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: selecionado ? Colors.transparent : cor.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icone,
                        size: 18,
                        color: selecionado ? Colors.white : cor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status,
                        style: TextStyle(
                          color: selecionado ? Colors.white : cor.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              selecionado
                                  ? Colors.white.withOpacity(0.3)
                                  : cor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${contagem[status] ?? 0}',
                          style: TextStyle(
                            color: selecionado ? Colors.white : cor.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildAgendamentosList(
    List<Agendamento> agendamentos,
    DateFormat dateFormat,
  ) {
    final dateFormatFull = DateFormat('dd/MM/yyyy');

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
                  _filtroSelecionado == 'Todos'
                      ? 'Não há agendamentos para este dia'
                      : 'Não há agendamentos com status $_filtroSelecionado',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
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

      // Definir tipo do agendamento
      String tipoAgendamento;
      IconData tipoIcone;
      Color tipoCor;

      if (ag.orcamentoId == 'receita_a_receber') {
        tipoAgendamento = 'Receita';
        tipoIcone = Icons.call_made;
        tipoCor = Colors.teal;
      } else if (ag.orcamentoId == 'despesa_a_pagar') {
        tipoAgendamento = 'Despesa';
        tipoIcone = Icons.call_received;
        tipoCor = Colors.red;
      } else if (ag.orcamentoId.isEmpty || ag.orcamentoId == '') {
        if (ag.observacoes.contains('[DIVERSO]')) {
          tipoAgendamento = 'Diversos';
          tipoIcone = Icons.event_available;
          tipoCor = Colors.purple;
        } else if (ag.observacoes.contains('[VENDA]')) {
          tipoAgendamento = 'Venda';
          tipoIcone = Icons.shopping_cart;
          tipoCor = Colors.orange;
        } else {
          tipoAgendamento = 'Serviço';
          tipoIcone = Icons.build_circle;
          tipoCor = Colors.blue;
        }
      } else {
        tipoAgendamento =
            '#${ag.orcamentoNumero?.toString().padLeft(4, '0') ?? '--'}';
        tipoIcone = Icons.description;
        tipoCor = Colors.blue;
      }

      return Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap:
              () => Navigator.pushNamed(
                context,
                AppRoutes.detalhesAgendamento,
                arguments: ag.id,
              ),
          onLongPress: () => _abrirFormulario(agendamento: ag),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Colors.grey.shade50],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Linha superior: Badge tipo + Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Badge com tipo do agendamento
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              tipoCor is MaterialColor
                                  ? tipoCor.shade400
                                  : tipoCor.withOpacity(0.8),
                              tipoCor is MaterialColor
                                  ? tipoCor.shade600
                                  : tipoCor,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: tipoCor.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(tipoIcone, size: 16, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              tipoAgendamento,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status chip clicável
                      InkWell(
                        onTap: () => _mudarStatus(ag),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: statusColor, width: 1.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 16, color: statusColor),
                              const SizedBox(width: 4),
                              Text(
                                ag.status,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Informações do cliente
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.teal.shade100, Colors.teal.shade50],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.person,
                          color: Colors.teal.shade700,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ag.clienteNome ?? 'Cliente não informado',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  dateFormatFull.format(ag.dataHora.toDate()),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  dateFormat.format(ag.dataHora.toDate()),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  // Valor (para despesas/receitas) ou Observações
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            // Verificar se é despesa ou receita para extrair valor
                            if (ag.orcamentoId == 'despesa_a_pagar' ||
                                ag.orcamentoId == 'receita_a_receber') {
                              // Extrair valor das observações
                              String valorExibir = '';
                              String descricaoExibir = '';
                              final linhas = ag.observacoes.split('\n');
                              for (final linha in linhas) {
                                if (linha.startsWith('Valor:')) {
                                  valorExibir =
                                      linha.replaceFirst('Valor:', '').trim();
                                } else if (linha.startsWith('Descrição:')) {
                                  descricaoExibir =
                                      linha
                                          .replaceFirst('Descrição:', '')
                                          .trim();
                                }
                              }

                              final isReceita =
                                  ag.orcamentoId == 'receita_a_receber';
                              final corValor =
                                  isReceita ? Colors.green : Colors.red;
                              final iconeValor =
                                  isReceita
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isReceita
                                        ? 'Valor a Receber'
                                        : 'Valor a Pagar',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: corValor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          iconeValor,
                                          color: corValor,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        valorExibir.isNotEmpty
                                            ? valorExibir
                                            : 'Valor não informado',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: corValor,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (descricaoExibir.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      descricaoExibir,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              );
                            }

                            // Para outros tipos, mostrar observações normais
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Observações',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  ag.observacoes.isNotEmpty
                                      ? ag.observacoes
                                              .replaceAll('[DIVERSO]', '')
                                              .replaceAll('[VENDA]', '')
                                              .trim()
                                              .isEmpty
                                          ? 'Sem observações'
                                          : ag.observacoes
                                              .replaceAll('[DIVERSO]', '')
                                              .replaceAll('[VENDA]', '')
                                              .trim()
                                      : 'Sem observações',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade800,
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'Opções',
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.more_vert,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        onSelected: (value) {
                          if (value == 'visualizar') {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.detalhesAgendamento,
                              arguments: ag.id,
                            );
                          } else if (value == 'editar') {
                            _abrirFormulario(agendamento: ag);
                          } else if (value == 'status') {
                            _mudarStatus(ag);
                          } else if (value == 'excluir') {
                            _confirmarExclusao(ag);
                          }
                        },
                        itemBuilder:
                            (BuildContext context) => <PopupMenuEntry<String>>[
                              PopupMenuItem<String>(
                                value: 'visualizar',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.visibility_outlined,
                                      color: Colors.blue.shade600,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text('Visualizar'),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'editar',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.edit_outlined,
                                      color: Colors.orange.shade600,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text('Editar'),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
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
                              const PopupMenuDivider(),
                              PopupMenuItem<String>(
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
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}
