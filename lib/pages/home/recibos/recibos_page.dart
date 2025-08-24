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
  String filtroStatus = 'Todos';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<RecibosProvider>().carregarRecibos());
  }

  Future<void> _abrirNovo() async {
    await Navigator.pushNamed(context, AppRoutes.novoRecibo);
  }

  Future<void> _excluir(Recibo r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Excluir recibo'),
            content: Text(
              'Excluir recibo #${r.numero.toString().padLeft(4, '0')}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Excluir'),
              ),
            ],
          ),
    );
    if (ok == true) {
      await context.read<RecibosProvider>().excluirRecibo(r.id);
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
        title: const Text('Recibos'),
        actions: [
          PopupMenuButton<String>(
            initialValue: filtroStatus,
            onSelected: (v) => setState(() => filtroStatus = v),
            itemBuilder:
                (_) => const [
                  PopupMenuItem(value: 'Todos', child: Text('Todos')),
                  PopupMenuItem(value: 'Aberto', child: Text('Aberto')),
                  PopupMenuItem(value: 'Emitido', child: Text('Emitido')),
                  PopupMenuItem(value: 'Cancelado', child: Text('Cancelado')),
                ],
          ),
        ],
      ),
      body: Consumer<RecibosProvider>(
        builder: (_, prov, __) {
          if (prov.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final lista =
              prov.recibos
                  .where(
                    (r) => filtroStatus == 'Todos' || r.status == filtroStatus,
                  )
                  .toList();
          if (lista.isEmpty) {
            return const Center(child: Text('Nenhum recibo.'));
          }
          return RefreshIndicator(
            onRefresh: prov.carregarRecibos,
            child: ListView.builder(
              itemCount: lista.length,
              itemBuilder: (_, i) {
                final r = lista[i];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '#${r.numero.toString().padLeft(4, '0')}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Chip(
                              label: Text(
                                r.status,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor: Colors.blueGrey,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey.shade300,
                            child: const Icon(Icons.person_outline),
                          ),
                          title: Text(
                            r.cliente.nome,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Criado em: ${df.format(r.criadoEm.toDate())}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                nf.format(r.valorTotal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              PopupMenuButton<String>(
                                tooltip: 'Mais opções',
                                onSelected: (v) {
                                  if (v == 'revisar') {
                                    _revisar(r);
                                  } else if (v == 'compartilhar') {
                                    _compartilhar(r);
                                  } else if (v == 'editar') {
                                    _editar(r);
                                  } else if (v == 'excluir') {
                                    _excluir(r);
                                  }
                                },
                                itemBuilder:
                                    (_) => const [
                                      PopupMenuItem(
                                        value: 'revisar',
                                        child: ListTile(
                                          leading: Icon(
                                            Icons.visibility_outlined,
                                          ),
                                          title: Text('Visualizar/Revisar'),
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'compartilhar',
                                        child: ListTile(
                                          leading: Icon(Icons.share_outlined),
                                          title: Text('Compartilhar'),
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'editar',
                                        child: ListTile(
                                          leading: Icon(Icons.edit_outlined),
                                          title: Text('Editar'),
                                        ),
                                      ),
                                      PopupMenuDivider(),
                                      PopupMenuItem(
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
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirNovo,
        child: const Icon(Icons.add),
      ),
    );
  }
}
