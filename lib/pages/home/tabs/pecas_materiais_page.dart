import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/pecas_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../models/peca_material.dart';
import 'visualizar_peca_page.dart';

class PecasMateriaisPage extends StatefulWidget {
  final bool isPickerMode;

  const PecasMateriaisPage({super.key, this.isPickerMode = false});

  @override
  State<PecasMateriaisPage> createState() => _PecasMateriaisPageState();
}

class _PecasMateriaisPageState extends State<PecasMateriaisPage> {
  final _searchController = TextEditingController();
  String _termoBusca = '';

  @override
  void initState() {
    super.initState();
    // ✅ CORREÇÃO: Usar Future.microtask para evitar setState durante build
    Future.microtask(
      () => Provider.of<PecasProvider>(context, listen: false).fetchPecas(),
    );
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _termoBusca = _searchController.text;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _termoBusca = '';
    });
  }

  void _usarParaOrcamento(PecaMaterial peca) {
    // Navegar para novo orçamento passando a peça como argumento
    Navigator.pushNamed(
      context,
      AppRoutes.novoOrcamento,
      arguments: {
        'servicoInicial': {
          'tipo': 'peca',
          'descricao': peca.nome,
          'detalhe': '',
          'preco': peca.preco ?? 0.0,
          'custo': 0.0,
          'quantidade': 1,
          'subtotal': peca.preco ?? 0.0,
        },
      },
    );
  }

  void _abrirVisualizacao(PecaMaterial peca) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VisualizarPecaPage(peca: peca)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PecasProvider>(
      builder: (context, provider, child) {
        final pecasFiltradas =
            provider.itens.where((PecaMaterial peca) {
              return peca.nome.toLowerCase().contains(
                _termoBusca.toLowerCase(),
              );
            }).toList();

        return _buildScaffold(context, provider, pecasFiltradas);
      },
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    PecasProvider provider,
    List<PecaMaterial> pecasFiltradas,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isPickerMode ? 'Selecione um Produto' : 'Peças e Materiais',
          style: const TextStyle(fontWeight: FontWeight.w600),
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
      body: Container(
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
                      Icons.handyman,
                      color: Colors.orange.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Suas Peças',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Gerencie seu estoque',
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
            _buildPecaCountBar(provider),
            Expanded(child: _buildContent(provider, pecasFiltradas)),
          ],
        ),
      ),
      floatingActionButton:
          widget.isPickerMode
              ? null
              : FloatingActionButton.extended(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.novoPecaMaterial);
                },
                icon: const Icon(Icons.add),
                label: const Text('Nova Peça'),
                backgroundColor: Colors.orange.shade600,
                elevation: 4,
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
            hintText: 'Buscar por nome da peça...',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            prefixIcon: Icon(Icons.search, color: Colors.orange.shade600),
            suffixIcon:
                _termoBusca.isNotEmpty
                    ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey.shade600),
                      onPressed: _clearSearch,
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

  Widget _buildPecaCountBar(PecasProvider provider) {
    final total = provider.itens.length;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(25),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.orange.shade600],
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.dashboard, size: 18, color: Colors.white),
                  const SizedBox(width: 6),
                  const Text(
                    'Total',
                    style: TextStyle(
                      color: Colors.white,
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
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$total',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    PecasProvider provider,
    List<PecaMaterial> pecasFiltradas,
  ) {
    if (provider.itens.isEmpty) {
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
                Icons.inventory_2_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Nenhuma peça cadastrada',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Toque em "Nova Peça" para adicionar',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    if (pecasFiltradas.isEmpty) {
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
              'Nenhum resultado encontrado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tente ajustar os filtros ou criar uma nova',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return _buildPecasList(provider, pecasFiltradas);
  }

  // <-- CORREÇÃO 2: O método agora aceita o 'provider' como parâmetro.
  Widget _buildPecasList(PecasProvider provider, List<PecaMaterial> pecas) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
      itemCount: pecas.length,
      itemBuilder: (context, index) {
        final peca = pecas[index];
        return _buildPecaCard(provider, peca);
      },
    );
  }

  Widget _buildPecaCard(PecasProvider provider, PecaMaterial peca) {
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.0),
        onTap: () {
          if (widget.isPickerMode) {
            Navigator.pop(context, {
              'nome': peca.nome,
              'preco': peca.preco ?? 0.0,
              'quantidade': 1.0,
              'unidade': '',
              'custo': 0.0,
              'descricao': '',
              'marca': '',
              'modelo': '',
              'codigoProduto': '',
              'codigoInterno': '',
            });
          } else {
            _abrirVisualizacao(peca);
          }
        },
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
                    // Badge com ícone da peça
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.shade400,
                            Colors.orange.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.shade200,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.handyman, size: 16, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Peça',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Chip de preço
                    if (peca.preco != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.orange.shade400,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.attach_money,
                              size: 16,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              currencyFormat.format(peca.preco),
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          'Sem preço',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Informações da peça
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.shade100,
                            Colors.orange.shade200,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.construction,
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
                            peca.nome,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            peca.preco != null
                                ? currencyFormat.format(peca.preco)
                                : 'Preço não definido',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
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
                          'Valor da Peça',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          peca.preco != null
                              ? currencyFormat.format(peca.preco)
                              : 'N/D',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
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
                        switch (value) {
                          case 'orcamento':
                            _usarParaOrcamento(peca);
                            break;
                          case 'editar':
                            Navigator.pushNamed(
                              context,
                              AppRoutes.novoPecaMaterial,
                              arguments: peca,
                            );
                            break;
                          case 'excluir':
                            _showDeleteConfirmationDialog(
                              context,
                              provider,
                              peca,
                            );
                            break;
                        }
                      },
                      itemBuilder:
                          (BuildContext context) => <PopupMenuEntry<String>>[
                            PopupMenuItem<String>(
                              value: 'orcamento',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.receipt_long,
                                    color: Colors.blue.shade600,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text('Usar para Orçamento'),
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

  Future<void> _showDeleteConfirmationDialog(
    BuildContext context,
    PecasProvider provider,
    PecaMaterial peca,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red.shade600,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Confirmar exclusão'),
            ],
          ),
          content: Text(
            'Deseja realmente excluir a peça "${peca.nome}"?\n\nEsta ação não pode ser desfeita.',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text('Excluir'),
              onPressed: () {
                provider.deletePeca(peca.id);
                Navigator.of(dialogContext).pop();

                // Usar o context do Scaffold, não o do dialog
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 12),
                          Expanded(child: Text('"${peca.nome}" foi excluído.')),
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
              },
            ),
          ],
        );
      },
    );
  }
}
