import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/receita.dart';
import '../../../providers/agendamentos_provider.dart';
import '../../../providers/transacoes_provider.dart';
import '../../../providers/user_provider.dart';
import 'nova_despesa_page.dart';
import 'detalhes_despesa_a_pagar_page.dart';

/// Página de Despesas a Pagar (transações futuras)
/// Mesma estrutura da DespesasPage, mas filtrando apenas isFutura = true
class DespesasAPagarPage extends StatefulWidget {
  const DespesasAPagarPage({super.key});

  @override
  State<DespesasAPagarPage> createState() => _DespesasAPagarPageState();
}

class _DespesasAPagarPageState extends State<DespesasAPagarPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _categoriaScrollController = ScrollController();
  String _filtroSelecionado = 'Todas';
  String _termoBusca = '';

  final List<String> _categorias = [
    'Todas',
    'Fornecedores',
    'Salários',
    'Aluguel',
    'Marketing',
    'Equipamentos',
    'Impostos',
    'Manutenção',
    'Outros',
  ];

  // Método para alternar categoria via swipe
  void _mudarCategoriaPorSwipe(DragEndDetails details) {
    final velocidade = details.primaryVelocity ?? 0;
    final indexAtual = _categorias.indexOf(_filtroSelecionado);

    if (velocidade < -300) {
      // Swipe para esquerda -> próxima categoria
      if (indexAtual < _categorias.length - 1) {
        final novoIndex = indexAtual + 1;
        setState(() {
          _filtroSelecionado = _categorias[novoIndex];
        });
        _rolarParaCategoria(novoIndex);
      }
    } else if (velocidade > 300) {
      // Swipe para direita -> categoria anterior
      if (indexAtual > 0) {
        final novoIndex = indexAtual - 1;
        setState(() {
          _filtroSelecionado = _categorias[novoIndex];
        });
        _rolarParaCategoria(novoIndex);
      }
    }
  }

  // Método para rolar a barra de filtros até a categoria selecionada
  void _rolarParaCategoria(int index) {
    const double larguraChip = 120.0;
    final double posicaoAlvo = index * larguraChip;

    _categoriaScrollController.animateTo(
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
    _categoriaScrollController.dispose();
    super.dispose();
  }

  Future<void> _abrirFormulario({Transacao? transacao}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NovaDespesaPage(transacao: transacao, isFutura: true),
      ),
    );
  }

  // Ação para visualizar detalhes da despesa
  void _visualizarDespesa(Transacao transacao) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetalhesDespesaAPagarPage(transacao: transacao),
      ),
    );
  }

  String _getCategoriaName(CategoriaTransacao categoria) {
    switch (categoria) {
      case CategoriaTransacao.vendas:
        return 'Vendas';
      case CategoriaTransacao.servicos:
        return 'Serviços';
      case CategoriaTransacao.investimentos:
        return 'Investimentos';
      case CategoriaTransacao.outros:
        return 'Outros';
      case CategoriaTransacao.fornecedores:
        return 'Fornecedores';
      case CategoriaTransacao.salarios:
        return 'Salários';
      case CategoriaTransacao.aluguel:
        return 'Aluguel';
      case CategoriaTransacao.marketing:
        return 'Marketing';
      case CategoriaTransacao.equipamentos:
        return 'Equipamentos';
      case CategoriaTransacao.impostos:
        return 'Impostos';
      case CategoriaTransacao.utilities:
        return 'Utilidades';
      case CategoriaTransacao.manutencao:
        return 'Manutenção';
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // Ação para alterar status da despesa (igual aos agendamentos)
  Future<void> _marcarComoPaga(Transacao transacao) async {
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    final statusConfig = {
      'Pendente': {
        'cor': Colors.orange,
        'icone': Icons.pending_outlined,
        'label': 'Pendente',
        'subtitle': null,
      },
      'Pago': {
        'cor': Colors.green,
        'icone': Icons.payments_outlined,
        'label': 'Pago',
        'subtitle': 'Marca como pago e registra despesa',
      },
      'Reagendar': {
        'cor': Colors.blue,
        'icone': Icons.event_repeat,
        'label': 'Reagendar',
        'subtitle': 'Adia para 7 dias depois',
      },
      'Cancelado': {
        'cor': Colors.red,
        'icone': Icons.cancel_outlined,
        'label': 'Cancelado',
        'subtitle': null,
      },
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
                  colors: [Colors.orange.shade50, Colors.white],
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
                        colors: [
                          Colors.orange.shade400,
                          Colors.orange.shade600,
                        ],
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
                    transacao.descricao,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormat.format(transacao.valor),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...statusConfig.entries.map((entry) {
                    final statusKey = entry.key;
                    final config = entry.value;
                    final cor = config['cor'] as MaterialColor;
                    final label = config['label'] as String;
                    final subtitle = config['subtitle'] as String?;
                    final isSelected =
                        statusKey == 'Pendente'; // Sempre pendente

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
                            subtitle != null
                                ? Text(
                                  subtitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
      // Marca como pago
      final transacoesProvider = context.read<TransacoesProvider>();
      final agendamentosProvider = context.read<AgendamentosProvider>();

      final transacaoAtualizada = Transacao(
        id: transacao.id,
        descricao: transacao.descricao,
        valor: transacao.valor,
        data: DateTime.now(),
        tipo: transacao.tipo,
        categoria: transacao.categoria,
        observacoes: transacao.observacoes,
        userId: transacao.userId,
        isFutura: false,
        agendamentoId: transacao.agendamentoId,
      );

      await transacoesProvider.atualizarTransacao(transacaoAtualizada);

      // Atualiza o agendamento vinculado para "Concluido" se existir
      if (transacao.agendamentoId != null &&
          transacao.agendamentoId!.isNotEmpty) {
        await agendamentosProvider.atualizarStatus(
          transacao.agendamentoId!,
          'Concluido',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Despesa paga e registrada (${currencyFormat.format(transacao.valor)})',
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
          ),
        );
      }
    } else if (novo == 'Reagendar') {
      // Reagenda para 7 dias depois
      final transacoesProvider = context.read<TransacoesProvider>();
      final novaData = transacao.data.add(const Duration(days: 7));
      final transacaoAtualizada = Transacao(
        id: transacao.id,
        descricao: transacao.descricao,
        valor: transacao.valor,
        data: novaData,
        tipo: transacao.tipo,
        categoria: transacao.categoria,
        observacoes: transacao.observacoes,
        userId: transacao.userId,
        isFutura: true,
        agendamentoId: transacao.agendamentoId,
      );

      await transacoesProvider.atualizarTransacao(transacaoAtualizada);

      if (mounted) {
        final dateFormat = DateFormat('dd/MM/yyyy');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.event_repeat, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Despesa reagendada para ${dateFormat.format(novaData)}',
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
          ),
        );
      }
    } else if (novo == 'Cancelado') {
      // Exclui a despesa
      final transacoesProvider = context.read<TransacoesProvider>();
      final agendamentosProvider = context.read<AgendamentosProvider>();

      // Cancela o agendamento vinculado se existir
      if (transacao.agendamentoId != null &&
          transacao.agendamentoId!.isNotEmpty) {
        await agendamentosProvider.atualizarStatus(
          transacao.agendamentoId!,
          'Cancelado',
        );
      }

      await transacoesProvider.removerTransacao(transacao.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.cancel, color: Colors.white),
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

  // Ação para editar a despesa a pagar
  void _editarDespesa(Transacao transacao) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NovaDespesaPage(transacao: transacao, isFutura: true),
      ),
    );
  }

  Future<void> _confirmarExclusao(Transacao transacao) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.warning_outlined,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Confirmar exclusão',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deseja realmente excluir esta despesa a pagar?',
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.trending_down,
                        color: Colors.orange.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          transacao.descricao,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '⚠️ Esta ação não pode ser desfeita',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () => Navigator.pop(ctx, false),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete_outline, size: 18),
                    SizedBox(width: 6),
                    Text('Excluir'),
                  ],
                ),
                onPressed: () => Navigator.pop(ctx, true),
              ),
            ],
          ),
    );

    if (confirmado == true && mounted) {
      await context.read<TransacoesProvider>().removerTransacao(transacao.id!);
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Despesa "${transacao.descricao}" excluída com sucesso',
                  ),
                ),
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

  CategoriaTransacao? _getCategoriaFromString(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'fornecedores':
        return CategoriaTransacao.fornecedores;
      case 'salários':
        return CategoriaTransacao.salarios;
      case 'aluguel':
        return CategoriaTransacao.aluguel;
      case 'marketing':
        return CategoriaTransacao.marketing;
      case 'equipamentos':
        return CategoriaTransacao.equipamentos;
      case 'impostos':
        return CategoriaTransacao.impostos;
      case 'manutenção':
        return CategoriaTransacao.manutencao;
      case 'outros':
        return CategoriaTransacao.outros;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Despesas a Pagar',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade600, Colors.orange.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: GestureDetector(
        onHorizontalDragEnd: _mudarCategoriaPorSwipe,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.orange.shade50, Colors.white, Colors.white],
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
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.call_received,
                        color: Colors.orange.shade700,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'A Pagar',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Despesas futuras previstas',
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
                  final despesasFuturas = provider.despesasAPagar;
                  final Map<String, int> contagemCategoria = {};
                  contagemCategoria['Todas'] = despesasFuturas.length;
                  for (var categoria in _categorias) {
                    if (categoria == 'Todas') continue;
                    final cat = _getCategoriaFromString(categoria);
                    contagemCategoria[categoria] =
                        despesasFuturas.where((d) => d.categoria == cat).length;
                  }
                  return _buildCategoriaFilterBar(contagemCategoria);
                },
              ),
              Expanded(
                child: Consumer<TransacoesProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final listaFiltrada =
                        provider.despesasAPagar.where((despesa) {
                          final filtroCategoria =
                              _filtroSelecionado == 'Todas' ||
                              despesa.categoria ==
                                  _getCategoriaFromString(_filtroSelecionado);
                          final filtroBusca =
                              _termoBusca.isEmpty ||
                              despesa.descricao.toLowerCase().contains(
                                _termoBusca.toLowerCase(),
                              );
                          return filtroCategoria && filtroBusca;
                        }).toList();

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
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Nenhuma despesa a pagar',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tente ajustar os filtros ou adicionar uma nova',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
                      itemCount: listaFiltrada.length,
                      itemBuilder: (context, index) {
                        return _buildDespesaCard(listaFiltrada[index]);
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
        onPressed: () => _abrirFormulario(),
        tooltip: 'Nova despesa a pagar',
        icon: const Icon(Icons.add),
        label: const Text('Nova A Pagar'),
        backgroundColor: Colors.orange.shade600,
      ),
    );
  }

  // ✅ Card de despesa a pagar moderno
  Widget _buildDespesaCard(Transacao despesa) {
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Cor e ícone baseado na categoria
    Color categoriaColor;
    IconData categoriaIcon;
    switch (despesa.categoria) {
      case CategoriaTransacao.fornecedores:
        categoriaColor = Colors.indigo;
        categoriaIcon = Icons.local_shipping_outlined;
        break;
      case CategoriaTransacao.salarios:
        categoriaColor = Colors.teal;
        categoriaIcon = Icons.people_outlined;
        break;
      case CategoriaTransacao.aluguel:
        categoriaColor = Colors.brown;
        categoriaIcon = Icons.home_outlined;
        break;
      case CategoriaTransacao.marketing:
        categoriaColor = Colors.pink;
        categoriaIcon = Icons.campaign_outlined;
        break;
      case CategoriaTransacao.equipamentos:
        categoriaColor = Colors.blueGrey;
        categoriaIcon = Icons.computer_outlined;
        break;
      case CategoriaTransacao.impostos:
        categoriaColor = Colors.red;
        categoriaIcon = Icons.receipt_long_outlined;
        break;
      case CategoriaTransacao.manutencao:
        categoriaColor = Colors.cyan;
        categoriaIcon = Icons.handyman_outlined;
        break;
      default:
        categoriaColor = Colors.grey;
        categoriaIcon = Icons.category_outlined;
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.0),
        onTap: () => _editarDespesa(despesa),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
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
                // Categoria chip e badge futura no topo
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: categoriaColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: categoriaColor, width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(categoriaIcon, size: 16, color: categoriaColor),
                          const SizedBox(width: 4),
                          Text(
                            despesa.categoria.nome,
                            style: TextStyle(
                              color: categoriaColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
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
                const SizedBox(height: 16),
                // Informações da despesa
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.shade100,
                            Colors.orange.shade50,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.call_received,
                        color: Colors.orange.shade700,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            despesa.descricao,
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
                                dateFormat.format(despesa.data),
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
                if (despesa.observacoes != null &&
                    despesa.observacoes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notes,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            despesa.observacoes!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                // Valor e ações na parte de baixo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Badge com valor
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Valor',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currencyFormat.format(despesa.valor),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    // Menu de opções
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
                          _visualizarDespesa(despesa);
                        } else if (value == 'editar') {
                          _editarDespesa(despesa);
                        } else if (value == 'status') {
                          _marcarComoPaga(despesa);
                        } else if (value == 'excluir') {
                          _confirmarExclusao(despesa);
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
                                    Icons.check_circle_outline,
                                    color: Colors.teal.shade600,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text('Marcar Paga'),
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
            hintText: 'Buscar por descrição...',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            prefixIcon: Icon(Icons.search, color: Colors.orange.shade600),
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

  Widget _buildCategoriaFilterBar(Map<String, int> contagem) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      height: 50,
      child: ListView.builder(
        controller: _categoriaScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categorias.length,
        itemBuilder: (context, index) {
          final categoria = _categorias[index];
          final selecionado = _filtroSelecionado == categoria;

          // Ícones e cores por categoria
          IconData icone;
          MaterialColor cor;
          switch (categoria.toLowerCase()) {
            case 'todas':
              icone = Icons.dashboard;
              cor = Colors.purple;
              break;
            case 'fornecedores':
              icone = Icons.local_shipping_outlined;
              cor = Colors.indigo;
              break;
            case 'salários':
              icone = Icons.people_outlined;
              cor = Colors.teal;
              break;
            case 'aluguel':
              icone = Icons.home_outlined;
              cor = Colors.brown;
              break;
            case 'marketing':
              icone = Icons.campaign_outlined;
              cor = Colors.pink;
              break;
            case 'equipamentos':
              icone = Icons.computer_outlined;
              cor = Colors.blueGrey;
              break;
            case 'impostos':
              icone = Icons.receipt_long_outlined;
              cor = Colors.red;
              break;
            case 'manutenção':
              icone = Icons.handyman_outlined;
              cor = Colors.cyan;
              break;
            case 'outros':
              icone = Icons.category_outlined;
              cor = Colors.grey;
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
                    _filtroSelecionado = categoria;
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
                        categoria,
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
                          '${contagem[categoria] ?? 0}',
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
}
