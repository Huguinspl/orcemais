import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/transacoes_provider.dart';
import '../providers/user_provider.dart';
import '../models/receita.dart';

/// Página de Controle Financeiro com gráficos e análises
class ControleFinanceiroPage extends StatefulWidget {
  const ControleFinanceiroPage({super.key});

  @override
  State<ControleFinanceiroPage> createState() => _ControleFinanceiroPageState();
}

class _ControleFinanceiroPageState extends State<ControleFinanceiroPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
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

    // Carregar transações
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = context.read<UserProvider>();
      final userId = userProvider.uid;
      if (userId.isNotEmpty) {
        context.read<TransacoesProvider>().carregarTransacoes(userId);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            slivers: [
              // App Bar com gradiente
              _buildAppBar(),

              // Conteúdo principal
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Cards de resumo
                    _buildResumoCards(),
                    const SizedBox(height: 24),

                    // Gráfico de Pizza
                    _buildGraficoPizza(),
                    const SizedBox(height: 24),

                    // Gráfico de Barras
                    _buildGraficoBarras(),
                    const SizedBox(height: 24),

                    // Lista de transações recentes
                    _buildTransacoesRecentes(),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Controle Financeiro',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.red.shade600, Colors.red.shade400],
            ),
          ),
          child: Center(
            child: Icon(
              Icons.account_balance_wallet,
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResumoCards() {
    return Consumer<TransacoesProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final formatMoeda = NumberFormat.currency(
          locale: 'pt_BR',
          symbol: 'R\$',
        );

        return Row(
          children: [
            Expanded(
              child: _buildResumoCard(
                titulo: 'Receitas',
                valor: formatMoeda.format(provider.totalReceitas),
                icone: Icons.trending_up,
                cor: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildResumoCard(
                titulo: 'Despesas',
                valor: formatMoeda.format(provider.totalDespesas),
                icone: Icons.trending_down,
                cor: Colors.red.shade600,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildResumoCard(
                titulo: 'Saldo',
                valor: formatMoeda.format(provider.saldo),
                icone: Icons.account_balance,
                cor: Colors.blue,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResumoCard({
    required String titulo,
    required String valor,
    required IconData icone,
    required Color cor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: cor, size: 28),
          const SizedBox(height: 8),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              valor,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: cor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraficoPizza() {
    return Consumer<TransacoesProvider>(
      builder: (context, provider, _) {
        if (provider.transacoes.isEmpty) {
          return _buildEmptyCard('Sem dados para exibir gráfico');
        }

        final despesasPorCategoria = provider.despesasPorCategoria();
        if (despesasPorCategoria.isEmpty) {
          return _buildEmptyCard('Nenhuma despesa cadastrada');
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.pie_chart, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  const Text(
                    'Despesas por Categoria',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: _buildPieChartSections(despesasPorCategoria),
                    sectionsSpace: 2,
                    centerSpaceRadius: 50,
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildLegenda(despesasPorCategoria),
            ],
          ),
        );
      },
    );
  }

  List<PieChartSectionData> _buildPieChartSections(
    Map<CategoriaTransacao, double> dados,
  ) {
    final cores = [
      Colors.red.shade400,
      Colors.orange.shade400,
      Colors.amber.shade400,
      Colors.red.shade300,
      Colors.blue.shade400,
      Colors.purple.shade400,
      Colors.pink.shade400,
      Colors.red.shade500,
    ];

    final total = dados.values.fold(0.0, (sum, valor) => sum + valor);
    int index = 0;

    return dados.entries.map((entry) {
      final percentual = (entry.value / total * 100);
      final cor = cores[index % cores.length];
      index++;

      return PieChartSectionData(
        value: entry.value,
        title: '${percentual.toStringAsFixed(0)}%',
        color: cor,
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegenda(Map<CategoriaTransacao, double> dados) {
    final cores = [
      Colors.red.shade400,
      Colors.orange.shade400,
      Colors.amber.shade400,
      Colors.red.shade300,
      Colors.blue.shade400,
      Colors.purple.shade400,
      Colors.pink.shade400,
      Colors.red.shade500,
    ];

    int index = 0;
    final formatMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children:
          dados.entries.map((entry) {
            final cor = cores[index % cores.length];
            index++;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                Text(
                  '${entry.key.nome}: ${formatMoeda.format(entry.value)}',
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            );
          }).toList(),
    );
  }

  Widget _buildGraficoBarras() {
    return Consumer<TransacoesProvider>(
      builder: (context, provider, _) {
        if (provider.transacoes.isEmpty) {
          return _buildEmptyCard('Sem dados para exibir gráfico');
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.bar_chart, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  const Text(
                    'Receitas x Despesas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _calcularMaxY(provider),
                    barGroups: _buildBarGroups(provider),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              'R\$${(value / 1000).toStringAsFixed(0)}k',
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) return const Text('Receitas');
                            if (value == 1) return const Text('Despesas');
                            return const Text('');
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 1000,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  double _calcularMaxY(TransacoesProvider provider) {
    final maxValor =
        provider.totalReceitas > provider.totalDespesas
            ? provider.totalReceitas
            : provider.totalDespesas;
    return maxValor * 1.2; // 20% a mais para margem
  }

  List<BarChartGroupData> _buildBarGroups(TransacoesProvider provider) {
    return [
      BarChartGroupData(
        x: 0,
        barRods: [
          BarChartRodData(
            toY: provider.totalReceitas,
            color: Colors.green,
            width: 40,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ],
      ),
      BarChartGroupData(
        x: 1,
        barRods: [
          BarChartRodData(
            toY: provider.totalDespesas,
            color: Colors.red.shade600,
            width: 40,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildTransacoesRecentes() {
    return Consumer<TransacoesProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.transacoes.isEmpty) {
          return _buildEmptyCard('Nenhuma transação cadastrada');
        }

        final transacoesRecentes = provider.transacoes.take(10).toList();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.history, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  const Text(
                    'Transações Recentes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...transacoesRecentes.map(_buildTransacaoItem),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransacaoItem(Transacao transacao) {
    final formatMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final formatData = DateFormat('dd/MM/yyyy');

    final isReceita = transacao.tipo == TipoTransacao.receita;
    final cor = isReceita ? Colors.green : Colors.red;
    final icone = isReceita ? Icons.add : Icons.remove;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icone, color: cor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transacao.descricao,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${transacao.categoria.nome} • ${formatData.format(transacao.data)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Text(
            formatMoeda.format(transacao.valor),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String mensagem) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              mensagem,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () => _mostrarDialogNovaTransacao(),
      backgroundColor: Colors.red.shade600,
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text(
        'Nova Transação',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _mostrarDialogNovaTransacao() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _NovaTransacaoSheet(),
    );
  }
}

/// Bottom sheet para adicionar nova transação
class _NovaTransacaoSheet extends StatefulWidget {
  const _NovaTransacaoSheet();

  @override
  State<_NovaTransacaoSheet> createState() => _NovaTransacaoSheetState();
}

class _NovaTransacaoSheetState extends State<_NovaTransacaoSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  final _observacoesController = TextEditingController();

  TipoTransacao _tipo = TipoTransacao.receita;
  CategoriaTransacao? _categoria;
  DateTime _data = DateTime.now();
  bool _salvando = false;

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.red.shade50, Colors.white],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red.shade600, Colors.red.shade400],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Nova Transação',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Tipo de transação
              SegmentedButton<TipoTransacao>(
                segments: const [
                  ButtonSegment(
                    value: TipoTransacao.receita,
                    label: Text('Receita'),
                    icon: Icon(Icons.trending_up),
                  ),
                  ButtonSegment(
                    value: TipoTransacao.despesa,
                    label: Text('Despesa'),
                    icon: Icon(Icons.trending_down),
                  ),
                ],
                selected: {_tipo},
                onSelectionChanged: (Set<TipoTransacao> newSelection) {
                  setState(() {
                    _tipo = newSelection.first;
                    _categoria = null; // Reset categoria ao mudar tipo
                  });
                },
              ),
              const SizedBox(height: 16),

              // Descrição
              TextFormField(
                controller: _descricaoController,
                decoration: InputDecoration(
                  labelText: 'Descrição',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                decoration: InputDecoration(
                  labelText: 'Valor',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Digite um valor';
                  }
                  final valor = double.tryParse(value.replaceAll(',', '.'));
                  if (valor == null || valor <= 0) {
                    return 'Digite um valor válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Categoria
              DropdownButtonFormField<CategoriaTransacao>(
                value: _categoria,
                decoration: InputDecoration(
                  labelText: 'Categoria',
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _getCategorias(),
                onChanged: (value) => setState(() => _categoria = value),
                validator: (value) {
                  if (value == null) return 'Selecione uma categoria';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Data
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(DateFormat('dd/MM/yyyy').format(_data)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                onTap: () async {
                  final dataSelecionada = await showDatePicker(
                    context: context,
                    initialDate: _data,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (dataSelecionada != null) {
                    setState(() => _data = dataSelecionada);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Observações
              TextFormField(
                controller: _observacoesController,
                decoration: InputDecoration(
                  labelText: 'Observações (opcional)',
                  prefixIcon: const Icon(Icons.notes),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                    backgroundColor: Colors.red.shade600,
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
                            'Salvar Transação',
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
    );
  }

  List<DropdownMenuItem<CategoriaTransacao>> _getCategorias() {
    final categorias =
        CategoriaTransacao.values.where((cat) {
          if (_tipo == TipoTransacao.receita) {
            return cat.isReceita;
          } else {
            return cat.isDespesa;
          }
        }).toList();

    return categorias.map((cat) {
      return DropdownMenuItem(value: cat, child: Text(cat.nome));
    }).toList();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);

    try {
      final userProvider = context.read<UserProvider>();
      final userId = userProvider.uid;

      if (userId.isEmpty) {
        throw Exception('Usuário não identificado');
      }

      final valor = double.parse(_valorController.text.replaceAll(',', '.'));

      final transacao = Transacao(
        descricao: _descricaoController.text,
        valor: valor,
        tipo: _tipo,
        categoria: _categoria!,
        data: _data,
        observacoes:
            _observacoesController.text.isEmpty
                ? null
                : _observacoesController.text,
        userId: userId,
      );

      final sucesso = await context
          .read<TransacoesProvider>()
          .adicionarTransacao(transacao);

      if (!mounted) return;

      if (sucesso) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Transação adicionada com sucesso!'),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        throw Exception('Erro ao salvar transação');
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
}
