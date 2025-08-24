import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/pecas_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../models/peca_material.dart';

class PecasMateriaisPage extends StatefulWidget {
  const PecasMateriaisPage({super.key});

  @override
  State<PecasMateriaisPage> createState() => _PecasMateriaisPageState();
}

class _PecasMateriaisPageState extends State<PecasMateriaisPage> {
  final _searchController = TextEditingController();
  String _termoBusca = '';

  @override
  void initState() {
    super.initState();
    Provider.of<PecasProvider>(context, listen: false).fetchPecas();
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PecasProvider>();

    final pecasFiltradas =
        provider.itens.where((PecaMaterial peca) {
          return peca.nome.toLowerCase().contains(_termoBusca.toLowerCase());
        }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Peças e Materiais'), centerTitle: true),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildContent(provider, pecasFiltradas)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.novoPecaMaterial);
        },
        tooltip: 'Adicionar Peça',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar por nome...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon:
              _termoBusca.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearSearch,
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

  Widget _buildContent(
    PecasProvider provider,
    List<PecaMaterial> pecasFiltradas,
  ) {
    if (provider.itens.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma peça cadastrada ainda. 🤷‍♂️\nClique em "+" para adicionar.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    if (pecasFiltradas.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum resultado encontrado. 🧐',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // <-- CORREÇÃO 1: Passando o 'provider' para o método da lista.
    return _buildPecasList(provider, pecasFiltradas);
  }

  // <-- CORREÇÃO 2: O método agora aceita o 'provider' como parâmetro.
  Widget _buildPecasList(PecasProvider provider, List<PecaMaterial> pecas) {
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: pecas.length,
      itemBuilder: (context, index) {
        final peca = pecas[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: Text(
              peca.nome,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle:
                peca.preco != null
                    ? Text(
                      currencyFormat.format(peca.preco),
                      style: TextStyle(color: Colors.green.shade700),
                    )
                    : const Text('Preço não definido'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.novoPecaMaterial,
                      arguments: peca,
                    );
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () {
                    // Agora a chamada funciona, pois 'provider' e 'peca' estão disponíveis
                    _showDeleteConfirmationDialog(context, provider, peca);
                  },
                ),
              ],
            ),
          ),
        );
      },
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
          title: const Text('Confirmar Exclusão'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Você tem certeza que deseja excluir a peça "${peca.nome}"?',
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Excluir'),
              onPressed: () {
                provider.deletePeca(peca.id);
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"${peca.nome}" foi excluído.'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
