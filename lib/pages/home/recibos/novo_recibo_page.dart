import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/cliente.dart';
import '../../../models/orcamento.dart';
import '../../../models/recibo.dart';
import 'revisar_recibo_page.dart';
import '../../../models/valor_recebido.dart';
import '../../../providers/orcamentos_provider.dart';
import '../../../providers/recibos_provider.dart';
import '../../home/orcamentos/novo_orcamento/selecionar_servicos_page.dart';
import '../../home/orcamentos/novo_orcamento/selecionar_pecas_page.dart';
import '../../home/tabs/clientes_page.dart';
import 'novo_valor_recebido_page.dart';

class NovoReciboPage extends StatefulWidget {
  final Recibo? recibo; // se fornecido, modo edição
  const NovoReciboPage({super.key, this.recibo});

  @override
  State<NovoReciboPage> createState() => _NovoReciboPageState();
}

class _NovoReciboPageState extends State<NovoReciboPage>
    with SingleTickerProviderStateMixin {
  int aba = 0; // 0 Infos Básicas, 1 Valores Recebidos
  late TabController _tabController;
  Orcamento? _orcamentoSelecionado;
  Cliente? _clienteSelecionado;
  final List<Map<String, dynamic>> _itens = [];
  final List<ValorRecebido> _valores = [];
  bool _salvando = false;

  bool get _isEdicao => widget.recibo != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() => aba = _tabController.index);
    });
    // Pré-carrega dados em modo edição
    final r = widget.recibo;
    if (r != null) {
      _clienteSelecionado = r.cliente;
      _itens.addAll(r.itens.map((e) => Map<String, dynamic>.from(e)));
      _valores.addAll(r.valoresRecebidos);
      // Não reconstruímos Orcamento; apenas mantemos numero para exibir.
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  double get _subtotalItens {
    double s = 0;
    for (final item in _itens) {
      final preco = (item['preco'] ?? 0).toDouble();
      final qtd = (item['quantidade'] ?? 1).toDouble();
      s += preco * qtd;
    }
    return s;
  }

  double get _totalValores => _valores.fold(0, (a, v) => a + v.valor);
  double get _valorTotal => _itens.isNotEmpty ? _subtotalItens : _totalValores;

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
        _orcamentoSelecionado = selecionado;
        _clienteSelecionado = selecionado.cliente;
        _itens
            .clear(); // inicialmente não importa itens do orçamento; usuário pode adicionar manual
      });
    }
  }

  Future<void> _selecionarCliente() async {
    final c = await Navigator.push<Cliente>(
      context,
      MaterialPageRoute(builder: (_) => const ClientesPage(isPickerMode: true)),
    );
    if (c != null) setState(() => _clienteSelecionado = c);
  }

  Future<void> _adicionarServico() async {
    final item = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const SelecionarServicosPage()),
    );
    if (item != null) setState(() => _itens.add(item));
  }

  Future<void> _adicionarPeca() async {
    final item = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const SelecionarPecasPage()),
    );
    if (item != null) setState(() => _itens.add(item));
  }

  void _removerItem(int i) {
    setState(() => _itens.removeAt(i));
  }

  Future<void> _adicionarValorRecebido() async {
    final vr = await Navigator.push<ValorRecebido>(
      context,
      MaterialPageRoute(builder: (_) => const NovoValorRecebidoPage()),
    );
    if (vr != null) setState(() => _valores.add(vr));
  }

  Future<void> _salvar() async {
    if (!_isEdicao &&
        (_orcamentoSelecionado == null || _clienteSelecionado == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione orçamento e cliente.')),
      );
      return;
    }
    if (_itens.isEmpty && _valores.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione itens ou valores recebidos.')),
      );
      return;
    }
    setState(() => _salvando = true);
    final prov = context.read<RecibosProvider>();
    try {
      Recibo salvo;
      if (_isEdicao) {
        final original = widget.recibo!;
        final atualizado = original.copyWith(
          cliente: _clienteSelecionado ?? original.cliente,
          itens: List<Map<String, dynamic>>.from(_itens),
          valoresRecebidos: List<ValorRecebido>.from(_valores),
          subtotalItens: _subtotalItens,
          totalValoresRecebidos: _totalValores,
          valorTotal: _valorTotal,
          atualizadoEm: Timestamp.now(),
        );
        await prov.atualizarRecibo(atualizado);
        salvo = atualizado;
      } else {
        final reciboBase = Recibo(
          id: '',
          numero: 0,
          orcamentoId: _orcamentoSelecionado!.id,
          orcamentoNumero: _orcamentoSelecionado!.numero,
          cliente: _clienteSelecionado!,
          itens: List<Map<String, dynamic>>.from(_itens),
          valoresRecebidos: List<ValorRecebido>.from(_valores),
          subtotalItens: _subtotalItens,
          totalValoresRecebidos: _totalValores,
          valorTotal: _valorTotal,
          status: 'Aberto',
          criadoEm: Timestamp.now(),
          atualizadoEm: Timestamp.now(),
        );
        salvo = await prov.adicionarRecibo(reciboBase);
      }
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => RevisarReciboPage(recibo: salvo)),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
    if (mounted) setState(() => _salvando = false);
  }

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return Scaffold(
      appBar: AppBar(title: Text(_isEdicao ? 'Editar Recibo' : 'Novo Recibo')),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Infos Básicas'),
              Tab(text: 'Valores Recebidos'),
            ],
          ),
          Expanded(
            child: IndexedStack(
              index: aba,
              children: [_buildInfosBasicas(), _buildValoresRecebidos()],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Valor Total',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      nf.format(_valorTotal),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed:
                    _salvando
                        ? null
                        : () {
                          if (aba == 0) {
                            _tabController.animateTo(1);
                          } else {
                            _salvar();
                          }
                        },
                child: Text(
                  aba == 0
                      ? 'Próximo'
                      : _isEdicao
                      ? 'Atualizar e Revisar'
                      : 'Revisar e Enviar',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfosBasicas() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          title: const Text('Orçamento'),
          subtitle: Text(
            _isEdicao
                ? (widget.recibo!.orcamentoNumero != null
                    ? '#${widget.recibo!.orcamentoNumero!.toString().padLeft(4, '0')}'
                    : '—')
                : _orcamentoSelecionado == null
                ? 'Selecionar'
                : '#${_orcamentoSelecionado!.numero.toString().padLeft(4, '0')} - ${_orcamentoSelecionado!.cliente.nome}',
          ),
          trailing: _isEdicao ? null : const Icon(Icons.search),
          onTap: _isEdicao ? null : _selecionarOrcamento,
        ),
        const SizedBox(height: 12),
        ListTile(
          title: const Text('Cliente'),
          subtitle: Text(_clienteSelecionado?.nome ?? 'Selecionar'),
          trailing: _isEdicao ? null : const Icon(Icons.person_search),
          onTap: _isEdicao ? null : _selecionarCliente,
        ),
        const SizedBox(height: 24),
        const Text(
          'Itens (Serviços / Produtos)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: _adicionarServico,
              icon: const Icon(Icons.home_repair_service),
              label: const Text('Serviço'),
            ),
            ElevatedButton.icon(
              onPressed: _adicionarPeca,
              icon: const Icon(Icons.build),
              label: const Text('Produto/Peça'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_itens.isEmpty)
          const Text('Nenhum item adicionado.')
        else
          ...List.generate(_itens.length, (i) {
            final it = _itens[i];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(it['nome'] ?? 'Item'),
              subtitle: Text(
                'Qtd: ${it['quantidade'] ?? 1}  Preço: ${(it['preco'] ?? 0)}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _removerItem(i),
              ),
            );
          }),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildValoresRecebidos() {
    final df = DateFormat('dd/MM/yyyy');
    final nf = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _adicionarValorRecebido,
              icon: const Icon(Icons.attach_money),
              label: const Text('Valor Recebido'),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _adicionarServico,
              icon: const Icon(Icons.home_repair_service),
              label: const Text('Serviço'),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _adicionarPeca,
              icon: const Icon(Icons.build),
              label: const Text('Produto'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_valores.isEmpty)
          const Text('Nenhum valor recebido.')
        else
          ..._valores.map(
            (v) => ListTile(
              title: Text(nf.format(v.valor)),
              subtitle: Text(
                '${df.format(v.data.toDate())} - ${v.formaPagamento}',
              ),
            ),
          ),
        const Divider(height: 32),
        Text(
          'Soma Valores Recebidos: ' + nf.format(_totalValores),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_itens.isNotEmpty)
          Text(
            'Subtotal Itens (substitui valores): ' + nf.format(_subtotalItens),
            style: const TextStyle(color: Colors.blueAccent),
          ),
        const SizedBox(height: 80),
      ],
    );
  }
}
