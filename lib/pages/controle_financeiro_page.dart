import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/agendamento.dart';
import '../models/cliente.dart';
import '../models/orcamento.dart';
import '../providers/agendamentos_provider.dart';
import '../providers/clients_provider.dart';
import '../providers/transacoes_provider.dart';
import '../providers/user_provider.dart';
import '../models/receita.dart';
import 'home/agendamentos/agendamento_a_receber_page.dart';
import 'home/tabs/clientes_page.dart';
import 'home/tabs/novo_cliente_page.dart';
import 'home/orcamentos/orcamentos_page.dart';

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

double? _parseMoeda(String text) {
  if (text.isEmpty) return null;
  final numeros = text.replaceAll(RegExp(r'[^0-9]'), '');
  if (numeros.isEmpty) return null;
  return int.parse(numeros) / 100;
}

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

  // Controle de expansão dos gráficos
  bool _graficoReceitasCategoriaExpandido = false;
  bool _graficoPizzaExpandido = false;
  bool _graficoBarrasExpandido = false;
  bool _graficoLinhaExpandido = false;
  bool _transacoesFuturasExpandido = false;

  // Período selecionado para filtro
  String _periodoSelecionado = 'Últimos 30 dias';
  int _diasPeriodo = 30;

  /// Filtra transações por período (não futuras)
  List<Transacao> _filtrarPorPeriodo(List<Transacao> transacoes) {
    if (_diasPeriodo == 0) return transacoes; // Todo período

    final dataLimite = DateTime.now().subtract(Duration(days: _diasPeriodo));
    return transacoes.where((t) => t.data.isAfter(dataLimite)).toList();
  }

  /// Calcula totais filtrados por período
  double _calcularTotalReceitas(TransacoesProvider provider) {
    final receitasFiltradas = _filtrarPorPeriodo(provider.receitas);
    return receitasFiltradas.fold(0.0, (sum, t) => sum + t.valor);
  }

  double _calcularTotalDespesas(TransacoesProvider provider) {
    final despesasFiltradas = _filtrarPorPeriodo(provider.despesas);
    return despesasFiltradas.fold(0.0, (sum, t) => sum + t.valor);
  }

  double _calcularSaldo(TransacoesProvider provider) {
    return _calcularTotalReceitas(provider) - _calcularTotalDespesas(provider);
  }

  /// Retorna receitas por categoria filtradas por período
  Map<CategoriaTransacao, double> _receitasPorCategoriaFiltradas(
    TransacoesProvider provider,
  ) {
    final receitasFiltradas = _filtrarPorPeriodo(provider.receitas);
    final Map<CategoriaTransacao, double> resultado = {};
    for (var transacao in receitasFiltradas) {
      resultado[transacao.categoria] =
          (resultado[transacao.categoria] ?? 0) + transacao.valor;
    }
    return resultado;
  }

  /// Retorna despesas por categoria filtradas por período
  Map<CategoriaTransacao, double> _despesasPorCategoriaFiltradas(
    TransacoesProvider provider,
  ) {
    final despesasFiltradas = _filtrarPorPeriodo(provider.despesas);
    final Map<CategoriaTransacao, double> resultado = {};
    for (var transacao in despesasFiltradas) {
      resultado[transacao.categoria] =
          (resultado[transacao.categoria] ?? 0) + transacao.valor;
    }
    return resultado;
  }

  /// Filtra transações futuras por período (olha para o futuro)
  List<Transacao> _filtrarFuturasPorPeriodo(List<Transacao> transacoes) {
    if (_diasPeriodo == 0) return transacoes; // Todo período

    final dataLimite = DateTime.now().add(Duration(days: _diasPeriodo));
    return transacoes.where((t) => t.data.isBefore(dataLimite)).toList();
  }

  /// Calcula totais filtrados para transações futuras
  double _calcularTotalReceitasAReceber(TransacoesProvider provider) {
    final receitasFiltradas = _filtrarFuturasPorPeriodo(
      provider.receitasAReceber,
    );
    return receitasFiltradas.fold(0.0, (sum, t) => sum + t.valor);
  }

  double _calcularTotalDespesasAPagar(TransacoesProvider provider) {
    final despesasFiltradas = _filtrarFuturasPorPeriodo(
      provider.despesasAPagar,
    );
    return despesasFiltradas.fold(0.0, (sum, t) => sum + t.valor);
  }

  double _calcularSaldoFuturo(TransacoesProvider provider) {
    return _calcularTotalReceitasAReceber(provider) -
        _calcularTotalDespesasAPagar(provider);
  }

  int _calcularTotalTransacoesFuturas(TransacoesProvider provider) {
    return _filtrarFuturasPorPeriodo(provider.receitasAReceber).length +
        _filtrarFuturasPorPeriodo(provider.despesasAPagar).length;
  }

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
                    // Período selecionado
                    _buildPeriodoSelector(),
                    const SizedBox(height: 16),

                    // Cards de resumo (Receitas, Despesas, Saldo)
                    _buildResumoCards(),
                    const SizedBox(height: 16),

                    // Cards de transações futuras (A Receber, A Pagar, Saldo Futuro)
                    _buildResumoCardsFuturos(),
                    const SizedBox(height: 24),

                    // Gráfico de Receitas por Categoria
                    _buildGraficoReceitasCategoria(),
                    const SizedBox(height: 16),

                    // Gráfico de Despesas por Categoria (Pizza)
                    _buildGraficoPizza(),
                    const SizedBox(height: 16),

                    // Gráfico de Barras (Receitas x Despesas)
                    _buildGraficoBarras(),
                    const SizedBox(height: 16),

                    // Gráfico de Evolução (Linha/Zigzag)
                    _buildGraficoEvolucao(),
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
      backgroundColor: Colors.transparent,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          // Calcula o progresso do colapso (0 = expandido, 1 = colapsado)
          final expandedHeight = 200.0;
          final collapsedHeight =
              kToolbarHeight + MediaQuery.of(context).padding.top;
          final currentHeight = constraints.maxHeight;
          final progress =
              1 -
              ((currentHeight - collapsedHeight) /
                      (expandedHeight - collapsedHeight))
                  .clamp(0.0, 1.0);

          // Cores para o gradiente - mais claro quando colapsado
          final startColor =
              Color.lerp(Colors.red.shade600, Colors.red.shade400, progress)!;
          final endColor =
              Color.lerp(Colors.red.shade400, Colors.red.shade300, progress)!;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [startColor, endColor],
              ),
            ),
            child: FlexibleSpaceBar(
              title: const Text(
                'Controle Financeiro',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
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
                  child: Opacity(
                    opacity: 1 - progress,
                    child: Icon(
                      Icons.account_balance_wallet,
                      size: 80,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodoSelector() {
    return Center(
      child: GestureDetector(
        onTap: _mostrarSeletorPeriodo,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today, size: 18, color: Colors.red.shade600),
              const SizedBox(width: 8),
              Text(
                _periodoSelecionado,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: Colors.grey.shade500,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarSeletorPeriodo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Indicador de arrasto
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.date_range, color: Colors.red.shade600),
                      const SizedBox(width: 12),
                      const Text(
                        'Selecionar Período',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildOpcaoPeriodo('Últimos 7 dias', 7),
                        _buildOpcaoPeriodo('Últimos 15 dias', 15),
                        _buildOpcaoPeriodo('Últimos 30 dias', 30),
                        _buildOpcaoPeriodo('Últimos 60 dias', 60),
                        _buildOpcaoPeriodo('Últimos 90 dias', 90),
                        _buildOpcaoPeriodo('Últimos 6 meses', 180),
                        _buildOpcaoPeriodo('Último ano', 365),
                        _buildOpcaoPeriodo('Todo período', 0),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildOpcaoPeriodo(String titulo, int dias) {
    final selecionado = _periodoSelecionado == titulo;
    return ListTile(
      leading: Icon(
        selecionado ? Icons.check_circle : Icons.circle_outlined,
        color: selecionado ? Colors.red.shade600 : Colors.grey.shade400,
      ),
      title: Text(
        titulo,
        style: TextStyle(
          fontWeight: selecionado ? FontWeight.w600 : FontWeight.normal,
          color: selecionado ? Colors.red.shade600 : Colors.grey.shade700,
        ),
      ),
      trailing:
          selecionado
              ? Icon(Icons.check, color: Colors.red.shade600, size: 20)
              : null,
      onTap: () {
        setState(() {
          _periodoSelecionado = titulo;
          _diasPeriodo = dias;
        });
        Navigator.pop(context);
      },
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

        // Usar valores filtrados por período
        final totalReceitas = _calcularTotalReceitas(provider);
        final totalDespesas = _calcularTotalDespesas(provider);
        final saldo = _calcularSaldo(provider);

        return Row(
          children: [
            Expanded(
              child: _buildResumoCard(
                titulo: 'Receitas',
                valor: formatMoeda.format(totalReceitas),
                icone: Icons.trending_up,
                cor: Colors.green,
                onTap:
                    () => _mostrarTransacoesFiltradas(
                      titulo: 'Receitas',
                      filtro: TipoTransacao.receita,
                      cor: Colors.green,
                    ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildResumoCard(
                titulo: 'Despesas',
                valor: formatMoeda.format(totalDespesas),
                icone: Icons.trending_down,
                cor: Colors.red.shade600,
                onTap:
                    () => _mostrarTransacoesFiltradas(
                      titulo: 'Despesas',
                      filtro: TipoTransacao.despesa,
                      cor: Colors.red,
                    ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildResumoCard(
                titulo: 'Saldo',
                valor: formatMoeda.format(saldo),
                icone: Icons.account_balance,
                cor: Colors.blue,
                onTap:
                    () => _mostrarTransacoesFiltradas(
                      titulo: 'Todas as Transações',
                      filtro: null, // null significa todas
                      cor: Colors.blue,
                    ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Cards de resumo para transações futuras (A Receber, A Pagar, Saldo Futuro)
  Widget _buildResumoCardsFuturos() {
    return Consumer<TransacoesProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const SizedBox.shrink();
        }

        final formatMoeda = NumberFormat.currency(
          locale: 'pt_BR',
          symbol: 'R\$',
        );

        // Usar valores filtrados por período
        final totalFuturas = _calcularTotalTransacoesFuturas(provider);
        final totalAReceber = _calcularTotalReceitasAReceber(provider);
        final totalAPagar = _calcularTotalDespesasAPagar(provider);
        final saldoFuturo = _calcularSaldoFuturo(provider);

        return GestureDetector(
          onTap:
              () => setState(
                () =>
                    _transacoesFuturasExpandido = !_transacoesFuturasExpandido,
              ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
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
                // Header sempre visível (card clicável)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.schedule,
                        color: Colors.orange.shade600,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Transações Futuras',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$totalFuturas transação(ões) prevista(s)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _transacoesFuturasExpandido ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey.shade400,
                        size: 28,
                      ),
                    ),
                  ],
                ),

                // Conteúdo expansível (cards)
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Column(
                    children: [
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildResumoCardFuturo(
                              titulo: 'A Receber',
                              valor: formatMoeda.format(totalAReceber),
                              icone: Icons.call_received,
                              cor: Colors.teal,
                              onTap:
                                  () => _mostrarTransacoesFiltradas(
                                    titulo: 'Receitas a Receber',
                                    filtro: TipoTransacao.receita,
                                    cor: Colors.teal,
                                    isFutura: true,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildResumoCardFuturo(
                              titulo: 'A Pagar',
                              valor: formatMoeda.format(totalAPagar),
                              icone: Icons.call_made,
                              cor: Colors.orange,
                              onTap:
                                  () => _mostrarTransacoesFiltradas(
                                    titulo: 'Despesas a Pagar',
                                    filtro: TipoTransacao.despesa,
                                    cor: Colors.orange,
                                    isFutura: true,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildResumoCardFuturo(
                              titulo: 'Saldo Futuro',
                              valor: formatMoeda.format(saldoFuturo),
                              icone: Icons.update,
                              cor: Colors.purple,
                              onTap:
                                  () => _mostrarTransacoesFiltradas(
                                    titulo: 'Todas Transações Futuras',
                                    filtro: null,
                                    cor: Colors.purple,
                                    isFutura: true,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  crossFadeState:
                      _transacoesFuturasExpandido
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResumoCardFuturo({
    required String titulo,
    required String valor,
    required IconData icone,
    required Color cor,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cor.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icone, color: cor, size: 24),
              const SizedBox(height: 6),
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  valor,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: cor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarTransacoesFiltradas({
    required String titulo,
    required TipoTransacao? filtro,
    required MaterialColor cor,
    bool isFutura = false,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _TransacoesFiltradasSheet(
            titulo: titulo,
            filtro: filtro,
            cor: cor,
            isFutura: isFutura,
          ),
    );
  }

  Widget _buildResumoCard({
    required String titulo,
    required String valor,
    required IconData icone,
    required Color cor,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
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
        ),
      ),
    );
  }

  Widget _buildGraficoReceitasCategoria() {
    return Consumer<TransacoesProvider>(
      builder: (context, provider, _) {
        // Usar dados filtrados por período
        final receitasPorCategoria = _receitasPorCategoriaFiltradas(provider);
        final transacoesFiltradas = _filtrarPorPeriodo(provider.transacoes);
        final temDados =
            transacoesFiltradas.isNotEmpty && receitasPorCategoria.isNotEmpty;

        return GestureDetector(
          onTap:
              temDados
                  ? () => setState(
                    () =>
                        _graficoReceitasCategoriaExpandido =
                            !_graficoReceitasCategoriaExpandido,
                  )
                  : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
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
                // Header sempre visível (card clicável)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.pie_chart,
                        color: Colors.green.shade600,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Receitas por Categoria',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            temDados
                                ? '${receitasPorCategoria.length} categoria(s)'
                                : 'Sem dados para exibir',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (temDados)
                      AnimatedRotation(
                        turns: _graficoReceitasCategoriaExpandido ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.grey.shade400,
                          size: 28,
                        ),
                      ),
                  ],
                ),

                // Conteúdo expansível (gráfico)
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild:
                      temDados
                          ? Column(
                            children: [
                              const SizedBox(height: 24),
                              SizedBox(
                                height: 200,
                                child: PieChart(
                                  PieChartData(
                                    sections: _buildPieChartSectionsReceitas(
                                      receitasPorCategoria,
                                    ),
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 50,
                                    borderData: FlBorderData(show: false),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildLegendaReceitas(receitasPorCategoria),
                            ],
                          )
                          : const SizedBox.shrink(),
                  crossFadeState:
                      _graficoReceitasCategoriaExpandido
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<PieChartSectionData> _buildPieChartSectionsReceitas(
    Map<CategoriaTransacao, double> dados,
  ) {
    final cores = [
      Colors.green.shade400,
      Colors.teal.shade400,
      Colors.cyan.shade400,
      Colors.green.shade300,
      Colors.lightGreen.shade400,
      Colors.lime.shade400,
      Colors.green.shade500,
      Colors.teal.shade300,
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

  Widget _buildLegendaReceitas(Map<CategoriaTransacao, double> dados) {
    final cores = [
      Colors.green.shade400,
      Colors.teal.shade400,
      Colors.cyan.shade400,
      Colors.green.shade300,
      Colors.lightGreen.shade400,
      Colors.lime.shade400,
      Colors.green.shade500,
      Colors.teal.shade300,
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

  Widget _buildGraficoPizza() {
    return Consumer<TransacoesProvider>(
      builder: (context, provider, _) {
        // Usar dados filtrados por período
        final despesasPorCategoria = _despesasPorCategoriaFiltradas(provider);
        final transacoesFiltradas = _filtrarPorPeriodo(provider.transacoes);
        final temDados =
            transacoesFiltradas.isNotEmpty && despesasPorCategoria.isNotEmpty;

        return GestureDetector(
          onTap:
              temDados
                  ? () => setState(
                    () => _graficoPizzaExpandido = !_graficoPizzaExpandido,
                  )
                  : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
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
                // Header sempre visível (card clicável)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.pie_chart,
                        color: Colors.red.shade600,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Despesas por Categoria',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            temDados
                                ? '${despesasPorCategoria.length} categoria(s)'
                                : 'Sem dados para exibir',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (temDados)
                      AnimatedRotation(
                        turns: _graficoPizzaExpandido ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.grey.shade400,
                          size: 28,
                        ),
                      ),
                  ],
                ),

                // Conteúdo expansível (gráfico)
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild:
                      temDados
                          ? Column(
                            children: [
                              const SizedBox(height: 24),
                              SizedBox(
                                height: 200,
                                child: PieChart(
                                  PieChartData(
                                    sections: _buildPieChartSections(
                                      despesasPorCategoria,
                                    ),
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 50,
                                    borderData: FlBorderData(show: false),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildLegenda(despesasPorCategoria),
                            ],
                          )
                          : const SizedBox.shrink(),
                  crossFadeState:
                      _graficoPizzaExpandido
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                ),
              ],
            ),
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
        final transacoesFiltradas = _filtrarPorPeriodo(provider.transacoes);
        final temDados = transacoesFiltradas.isNotEmpty;
        final formatMoeda = NumberFormat.currency(
          locale: 'pt_BR',
          symbol: 'R\$',
        );

        // Calcular saldo filtrado
        final saldoFiltrado = _calcularSaldo(provider);

        return GestureDetector(
          onTap:
              temDados
                  ? () => setState(
                    () => _graficoBarrasExpandido = !_graficoBarrasExpandido,
                  )
                  : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
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
                // Header sempre visível (card clicável)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.bar_chart,
                        color: Colors.blue.shade600,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Receitas x Despesas',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            temDados
                                ? 'Saldo: ${formatMoeda.format(saldoFiltrado)}'
                                : 'Sem dados para exibir',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  saldoFiltrado >= 0
                                      ? Colors.green.shade600
                                      : Colors.red.shade600,
                              fontWeight:
                                  temDados
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (temDados)
                      AnimatedRotation(
                        turns: _graficoBarrasExpandido ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.grey.shade400,
                          size: 28,
                        ),
                      ),
                  ],
                ),

                // Conteúdo expansível (gráfico)
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild:
                      temDados
                          ? Column(
                            children: [
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
                                              style: const TextStyle(
                                                fontSize: 10,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            if (value == 0)
                                              return const Text('Receitas');
                                            if (value == 1)
                                              return const Text('Despesas');
                                            return const Text('');
                                          },
                                        ),
                                      ),
                                      topTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      rightTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
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
                          )
                          : const SizedBox.shrink(),
                  crossFadeState:
                      _graficoBarrasExpandido
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  double _calcularMaxY(TransacoesProvider provider) {
    // Usar valores filtrados por período
    final totalReceitas = _calcularTotalReceitas(provider);
    final totalDespesas = _calcularTotalDespesas(provider);
    final maxValor =
        totalReceitas > totalDespesas ? totalReceitas : totalDespesas;
    return maxValor * 1.2; // 20% a mais para margem
  }

  List<BarChartGroupData> _buildBarGroups(TransacoesProvider provider) {
    // Usar valores filtrados por período
    final totalReceitas = _calcularTotalReceitas(provider);
    final totalDespesas = _calcularTotalDespesas(provider);

    return [
      BarChartGroupData(
        x: 0,
        barRods: [
          BarChartRodData(
            toY: totalReceitas,
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
            toY: totalDespesas,
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

  Widget _buildGraficoEvolucao() {
    return Consumer<TransacoesProvider>(
      builder: (context, provider, _) {
        final transacoesFiltradas = _filtrarPorPeriodo(provider.transacoes);
        final temDados = transacoesFiltradas.isNotEmpty;
        final formatMoeda = NumberFormat.currency(
          locale: 'pt_BR',
          symbol: 'R\$',
        );

        return GestureDetector(
          onTap:
              temDados
                  ? () => setState(
                    () => _graficoLinhaExpandido = !_graficoLinhaExpandido,
                  )
                  : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
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
                // Header sempre visível (card clicável)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.show_chart,
                        color: Colors.purple.shade600,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Evolução Financeira',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            temDados
                                ? '${transacoesFiltradas.length} transação(ões)'
                                : 'Sem dados para exibir',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (temDados)
                      AnimatedRotation(
                        turns: _graficoLinhaExpandido ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.grey.shade400,
                          size: 28,
                        ),
                      ),
                  ],
                ),

                // Conteúdo expansível (gráfico)
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild:
                      temDados
                          ? Column(
                            children: [
                              const SizedBox(height: 24),
                              SizedBox(
                                height: 220,
                                child: LineChart(
                                  LineChartData(
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                      horizontalInterval: _calcularIntervalY(
                                        provider,
                                      ),
                                      getDrawingHorizontalLine: (value) {
                                        return FlLine(
                                          color: Colors.grey.shade200,
                                          strokeWidth: 1,
                                        );
                                      },
                                    ),
                                    titlesData: FlTitlesData(
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 50,
                                          getTitlesWidget: (value, meta) {
                                            if (value == 0) {
                                              return const Text(
                                                'R\$0',
                                                style: TextStyle(fontSize: 10),
                                              );
                                            }
                                            return Text(
                                              'R\$${(value / 1000).toStringAsFixed(0)}k',
                                              style: const TextStyle(
                                                fontSize: 10,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 30,
                                          getTitlesWidget: (value, meta) {
                                            final transacoes =
                                                _getTransacoesOrdenadas(
                                                  provider,
                                                );
                                            if (value.toInt() >= 0 &&
                                                value.toInt() <
                                                    transacoes.length) {
                                              final data =
                                                  transacoes[value.toInt()]
                                                      .data;
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 8,
                                                ),
                                                child: Text(
                                                  '${data.day}/${data.month}',
                                                  style: const TextStyle(
                                                    fontSize: 9,
                                                  ),
                                                ),
                                              );
                                            }
                                            return const Text('');
                                          },
                                          interval: _calcularIntervalX(
                                            provider,
                                          ),
                                        ),
                                      ),
                                      topTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      rightTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    lineBarsData: [
                                      // Linha de Receitas
                                      LineChartBarData(
                                        spots: _buildReceitasSpots(provider),
                                        isCurved: true,
                                        curveSmoothness: 0.3,
                                        color: Colors.green.shade400,
                                        barWidth: 3,
                                        isStrokeCapRound: true,
                                        dotData: FlDotData(
                                          show: true,
                                          getDotPainter: (
                                            spot,
                                            percent,
                                            barData,
                                            index,
                                          ) {
                                            return FlDotCirclePainter(
                                              radius: 4,
                                              color: Colors.white,
                                              strokeWidth: 2,
                                              strokeColor:
                                                  Colors.green.shade400,
                                            );
                                          },
                                        ),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          color: Colors.green.withOpacity(0.1),
                                        ),
                                      ),
                                      // Linha de Despesas
                                      LineChartBarData(
                                        spots: _buildDespesasSpots(provider),
                                        isCurved: true,
                                        curveSmoothness: 0.3,
                                        color: Colors.red.shade400,
                                        barWidth: 3,
                                        isStrokeCapRound: true,
                                        dotData: FlDotData(
                                          show: true,
                                          getDotPainter: (
                                            spot,
                                            percent,
                                            barData,
                                            index,
                                          ) {
                                            return FlDotCirclePainter(
                                              radius: 4,
                                              color: Colors.white,
                                              strokeWidth: 2,
                                              strokeColor: Colors.red.shade400,
                                            );
                                          },
                                        ),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          color: Colors.red.withOpacity(0.1),
                                        ),
                                      ),
                                    ],
                                    minY: 0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Legenda
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildLegendaItem(
                                    'Receitas',
                                    Colors.green.shade400,
                                  ),
                                  const SizedBox(width: 24),
                                  _buildLegendaItem(
                                    'Despesas',
                                    Colors.red.shade400,
                                  ),
                                ],
                              ),
                            ],
                          )
                          : const SizedBox.shrink(),
                  crossFadeState:
                      _graficoLinhaExpandido
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegendaItem(String label, Color cor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: cor,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  List<Transacao> _getTransacoesOrdenadas(TransacoesProvider provider) {
    // Agrupa transações por data (não futuras) e filtra por período
    final transacoes = _filtrarPorPeriodo(
      provider.transacoes.where((t) => !t.isFutura).toList(),
    )..sort((a, b) => a.data.compareTo(b.data));
    return transacoes;
  }

  List<FlSpot> _buildReceitasSpots(TransacoesProvider provider) {
    final transacoes = _getTransacoesOrdenadas(provider);
    if (transacoes.isEmpty) return [];

    // Agrupa por data e acumula receitas
    final Map<String, double> receitasPorDia = {};
    for (final t in transacoes) {
      final key = '${t.data.year}-${t.data.month}-${t.data.day}';
      if (t.tipo == TipoTransacao.receita) {
        receitasPorDia[key] = (receitasPorDia[key] ?? 0) + t.valor;
      } else {
        receitasPorDia[key] = receitasPorDia[key] ?? 0;
      }
    }

    final spots = <FlSpot>[];
    final datas = receitasPorDia.keys.toList();
    for (int i = 0; i < datas.length; i++) {
      spots.add(FlSpot(i.toDouble(), receitasPorDia[datas[i]]!));
    }
    return spots;
  }

  List<FlSpot> _buildDespesasSpots(TransacoesProvider provider) {
    final transacoes = _getTransacoesOrdenadas(provider);
    if (transacoes.isEmpty) return [];

    // Agrupa por data e acumula despesas
    final Map<String, double> despesasPorDia = {};
    for (final t in transacoes) {
      final key = '${t.data.year}-${t.data.month}-${t.data.day}';
      if (t.tipo == TipoTransacao.despesa) {
        despesasPorDia[key] = (despesasPorDia[key] ?? 0) + t.valor;
      } else {
        despesasPorDia[key] = despesasPorDia[key] ?? 0;
      }
    }

    final spots = <FlSpot>[];
    final datas = despesasPorDia.keys.toList();
    for (int i = 0; i < datas.length; i++) {
      spots.add(FlSpot(i.toDouble(), despesasPorDia[datas[i]]!));
    }
    return spots;
  }

  double _calcularIntervalY(TransacoesProvider provider) {
    // Usar valores filtrados por período
    final totalReceitas = _calcularTotalReceitas(provider);
    final totalDespesas = _calcularTotalDespesas(provider);
    final max = totalReceitas > totalDespesas ? totalReceitas : totalDespesas;
    if (max <= 1000) return 200;
    if (max <= 5000) return 1000;
    if (max <= 10000) return 2000;
    return 5000;
  }

  double _calcularIntervalX(TransacoesProvider provider) {
    final transacoes = _getTransacoesOrdenadas(provider);
    if (transacoes.length <= 5) return 1;
    if (transacoes.length <= 10) return 2;
    return (transacoes.length / 5).ceil().toDouble();
  }

  Widget _buildTransacoesRecentes() {
    return Consumer<TransacoesProvider>(
      builder: (context, provider, _) {
        final totalTransacoes = provider.transacoes.length;

        return GestureDetector(
          onTap: () => _mostrarTransacoesRecentes(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.history,
                    color: Colors.indigo.shade600,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Transações Recentes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$totalTransacoes transação(ões) no total',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                  size: 24,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _mostrarTransacoesRecentes(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _TransacoesRecentesSheet(),
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
    // Primeiro mostra o card para selecionar o tipo
    final resultado = await showModalBottomSheet<Map<String, dynamic>>(
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
                    'Nova Transação',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selecione o tipo de transação',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),

                  // Transações Atuais
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transações Atuais',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Botão Receita
                            Expanded(
                              child: _buildTipoTransacaoButton(
                                context: context,
                                tipo: TipoTransacao.receita,
                                isFutura: false,
                                titulo: 'Receita',
                                subtitulo: 'Entrada de dinheiro',
                                icone: Icons.trending_up,
                                cor: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Botão Despesa
                            Expanded(
                              child: _buildTipoTransacaoButton(
                                context: context,
                                tipo: TipoTransacao.despesa,
                                isFutura: false,
                                titulo: 'Despesa',
                                subtitulo: 'Saída de dinheiro',
                                icone: Icons.trending_down,
                                cor: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Transações Futuras
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 16,
                              color: Colors.orange.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Transações Futuras',
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
                            // Botão Receita a Receber
                            Expanded(
                              child: _buildTipoTransacaoButton(
                                context: context,
                                tipo: TipoTransacao.receita,
                                isFutura: true,
                                titulo: 'A Receber',
                                subtitulo: 'Receita futura',
                                icone: Icons.call_received,
                                cor: Colors.teal,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Botão Despesa a Pagar
                            Expanded(
                              child: _buildTipoTransacaoButton(
                                context: context,
                                tipo: TipoTransacao.despesa,
                                isFutura: true,
                                titulo: 'A Pagar',
                                subtitulo: 'Despesa futura',
                                icone: Icons.call_made,
                                cor: Colors.orange,
                              ),
                            ),
                          ],
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

    // Se selecionou um tipo, abre o formulário
    if (resultado != null && mounted) {
      final tipo = resultado['tipo'] as TipoTransacao;
      final isFutura = resultado['isFutura'] as bool;

      // Para receita a receber, navega para página completa com AppBar
      if (isFutura && tipo == TipoTransacao.receita) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) =>
                    const AgendamentoAReceberPage(fromControleFinanceiro: true),
          ),
        );
      } else {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder:
              (context) =>
                  _NovaTransacaoSheet(tipoInicial: tipo, isFutura: isFutura),
        );
      }
    }
  }

  Widget _buildTipoTransacaoButton({
    required BuildContext context,
    required TipoTransacao tipo,
    required bool isFutura,
    required String titulo,
    required String subtitulo,
    required IconData icone,
    required MaterialColor cor,
  }) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, {'tipo': tipo, 'isFutura': isFutura}),
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
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget para exibir transações recentes em um modal
class _TransacoesRecentesSheet extends StatelessWidget {
  const _TransacoesRecentesSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade600, Colors.indigo.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Indicador de arrasto
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.history,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Transações Recentes',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Consumer<TransacoesProvider>(
                            builder: (context, provider, _) {
                              return Text(
                                '${provider.transacoes.length} transação(ões)',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Lista de transações
          Expanded(
            child: Consumer<TransacoesProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.transacoes.isEmpty) {
                  return Center(
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
                          'Nenhuma transação cadastrada',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Ordenar por data mais recente
                final transacoesOrdenadas = List<Transacao>.from(
                  provider.transacoes,
                )..sort((a, b) => b.data.compareTo(a.data));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: transacoesOrdenadas.length,
                  itemBuilder: (context, index) {
                    final transacao = transacoesOrdenadas[index];
                    return _buildTransacaoCard(context, transacao);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransacaoCard(BuildContext context, Transacao transacao) {
    final formatMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final formatData = DateFormat('dd/MM/yyyy');

    final isReceita = transacao.tipo == TipoTransacao.receita;
    final corTransacao = isReceita ? Colors.green : Colors.red;

    // Determina badge baseado em isFutura
    String badge;
    Color corBadge;
    if (transacao.isFutura) {
      badge = isReceita ? 'A Receber' : 'A Pagar';
      corBadge = isReceita ? Colors.teal : Colors.orange;
    } else {
      badge = isReceita ? 'Receita' : 'Despesa';
      corBadge = corTransacao;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: corBadge.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isReceita ? Icons.trending_up : Icons.trending_down,
              color: corBadge,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transacao.descricao,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        transacao.categoria.nome,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formatData.format(transacao.data),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isReceita ? '+' : '-'} ${formatMoeda.format(transacao.valor)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: corBadge,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: corBadge.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10,
                    color: corBadge,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet para adicionar nova transação
class _NovaTransacaoSheet extends StatefulWidget {
  final TipoTransacao tipoInicial;
  final bool isFutura;

  const _NovaTransacaoSheet({required this.tipoInicial, this.isFutura = false});

  @override
  State<_NovaTransacaoSheet> createState() => _NovaTransacaoSheetState();
}

class _NovaTransacaoSheetState extends State<_NovaTransacaoSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  final _observacoesController = TextEditingController();

  late TipoTransacao _tipo;
  CategoriaTransacao? _categoria;
  DateTime _data = DateTime.now();
  bool _salvando = false;

  // Novos campos para receita a receber (isFutura = true)
  bool _repetirParcelar = false;
  Orcamento? _orcamentoSelecionado;
  Cliente? _clienteSelecionado;
  DateTime? _dataRecebimento;
  TimeOfDay? _horaRecebimento;
  bool _salvarEmAgendamento = true; // Por padrão, salva na agenda

  @override
  void initState() {
    super.initState();
    _tipo = widget.tipoInicial;

    // Valores padrão para receita a receber
    if (widget.isFutura && widget.tipoInicial == TipoTransacao.receita) {
      _dataRecebimento = DateTime.now().add(const Duration(days: 7));
      _horaRecebimento = const TimeOfDay(hour: 10, minute: 0);
    }
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  String get _tituloFormulario {
    if (widget.isFutura) {
      return _tipo == TipoTransacao.receita
          ? 'Nova Receita a Receber'
          : 'Nova Despesa a Pagar';
    }
    return _tipo == TipoTransacao.receita ? 'Nova Receita' : 'Nova Despesa';
  }

  String get _subtituloFormulario {
    if (widget.isFutura) {
      return _tipo == TipoTransacao.receita
          ? 'Receita futura a receber'
          : 'Despesa futura a pagar';
    }
    return _tipo == TipoTransacao.receita
        ? 'Entrada de dinheiro'
        : 'Saída de dinheiro';
  }

  MaterialColor get _corTema {
    if (widget.isFutura) {
      return _tipo == TipoTransacao.receita ? Colors.teal : Colors.orange;
    }
    return _tipo == TipoTransacao.receita ? Colors.green : Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final isReceita = _tipo == TipoTransacao.receita;
    final corTema = _corTema;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [corTema.shade50, Colors.white],
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
                    child: Icon(
                      isReceita ? Icons.trending_up : Icons.trending_down,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _tituloFormulario,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _subtituloFormulario,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.isFutura)
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

              // ========== CAMPOS ESPECIAIS PARA RECEITA A RECEBER ==========
              if (widget.isFutura && isReceita) ...[
                // Repetir / Parcelar
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
                        onChanged:
                            (value) => setState(() => _repetirParcelar = value),
                        activeColor: corTema.shade600,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Receita de Orçamento
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

                // Cliente
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
              ],

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
                  prefixIcon: Icon(Icons.attach_money, color: corTema.shade600),
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

              // ========== CAMPOS DE DATA/HORA PARA RECEITA A RECEBER ==========
              if (widget.isFutura && _tipo == TipoTransacao.receita) ...[
                // Data do Recebimento
                ListTile(
                  leading: Icon(Icons.event, color: corTema.shade600),
                  title: Text(
                    _dataRecebimento != null
                        ? DateFormat('dd/MM/yyyy').format(_dataRecebimento!)
                        : 'Selecionar data',
                    style: TextStyle(
                      color:
                          _dataRecebimento != null
                              ? Colors.black
                              : Colors.grey.shade500,
                    ),
                  ),
                  subtitle: const Text('Data do Recebimento'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  onTap: _selecionarDataRecebimento,
                ),
                const SizedBox(height: 16),

                // Hora do Recebimento
                ListTile(
                  leading: Icon(Icons.access_time, color: corTema.shade600),
                  title: Text(
                    _horaRecebimento != null
                        ? _horaRecebimento!.format(context)
                        : 'Selecionar hora',
                    style: TextStyle(
                      color:
                          _horaRecebimento != null
                              ? Colors.black
                              : Colors.grey.shade500,
                    ),
                  ),
                  subtitle: const Text('Hora do Recebimento'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  onTap: _selecionarHoraRecebimento,
                ),
                const SizedBox(height: 16),

                // Checkbox Salvar em Agendamento
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        _salvarEmAgendamento
                            ? corTema.shade50
                            : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          _salvarEmAgendamento
                              ? corTema.shade300
                              : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month,
                        color:
                            _salvarEmAgendamento
                                ? corTema.shade600
                                : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Salvar em Agendamento',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color:
                                    _salvarEmAgendamento
                                        ? corTema.shade700
                                        : Colors.grey.shade700,
                              ),
                            ),
                            Text(
                              'Também adicionar na agenda',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _salvarEmAgendamento,
                        onChanged:
                            (value) =>
                                setState(() => _salvarEmAgendamento = value),
                        activeColor: corTema.shade600,
                      ),
                    ],
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
                          : Text(
                            isReceita ? 'Salvar Receita' : 'Salvar Despesa',
                            style: const TextStyle(
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

  // ========== Métodos para Receita a Receber ==========

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
        _descricaoController.text =
            'Orçamento #${orcamento.numero.toString().padLeft(4, '0')} - ${orcamento.cliente.nome}';
        final valorFormatado =
            'R\$ ${orcamento.valorTotal.toStringAsFixed(2).replaceAll('.', ',')}';
        _valorController.text = valorFormatado;
        _clienteSelecionado = orcamento.cliente;
      });
    }
  }

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
          content: Text('Erro ao buscar contatos: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
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

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    // Validação adicional para receita a receber
    if (widget.isFutura &&
        _tipo == TipoTransacao.receita &&
        _dataRecebimento == null) {
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

      // Monta observações para receita a receber
      String? observacoesFinais =
          _observacoesController.text.isEmpty
              ? null
              : _observacoesController.text;

      if (widget.isFutura && _tipo == TipoTransacao.receita) {
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
        observacoesFinais = obsCompletas.toString().trim();
      }

      final transacao = Transacao(
        descricao: _descricaoController.text,
        valor: valor,
        tipo: _tipo,
        categoria: _categoria!,
        data:
            widget.isFutura && _tipo == TipoTransacao.receita
                ? _dataRecebimento!
                : _data,
        observacoes: observacoesFinais,
        userId: userId,
        isFutura: widget.isFutura,
      );

      final sucesso = await context
          .read<TransacoesProvider>()
          .adicionarTransacao(transacao);

      if (!mounted) return;

      if (sucesso) {
        // Salvar na agenda se opção estiver marcada
        if (widget.isFutura &&
            _tipo == TipoTransacao.receita &&
            _salvarEmAgendamento) {
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
          if (_categoria != null) {
            obsAgendamento.writeln('Categoria: ${_categoria!.nome}');
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
              _clienteSelecionado?.nome ??
              'Receita: ${_descricaoController.text}';

          await agProv.adicionarAgendamento(
            orcamentoId: 'receita_a_receber',
            orcamentoNumero: _orcamentoSelecionado?.numero,
            clienteNome: clienteNome,
            dataHora: Timestamp.fromDate(dataHoraRecebimento),
            status: 'Pendente',
            observacoes: obsAgendamento.toString().trim(),
          );
        }

        final isReceita = _tipo == TipoTransacao.receita;
        Navigator.pop(context);

        String mensagem;
        if (widget.isFutura) {
          if (_salvarEmAgendamento && isReceita) {
            mensagem = 'Receita a receber adicionada e agendada!';
          } else {
            mensagem =
                isReceita
                    ? 'Receita a receber adicionada!'
                    : 'Despesa a pagar adicionada!';
          }
        } else {
          mensagem =
              isReceita
                  ? 'Receita adicionada com sucesso!'
                  : 'Despesa adicionada com sucesso!';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(mensagem)),
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

/// Widget para exibir transações filtradas em um modal
class _TransacoesFiltradasSheet extends StatelessWidget {
  final String titulo;
  final TipoTransacao? filtro;
  final MaterialColor cor;
  final bool isFutura;

  const _TransacoesFiltradasSheet({
    required this.titulo,
    required this.filtro,
    required this.cor,
    this.isFutura = false,
  });

  String get _textoBotao {
    if (isFutura) {
      return filtro == TipoTransacao.receita
          ? 'Nova A Receber'
          : 'Nova A Pagar';
    } else {
      return filtro == TipoTransacao.receita ? 'Nova Receita' : 'Nova Despesa';
    }
  }

  IconData get _iconeBotao {
    if (filtro == TipoTransacao.receita) {
      return Icons.trending_up;
    } else {
      return Icons.trending_down;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cor.shade600, cor.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Indicador de arrasto
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        filtro == TipoTransacao.receita
                            ? Icons.trending_up
                            : filtro == TipoTransacao.despesa
                            ? Icons.trending_down
                            : Icons.account_balance,
                        color: Colors.white,
                        size: 28,
                      ),
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
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Consumer<TransacoesProvider>(
                            builder: (context, provider, _) {
                              final transacoesFiltradas =
                                  _getTransacoesFiltradas(provider);
                              return Text(
                                '${transacoesFiltradas.length} transação(ões)',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Lista de transações
          Expanded(
            child: Consumer<TransacoesProvider>(
              builder: (context, provider, _) {
                final transacoesFiltradas = _getTransacoesFiltradas(provider);

                if (transacoesFiltradas.isEmpty) {
                  return Center(
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
                          filtro == TipoTransacao.receita
                              ? 'Nenhuma receita cadastrada'
                              : filtro == TipoTransacao.despesa
                              ? 'Nenhuma despesa cadastrada'
                              : 'Nenhuma transação cadastrada',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 80, // Espaço para o botão fixo
                  ),
                  itemCount: transacoesFiltradas.length,
                  itemBuilder: (context, index) {
                    final transacao = transacoesFiltradas[index];
                    return _buildTransacaoCard(context, transacao);
                  },
                );
              },
            ),
          ),

          // Botão fixo na parte inferior
          if (filtro != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Fecha o modal de lista
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder:
                            (context) => _NovaTransacaoSheet(
                              tipoInicial: filtro!,
                              isFutura: isFutura,
                            ),
                      );
                    },
                    icon: Icon(_iconeBotao, size: 22),
                    label: Text(
                      _textoBotao,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cor.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Transacao> _getTransacoesFiltradas(TransacoesProvider provider) {
    // Filtra primeiro por isFutura
    var transacoes =
        provider.transacoes.where((t) => t.isFutura == isFutura).toList();

    // Depois filtra por tipo se especificado
    if (filtro != null) {
      transacoes = transacoes.where((t) => t.tipo == filtro).toList();
    }
    return transacoes;
  }

  Widget _buildTransacaoCard(BuildContext context, Transacao transacao) {
    final formatMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final formatData = DateFormat('dd/MM/yyyy');

    final isReceita = transacao.tipo == TipoTransacao.receita;
    final corTransacao = isReceita ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: corTransacao.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isReceita ? Icons.trending_up : Icons.trending_down,
              color: corTransacao,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transacao.descricao,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        transacao.categoria.nome,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formatData.format(transacao.data),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                if (transacao.observacoes != null &&
                    transacao.observacoes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    transacao.observacoes!,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isReceita ? '+' : '-'} ${formatMoeda.format(transacao.valor)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: corTransacao,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: corTransacao.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isReceita ? 'Receita' : 'Despesa',
                  style: TextStyle(
                    fontSize: 10,
                    color: corTransacao,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          // Menu de opções (3 pontinhos)
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.grey.shade600, size: 20),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              if (value == 'editar') {
                _editarTransacao(context, transacao);
              } else if (value == 'excluir') {
                _confirmarExclusao(context, transacao);
              }
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'editar',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          color: Colors.blue.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Text('Editar'),
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
                          size: 20,
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
    );
  }

  void _editarTransacao(BuildContext context, Transacao transacao) {
    Navigator.pop(context); // Fecha o modal de lista
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditarTransacaoSheet(transacao: transacao),
    );
  }

  void _confirmarExclusao(BuildContext context, Transacao transacao) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red.shade600),
                const SizedBox(width: 12),
                const Text('Excluir Transação'),
              ],
            ),
            content: Text(
              'Deseja realmente excluir "${transacao.descricao}"?\n\nEssa ação não pode ser desfeita.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);

                  final provider = context.read<TransacoesProvider>();
                  final sucesso = await provider.removerTransacao(
                    transacao.id!,
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(
                              sucesso ? Icons.check_circle : Icons.error,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              sucesso
                                  ? 'Transação excluída com sucesso!'
                                  : 'Erro ao excluir transação',
                            ),
                          ],
                        ),
                        backgroundColor: sucesso ? Colors.green : Colors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Excluir'),
              ),
            ],
          ),
    );
  }
}

/// Widget para editar uma transação existente
class _EditarTransacaoSheet extends StatefulWidget {
  final Transacao transacao;

  const _EditarTransacaoSheet({required this.transacao});

  @override
  State<_EditarTransacaoSheet> createState() => _EditarTransacaoSheetState();
}

class _EditarTransacaoSheetState extends State<_EditarTransacaoSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descricaoController;
  late TextEditingController _valorController;
  late TextEditingController _observacoesController;

  late TipoTransacao _tipo;
  CategoriaTransacao? _categoria;
  late DateTime _data;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _tipo = widget.transacao.tipo;
    _categoria = widget.transacao.categoria;
    _data = widget.transacao.data;
    _descricaoController = TextEditingController(
      text: widget.transacao.descricao,
    );
    _observacoesController = TextEditingController(
      text: widget.transacao.observacoes ?? '',
    );

    // Formatar o valor inicial para o campo de moeda
    final valorFormatado =
        'R\$ ${widget.transacao.valor.toStringAsFixed(2).replaceAll('.', ',')}';
    _valorController = TextEditingController(text: valorFormatado);
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  String get _tituloEdicao {
    if (widget.transacao.isFutura) {
      return _tipo == TipoTransacao.receita
          ? 'Editar Receita a Receber'
          : 'Editar Despesa a Pagar';
    }
    return _tipo == TipoTransacao.receita ? 'Editar Receita' : 'Editar Despesa';
  }

  MaterialColor get _corTema {
    if (widget.transacao.isFutura) {
      return _tipo == TipoTransacao.receita ? Colors.teal : Colors.orange;
    }
    return _tipo == TipoTransacao.receita ? Colors.green : Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final isReceita = _tipo == TipoTransacao.receita;
    final corTema = _corTema;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [corTema.shade50, Colors.white],
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
                        colors: [corTema.shade600, corTema.shade400],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.edit_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _tituloEdicao,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Altere os dados da transação',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.transacao.isFutura)
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
                  prefixIcon: Icon(Icons.attach_money, color: corTema.shade600),
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
                value: _categoria,
                decoration: InputDecoration(
                  labelText: 'Categoria',
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _buildCategoriasDropdown(),
                onChanged: (value) => setState(() => _categoria = value),
                validator: (value) {
                  if (value == null) {
                    return 'Selecione uma categoria';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Data
              InkWell(
                onTap: _selecionarData,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Data',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(_data),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Observações
              TextFormField(
                controller: _observacoesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Observações (opcional)',
                  prefixIcon: const Icon(Icons.notes),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botão Salvar
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
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Text(
                            'Salvar Alterações',
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

  List<DropdownMenuItem<CategoriaTransacao>> _buildCategoriasDropdown() {
    final categorias =
        CategoriaTransacao.values.where((cat) {
          if (_tipo == TipoTransacao.receita) {
            return cat == CategoriaTransacao.vendas ||
                cat == CategoriaTransacao.servicos ||
                cat == CategoriaTransacao.outros;
          } else {
            return cat != CategoriaTransacao.vendas &&
                cat != CategoriaTransacao.servicos;
          }
        }).toList();

    return categorias.map((cat) {
      return DropdownMenuItem(value: cat, child: Text(cat.nome));
    }).toList();
  }

  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('pt', 'BR'),
    );
    if (data != null) {
      setState(() => _data = data);
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);

    try {
      final valor = _parseMoeda(_valorController.text) ?? 0.0;

      final transacaoAtualizada = Transacao(
        id: widget.transacao.id,
        descricao: _descricaoController.text,
        valor: valor,
        tipo: _tipo,
        categoria: _categoria!,
        data: _data,
        observacoes:
            _observacoesController.text.isEmpty
                ? null
                : _observacoesController.text,
        userId: widget.transacao.userId,
        isFutura: widget.transacao.isFutura,
      );

      final sucesso = await context
          .read<TransacoesProvider>()
          .atualizarTransacao(transacaoAtualizada);

      if (!mounted) return;

      if (sucesso) {
        Navigator.pop(context);

        String mensagem;
        if (widget.transacao.isFutura) {
          mensagem =
              _tipo == TipoTransacao.receita
                  ? 'Receita a receber atualizada!'
                  : 'Despesa a pagar atualizada!';
        } else {
          mensagem =
              _tipo == TipoTransacao.receita
                  ? 'Receita atualizada com sucesso!'
                  : 'Despesa atualizada com sucesso!';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(mensagem),
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
        throw Exception('Erro ao atualizar transação');
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
