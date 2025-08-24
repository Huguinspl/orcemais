import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../models/agendamento.dart';
import '../../../../models/orcamento.dart';
import '../../../../providers/agendamentos_provider.dart';
import '../../../../providers/orcamentos_provider.dart';

class NovoAgendamentoPage extends StatefulWidget {
  final Agendamento? agendamento;
  const NovoAgendamentoPage({super.key, this.agendamento});

  @override
  State<NovoAgendamentoPage> createState() => _NovoAgendamentoPageState();
}

class _NovoAgendamentoPageState extends State<NovoAgendamentoPage> {
  final _formKey = GlobalKey<FormState>();
  Timestamp? _dataHora;
  String _status = 'Pendente';
  String _observacoes = '';
  Orcamento? _orcamentoSelecionado;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final ag = widget.agendamento;
    if (ag != null) {
      _dataHora = ag.dataHora;
      _status = ag.status;
      _observacoes = ag.observacoes;
      // Buscar orçamento correspondente se necessário
      final orcProv = context.read<OrcamentosProvider>();
      _orcamentoSelecionado = orcProv.orcamentos.firstWhere(
        (o) => o.id == ag.orcamentoId,
        orElse:
            () => Orcamento(
              id: ag.orcamentoId,
              numero: ag.orcamentoNumero ?? 0,
              cliente:
                  (orcProv.orcamentos.isNotEmpty
                      ? orcProv.orcamentos.first.cliente
                      : throw Exception(
                        'Cliente não carregado',
                      )), // fallback mínimo
              itens: const [],
              subtotal: 0,
              desconto: 0,
              valorTotal: 0,
              status: 'Aberto',
              dataCriacao: ag.criadoEm,
            ),
      );
    }
    // Garante que orçamentos estejam carregados para seleção
    if (context.read<OrcamentosProvider>().orcamentos.isEmpty) {
      context.read<OrcamentosProvider>().carregarOrcamentos();
    }
  }

  Future<void> _selecionarDataHora() async {
    final agora = DateTime.now();
    final data = await showDatePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
      initialDate: _dataHora?.toDate() ?? agora,
    );
    if (data == null) return;
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dataHora?.toDate() ?? agora),
    );
    if (hora == null) return;
    final combinado = DateTime(
      data.year,
      data.month,
      data.day,
      hora.hour,
      hora.minute,
    );
    setState(() => _dataHora = Timestamp.fromDate(combinado));
  }

  Future<void> _selecionarOrcamento() async {
    final orcProv = context.read<OrcamentosProvider>();
    if (orcProv.orcamentos.isEmpty) {
      await orcProv.carregarOrcamentos();
    }
    final selecionado = await showModalBottomSheet<Orcamento>(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        final lista = orcProv.orcamentos;
        return DraggableScrollableSheet(
          expand: false,
          builder:
              (_, scroll) => Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      'Selecionar Orçamento',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scroll,
                      itemCount: lista.length,
                      itemBuilder: (_, i) {
                        final o = lista[i];
                        return ListTile(
                          title: Text(
                            '#${o.numero.toString().padLeft(4, '0')} - ${o.cliente.nome}',
                          ),
                          subtitle: Text(
                            'Criado em ${DateFormat('dd/MM/yyyy').format(o.dataCriacao.toDate())}',
                          ),
                          onTap: () => Navigator.pop(context, o),
                        );
                      },
                    ),
                  ),
                ],
              ),
        );
      },
    );
    if (selecionado != null) {
      setState(() => _orcamentoSelecionado = selecionado);
    }
  }

  Future<void> _salvar() async {
    if (_orcamentoSelecionado == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecione um orçamento.')));
      return;
    }
    if (_dataHora == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Defina data e hora.')));
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _salvando = true);
    final provider = context.read<AgendamentosProvider>();
    try {
      if (widget.agendamento == null) {
        await provider.adicionarAgendamento(
          orcamentoId: _orcamentoSelecionado!.id,
          orcamentoNumero: _orcamentoSelecionado!.numero,
          clienteNome: _orcamentoSelecionado!.cliente.nome,
          dataHora: _dataHora!,
          status: _status,
          observacoes: _observacoes,
        );
      } else {
        await provider.atualizarAgendamento(
          widget.agendamento!.copyWith(
            orcamentoId: _orcamentoSelecionado!.id,
            orcamentoNumero: _orcamentoSelecionado!.numero,
            clienteNome: _orcamentoSelecionado!.cliente.nome,
            dataHora: _dataHora!,
            status: _status,
            observacoes: _observacoes,
          ),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
    }
    if (mounted) setState(() => _salvando = false);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.agendamento == null
              ? 'Novo Agendamento'
              : 'Editar Agendamento',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Orçamento'),
              subtitle: Text(
                _orcamentoSelecionado == null
                    ? 'Nenhum selecionado'
                    : '#${_orcamentoSelecionado!.numero.toString().padLeft(4, '0')} - ${_orcamentoSelecionado!.cliente.nome}',
              ),
              trailing: const Icon(Icons.search),
              onTap: _selecionarOrcamento,
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Data e Hora'),
              subtitle: Text(
                _dataHora == null
                    ? 'Selecionar'
                    : dateFormat.format(_dataHora!.toDate()),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selecionarDataHora,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: 'Pendente', child: Text('Pendente')),
                DropdownMenuItem(
                  value: 'Confirmado',
                  child: Text('Confirmado'),
                ),
                DropdownMenuItem(value: 'Concluido', child: Text('Concluído')),
                DropdownMenuItem(value: 'Cancelado', child: Text('Cancelado')),
              ],
              onChanged: (v) => setState(() => _status = v ?? 'Pendente'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _observacoes,
              decoration: const InputDecoration(
                labelText: 'Observações',
                border: OutlineInputBorder(),
              ),
              minLines: 3,
              maxLines: 5,
              onSaved: (v) => _observacoes = v?.trim() ?? '',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _salvando ? null : _salvar,
                icon:
                    _salvando
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.save),
                label: Text(_salvando ? 'Salvando...' : 'Salvar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
