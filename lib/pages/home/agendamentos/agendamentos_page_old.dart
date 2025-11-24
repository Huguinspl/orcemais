import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../models/agendamento.dart';
import '../../../../providers/agendamentos_provider.dart';
import 'novo_agendamento_page.dart';

class AgendamentosPage extends StatefulWidget {
  const AgendamentosPage({super.key});

  @override
  State<AgendamentosPage> createState() => _AgendamentosPageState();
}

class _AgendamentosPageState extends State<AgendamentosPage> {
  String filtroStatus = 'Todos';

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<AgendamentosProvider>().carregarAgendamentos(),
    );
  }

  Future<void> _abrirFormulario({Agendamento? agendamento}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NovoAgendamentoPage(agendamento: agendamento),
      ),
    );
  }

  Future<void> _mudarStatus(Agendamento ag) async {
    final novo = await showDialog<String>(
      context: context,
      builder:
          (_) => SimpleDialog(
            title: const Text('Alterar status'),
            children: [
              for (final s in const [
                'Pendente',
                'Confirmado',
                'Concluido',
                'Cancelado',
              ])
                RadioListTile<String>(
                  title: Text(s),
                  value: s,
                  groupValue: ag.status,
                  onChanged: (v) => Navigator.pop(context, v),
                ),
            ],
          ),
    );
    if (novo != null && novo != ag.status) {
      await context.read<AgendamentosProvider>().atualizarStatus(ag.id, novo);
    }
  }

  Future<void> _confirmarExclusao(Agendamento ag) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Excluir agendamento'),
            content: Text(
              'Excluir agendamento do orçamento #${ag.orcamentoNumero?.toString().padLeft(4, '0') ?? '--'}?',
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
    if (confirmar == true) {
      await context.read<AgendamentosProvider>().excluirAgendamento(ag.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendamentos'),
        actions: [
          PopupMenuButton<String>(
            initialValue: filtroStatus,
            onSelected: (v) => setState(() => filtroStatus = v),
            itemBuilder:
                (_) => [
                  const PopupMenuItem(value: 'Todos', child: Text('Todos')),
                  const PopupMenuItem(
                    value: 'Pendente',
                    child: Text('Pendente'),
                  ),
                  const PopupMenuItem(
                    value: 'Confirmado',
                    child: Text('Confirmado'),
                  ),
                  const PopupMenuItem(
                    value: 'Concluido',
                    child: Text('Concluído'),
                  ),
                  const PopupMenuItem(
                    value: 'Cancelado',
                    child: Text('Cancelado'),
                  ),
                ],
          ),
        ],
      ),
      body: Consumer<AgendamentosProvider>(
        builder: (_, provider, __) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final lista =
              provider.agendamentos
                  .where(
                    (a) => filtroStatus == 'Todos' || a.status == filtroStatus,
                  )
                  .toList();
          if (lista.isEmpty) {
            return const Center(child: Text('Nenhum agendamento.'));
          }
          return RefreshIndicator(
            onRefresh: provider.carregarAgendamentos,
            child: ListView.builder(
              itemCount: lista.length,
              itemBuilder: (_, i) {
                final ag = lista[i];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    onTap: () => _abrirFormulario(agendamento: ag),
                    title: Text(
                      'Orçamento #${ag.orcamentoNumero?.toString().padLeft(4, '0') ?? '--'}',
                    ),
                    subtitle: Text(
                      '${ag.clienteNome ?? ''}\n${dateFormat.format(ag.dataHora.toDate())}',
                    ),
                    isThreeLine: true,
                    leading: const Icon(Icons.event_note),
                    trailing: PopupMenuButton(
                      onSelected: (value) {
                        if (value == 'status') _mudarStatus(ag);
                        if (value == 'excluir') _confirmarExclusao(ag);
                      },
                      itemBuilder:
                          (_) => const [
                            PopupMenuItem(
                              value: 'status',
                              child: Text('Alterar status'),
                            ),
                            PopupMenuItem(
                              value: 'excluir',
                              child: Text('Excluir'),
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
        onPressed: () => _abrirFormulario(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
