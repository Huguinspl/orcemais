import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/receita.dart';
import '../../../providers/transacoes_provider.dart';
import '../../../providers/user_provider.dart';
import '../receitas/visualizar_receita_page.dart';
import '../despesas/visualizar_despesa_page.dart';
import 'visualizar_extrato_page.dart';

class ExtratoPage extends StatefulWidget {
  const ExtratoPage({super.key});

  @override
  State<ExtratoPage> createState() => _ExtratoPageState();
}

class _ExtratoPageState extends State<ExtratoPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _filtroScrollController = ScrollController();
  String _filtroSelecionado = 'Todas';
  String _termoBusca = '';

  final List<String> _filtros = ['Todas', 'Receitas', 'Despesas'];

  // Método para alternar filtro via swipe
  void _mudarFiltroPorSwipe(DragEndDetails details) {
    final velocidade = details.primaryVelocity ?? 0;
    final indexAtual = _filtros.indexOf(_filtroSelecionado);

    if (velocidade < -300) {
      // Swipe para esquerda -> próximo filtro
      if (indexAtual < _filtros.length - 1) {
        final novoIndex = indexAtual + 1;
        setState(() {
          _filtroSelecionado = _filtros[novoIndex];
        });
        _rolarParaFiltro(novoIndex);
      }
    } else if (velocidade > 300) {
      // Swipe para direita -> filtro anterior
      if (indexAtual > 0) {
        final novoIndex = indexAtual - 1;
        setState(() {
          _filtroSelecionado = _filtros[novoIndex];
        });
        _rolarParaFiltro(novoIndex);
      }
    }
  }

  // Método para rolar a barra de filtros
  void _rolarParaFiltro(int index) {
    const double larguraChip = 120.0;
    final double posicaoAlvo = index * larguraChip;

    _filtroScrollController.animateTo(
      posicaoAlvo,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final userId = context.read<UserProvider>().uid;
      if (userId != null) {
        Provider.of<TransacoesProvider>(
          context,
          listen: false,
        ).carregarTransacoes(userId);
      }
    });

    _searchController.addListener(() {
      setState(() {
        _termoBusca = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _filtroScrollController.dispose();
    super.dispose();
  }

  void _visualizarTransacao(Transacao transacao) {
    if (transacao.tipo == TipoTransacao.receita) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VisualizarReceitaPage(receita: transacao),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VisualizarDespesaPage(despesa: transacao),
        ),
      );
    }
  }

  // Calcula o saldo atual (receitas - despesas) para transações não futuras
  double _calcularSaldo(TransacoesProvider provider) {
    final transacoesReais =
        provider.transacoes.where((t) => !t.isFutura).toList();
    double totalReceitas = 0;
    double totalDespesas = 0;

    for (var t in transacoesReais) {
      if (t.tipo == TipoTransacao.receita) {
        totalReceitas += t.valor;
      } else {
        totalDespesas += t.valor;
      }
    }

    return totalReceitas - totalDespesas;
  }

  // Calcula o total de receitas
  double _calcularTotalReceitas(TransacoesProvider provider) {
    return provider.transacoes
        .where((t) => t.tipo == TipoTransacao.receita && !t.isFutura)
        .fold(0.0, (sum, t) => sum + t.valor);
  }

  // Calcula o total de despesas
  double _calcularTotalDespesas(TransacoesProvider provider) {
    return provider.transacoes
        .where((t) => t.tipo == TipoTransacao.despesa && !t.isFutura)
        .fold(0.0, (sum, t) => sum + t.valor);
  }

  // Abre modal para selecionar período e baixar extrato
  Future<void> _abrirSelecionarPeriodo() async {
    DateTime dataInicio = DateTime.now().subtract(const Duration(days: 30));
    DateTime dataFim = DateTime.now();

    final resultado = await showModalBottomSheet<Map<String, DateTime>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            final dateFormat = DateFormat('dd/MM/yyyy');
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Título
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.download_outlined,
                          color: Colors.blue.shade700,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Baixar Extrato',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          Text(
                            'Selecione o período desejado',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Data Início
                  InkWell(
                    onTap: () async {
                      final data = await showDatePicker(
                        context: context,
                        initialDate: dataInicio,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        locale: const Locale('pt', 'BR'),
                      );
                      if (data != null) {
                        setStateModal(() => dataInicio = data);
                      }
                    },
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
                            color: Colors.blue.shade600,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Data Início',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  dateFormat.format(dataInicio),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Data Fim
                  InkWell(
                    onTap: () async {
                      final data = await showDatePicker(
                        context: context,
                        initialDate: dataFim,
                        firstDate: dataInicio,
                        lastDate: DateTime.now(),
                        locale: const Locale('pt', 'BR'),
                      );
                      if (data != null) {
                        setStateModal(() => dataFim = data);
                      }
                    },
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
                            color: Colors.blue.shade600,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Data Fim',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  dateFormat.format(dataFim),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Atalhos de período
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildAtalho('Últimos 7 dias', () {
                          setStateModal(() {
                            dataFim = DateTime.now();
                            dataInicio = dataFim.subtract(
                              const Duration(days: 7),
                            );
                          });
                        }),
                        _buildAtalho('Últimos 15 dias', () {
                          setStateModal(() {
                            dataFim = DateTime.now();
                            dataInicio = dataFim.subtract(
                              const Duration(days: 15),
                            );
                          });
                        }),
                        _buildAtalho('Últimos 30 dias', () {
                          setStateModal(() {
                            dataFim = DateTime.now();
                            dataInicio = dataFim.subtract(
                              const Duration(days: 30),
                            );
                          });
                        }),
                        _buildAtalho('Este mês', () {
                          setStateModal(() {
                            final agora = DateTime.now();
                            dataInicio = DateTime(agora.year, agora.month, 1);
                            dataFim = agora;
                          });
                        }),
                        _buildAtalho('Mês passado', () {
                          setStateModal(() {
                            final agora = DateTime.now();
                            dataInicio = DateTime(
                              agora.year,
                              agora.month - 1,
                              1,
                            );
                            dataFim = DateTime(agora.year, agora.month, 0);
                          });
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Botão Gerar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context, {
                          'inicio': dataInicio,
                          'fim': dataFim,
                        });
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Gerar Extrato'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );

    if (resultado != null) {
      _gerarExtratoPeriodo(resultado['inicio']!, resultado['fim']!);
    }
  }

  Widget _buildAtalho(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label),
        onPressed: onTap,
        backgroundColor: Colors.blue.shade50,
        labelStyle: TextStyle(color: Colors.blue.shade700, fontSize: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.blue.shade200),
        ),
      ),
    );
  }

  void _gerarExtratoPeriodo(DateTime dataInicio, DateTime dataFim) {
    final provider = context.read<TransacoesProvider>();

    // Filtrar transações do período
    final transacoesPeriodo =
        provider.transacoes.where((t) {
          if (t.isFutura) return false;
          return t.data.isAfter(dataInicio.subtract(const Duration(days: 1))) &&
              t.data.isBefore(dataFim.add(const Duration(days: 1)));
        }).toList();

    // Calcular saldo inicial (antes do período)
    double saldoInicial = 0;
    for (var t in provider.transacoes) {
      if (t.isFutura) continue;
      if (t.data.isBefore(dataInicio)) {
        if (t.tipo == TipoTransacao.receita) {
          saldoInicial += t.valor;
        } else {
          saldoInicial -= t.valor;
        }
      }
    }

    // Calcular totais do período
    double totalReceitas = 0;
    double totalDespesas = 0;
    for (var t in transacoesPeriodo) {
      if (t.tipo == TipoTransacao.receita) {
        totalReceitas += t.valor;
      } else {
        totalDespesas += t.valor;
      }
    }

    final saldoFinal = saldoInicial + totalReceitas - totalDespesas;

    // Navegar para página de visualização
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => VisualizarExtratoPage(
              transacoes: transacoesPeriodo,
              dataInicio: dataInicio,
              dataFim: dataFim,
              saldoInicial: saldoInicial,
              saldoFinal: saldoFinal,
              totalReceitas: totalReceitas,
              totalDespesas: totalDespesas,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Extrato',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.blue.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: GestureDetector(
        onHorizontalDragEnd: _mudarFiltroPorSwipe,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue.shade50, Colors.white, Colors.white],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card de Saldo
              _buildSaldoCard(),
              const SizedBox(height: 8),
              _buildSearchBar(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.receipt_long,
                        color: Colors.blue.shade700,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Extrato',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Histórico de movimentações',
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
              Consumer<TransacoesProvider>(
                builder: (context, provider, child) {
                  final transacoesReais =
                      provider.transacoes.where((t) => !t.isFutura).toList();
                  final Map<String, int> contagemFiltro = {};
                  contagemFiltro['Todas'] = transacoesReais.length;
                  contagemFiltro['Receitas'] =
                      transacoesReais
                          .where((t) => t.tipo == TipoTransacao.receita)
                          .length;
                  contagemFiltro['Despesas'] =
                      transacoesReais
                          .where((t) => t.tipo == TipoTransacao.despesa)
                          .length;
                  return _buildFiltroBar(contagemFiltro);
                },
              ),
              Expanded(
                child: Consumer<TransacoesProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Filtrar transações reais (não futuras)
                    var listaFiltrada =
                        provider.transacoes.where((t) => !t.isFutura).toList();

                    // Aplicar filtro de tipo
                    if (_filtroSelecionado == 'Receitas') {
                      listaFiltrada =
                          listaFiltrada
                              .where((t) => t.tipo == TipoTransacao.receita)
                              .toList();
                    } else if (_filtroSelecionado == 'Despesas') {
                      listaFiltrada =
                          listaFiltrada
                              .where((t) => t.tipo == TipoTransacao.despesa)
                              .toList();
                    }

                    // Aplicar filtro de busca
                    if (_termoBusca.isNotEmpty) {
                      listaFiltrada =
                          listaFiltrada
                              .where(
                                (t) => t.descricao.toLowerCase().contains(
                                  _termoBusca.toLowerCase(),
                                ),
                              )
                              .toList();
                    }

                    // Ordenar por data (mais recente primeiro)
                    listaFiltrada.sort((a, b) => b.data.compareTo(a.data));

                    if (listaFiltrada.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.receipt_long_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Nenhuma transação encontrada',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tente ajustar os filtros',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Agrupar por data
                    final transacoesPorData = <String, List<Transacao>>{};
                    final dateFormat = DateFormat('dd/MM/yyyy');

                    for (var t in listaFiltrada) {
                      final dataStr = dateFormat.format(t.data);
                      if (!transacoesPorData.containsKey(dataStr)) {
                        transacoesPorData[dataStr] = [];
                      }
                      transacoesPorData[dataStr]!.add(t);
                    }

                    final datasOrdenadas = transacoesPorData.keys.toList();

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
                      itemCount: datasOrdenadas.length,
                      itemBuilder: (context, index) {
                        final data = datasOrdenadas[index];
                        final transacoesDoDia = transacoesPorData[data]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Cabeçalho da data
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 14,
                                          color: Colors.blue.shade700,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _formatarDataLabel(data),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${transacoesDoDia.length} ${transacoesDoDia.length == 1 ? 'movimentação' : 'movimentações'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Lista de transações do dia
                            ...transacoesDoDia.map((t) => _buildExtratoItem(t)),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirSelecionarPeriodo,
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.download),
        label: const Text(
          'Baixar Extrato',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  String _formatarDataLabel(String dataStr) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final data = dateFormat.parse(dataStr);
    final hoje = DateTime.now();
    final ontem = hoje.subtract(const Duration(days: 1));

    if (data.year == hoje.year &&
        data.month == hoje.month &&
        data.day == hoje.day) {
      return 'Hoje';
    } else if (data.year == ontem.year &&
        data.month == ontem.month &&
        data.day == ontem.day) {
      return 'Ontem';
    } else {
      return DateFormat('dd MMM yyyy', 'pt_BR').format(data);
    }
  }

  Widget _buildSaldoCard() {
    return Consumer<TransacoesProvider>(
      builder: (context, provider, child) {
        final currencyFormat = NumberFormat.currency(
          locale: 'pt_BR',
          symbol: 'R\$',
        );

        final saldo = _calcularSaldo(provider);
        final totalReceitas = _calcularTotalReceitas(provider);
        final totalDespesas = _calcularTotalDespesas(provider);

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade700, Colors.blue.shade500],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade300.withOpacity(0.5),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Saldo principal
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white.withOpacity(0.9),
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Saldo Atual',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                currencyFormat.format(saldo),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 20),
              // Linha divisória
              Container(height: 1, color: Colors.white.withOpacity(0.2)),
              const SizedBox(height: 16),
              // Resumo de entradas e saídas
              Row(
                children: [
                  Expanded(
                    child: _buildResumoMini(
                      icone: Icons.arrow_upward,
                      label: 'Entradas',
                      valor: currencyFormat.format(totalReceitas),
                      cor: Colors.green.shade300,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  Expanded(
                    child: _buildResumoMini(
                      icone: Icons.arrow_downward,
                      label: 'Saídas',
                      valor: currencyFormat.format(totalDespesas),
                      cor: Colors.red.shade300,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResumoMini({
    required IconData icone,
    required String label,
    required String valor,
    required Color cor,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: cor.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(icone, color: cor, size: 16),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          valor,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Buscar transação...',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
            suffixIcon:
                _termoBusca.isNotEmpty
                    ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey.shade400),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                    : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFiltroBar(Map<String, int> contagem) {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 12),
      child: ListView.builder(
        controller: _filtroScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filtros.length,
        itemBuilder: (context, index) {
          final filtro = _filtros[index];
          final isSelected = filtro == _filtroSelecionado;
          final count = contagem[filtro] ?? 0;

          Color chipColor;
          switch (filtro) {
            case 'Receitas':
              chipColor = Colors.green;
              break;
            case 'Despesas':
              chipColor = Colors.red;
              break;
            default:
              chipColor = Colors.blue;
          }

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(filtro),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? Colors.white.withOpacity(0.3)
                              : chipColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : chipColor,
                      ),
                    ),
                  ),
                ],
              ),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: Colors.grey.shade100,
              selectedColor: chipColor,
              checkmarkColor: Colors.white,
              showCheckmark: false,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
                side: BorderSide(
                  color: isSelected ? chipColor : Colors.grey.shade300,
                ),
              ),
              onSelected: (selected) {
                setState(() {
                  _filtroSelecionado = filtro;
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildExtratoItem(Transacao transacao) {
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    final isReceita = transacao.tipo == TipoTransacao.receita;
    final corTipo = isReceita ? Colors.green : Colors.red;
    final icone = isReceita ? Icons.arrow_upward : Icons.arrow_downward;
    final sinal = isReceita ? '+' : '-';

    // Ícone da categoria
    IconData categoriaIcon;
    switch (transacao.categoria) {
      case CategoriaTransacao.vendas:
        categoriaIcon = Icons.shopping_cart_outlined;
        break;
      case CategoriaTransacao.servicos:
        categoriaIcon = Icons.build_outlined;
        break;
      case CategoriaTransacao.investimentos:
        categoriaIcon = Icons.trending_up;
        break;
      case CategoriaTransacao.fornecedores:
        categoriaIcon = Icons.local_shipping_outlined;
        break;
      case CategoriaTransacao.salarios:
        categoriaIcon = Icons.people_outlined;
        break;
      case CategoriaTransacao.aluguel:
        categoriaIcon = Icons.home_outlined;
        break;
      case CategoriaTransacao.marketing:
        categoriaIcon = Icons.campaign_outlined;
        break;
      case CategoriaTransacao.equipamentos:
        categoriaIcon = Icons.computer_outlined;
        break;
      case CategoriaTransacao.impostos:
        categoriaIcon = Icons.receipt_outlined;
        break;
      case CategoriaTransacao.utilities:
        categoriaIcon = Icons.bolt_outlined;
        break;
      case CategoriaTransacao.manutencao:
        categoriaIcon = Icons.handyman_outlined;
        break;
      default:
        categoriaIcon = Icons.category_outlined;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _visualizarTransacao(transacao),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Ícone com indicador de tipo
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: corTipo.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(categoriaIcon, color: corTipo, size: 24),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: corTipo,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(icone, color: Colors.white, size: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              // Descrição e categoria
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transacao.descricao,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: corTipo.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            transacao.categoria.nome,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: corTipo,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('HH:mm').format(transacao.data),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Valor
              Text(
                '$sinal ${currencyFormat.format(transacao.valor)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: corTipo,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
