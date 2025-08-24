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

  final List<String> _status = ['Todos', 'Aberto', 'Enviado', 'Concluído'];

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
            title: const Text('Confirmar exclusão'),
            content: Text(
              'Deseja realmente excluir o orçamento para "${orcamento.cliente.nome}"?',
            ),
            actions: [
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () => Navigator.pop(ctx, false),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                child: const Text('Excluir'),
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
            content: Text(
              'Orçamento para "${orcamento.cliente.nome}" excluído.',
            ),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  Future<void> _mostrarDialogoStatus(Orcamento orcamento) async {
    final novoStatus = await showDialog<String>(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: const Text('Alterar Status'),
            children:
                _status.where((s) => s != 'Todos').map((status) {
                  return SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, status),
                    child: Text(status),
                  );
                }).toList(),
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
        title: const Text('Orçamentos Criados'),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Orçamentos',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
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
                              orc.status.toLowerCase() == status.toLowerCase(),
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
                  return const Center(
                    child: Text(
                      'Nenhum orçamento encontrado.',
                      style: TextStyle(color: Colors.grey),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        tooltip: 'Novo orçamento',
        child: const Icon(Icons.add),
      ),
    );
  }

  // ✅ CORREÇÃO: Card de orçamento agora usa um PopupMenuButton para as ações
  Widget _buildOrcamentoCard(Orcamento orcamento) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          12,
          12,
          0,
          12,
        ), // Ajuste no padding direito
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#${orcamento.numero.toString().padLeft(4, '0')}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                InkWell(
                  onTap: () => _mostrarDialogoStatus(orcamento),
                  borderRadius: BorderRadius.circular(20),
                  child: Chip(
                    label: Text(
                      orcamento.status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor:
                        Colors.blueGrey, // Pode ser dinâmico no futuro
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.secondaryContainer,
                child: Icon(
                  Icons.person_outline,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
              title: Text(
                orcamento.cliente.nome,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Criado em: ${dateFormat.format(orcamento.dataCriacao.toDate())}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currencyFormat.format(orcamento.valorTotal),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                      fontSize: 16,
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Mais opções',
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
                          const PopupMenuItem<String>(
                            value: 'revisar',
                            child: ListTile(
                              leading: Icon(Icons.visibility_outlined),
                              title: Text('Visualizar/Revisar'),
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'editar',
                            child: ListTile(
                              leading: Icon(Icons.edit_outlined),
                              title: Text('Editar'),
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem<String>(
                            value: 'excluir',
                            child: ListTile(
                              leading: Icon(Icons.delete_outline),
                              title: Text('Excluir'),
                            ),
                          ),
                        ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar por cliente...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon:
              _termoBusca.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _searchController.clear(),
                  )
                  : null,
          filled: true,
          fillColor: Colors.grey.shade200,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusFilterBar(Map<String, int> contagem) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(_status.length, (index) {
          final status = _status[index];
          final selecionado = _filtroSelecionado == status;
          final theme = Theme.of(context);

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text('$status (${contagem[status] ?? 0})'),
              selected: selecionado,
              onSelected: (_) {
                setState(() {
                  _filtroSelecionado = status;
                });
              },
              selectedColor: theme.colorScheme.primary,
              labelStyle: TextStyle(
                color:
                    selecionado ? theme.colorScheme.onPrimary : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color:
                      selecionado ? Colors.transparent : Colors.grey.shade300,
                ),
              ),
              showCheckmark: false,
            ),
          );
        }),
      ),
    );
  }
}
