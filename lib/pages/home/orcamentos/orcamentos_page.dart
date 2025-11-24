import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/orcamento.dart';
import '../../../providers/orcamentos_provider.dart';
import 'novo_orcamento_page.dart';
import 'revisar_orcamento_page.dart'; // Importe a página de revisão

class OrcamentosPage extends StatefulWidget {
  const OrcamentosPage({super.key});

  @override
  State<OrcamentosPage> createState() => _OrcamentosPageState();
}

class _OrcamentosPageState extends State<OrcamentosPage> {
  final TextEditingController _searchController = TextEditingController();
  String _filtroSelecionado = 'Aberto';
  String _termoBusca = '';

  final List<String> _status = [
    'Todos',
    'Aberto',
    'Enviado',
    'Aprovado',
    'Recusado',
    'Concluído',
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<OrcamentosProvider>(
        context,
        listen: false,
      ).carregarOrcamentos();
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
    super.dispose();
  }

  Future<void> _abrirFormulario({Orcamento? orcamento}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NovoOrcamentoPage(orcamento: orcamento),
      ),
    );
  }

  // ✅ NOVA FUNÇÃO: Ação para visualizar/revisar o orçamento
  void _revisarOrcamento(Orcamento orcamento) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RevisarOrcamentoPage(orcamento: orcamento),
      ),
    );
  }

  Future<void> _confirmarExclusao(Orcamento orcamento) async {
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
                  'Deseja realmente excluir o orçamento?',
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
                      Icon(Icons.person, color: Colors.grey.shade600, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          orcamento.cliente.nome,
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
      await context.read<OrcamentosProvider>().excluirOrcamento(orcamento.id);
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
                    'Orçamento de "${orcamento.cliente.nome}" excluído com sucesso',
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

  Future<void> _mostrarDialogoStatus(Orcamento orcamento) async {
    final novoStatus = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.edit_note, color: Colors.blue.shade700),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Alterar Status',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  _status.where((s) => s != 'Todos').map((status) {
                    IconData icone;
                    Color cor;
                    switch (status.toLowerCase()) {
                      case 'aberto':
                        icone = Icons.pending_outlined;
                        cor = Colors.orange;
                        break;
                      case 'enviado':
                        icone = Icons.send_outlined;
                        cor = Colors.blue;
                        break;
                      case 'aprovado':
                        icone = Icons.check_circle_outline;
                        cor = const Color(0xFF10B981);
                        break;
                      case 'recusado':
                        icone = Icons.cancel_outlined;
                        cor = const Color(0xFFEF4444);
                        break;
                      case 'concluído':
                        icone = Icons.task_alt;
                        cor = Colors.green;
                        break;
                      default:
                        icone = Icons.info_outline;
                        cor = Colors.grey;
                    }

                    final selecionado = orcamento.status == status;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.pop(context, status),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  selecionado
                                      ? cor.withOpacity(0.1)
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selecionado ? cor : Colors.grey.shade300,
                                width: selecionado ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(icone, color: cor),
                                const SizedBox(width: 12),
                                Text(
                                  status,
                                  style: TextStyle(
                                    fontWeight:
                                        selecionado
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                    color: cor,
                                    fontSize: 15,
                                  ),
                                ),
                                if (selecionado) ...[
                                  const Spacer(),
                                  Icon(
                                    Icons.check_circle,
                                    color: cor,
                                    size: 20,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
    );

    if (novoStatus != null && novoStatus != orcamento.status && mounted) {
      await context.read<OrcamentosProvider>().atualizarStatus(
        orcamento.id,
        novoStatus,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Orçamentos Criados',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.blue.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
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
            const SizedBox(height: 16),
            _buildSearchBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.description_outlined,
                      color: Colors.blue.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seus Orçamentos',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Gerencie e acompanhe',
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
            Consumer<OrcamentosProvider>(
              builder: (context, provider, child) {
                final Map<String, int> contagemStatus = {};
                contagemStatus['Todos'] = provider.orcamentos.length;
                for (var status in _status) {
                  if (status == 'Todos') continue;
                  contagemStatus[status] =
                      provider.orcamentos
                          .where(
                            (orc) =>
                                orc.status.toLowerCase() ==
                                status.toLowerCase(),
                          )
                          .length;
                }
                return _buildStatusFilterBar(contagemStatus);
              },
            ),
            Expanded(
              child: Consumer<OrcamentosProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final listaFiltrada =
                      provider.orcamentos.where((orc) {
                        final filtroStatus =
                            _filtroSelecionado == 'Todos' ||
                            orc.status.toLowerCase() ==
                                _filtroSelecionado.toLowerCase();
                        final filtroBusca = orc.cliente.nome
                            .toLowerCase()
                            .contains(_termoBusca.toLowerCase());
                        return filtroStatus && filtroBusca;
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
                            'Nenhum orçamento encontrado',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tente ajustar os filtros ou criar um novo',
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
                      return _buildOrcamentoCard(listaFiltrada[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        tooltip: 'Novo orçamento',
        icon: const Icon(Icons.add),
        label: const Text('Novo Orçamento'),
        backgroundColor: Colors.blue.shade600,
      ),
    );
  }

  // ✅ Card de orçamento moderno e acessível
  Widget _buildOrcamentoCard(Orcamento orcamento) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Cor dinâmica baseada no status
    Color statusColor;
    IconData statusIcon;
    switch (orcamento.status.toLowerCase()) {
      case 'aberto':
        statusColor = Colors.orange;
        statusIcon = Icons.pending_outlined;
        break;
      case 'enviado':
        statusColor = Colors.blue;
        statusIcon = Icons.send_outlined;
        break;
      case 'aprovado':
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.check_circle_outline;
        break;
      case 'recusado':
        statusColor = const Color(0xFFEF4444);
        statusIcon = Icons.cancel_outlined;
        break;
      case 'concluído':
        statusColor = Colors.green;
        statusIcon = Icons.task_alt;
        break;
      default:
        statusColor = Colors.blueGrey;
        statusIcon = Icons.info_outline;
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.0),
        onTap: () => _revisarOrcamento(orcamento),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Badge com número do orçamento
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.blue.shade600],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade200,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.tag, size: 16, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            '#${orcamento.numero.toString().padLeft(4, '0')}',
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
                      onTap: () => _mostrarDialogoStatus(orcamento),
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
                              orcamento.status,
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
                          colors: [
                            theme.colorScheme.primaryContainer,
                            theme.colorScheme.secondaryContainer,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.person,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            orcamento.cliente.nome,
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
                                dateFormat.format(
                                  orcamento.dataCriacao.toDate(),
                                ),
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
                // Valor e ações
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Valor Total',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currencyFormat.format(orcamento.valorTotal),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                            fontSize: 20,
                          ),
                        ),
                      ],
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
                        if (value == 'revisar') {
                          _revisarOrcamento(orcamento);
                        } else if (value == 'editar') {
                          _abrirFormulario(orcamento: orcamento);
                        } else if (value == 'excluir') {
                          _confirmarExclusao(orcamento);
                        }
                      },
                      itemBuilder:
                          (BuildContext context) => <PopupMenuEntry<String>>[
                            PopupMenuItem<String>(
                              value: 'revisar',
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
            hintText: '🔍 Buscar por cliente...',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            prefixIcon: Icon(Icons.search, color: Colors.blue.shade600),
            suffixIcon:
                _termoBusca.isNotEmpty
                    ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey.shade600),
                      onPressed: () => _searchController.clear(),
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
            case 'aberto':
              icone = Icons.pending_outlined;
              cor = Colors.orange;
              break;
            case 'enviado':
              icone = Icons.send_outlined;
              cor = Colors.blue;
              break;
            case 'aprovado':
              icone = Icons.check_circle_outline;
              cor = Colors.green;
              break;
            case 'recusado':
              icone = Icons.cancel_outlined;
              cor = Colors.red;
              break;
            case 'concluído':
              icone = Icons.task_alt;
              cor = Colors.teal;
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
                        '$status',
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
}
