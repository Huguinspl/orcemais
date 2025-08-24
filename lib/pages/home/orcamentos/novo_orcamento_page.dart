import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/cliente.dart';
import '../../../models/orcamento.dart';
import '../../../providers/orcamentos_provider.dart';
import '../tabs/clientes_page.dart';
import 'novo_orcamento/etapa_cliente.dart';
import 'novo_orcamento/etapa_itens.dart';
import 'novo_orcamento/rodape_orcamento.dart';
import 'novo_orcamento/selecionar_servicos_page.dart';
import 'novo_orcamento/selecionar_pecas_page.dart'; // ✅ CORREÇÃO 1: Importar a página de peças
import 'revisar_orcamento_page.dart';
import 'novo_orcamento/dialogo_desconto.dart';
import 'novo_orcamento/etapas_bar.dart';

enum DescontoTipo { percentual, valor }

class NovoOrcamentoPage extends StatefulWidget {
  final Orcamento? orcamento;
  const NovoOrcamentoPage({super.key, this.orcamento});

  @override
  State<NovoOrcamentoPage> createState() => _NovoOrcamentoPageState();
}

class _NovoOrcamentoPageState extends State<NovoOrcamentoPage> {
  int etapaAtual = 0;
  Cliente? clienteSelecionado;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _itensDoOrcamento = [];
  double _subtotal = 0.0;
  double _custoTotal = 0.0;
  double _desconto = 0.0;
  double _valorTotal = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.orcamento != null) {
      final o = widget.orcamento!;
      clienteSelecionado = o.cliente;
      _itensDoOrcamento.addAll(List<Map<String, dynamic>>.from(o.itens));
      _desconto = o.desconto;
      _calcularTotais();
    }
  }

  final List<Map<String, dynamic>> etapas = [
    {'icon': Icons.person_outline, 'label': 'Cliente'},
    {'icon': Icons.list_alt_outlined, 'label': 'Itens'},
    {'icon': Icons.description_outlined, 'label': 'Detalhes'},
    {'icon': Icons.palette_outlined, 'label': 'Aparência'},
  ];

  void _calcularTotais() {
    double subtotalCalculado = 0.0;
    double custoTotalCalculado = 0.0;
    for (var item in _itensDoOrcamento) {
      final preco = item['preco'] as double? ?? 0.0;
      final custo = item['custo'] as double? ?? 0.0;
      final quantidade = item['quantidade'] as double? ?? 1.0;

      subtotalCalculado += preco * quantidade;
      custoTotalCalculado += custo;
    }

    final totalCalculado =
        (subtotalCalculado + custoTotalCalculado) - _desconto;

    setState(() {
      _subtotal = subtotalCalculado;
      _custoTotal = custoTotalCalculado;
      _valorTotal = totalCalculado < 0 ? 0 : totalCalculado;
    });
  }

  Future<void> _mostrarDialogoDesconto() async {
    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => DialogoDesconto(subtotal: _subtotal),
    );
    if (resultado != null && mounted) {
      final tipo = resultado['tipo'] as DescontoTipo;
      final valor = resultado['valor'] as double;
      double descontoCalculado = 0.0;
      if (tipo == DescontoTipo.percentual) {
        descontoCalculado = (_subtotal * valor) / 100;
      } else {
        descontoCalculado = valor;
      }
      if (descontoCalculado > _subtotal) {
        descontoCalculado = _subtotal;
      }
      setState(() {
        _desconto = descontoCalculado;
      });
      _calcularTotais();
    }
  }

  void _adicionarServico() async {
    final novoItem = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const SelecionarServicosPage()),
    );
    if (novoItem != null && mounted) {
      setState(() {
        _itensDoOrcamento.add(novoItem);
      });
      _calcularTotais();
    }
  }

  // ✅ CORREÇÃO 2: Nova função para adicionar peças/materiais
  void _adicionarPeca() async {
    final novoItem = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const SelecionarPecasPage()),
    );
    if (novoItem != null && mounted) {
      setState(() {
        _itensDoOrcamento.add(novoItem);
      });
      _calcularTotais();
    }
  }

  void _removerItem(int index) {
    setState(() {
      _itensDoOrcamento.removeAt(index);
    });
    _calcularTotais();
  }

  void _selecionarCliente() async {
    final selecionado = await Navigator.push<Cliente>(
      context,
      MaterialPageRoute(builder: (_) => const ClientesPage(isPickerMode: true)),
    );
    if (selecionado != null && mounted) {
      setState(() {
        clienteSelecionado = selecionado;
      });
    }
  }

  Future<void> _revisarEEnviar() async {
    if (clienteSelecionado == null || _itensDoOrcamento.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cliente e itens são obrigatórios.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final orcamentoParaSalvar = Orcamento(
        id: widget.orcamento?.id ?? '',
        cliente: clienteSelecionado!,
        itens: _itensDoOrcamento,
        subtotal: _subtotal,
        desconto: _desconto,
        valorTotal: _valorTotal,
        status: widget.orcamento?.status ?? 'Aberto',
        dataCriacao: widget.orcamento?.dataCriacao ?? Timestamp.now(),
      );
      final provider = context.read<OrcamentosProvider>();
      final Orcamento orcamentoFinal;
      if (widget.orcamento == null) {
        orcamentoFinal = await provider.adicionarOrcamento(orcamentoParaSalvar);
      } else {
        await provider.atualizarOrcamento(orcamentoParaSalvar);
        orcamentoFinal = orcamentoParaSalvar;
      }
      if (mounted) {
        if (widget.orcamento != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => RevisarOrcamentoPage(orcamento: orcamentoFinal),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RevisarOrcamentoPage(orcamento: orcamentoFinal),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _proximaEtapa() {
    if (etapaAtual == 0 && clienteSelecionado == null) {
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
    if (etapaAtual < etapas.length - 1) {
      setState(() => etapaAtual++);
    } else {
      _revisarEEnviar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.orcamento != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Orçamento' : 'Novo Orçamento'),
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
      bottomNavigationBar: RodapeOrcamento(
        subtotal: _subtotal,
        desconto: _desconto,
        valorTotal: _valorTotal,
        custoTotal: _custoTotal,
        isUltimaEtapa: etapaAtual == etapas.length - 1,
        isSaving: _isSaving,
        onMostrarDialogoDesconto: _mostrarDialogoDesconto,
        onRevisarEEnviar: _revisarEEnviar,
        onProximaEtapa: _proximaEtapa,
      ),
    );
  }

  Widget _buildConteudoEtapa() {
    switch (etapaAtual) {
      case 0:
        return EtapaClienteWidget(
          clienteSelecionado: clienteSelecionado,
          onSelecionarCliente: _selecionarCliente,
        );
      case 1:
        return EtapaItensWidget(
          itens: _itensDoOrcamento,
          onAdicionarServico: _adicionarServico,
          onAdicionarPeca:
              _adicionarPeca, // <-- ✅ CORREÇÃO 3: Conectando a nova função
          onRemoverItem: _removerItem,
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
