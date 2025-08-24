import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/despesa.dart';
import '../../../providers/despesas_provider.dart';
import '../../../routes/app_routes.dart';

class DespesasPage extends StatefulWidget {
  const DespesasPage({super.key});

  @override
  State<DespesasPage> createState() => _DespesasPageState();
}

class _DespesasPageState extends State<DespesasPage> {
  String filtroForma = 'Todas';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<DespesasProvider>().carregarDespesas());
  }

  Future<void> _abrirNova() async {
    await Navigator.pushNamed(context, AppRoutes.novaDespesa);
  }

  Future<void> _excluir(Despesa d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Excluir despesa'),
            content: Text(
              'Excluir despesa #${d.numero.toString().padLeft(4, '0')}?',
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
      await context.read<DespesasProvider>().excluirDespesa(d.id);
    }
  }

  void _editar(Despesa d) {
    Navigator.pushNamed(context, AppRoutes.novaDespesa, arguments: d);
  }

  void _visualizar(Despesa d) {
    final df = DateFormat('dd/MM/yyyy');
    final nf = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Despesa #${d.numero.toString().padLeft(4, '0')}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Data: ${df.format(d.data.toDate())}'),
                Text('Valor: ${nf.format(d.valor)}'),
                Text('Forma: ${d.formaPagamento}'),
                if (d.orcamentoNumero != null)
                  Text(
                    'Orçamento: #${d.orcamentoNumero!.toString().padLeft(4, '0')}',
                  ),
                if (d.cliente != null) Text('Cliente: ${d.cliente!.nome}'),
                const SizedBox(height: 8),
                Text('Descrição:'),
                Text(d.descricao.isEmpty ? '—' : d.descricao),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy');
    final nf = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Despesas'),
        actions: [
          PopupMenuButton<String>(
            initialValue: filtroForma,
            onSelected: (v) => setState(() => filtroForma = v),
            itemBuilder:
                (_) => [
                  const PopupMenuItem(value: 'Todas', child: Text('Todas')),
                  const PopupMenuItem(value: 'Pix', child: Text('Pix')),
                  const PopupMenuItem(
                    value: 'Dinheiro',
                    child: Text('Dinheiro'),
                  ),
                  const PopupMenuItem(value: 'Crédito', child: Text('Crédito')),
                  const PopupMenuItem(value: 'Débito', child: Text('Débito')),
                ],
          ),
        ],
      ),
      body: Consumer<DespesasProvider>(
        builder: (_, prov, __) {
          if (prov.isLoading)
            return const Center(child: CircularProgressIndicator());
          final lista =
              prov.despesas
                  .where(
                    (d) =>
                        filtroForma == 'Todas' ||
                        d.formaPagamento == filtroForma,
                  )
                  .toList();
          if (lista.isEmpty)
            return const Center(child: Text('Nenhuma despesa.'));
          return RefreshIndicator(
            onRefresh: prov.carregarDespesas,
            child: ListView.builder(
              itemCount: lista.length,
              itemBuilder: (_, i) {
                final d = lista[i];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(
                      '#${d.numero.toString().padLeft(4, '0')}  ${nf.format(d.valor)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${df.format(d.data.toDate())} • ${d.formaPagamento}${d.cliente != null ? ' • ${d.cliente!.nome}' : ''}',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'ver')
                          _visualizar(d);
                        else if (v == 'editar')
                          _editar(d);
                        else if (v == 'excluir')
                          _excluir(d);
                      },
                      itemBuilder:
                          (_) => const [
                            PopupMenuItem(
                              value: 'ver',
                              child: ListTile(
                                leading: Icon(Icons.visibility_outlined),
                                title: Text('Visualizar'),
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
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirNova,
        child: const Icon(Icons.add),
      ),
    );
  }
}
