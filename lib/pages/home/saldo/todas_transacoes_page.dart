import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/receita.dart';
import '../../../providers/transacoes_provider.dart';
import '../../../providers/user_provider.dart';
import '../receitas/visualizar_receita_page.dart';
import '../despesas/visualizar_despesa_page.dart';
import '../receitas/detalhes_receita_a_receber_page.dart';
import '../despesas/detalhes_despesa_a_pagar_page.dart';

class TodasTransacoesPage extends StatefulWidget {
  const TodasTransacoesPage({super.key});

  @override
  State<TodasTransacoesPage> createState() => _TodasTransacoesPageState();
}

class _TodasTransacoesPageState extends State<TodasTransacoesPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _filtroScrollController = ScrollController();
  String _filtroSelecionado = 'Todas';
  String _termoBusca = '';

  final List<String> _filtros = [
    'Todas',
    'Receitas',
    'Despesas',
    'A Receber',
    'A Pagar',
  ];

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
    const double larguraChip = 100.0;
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
    if (transacao.isFutura) {
      // Transação futura - abre página de detalhes
      if (transacao.tipo == TipoTransacao.receita) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetalhesReceitaAReceberPage(transacao: transacao),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetalhesDespesaAPagarPage(transacao: transacao),
          ),
        );
      }
    } else {
      // Transação realizada - abre página de visualização
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
  }

  // Calcula totais
  Map<String, double> _calcularTotais(TransacoesProvider provider) {
    double totalReceitas = 0;
    double totalDespesas = 0;
    double totalAReceber = 0;
    double totalAPagar = 0;

    for (var t in provider.transacoes) {
      if (t.isFutura) {
        if (t.tipo == TipoTransacao.receita) {
          totalAReceber += t.valor;
        } else {
          totalAPagar += t.valor;
        }
      } else {
        if (t.tipo == TipoTransacao.receita) {
          totalReceitas += t.valor;
        } else {
          totalDespesas += t.valor;
        }
      }
    }

    return {
      'receitas': totalReceitas,
      'despesas': totalDespesas,
      'aReceber': totalAReceber,
      'aPagar': totalAPagar,
      'saldo': totalReceitas - totalDespesas,
      'saldoFuturo': totalAReceber - totalAPagar,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Todas Transações',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade700, Colors.indigo.shade500],
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
              colors: [Colors.indigo.shade50, Colors.white, Colors.white],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card de Resumo
              _buildResumoCard(),
              const SizedBox(height: 8),
              _buildSearchBar(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.list_alt,
                        color: Colors.indigo.shade700,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Todas Transações',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Histórico completo de movimentações',
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
                  final transacoes = provider.transacoes;
                  final Map<String, int> contagemFiltro = {};
                  contagemFiltro['Todas'] = transacoes.length;
                  contagemFiltro['Receitas'] =
                      transacoes
                          .where(
                            (t) =>
                                t.tipo == TipoTransacao.receita && !t.isFutura,
                          )
                          .length;
                  contagemFiltro['Despesas'] =
                      transacoes
                          .where(
                            (t) =>
                                t.tipo == TipoTransacao.despesa && !t.isFutura,
                          )
                          .length;
                  contagemFiltro['A Receber'] =
                      transacoes
                          .where(
                            (t) =>
                                t.tipo == TipoTransacao.receita && t.isFutura,
                          )
                          .length;
                  contagemFiltro['A Pagar'] =
                      transacoes
                          .where(
                            (t) =>
                                t.tipo == TipoTransacao.despesa && t.isFutura,
                          )
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

                    // Filtrar transações
                    var listaFiltrada = provider.transacoes.toList();

                    // Aplicar filtro de tipo
                    switch (_filtroSelecionado) {
                      case 'Receitas':
                        listaFiltrada =
                            listaFiltrada
                                .where(
                                  (t) =>
                                      t.tipo == TipoTransacao.receita &&
                                      !t.isFutura,
                                )
                                .toList();
                        break;
                      case 'Despesas':
                        listaFiltrada =
                            listaFiltrada
                                .where(
                                  (t) =>
                                      t.tipo == TipoTransacao.despesa &&
                                      !t.isFutura,
                                )
                                .toList();
                        break;
                      case 'A Receber':
                        listaFiltrada =
                            listaFiltrada
                                .where(
                                  (t) =>
                                      t.tipo == TipoTransacao.receita &&
                                      t.isFutura,
                                )
                                .toList();
                        break;
                      case 'A Pagar':
                        listaFiltrada =
                            listaFiltrada
                                .where(
                                  (t) =>
                                      t.tipo == TipoTransacao.despesa &&
                                      t.isFutura,
                                )
                                .toList();
                        break;
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
                                      color: Colors.indigo.shade100,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 14,
                                          color: Colors.indigo.shade700,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _formatarDataLabel(data),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.indigo.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${transacoesDoDia.length} ${transacoesDoDia.length == 1 ? 'transação' : 'transações'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Lista de transações do dia
                            ...transacoesDoDia.map(
                              (t) => _buildTransacaoItem(t),
                            ),
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
    );
  }

  String _formatarDataLabel(String dataStr) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final data = dateFormat.parse(dataStr);
    final hoje = DateTime.now();
    final ontem = hoje.subtract(const Duration(days: 1));
    final amanha = hoje.add(const Duration(days: 1));

    if (data.year == hoje.year &&
        data.month == hoje.month &&
        data.day == hoje.day) {
      return 'Hoje';
    } else if (data.year == ontem.year &&
        data.month == ontem.month &&
        data.day == ontem.day) {
      return 'Ontem';
    } else if (data.year == amanha.year &&
        data.month == amanha.month &&
        data.day == amanha.day) {
      return 'Amanhã';
    } else {
      return DateFormat('dd MMM yyyy', 'pt_BR').format(data);
    }
  }

  Widget _buildResumoCard() {
    return Consumer<TransacoesProvider>(
      builder: (context, provider, child) {
        final currencyFormat = NumberFormat.currency(
          locale: 'pt_BR',
          symbol: 'R\$',
        );

        final totais = _calcularTotais(provider);

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.indigo.shade700, Colors.indigo.shade500],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.indigo.shade300.withOpacity(0.5),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Total de transações
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
                currencyFormat.format(totais['saldo']!),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 20),
              // Linha divisória
              Container(height: 1, color: Colors.white.withOpacity(0.2)),
              const SizedBox(height: 16),
              // Resumo detalhado
              Row(
                children: [
                  Expanded(
                    child: _buildResumoMini(
                      icone: Icons.arrow_upward,
                      label: 'Receitas',
                      valor: currencyFormat.format(totais['receitas']!),
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
                      label: 'Despesas',
                      valor: currencyFormat.format(totais['despesas']!),
                      cor: Colors.red.shade300,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: Colors.white.withOpacity(0.2)),
              const SizedBox(height: 12),
              // Futuras
              Row(
                children: [
                  Expanded(
                    child: _buildResumoMini(
                      icone: Icons.call_received,
                      label: 'A Receber',
                      valor: currencyFormat.format(totais['aReceber']!),
                      cor: Colors.green.shade200,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  Expanded(
                    child: _buildResumoMini(
                      icone: Icons.call_made,
                      label: 'A Pagar',
                      valor: currencyFormat.format(totais['aPagar']!),
                      cor: Colors.orange.shade300,
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
              child: Icon(icone, color: cor, size: 14),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
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
            case 'A Receber':
              chipColor = Colors.teal;
              break;
            case 'A Pagar':
              chipColor = Colors.orange;
              break;
            default:
              chipColor = Colors.indigo;
          }

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(filtro),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? Colors.white.withOpacity(0.3)
                              : chipColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 11,
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
                fontSize: 13,
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

  Widget _buildTransacaoItem(Transacao transacao) {
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    final isReceita = transacao.tipo == TipoTransacao.receita;
    final isFutura = transacao.isFutura;

    Color corTipo;
    IconData icone;
    String tipoLabel;

    if (isFutura) {
      if (isReceita) {
        corTipo = Colors.teal;
        icone = Icons.call_received;
        tipoLabel = 'A Receber';
      } else {
        corTipo = Colors.orange;
        icone = Icons.call_made;
        tipoLabel = 'A Pagar';
      }
    } else {
      if (isReceita) {
        corTipo = Colors.green;
        icone = Icons.arrow_upward;
        tipoLabel = 'Receita';
      } else {
        corTipo = Colors.red;
        icone = Icons.arrow_downward;
        tipoLabel = 'Despesa';
      }
    }

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
              // Descrição e tipo
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
                            tipoLabel,
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
                isFutura
                    ? currencyFormat.format(transacao.valor)
                    : '$sinal ${currencyFormat.format(transacao.valor)}',
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
