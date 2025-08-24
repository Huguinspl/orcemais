import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/despesa.dart';
import '../../../models/orcamento.dart';
import '../../../models/cliente.dart';
import '../../../providers/despesas_provider.dart';
import '../../../providers/orcamentos_provider.dart';
import '../../home/tabs/clientes_page.dart';

class NovaDespesaPage extends StatefulWidget {
  final Despesa? despesa;
  const NovaDespesaPage({super.key, this.despesa});

  @override
  State<NovaDespesaPage> createState() => _NovaDespesaPageState();
}

class _NovaDespesaPageState extends State<NovaDespesaPage> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _data;
  final _valorCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  String _forma = 'Dinheiro';
  Orcamento? _orcamento;
  Cliente? _cliente;
  bool _salvando = false;

  bool get _isEdicao => widget.despesa != null;

  @override
  void initState() {
    super.initState();
    if (_isEdicao) {
      final d = widget.despesa!;
      _data = d.data.toDate();
      _valorCtrl.text = d.valor.toStringAsFixed(2);
      _descricaoCtrl.text = d.descricao;
      _forma = d.formaPagamento;
      // orçamento e cliente não reconstruímos completamente; apenas exibiremos número/nome
    } else {
      _data = DateTime.now();
    }
  }

  @override
  void dispose() {
    _valorCtrl.dispose();
    _descricaoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickData() async {
    final sel = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (sel != null) setState(() => _data = sel);
  }

  Future<void> _selecionarOrcamento() async {
    final prov = context.read<OrcamentosProvider>();
    if (prov.orcamentos.isEmpty) await prov.carregarOrcamentos();
    final selecionado = await showModalBottomSheet<Orcamento>(
      context: context,
      builder:
          (_) => ListView(
            children: [
              const ListTile(title: Text('Selecionar Orçamento')),
              ...prov.orcamentos.map(
                (o) => ListTile(
                  title: Text(
                    '#${o.numero.toString().padLeft(4, '0')} - ${o.cliente.nome}',
                  ),
                  subtitle: Text(
                    DateFormat('dd/MM/yyyy').format(o.dataCriacao.toDate()),
                  ),
                  onTap: () => Navigator.pop(context, o),
                ),
              ),
            ],
          ),
    );
    if (selecionado != null) {
      setState(() {
        _orcamento = selecionado;
        _cliente = selecionado.cliente;
      });
    }
  }

  Future<void> _selecionarCliente() async {
    final c = await Navigator.push<Cliente>(
      context,
      MaterialPageRoute(builder: (_) => const ClientesPage(isPickerMode: true)),
    );
    if (c != null) setState(() => _cliente = c);
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isEdicao && _orcamento == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecione um orçamento.')));
      return;
    }
    setState(() => _salvando = true);
    final prov = context.read<DespesasProvider>();
    try {
      final valor = double.tryParse(_valorCtrl.text.replaceAll(',', '.')) ?? 0;
      if (_isEdicao) {
        final original = widget.despesa!;
        final atualizado = original.copyWith(
          data: Timestamp.fromDate(_data),
          valor: valor,
          formaPagamento: _forma,
          descricao: _descricaoCtrl.text.trim(),
          atualizadoEm: Timestamp.now(),
        );
        await prov.atualizarDespesa(atualizado);
        if (mounted) Navigator.pop(context);
      } else {
        final base = Despesa(
          id: '',
          numero: 0,
          data: Timestamp.fromDate(_data),
          valor: valor,
          formaPagamento: _forma,
          orcamentoId: _orcamento?.id,
          orcamentoNumero: _orcamento?.numero,
          cliente: _cliente,
          descricao: _descricaoCtrl.text.trim(),
          criadoEm: Timestamp.now(),
          atualizadoEm: Timestamp.now(),
        );
        await prov.adicionarDespesa(base);
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
    if (mounted) setState(() => _salvando = false);
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy');
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdicao ? 'Editar Despesa' : 'Nova Despesa'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              title: const Text('Data'),
              subtitle: Text(df.format(_data)),
              trailing: const Icon(Icons.calendar_month),
              onTap: _pickData,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _valorCtrl,
              decoration: const InputDecoration(
                labelText: 'Valor (R\$)',
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (v) {
                final valor = double.tryParse(v?.replaceAll(',', '.') ?? '');
                if (valor == null || valor <= 0) return 'Informe valor > 0';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _forma,
              decoration: const InputDecoration(
                labelText: 'Forma de Pagamento',
              ),
              items: const [
                DropdownMenuItem(value: 'Dinheiro', child: Text('Dinheiro')),
                DropdownMenuItem(value: 'Pix', child: Text('Pix')),
                DropdownMenuItem(value: 'Crédito', child: Text('Crédito')),
                DropdownMenuItem(value: 'Débito', child: Text('Débito')),
              ],
              onChanged: (v) => setState(() => _forma = v!),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: const Text('Orçamento'),
              subtitle: Text(
                _orcamento == null && !_isEdicao
                    ? 'Selecionar'
                    : _isEdicao && widget.despesa!.orcamentoNumero != null
                    ? '#${widget.despesa!.orcamentoNumero!.toString().padLeft(4, '0')}'
                    : _orcamento != null
                    ? '#${_orcamento!.numero.toString().padLeft(4, '0')} - ${_orcamento!.cliente.nome}'
                    : '—',
              ),
              trailing: _isEdicao ? null : const Icon(Icons.search),
              onTap: _isEdicao ? null : _selecionarOrcamento,
            ),
            const SizedBox(height: 8),
            ListTile(
              title: const Text('Cliente'),
              subtitle: Text(
                _cliente?.nome ??
                    (_isEdicao && widget.despesa!.cliente != null
                        ? widget.despesa!.cliente!.nome
                        : 'Selecionar'),
              ),
              trailing: _isEdicao ? null : const Icon(Icons.person_search),
              onTap: _isEdicao ? null : _selecionarCliente,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descricaoCtrl,
              decoration: const InputDecoration(labelText: 'Descrição'),
              maxLines: 3,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _salvando ? null : _salvar,
              child: Text(_isEdicao ? 'Salvar Alterações' : 'Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
