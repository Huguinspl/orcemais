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
              colors: [Colors.indigo.shade600, Colors.indigo.shade400],
            ),
          ),
        ),
        title: Text(
          widget.isPickerMode ? 'Selecione um Cliente' : 'Clientes',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo.shade50, Colors.white, Colors.white],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildSearchBar(),
            if (!widget.isPickerMode) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.people_outlined,
                        color: Colors.indigo.shade700,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Seus Clientes',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Consumer<ClientsProvider>(
                          builder: (_, prov, __) {
                            return Text(
                              '${prov.clientes.length} ${prov.clientes.length == 1 ? 'cliente cadastrado' : 'clientes cadastrados'}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
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
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Nenhum cliente cadastrado',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Comece adicionando seu primeiro cliente',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

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
                            'Nenhum cliente encontrado',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tente buscar com outro termo',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return _buildClientList(listaFiltrada);
                },
              ),
            ),
          ],
        ),
      ),
      // <-- MUDANÇA: O botão agora aparece em ambos os modos
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        tooltip: 'Novo cliente',
        icon: const Icon(Icons.add),
        label: const Text('Novo Cliente'),
        backgroundColor: Colors.indigo.shade600,
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
            hintText: '🔍 Buscar por nome...',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            prefixIcon: Icon(Icons.search, color: Colors.indigo.shade600),
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

  Widget _buildClientList(List<Cliente> clientes) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
      itemCount: clientes.length,
      itemBuilder: (_, i) => _item(clientes[i]),
    );
  }

  Widget _item(Cliente c) {
    final iniciais = c.nome.isNotEmpty ? c.nome[0].toUpperCase() : '?';

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap:
            widget.isPickerMode
                ? () {
                  Navigator.pop(context, c);
                }
                : null,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.grey.shade50],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar com gradiente
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.indigo.shade400, Colors.indigo.shade600],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.shade200,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      iniciais,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Informações do cliente
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.nome,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (c.celular.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_android,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                c.celular,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (c.email.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.email_outlined,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                c.email,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Ações
                if (widget.isPickerMode)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.chevron_right,
                      color: Colors.indigo.shade600,
                    ),
                  )
                else
                  PopupMenuButton<String>(
                    tooltip: 'Opções',
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.more_vert, color: Colors.grey.shade700),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    onSelected: (value) {
                      if (value == 'editar') {
                        _abrirFormulario(original: c);
                      } else if (value == 'excluir') {
                        _confirmarExclusao(c);
                      }
                    },
                    itemBuilder:
                        (BuildContext context) => <PopupMenuEntry<String>>[
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
                  'Deseja realmente excluir o cliente?',
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
                          cliente.nome,
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

    if (ok == true && mounted) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await Provider.of<ClientsProvider>(
          context,
          listen: false,
        ).excluir(uid, cliente.id);

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
                        'Cliente "${cliente.nome}" excluído com sucesso',
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
  }
}
