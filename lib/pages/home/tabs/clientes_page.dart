import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/cliente.dart';
import '../../../providers/clients_provider.dart';
import 'novo_cliente_page.dart';

class ClientesPage extends StatefulWidget {
  final bool isPickerMode;

  const ClientesPage({super.key, this.isPickerMode = false});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  final _searchController = TextEditingController();
  String _termoBusca = '';

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      Future.microtask(() {
        if (mounted) {
          Provider.of<ClientsProvider>(
            context,
            listen: false,
          ).carregarTodos(uid);
        }
      });
    }
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

  void _clearSearch() {
    _searchController.clear();
  }

  Future<void> _abrirFormulario({Cliente? original}) async {
    FocusScope.of(context).unfocus();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NovoClientePage(original: original)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade600, Colors.blue.shade400],
            ),
          ),
        ),
        title: Text(widget.isPickerMode ? 'Selecione um Cliente' : 'Clientes'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: Consumer<ClientsProvider>(
              builder: (_, prov, __) {
                final listaFiltrada =
                    prov.clientes.where((cliente) {
                      return cliente.nome.toLowerCase().contains(
                        _termoBusca.toLowerCase(),
                      );
                    }).toList();

                if (prov.clientes.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhum cliente cadastrado ainda. 🤷‍♂️',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return _buildClientList(listaFiltrada);
              },
            ),
          ),
        ],
      ),
      // <-- MUDANÇA: O botão agora aparece em ambos os modos
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        tooltip: 'Novo cliente',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar por nome...',
          prefixIcon: Icon(Icons.search, color: Colors.blue.shade600),
          suffixIcon:
              _termoBusca.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearSearch,
                    color: Colors.blue.shade600,
                  )
                  : null,
          filled: true,
          fillColor: Colors.blue.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.blue.shade300, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildClientList(List<Cliente> clientes) {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: clientes.length,
      itemBuilder: (_, i) => _item(clientes[i]),
    );
  }

  Widget _item(Cliente c) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.blue.shade50.withOpacity(0.3)],
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          onTap:
              widget.isPickerMode
                  ? () {
                    Navigator.pop(context, c);
                  }
                  : null,
          leading: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
              ),
            ),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                c.nome.isNotEmpty ? c.nome[0].toUpperCase() : '?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
          ),
          title: Text(
            c.nome,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: c.celular.isNotEmpty ? Text(c.celular) : null,
          trailing:
              widget.isPickerMode
                  ? Icon(Icons.chevron_right, color: Colors.blue.shade600)
                  : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.edit_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        tooltip: 'Editar',
                        onPressed: () => _abrirFormulario(original: c),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: theme.colorScheme.error,
                        ),
                        tooltip: 'Excluir',
                        onPressed: () => _confirmarExclusao(c),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }

  Future<void> _confirmarExclusao(Cliente cliente) async {
    FocusScope.of(context).unfocus();

    final bool? ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirmar exclusão'),
            content: Text('Deseja excluir o cliente "${cliente.nome}"?'),
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

    if (ok == true && mounted) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cliente "${cliente.nome}" excluído.'),
            backgroundColor: Colors.red,
          ),
        );
        await Provider.of<ClientsProvider>(
          context,
          listen: false,
        ).excluir(uid, cliente.id);
      }
    }
  }
}
