import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import para formatação de moeda
import 'package:provider/provider.dart';
import '../../../providers/services_provider.dart';
import '../../../models/servico.dart';
import 'novo_servico_page.dart';

class ServicosPage extends StatefulWidget {
  const ServicosPage({super.key});

  @override
  State<ServicosPage> createState() => _ServicosPageState();
}

class _ServicosPageState extends State<ServicosPage> {
  final _searchController = TextEditingController();
  String _termoBusca = '';

  @override
  void initState() {
    super.initState();
    _carregarServicos();
    _searchController.addListener(() {
      setState(() {
        _termoBusca = _searchController.text;
      });
    });
  }

  Future<void> _carregarServicos() async {
    if (!mounted) return;
    await Provider.of<ServicesProvider>(
      context,
      listen: false,
    ).carregarServicos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
  }

  Future<void> _abrirFormulario({Servico? original}) async {
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NovoServicoPage(original: original)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Catálogo de Serviços'),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(),
          // ✅ MUDANÇA: Adicionando o título da seção para consistência
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Serviços Cadastrados',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Consumer<ServicesProvider>(
              builder: (_, prov, __) {
                if (prov.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final listaFiltrada =
                    prov.servicos.where((servico) {
                      return servico.titulo.toLowerCase().contains(
                        _termoBusca.toLowerCase(),
                      );
                    }).toList();

                if (prov.servicos.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhum serviço cadastrado ainda. 🤷‍♂️',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                if (listaFiltrada.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhum serviço encontrado. 🧐',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return _buildServiceList(listaFiltrada);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        tooltip: 'Novo Serviço',
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
          hintText: 'Buscar por nome do serviço...',
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

  Widget _buildServiceList(List<Servico> servicos) {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: servicos.length,
      itemBuilder: (_, i) => _item(servicos[i]),
    );
  }

  Widget _item(Servico servico) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.build_outlined,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          servico.titulo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          servico.descricao,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ MUDANÇA: Adicionando o preço do serviço ao card
            Text(
              currencyFormat.format(servico.preco),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            IconButton(
              icon: Icon(Icons.edit_outlined, color: theme.colorScheme.primary),
              tooltip: 'Editar',
              onPressed: () => _abrirFormulario(original: servico),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              tooltip: 'Excluir',
              onPressed: () => _confirmarExclusao(servico),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarExclusao(Servico servico) async {
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirmar exclusão'),
            content: Text(
              'Deseja realmente excluir o serviço "${servico.titulo}"?',
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
      try {
        await Provider.of<ServicesProvider>(
          context,
          listen: false,
        ).excluirServico(servico.id);

        if (mounted) {
          ScaffoldMessenger.of(context)
            ..removeCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text('Serviço "${servico.titulo}" excluído.'),
                backgroundColor: Colors.red,
              ),
            );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
            ..removeCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text('Erro ao excluir: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
        }
      }
    }
  }
}
