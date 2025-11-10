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
import 'novo_recibo/etapas_bar.dart';
import 'novo_recibo/rodape_recibo.dart';
import 'novo_recibo/etapa_orcamento.dart';
import 'novo_recibo/etapa_cliente.dart';
import 'novo_recibo/etapa_itens.dart';
import 'novo_recibo/etapa_valores.dart';

class NovoReciboPage extends StatefulWidget {
  final Recibo? recibo; // se fornecido, modo edição
  const NovoReciboPage({super.key, this.recibo});

  @override
  State<NovoReciboPage> createState() => _NovoReciboPageState();
}

class _NovoReciboPageState extends State<NovoReciboPage> {
  int etapaAtual = 0; // 0: Orçamento, 1: Cliente, 2: Itens, 3: Valores
  Orcamento? _orcamentoSelecionado;
  Cliente? _clienteSelecionado;
  final List<Map<String, dynamic>> _itens = [];
  final List<ValorRecebido> _valores = [];
  bool _salvando = false;

  bool get _isEdicao => widget.recibo != null;

  final List<Map<String, dynamic>> etapas = [
    {'icon': Icons.receipt_long, 'label': 'Orçamento'},
    {'icon': Icons.person, 'label': 'Cliente'},
    {'icon': Icons.shopping_cart, 'label': 'Itens'},
    {'icon': Icons.attach_money, 'label': 'Valores'},
  ];

  @override
  void initState() {
    super.initState();
    // Pré-carrega dados em modo edição
    final r = widget.recibo;
    if (r != null) {
      _clienteSelecionado = r.cliente;
      _itens.addAll(r.itens.map((e) => Map<String, dynamic>.from(e)));
      _valores.addAll(r.valoresRecebidos);
    }
  }

  @override
  void dispose() {
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
      MaterialPageRoute(
        builder: (_) => const SelecionarServicosPage(
          textoBotao: 'Adicionar ao Recibo',
        ),
      ),
    );
    if (item != null) setState(() => _itens.add(item));
  }

  Future<void> _adicionarPeca() async {
    final item = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => const SelecionarPecasPage(
          textoBotao: 'Adicionar ao Recibo',
        ),
      ),
    );
    if (item != null) setState(() => _itens.add(item));
  }

  void _removerItem(int i) {
    setState(() => _itens.removeAt(i));
  }

  void _removerValor(int i) {
    setState(() => _valores.removeAt(i));
  }

  Future<void> _adicionarValorRecebido() async {
    final vr = await Navigator.push<ValorRecebido>(
      context,
      MaterialPageRoute(builder: (_) => const NovoValorRecebidoPage()),
    );
    if (vr != null) setState(() => _valores.add(vr));
  }

  void _proximaEtapa() {
    // Validação de cliente na etapa 1
    if (etapaAtual == 1 && _clienteSelecionado == null) {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Por favor, selecione um cliente para continuar.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    // Validação de itens na etapa 2
    if (etapaAtual == 2 && _itens.isEmpty) {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Adicione pelo menos um item para continuar.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    if (etapaAtual < etapas.length - 1) {
      setState(() => etapaAtual++);
    } else {
      _salvar();
    }
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdicao ? 'Editar Recibo' : 'Novo Recibo'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          EtapasBar(
            etapas: etapas,
            etapaAtual: etapaAtual,
            onEtapaTapped: (index) {
              setState(() {
                etapaAtual = index;
              });
            },
          ),
          Expanded(child: _buildConteudoEtapa()),
        ],
      ),
      bottomNavigationBar: RodapeRecibo(
        valorTotal: _valorTotal,
        isUltimaEtapa: etapaAtual == etapas.length - 1,
        isSaving: _salvando,
        onRevisarESalvar: _salvar,
        onProximaEtapa: _proximaEtapa,
      ),
    );
  }

  Widget _buildConteudoEtapa() {
    switch (etapaAtual) {
      case 0:
        return EtapaOrcamentoWidget(
          orcamentoSelecionado: _orcamentoSelecionado,
          onSelecionarOrcamento: _selecionarOrcamento,
        );
      case 1:
        return EtapaClienteWidget(
          clienteSelecionado: _clienteSelecionado,
          onSelecionarCliente: _selecionarCliente,
        );
      case 2:
        return EtapaItensWidget(
          itens: _itens,
          onAdicionarServico: _adicionarServico,
          onAdicionarPeca: _adicionarPeca,
          onRemoverItem: _removerItem,
        );
      case 3:
        return EtapaValoresWidget(
          valores: _valores,
          onAdicionarValor: _adicionarValorRecebido,
          onRemoverValor: _removerValor,
        );
      default:
        return Center(
          child: Text(
            'Conteúdo da etapa: ${etapas[etapaAtual]['label']}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
        );
    }
  }
}
