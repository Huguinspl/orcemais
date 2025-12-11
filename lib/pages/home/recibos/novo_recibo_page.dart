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
import 'novo_recibo/etapa_cliente_orcamento.dart';
import 'novo_recibo/etapa_itens_valores.dart';

class NovoReciboPage extends StatefulWidget {
  final Recibo? recibo; // se fornecido, modo edição
  const NovoReciboPage({super.key, this.recibo});

  @override
  State<NovoReciboPage> createState() => _NovoReciboPageState();
}

class _NovoReciboPageState extends State<NovoReciboPage> {
  int etapaAtual = 0; // 0: Cliente/Orçamento, 1: Itens e Valores
  Orcamento? _orcamentoSelecionado;
  Cliente? _clienteSelecionado;
  final List<Map<String, dynamic>> _itens = [];
  final List<ValorRecebido> _valores = [];
  bool _salvando = false;

  bool get _isEdicao => widget.recibo != null;

  final List<Map<String, dynamic>> etapas = [
    {'icon': Icons.person, 'label': 'Cliente'},
    {'icon': Icons.list_alt, 'label': 'Itens e Valores'},
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null) {
      // Check for cliente argument
      if (args.containsKey('cliente') && _clienteSelecionado == null) {
        setState(() {
          _clienteSelecionado = args['cliente'] as Cliente;
        });
      }
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

  // Método para verificar se cada etapa está completa
  List<bool> get _etapasCompletas {
    return [
      _clienteSelecionado !=
          null, // Etapa 0 (Cliente/Orçamento) só completa se tiver cliente
      _itens.isNotEmpty, // Etapa 1 (Itens e Valores) só completa se tiver itens
    ];
  }

  Future<void> _selecionarOrcamento() async {
    final prov = context.read<OrcamentosProvider>();
    if (prov.orcamentos.isEmpty) await prov.carregarOrcamentos();

    // Filtra apenas orçamentos com status "Enviado"
    final orcamentosEnviados =
        prov.orcamentos.where((o) => o.status == 'Enviado').toList();

    if (orcamentosEnviados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Nenhum orçamento enviado disponível.'),
              ),
            ],
          ),
          backgroundColor: Colors.teal.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    final selecionado = await showModalBottomSheet<Orcamento>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder:
                (context, scrollController) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Header com gradiente
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.teal.shade600,
                              Colors.teal.shade400,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.receipt_long,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Selecionar Orçamento',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Apenas orçamentos enviados',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: orcamentosEnviados.length,
                          itemBuilder: (context, index) {
                            final o = orcamentosEnviados[index];
                            final nf = NumberFormat.currency(
                              locale: 'pt_BR',
                              symbol: 'R\$',
                            );
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => Navigator.pop(context, o),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.teal.shade400,
                                              Colors.teal.shade600,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.teal.shade200,
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            '#${o.numero.toString().padLeft(4, '0')}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              o.cliente.nome,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.calendar_today,
                                                  size: 14,
                                                  color: Colors.grey.shade600,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  DateFormat(
                                                    'dd/MM/yyyy',
                                                  ).format(
                                                    o.dataCriacao.toDate(),
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.shopping_cart,
                                                  size: 14,
                                                  color: Colors.grey.shade600,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${o.itens.length} ${o.itens.length == 1 ? 'item' : 'itens'}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Icon(
                                                  Icons.attach_money,
                                                  size: 14,
                                                  color: Colors.teal.shade600,
                                                ),
                                                Text(
                                                  nf.format(o.valorTotal),
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.teal.shade700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                        color: Colors.grey.shade400,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
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
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Orçamento #${selecionado.numero.toString().padLeft(4, '0')} carregado com ${selecionado.itens.length} ${selecionado.itens.length == 1 ? 'item' : 'itens'}',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.teal.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
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
        builder:
            (_) =>
                const SelecionarServicosPage(textoBotao: 'Adicionar ao Recibo'),
      ),
    );
    if (item != null) setState(() => _itens.add(item));
  }

  Future<void> _adicionarPeca() async {
    final item = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder:
            (_) => const SelecionarPecasPage(textoBotao: 'Adicionar ao Recibo'),
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
    // Validação de cliente na etapa 0
    if (etapaAtual == 0 && _clienteSelecionado == null) {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Por favor, selecione um cliente para continuar.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.teal.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      return;
    }

    // Validação de itens na etapa 1
    if (etapaAtual == 1 && _itens.isEmpty) {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Adicione pelo menos um item para continuar.'),
                ),
              ],
            ),
            backgroundColor: Colors.teal.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
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
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(child: Text('Selecione um cliente.')),
            ],
          ),
          backgroundColor: Colors.teal.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    if (_itens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(child: Text('Adicione pelo menos um item.')),
            ],
          ),
          backgroundColor: Colors.teal.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Erro: $e')),
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
    if (mounted) setState(() => _salvando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdicao ? 'Editar Recibo' : 'Novo Recibo',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade600, Colors.teal.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          EtapasBar(
            etapas: etapas,
            etapaAtual: etapaAtual,
            etapasCompletas: _etapasCompletas,
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
        // Etapa 1: Cliente OU Orçamento
        return EtapaClienteOrcamentoWidget(
          clienteSelecionado: _clienteSelecionado,
          orcamentoSelecionado: _orcamentoSelecionado,
          onSelecionarCliente: _selecionarCliente,
          onSelecionarOrcamento: _selecionarOrcamento,
        );
      case 1:
        // Etapa 2: Itens e Valores
        return EtapaItensValoresWidget(
          itens: _itens,
          valores: _valores,
          onAdicionarServico: _adicionarServico,
          onAdicionarPeca: _adicionarPeca,
          onRemoverItem: _removerItem,
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
