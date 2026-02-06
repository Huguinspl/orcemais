import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../models/receita.dart';
import '../../../providers/business_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../utils/extrato_pdf_generator.dart';

/// Página para visualizar e compartilhar o extrato gerado
/// Layout similar ao PDF para parecer um documento
class VisualizarExtratoPage extends StatefulWidget {
  final List<Transacao> transacoes;
  final DateTime dataInicio;
  final DateTime dataFim;
  final double saldoInicial;
  final double saldoFinal;
  final double totalReceitas;
  final double totalDespesas;

  const VisualizarExtratoPage({
    super.key,
    required this.transacoes,
    required this.dataInicio,
    required this.dataFim,
    required this.saldoInicial,
    required this.saldoFinal,
    required this.totalReceitas,
    required this.totalDespesas,
  });

  @override
  State<VisualizarExtratoPage> createState() => _VisualizarExtratoPageState();
}

class _VisualizarExtratoPageState extends State<VisualizarExtratoPage> {
  final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final dateFormat = DateFormat('dd/MM/yyyy');
  final dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

  // Cores do tema
  Color get corPrimaria => Colors.blue.shade700;
  Color get corReceita => Colors.green.shade600;
  Color get corDespesa => Colors.red.shade600;

  // Gerar e compartilhar PDF
  Future<void> _compartilharPdf() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final businessProvider = context.read<BusinessProvider>();
      final userProvider = context.read<UserProvider>();

      await businessProvider.carregarDoFirestore();

      final pdfBytes = await ExtratoPdfGenerator.generate(
        transacoes: widget.transacoes,
        dataInicio: widget.dataInicio,
        dataFim: widget.dataFim,
        saldoInicial: widget.saldoInicial,
        saldoFinal: widget.saldoFinal,
        totalReceitas: widget.totalReceitas,
        totalDespesas: widget.totalDespesas,
        businessProvider: businessProvider,
        nomePessoal: userProvider.nome,
        emailPessoal: userProvider.email,
        cpfPessoal: userProvider.cpf,
      );

      if (mounted) Navigator.of(context).pop();

      final dataInicioStr = DateFormat('ddMMyyyy').format(widget.dataInicio);
      final dataFimStr = DateFormat('ddMMyyyy').format(widget.dataFim);

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'extrato_${dataInicioStr}_a_$dataFimStr.pdf',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Extrato compartilhado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      debugPrint('Erro ao gerar PDF do extrato: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Compartilhar resumo como texto
  Future<void> _compartilharTexto() async {
    try {
      final businessProvider = context.read<BusinessProvider>();
      await businessProvider.carregarDoFirestore();

      final nomeEmpresa =
          businessProvider.nomeEmpresa.isNotEmpty
              ? businessProvider.nomeEmpresa
              : 'Meu Negócio';

      final textoExtrato = '''
📊 EXTRATO FINANCEIRO - $nomeEmpresa

📅 Período: ${dateFormat.format(widget.dataInicio)} a ${dateFormat.format(widget.dataFim)}

💰 RESUMO:
• Saldo Inicial: ${currencyFormat.format(widget.saldoInicial)}
• Total Entradas: + ${currencyFormat.format(widget.totalReceitas)}
• Total Saídas: - ${currencyFormat.format(widget.totalDespesas)}
• Saldo Final: ${currencyFormat.format(widget.saldoFinal)}

📝 MOVIMENTAÇÕES (${widget.transacoes.length}):
${_gerarListaTransacoes()}

---
Gerado pelo Gestorfy em ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}
''';

      await Share.share(
        textoExtrato,
        subject:
            'Extrato Financeiro - ${dateFormat.format(widget.dataInicio)} a ${dateFormat.format(widget.dataFim)}',
      );
    } catch (e) {
      debugPrint('Erro ao compartilhar texto: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao compartilhar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _gerarListaTransacoes() {
    final buffer = StringBuffer();
    final transacoesOrdenadas = List<Transacao>.from(widget.transacoes)
      ..sort((a, b) => a.data.compareTo(b.data));

    String? dataAtual;
    for (var t in transacoesOrdenadas) {
      final dataStr = dateFormat.format(t.data);
      if (dataStr != dataAtual) {
        dataAtual = dataStr;
        buffer.writeln('\n📆 $dataStr');
      }

      final isReceita = t.tipo == TipoTransacao.receita;
      final emoji = isReceita ? '🟢' : '🔴';
      final sinal = isReceita ? '+' : '-';
      buffer.writeln(
        '$emoji ${t.descricao}: $sinal ${currencyFormat.format(t.valor)}',
      );
    }

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final businessProvider = context.watch<BusinessProvider>();
    final userProvider = context.watch<UserProvider>();

    // Dados da empresa/usuário
    final nomeExibicao = businessProvider.getNomeExibicao(userProvider.nome);
    final emailExibicao = businessProvider.getEmailExibicao(userProvider.email);
    final documentoExibicao = businessProvider.getDocumentoExibicao(
      userProvider.cpf,
    );
    final telefone = businessProvider.telefone;
    final logoUrl = businessProvider.logoUrl;

    // Agrupar transações por data (ordem cronológica como no PDF)
    final transacoesPorData = <String, List<Transacao>>{};
    final transacoesOrdenadas = List<Transacao>.from(widget.transacoes)
      ..sort((a, b) => a.data.compareTo(b.data));

    for (var t in transacoesOrdenadas) {
      final dataStr = dateFormat.format(t.data);
      transacoesPorData.putIfAbsent(dataStr, () => []).add(t);
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Extrato do Período',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: corPrimaria,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade300,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== CABEÇALHO (HEADER) =====
              _buildHeader(
                logoUrl: logoUrl,
                nomeEmpresa: nomeExibicao,
                telefone: telefone,
                email: emailExibicao,
                documento: documentoExibicao,
              ),

              // ===== TÍTULO DO EXTRATO =====
              _buildTituloExtrato(),

              // ===== RESUMO DO PERÍODO =====
              _buildResumo(),

              // ===== LISTA DE MOVIMENTAÇÕES =====
              _buildMovimentacoes(transacoesPorData),

              // ===== RODAPÉ =====
              _buildFooter(),
            ],
          ),
        ),
      ),
      // Botões de compartilhamento
      bottomNavigationBar: _buildBotoesCompartilhar(),
    );
  }

  /// Cabeçalho com logo e dados da empresa (igual ao PDF)
  Widget _buildHeader({
    required String? logoUrl,
    required String nomeEmpresa,
    required String telefone,
    required String email,
    required String documento,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo
          if (logoUrl != null && logoUrl.isNotEmpty)
            Container(
              width: 60,
              height: 60,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  logoUrl,
                  fit: BoxFit.contain,
                  errorBuilder:
                      (context, error, stackTrace) => Container(
                        color: Colors.grey.shade200,
                        child: Icon(
                          Icons.business,
                          color: Colors.grey.shade400,
                          size: 32,
                        ),
                      ),
                ),
              ),
            ),
          // Dados da empresa
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nomeEmpresa,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: corPrimaria,
                  ),
                ),
                if (telefone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Tel: $telefone',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
                if (documento.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    documento,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Título com período e data de emissão (igual ao PDF)
  Widget _buildTituloExtrato() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EXTRATO FINANCEIRO',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: corPrimaria,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Período: ${dateFormat.format(widget.dataInicio)} a ${dateFormat.format(widget.dataFim)}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Emitido em:',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
              Text(
                dateTimeFormat.format(DateTime.now()),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Box de resumo com 4 colunas (igual ao PDF)
  Widget _buildResumo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildResumoItem(
              label: 'Saldo Inicial',
              valor: currencyFormat.format(widget.saldoInicial),
              cor: Colors.grey.shade700,
            ),
          ),
          Container(width: 1, height: 50, color: Colors.grey.shade200),
          Expanded(
            child: _buildResumoItem(
              label: 'Total Entradas',
              valor: '+ ${currencyFormat.format(widget.totalReceitas)}',
              cor: corReceita,
            ),
          ),
          Container(width: 1, height: 50, color: Colors.grey.shade200),
          Expanded(
            child: _buildResumoItem(
              label: 'Total Saídas',
              valor: '- ${currencyFormat.format(widget.totalDespesas)}',
              cor: corDespesa,
            ),
          ),
          Container(width: 1, height: 50, color: Colors.grey.shade200),
          Expanded(
            child: _buildResumoItem(
              label: 'Saldo Final',
              valor: currencyFormat.format(widget.saldoFinal),
              cor: widget.saldoFinal >= 0 ? corReceita : corDespesa,
              destaque: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoItem({
    required String label,
    required String valor,
    required Color cor,
    bool destaque = false,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          valor,
          style: TextStyle(
            fontSize: destaque ? 14 : 12,
            fontWeight: FontWeight.bold,
            color: cor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Lista de movimentações agrupadas por data (igual ao PDF)
  Widget _buildMovimentacoes(Map<String, List<Transacao>> transacoesPorData) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MOVIMENTAÇÕES',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: corPrimaria,
            ),
          ),
          const SizedBox(height: 12),

          if (widget.transacoes.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Nenhuma transação no período',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          else
            ...transacoesPorData.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabeçalho da data (fundo cinza)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    color: Colors.grey.shade200,
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Transações do dia
                  ...entry.value.map((t) => _buildTransacaoRow(t)),
                  const SizedBox(height: 8),
                ],
              );
            }),
        ],
      ),
    );
  }

  /// Linha de transação (igual ao PDF)
  Widget _buildTransacaoRow(Transacao transacao) {
    final isReceita = transacao.tipo == TipoTransacao.receita;
    final cor = isReceita ? corReceita : corDespesa;
    final sinal = isReceita ? '+' : '-';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          // Hora
          SizedBox(
            width: 50,
            child: Text(
              DateFormat('HH:mm').format(transacao.data),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          // Descrição e categoria
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transacao.descricao,
                  style: const TextStyle(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  transacao.categoria.nome,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          // Valor
          Text(
            '$sinal ${currencyFormat.format(transacao.valor)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }

  /// Rodapé (igual ao PDF)
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Documento gerado pelo Gestorfy',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
          Text(
            '${widget.transacoes.length} transações',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildBotoesCompartilhar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Botão PDF
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _compartilharPdf,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Enviar PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Botão Texto/Link
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _compartilharTexto,
                icon: const Icon(Icons.textsms_outlined),
                label: const Text('Enviar Texto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
