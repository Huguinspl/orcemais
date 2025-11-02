import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/cliente.dart';
import '../../../models/orcamento.dart';
import '../../../providers/orcamentos_provider.dart';
import '../tabs/clientes_page.dart';
import 'novo_orcamento/etapa_cliente.dart';
import 'novo_orcamento/etapa_itens.dart';
import 'novo_orcamento/etapa_detalhes.dart';
import 'novo_orcamento/formas_pagamento_page.dart';
import 'novo_orcamento/rodape_orcamento.dart';
import 'novo_orcamento/selecionar_servicos_page.dart';
import 'novo_orcamento/selecionar_pecas_page.dart'; // ✅ CORREÇÃO 1: Importar a página de peças
import 'revisar_orcamento_page.dart';
import 'novo_orcamento/aplicar_desconto_page.dart';
import 'novo_orcamento/etapas_bar.dart';
import 'novo_orcamento/contratos_e_garantia_page.dart';
import 'novo_orcamento/laudo_tecnico_page.dart';
import 'novo_orcamento/informacoes_adicionais_page.dart';

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

  // Resumos/estado simples para etapa Detalhes (placeholders iniciais)
  String? _resumoFormaPagamento;
  String? _metodoPagamento; // dinheiro, pix, debito, credito, boleto
  int? _parcelas; // quando crédito
  String? _resumoLaudoTecnico;
  String? _laudoTecnico;
  String? _resumoCondicoes;
  String? _resumoGarantiaData;
  String? _condicoesContratuais;
  String? _garantia;
  String? _informacoesAdicionais;

  @override
  void initState() {
    super.initState();
    if (widget.orcamento != null) {
      final o = widget.orcamento!;
      clienteSelecionado = o.cliente;
      _itensDoOrcamento.addAll(List<Map<String, dynamic>>.from(o.itens));
      _desconto = o.desconto;
      _metodoPagamento = o.metodoPagamento;
      _parcelas = o.parcelas;
      _laudoTecnico = o.laudoTecnico;
      _condicoesContratuais = o.condicoesContratuais;
      _garantia = o.garantia;
      _informacoesAdicionais = o.informacoesAdicionais;
      if (_metodoPagamento != null) {
        _resumoFormaPagamento =
            _metodoPagamento == 'credito' && _parcelas != null
                ? 'Crédito em ${_parcelas}x'
                : _metodoPagamento!.substring(0, 1).toUpperCase() +
                    _metodoPagamento!.substring(1);
      }
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
    final resultado = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => AplicarDescontoPage(subtotal: _subtotal),
      ),
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

  // Placeholders: abra uma página/diálogo no futuro; por ora, só marca um resumo
  void _editarFormaPagamentoParcelas() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const FormasPagamentoPage()),
    );
    if (result != null && mounted) {
      setState(() {
        _resumoFormaPagamento = result['resumo'] as String?;
        _metodoPagamento = result['metodo'] as String?;
        _parcelas = result['parcelas'] as int?;
      });
    }
  }

  void _editarLaudoTecnico() async {
    final texto = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => LaudoTecnicoPage(textoInicial: _laudoTecnico),
      ),
    );
    if (!mounted) return;
    if (texto != null) {
      setState(() {
        _laudoTecnico = texto;
        _resumoLaudoTecnico =
            texto.length > 60 ? '${texto.substring(0, 60)}…' : texto;
      });
    }
  }

  Future<void> _editarCondicoesContratuais() async {
    final res = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder:
            (_) => ContratosEGarantiaPage(
              condicoesIniciais: _condicoesContratuais,
              garantiaInicial: _garantia,
            ),
      ),
    );
    if (!mounted) return;
    if (res != null) {
      setState(() {
        _condicoesContratuais = res['condicoes'];
        _garantia = res['garantia'];
        _resumoCondicoes =
            (_condicoesContratuais ?? '').isNotEmpty
                ? (_condicoesContratuais!.length > 60
                    ? '${_condicoesContratuais!.substring(0, 60)}…'
                    : _condicoesContratuais)
                : null;
        _resumoGarantiaData =
            (_garantia ?? '').isNotEmpty
                ? (_garantia!.length > 60
                    ? '${_garantia!.substring(0, 60)}…'
                    : _garantia)
                : null;
      });
    }
  }

  void _editarGarantiaEDataVisita() async {
    // Reusa a mesma página para editar as duas coisas
    await _editarCondicoesContratuais();
  }

  void _editarInformacoesAdicionais() async {
    final texto = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder:
            (_) =>
                InformacoesAdicionaisPage(textoInicial: _informacoesAdicionais),
      ),
    );
    if (!mounted) return;
    if (texto != null) {
      setState(() {
        _informacoesAdicionais = texto;
        // Reutiliza o campo de resumo da última carta (antes usada para garantia/data)
        _resumoGarantiaData =
            texto.isNotEmpty
                ? (texto.length > 60 ? '${texto.substring(0, 60)}…' : texto)
                : null;
      });
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
        metodoPagamento: _metodoPagamento,
        parcelas: _parcelas,
        laudoTecnico: _laudoTecnico,
        condicoesContratuais: _condicoesContratuais,
        garantia: _garantia,
        informacoesAdicionais: _informacoesAdicionais,
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
      case 2:
        return EtapaDetalhesWidget(
          onDescontos: _mostrarDialogoDesconto,
          onFormasPagamentoParcelas: _editarFormaPagamentoParcelas,
          onLaudoTecnico: _editarLaudoTecnico,
          onCondicoesContratuais: _editarCondicoesContratuais,
          onGarantiaEDataVisita: _editarGarantiaEDataVisita,
          onInformacoesAdicionais: _editarInformacoesAdicionais,
          resumoDescontos:
              _desconto > 0
                  ? 'Desconto aplicado: R\$ ${_desconto.toStringAsFixed(2)}'
                  : null,
          resumoFormaPagamento: _resumoFormaPagamento,
          resumoLaudoTecnico: _resumoLaudoTecnico,
          resumoCondicoes: _resumoCondicoes,
          resumoGarantiaData: _resumoGarantiaData,
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
