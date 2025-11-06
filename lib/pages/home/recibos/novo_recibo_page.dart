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

    // Filtra apenas orçamentos com status "Enviado"
    final orcamentosEnviados =
        prov.orcamentos.where((o) => o.status == 'Enviado').toList();

    if (orcamentosEnviados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum orçamento enviado disponível.')),
      );
      return;
    }

    final selecionado = await showModalBottomSheet<Orcamento>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (_) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder:
                (context, scrollController) => Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.receipt_long,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Selecionar Orçamento Enviado',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        children:
                            orcamentosEnviados.map((o) {
                              final nf = NumberFormat.currency(
                                locale: 'pt_BR',
                                symbol: 'R\$',
                              );
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                elevation: 2,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.orange.shade100,
                                    child: Text(
                                      '#${o.numero.toString().padLeft(4, '0')}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    o.cliente.nome,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        'Data: ${DateFormat('dd/MM/yyyy').format(o.dataCriacao.toDate())}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      Text(
                                        'Total: ${nf.format(o.valorTotal)}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green,
                                        ),
                                      ),
                                      Text(
                                        '${o.itens.length} ${o.itens.length == 1 ? 'item' : 'itens'}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Colors.grey.shade400,
                                  ),
                                  onTap: () => Navigator.pop(context, o),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ],
                ),
          ),
    );
    if (selecionado != null) {
      setState(() {
        _orcamentoSelecionado = selecionado;
        _clienteSelecionado = selecionado.cliente;
        // NOVO: Carrega os itens do orçamento automaticamente
        _itens.clear();
        _itens.addAll(
          selecionado.itens.map((e) => Map<String, dynamic>.from(e)),
        );
      });

      // Mostra mensagem de confirmação
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Orçamento #${selecionado.numero.toString().padLeft(4, '0')} carregado com ${selecionado.itens.length} ${selecionado.itens.length == 1 ? 'item' : 'itens'}',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
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
    // Validação: apenas cliente e itens são obrigatórios
    if (_clienteSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um cliente.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_itens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione pelo menos um item.'),
          backgroundColor: Colors.orange,
        ),
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
          orcamentoId: _orcamentoSelecionado?.id, // Opcional
          orcamentoNumero: _orcamentoSelecionado?.numero, // Opcional
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
    final nf = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Card de Orçamento (Opcional)
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade700, Colors.orange.shade500],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long, color: Colors.white),
                    const SizedBox(width: 12),
                    const Text(
                      'Orçamento (Opcional)',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'OPCIONAL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                title: Text(
                  _isEdicao
                      ? (widget.recibo!.orcamentoNumero != null
                          ? '#${widget.recibo!.orcamentoNumero!.toString().padLeft(4, '0')}'
                          : 'Sem orçamento vinculado')
                      : _orcamentoSelecionado == null
                      ? 'Nenhum orçamento vinculado'
                      : '#${_orcamentoSelecionado!.numero.toString().padLeft(4, '0')}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color:
                        _orcamentoSelecionado == null
                            ? Colors.grey
                            : Colors.black,
                  ),
                ),
                subtitle:
                    _orcamentoSelecionado != null
                        ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'Cliente: ${_orcamentoSelecionado!.cliente.nome}',
                            ),
                            Text(
                              'Data: ${DateFormat('dd/MM/yyyy').format(_orcamentoSelecionado!.dataCriacao.toDate())}',
                            ),
                            Text(
                              'Valor: ${nf.format(_orcamentoSelecionado!.valorTotal)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        )
                        : const Text(
                          'Você pode criar um recibo sem vincular a um orçamento. Apenas adicione o cliente e os itens.',
                          style: TextStyle(fontSize: 12),
                        ),
                trailing:
                    _isEdicao
                        ? null
                        : Icon(Icons.search, color: Colors.orange.shade700),
                onTap: _isEdicao ? null : _selecionarOrcamento,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Card de Cliente (Obrigatório)
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade700, Colors.blue.shade500],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Colors.white),
                    const SizedBox(width: 12),
                    const Text(
                      'Cliente',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade400,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'OBRIGATÓRIO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                title: Text(
                  _clienteSelecionado?.nome ?? 'Nenhum cliente selecionado',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color:
                        _clienteSelecionado == null
                            ? Colors.grey
                            : Colors.black,
                  ),
                ),
                subtitle:
                    _clienteSelecionado != null
                        ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_clienteSelecionado!.telefone.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text('Tel: ${_clienteSelecionado!.telefone}'),
                            ],
                            if (_clienteSelecionado!.email.isNotEmpty)
                              Text('Email: ${_clienteSelecionado!.email}'),
                          ],
                        )
                        : const Text('Toque para selecionar um cliente'),
                trailing:
                    _isEdicao
                        ? null
                        : Icon(
                          Icons.person_search,
                          color: Colors.blue.shade700,
                        ),
                onTap: _isEdicao ? null : _selecionarCliente,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Seção de Itens (Obrigatório)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'Itens (Serviços / Produtos)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'OBRIGATÓRIO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (_itens.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_itens.length} ${_itens.length == 1 ? 'item' : 'itens'}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade900,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: _adicionarServico,
              icon: const Icon(Icons.home_repair_service, size: 18),
              label: const Text('Serviço'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _adicionarPeca,
              icon: const Icon(Icons.build, size: 18),
              label: const Text('Produto/Peça'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_itens.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_outlined,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Adicione pelo menos um item (obrigatório). Você pode selecionar um orçamento ou adicionar itens manualmente.',
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Itens do Orçamento (${_itens.length})',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      NumberFormat.currency(
                        locale: 'pt_BR',
                        symbol: 'R\$',
                      ).format(_subtotalItens),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ...List.generate(_itens.length, (i) {
                final it = _itens[i];
                final preco = (it['preco'] ?? 0).toDouble();
                final qtd = (it['quantidade'] ?? 1).toDouble();
                final total = preco * qtd;
                final nf = NumberFormat.currency(
                  locale: 'pt_BR',
                  symbol: 'R\$',
                );
                final tipo = it['tipo'] ?? 'item'; // 'servico' ou 'peca'

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  elevation: 1,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor:
                          tipo == 'servico'
                              ? Colors.blue.shade50
                              : Colors.orange.shade50,
                      child: Icon(
                        tipo == 'servico'
                            ? Icons.home_repair_service
                            : Icons.build,
                        size: 20,
                        color:
                            tipo == 'servico'
                                ? Colors.blue.shade700
                                : Colors.orange.shade700,
                      ),
                    ),
                    title: Text(
                      it['nome'] ?? 'Item',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Qtd: ${qtd.toStringAsFixed(qtd.truncateToDouble() == qtd ? 0 : 2)}  •  Preço: ${nf.format(preco)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Total: ${nf.format(total)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red.shade400,
                      ),
                      onPressed: () => _removerItem(i),
                      tooltip: 'Remover item',
                    ),
                  ),
                );
              }),
            ],
          ),
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: _adicionarValorRecebido,
              icon: const Icon(Icons.attach_money, size: 18),
              label: const Text('Valor Recebido'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _adicionarServico,
              icon: const Icon(Icons.home_repair_service, size: 18),
              label: const Text('Serviço'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _adicionarPeca,
              icon: const Icon(Icons.build, size: 18),
              label: const Text('Produto'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Seção de Valores Recebidos
        if (_valores.isNotEmpty) ...[
          const Text(
            'Valores Recebidos',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Column(
            children:
                _valores.map((v) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 1,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.shade50,
                        child: Icon(
                          Icons.attach_money,
                          color: Colors.green.shade700,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        nf.format(v.valor),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        '${df.format(v.data.toDate())} - ${v.formaPagamento}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red.shade400,
                        ),
                        onPressed: () {
                          setState(() => _valores.remove(v));
                        },
                        tooltip: 'Remover valor',
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        const Divider(height: 1),
        const SizedBox(height: 16),

        // Resumo de Totais
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade50, Colors.green.shade100],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Soma Valores Recebidos:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  Text(
                    nf.format(_totalValores),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
              if (_itens.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Subtotal Itens (substitui valores):',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      nf.format(_subtotalItens),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}
