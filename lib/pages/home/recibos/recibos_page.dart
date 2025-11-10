import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/recibo.dart';
import '../../../providers/recibos_provider.dart';
import '../../../routes/app_routes.dart';
import 'novo_recibo_page.dart';
import 'revisar_recibo_page.dart';
import 'compartilhar_recibo_page.dart';

class RecibosPage extends StatefulWidget {
  const RecibosPage({super.key});

  @override
  State<RecibosPage> createState() => _RecibosPageState();
}

class _RecibosPageState extends State<RecibosPage> {
  String filtroStatus = 'Aberto';
  final TextEditingController _searchController = TextEditingController();
  String _termoBusca = '';

  final List<String> _status = ['Todos', 'Aberto', 'Emitido', 'Cancelado'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<RecibosProvider>().carregarRecibos());

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

  Future<void> _abrirNovo() async {
    await Navigator.pushNamed(context, AppRoutes.novoRecibo);
  }

  Future<void> _excluir(Recibo r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
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
                  'Deseja realmente excluir o recibo?',
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.tag,
                            size: 18,
                            color: Colors.blueGrey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '#${r.numero.toString().padLeft(4, '0')}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            color: Colors.grey.shade600,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              r.cliente.nome,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
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
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                onPressed: () => Navigator.pop(context, true),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete_outline, size: 18),
                    SizedBox(width: 6),
                    Text('Excluir'),
                  ],
                ),
              ),
            ],
          ),
    );
    if (ok == true) {
      await context.read<RecibosProvider>().excluirRecibo(r.id);
      if (mounted) {
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
                      'Recibo #${r.numero.toString().padLeft(4, '0')} excluído com sucesso',
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
  }

  void _revisar(Recibo r) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RevisarReciboPage(recibo: r)),
    );
  }

  void _compartilhar(Recibo r) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CompartilharReciboPage(recibo: r)),
    );
  }

  void _editar(Recibo r) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NovoReciboPage(recibo: r)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy');
    final nf = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recibos',
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
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade50, Colors.white, Colors.white],
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
                      Icons.receipt_outlined,
                      color: Colors.teal.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seus Recibos',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Gerencie e compartilhe',
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
            Consumer<RecibosProvider>(
              builder: (context, provider, child) {
                final Map<String, int> contagemStatus = {};
                contagemStatus['Todos'] = provider.recibos.length;
                for (var status in _status) {
                  if (status == 'Todos') continue;
                  contagemStatus[status] =
                      provider.recibos
                          .where((rec) => rec.status == status)
                          .length;
                }
                return _buildStatusFilterBar(contagemStatus);
              },
            ),
            Expanded(
              child: Consumer<RecibosProvider>(
                builder: (_, prov, __) {
                  if (prov.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final lista =
                      prov.recibos.where((r) {
                        final filtroStatusMatch =
                            filtroStatus == 'Todos' || r.status == filtroStatus;
                        final filtroBusca = r.cliente.nome
                            .toLowerCase()
                            .contains(_termoBusca.toLowerCase());
                        return filtroStatusMatch && filtroBusca;
                      }).toList();

                  if (lista.isEmpty) {
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
                            'Nenhum recibo encontrado',
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

                  return RefreshIndicator(
                    onRefresh: prov.carregarRecibos,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
                      itemCount: lista.length,
                      itemBuilder: (_, i) {
                        final r = lista[i];
                        return _buildReciboCard(r, df, nf);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirNovo,
        tooltip: 'Novo recibo',
        icon: const Icon(Icons.add),
        label: const Text('Novo Recibo'),
        backgroundColor: Colors.teal.shade600,
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
            prefixIcon: Icon(Icons.search, color: Colors.teal.shade600),
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
          final selecionado = filtroStatus == status;

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
            case 'emitido':
              icone = Icons.check_circle_outline;
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
                    filtroStatus = status;
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

  Widget _buildReciboCard(Recibo recibo, DateFormat df, NumberFormat nf) {
    final theme = Theme.of(context);

    // Cor dinâmica baseada no status
    Color statusColor;
    IconData statusIcon;
    switch (recibo.status.toLowerCase()) {
      case 'aberto':
        statusColor = Colors.orange;
        statusIcon = Icons.pending_outlined;
        break;
      case 'emitido':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'cancelado':
        statusColor = Colors.red;
        statusIcon = Icons.cancel_outlined;
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
        onTap: () => _revisar(recibo),
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
                    // Badge com número do recibo
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.teal.shade400, Colors.teal.shade600],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.shade200,
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
                            '#${recibo.numero.toString().padLeft(4, '0')}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status chip
                    Container(
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
                            recibo.status,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
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
                            recibo.cliente.nome,
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
                                df.format(recibo.criadoEm.toDate()),
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
                          nf.format(recibo.valorTotal),
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
                      onSelected: (v) {
                        if (v == 'revisar') {
                          _revisar(recibo);
                        } else if (v == 'compartilhar') {
                          _compartilhar(recibo);
                        } else if (v == 'editar') {
                          _editar(recibo);
                        } else if (v == 'excluir') {
                          _excluir(recibo);
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
                              value: 'compartilhar',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.share_outlined,
                                    color: Colors.purple.shade600,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text('Compartilhar'),
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
}
