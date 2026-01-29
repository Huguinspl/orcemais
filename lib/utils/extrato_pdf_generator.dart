import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/receita.dart';
import '../providers/business_provider.dart';
import 'pdf_color_utils.dart';

/// Gerador de PDF para Extrato Financeiro
class ExtratoPdfGenerator {
  static Future<Uint8List> generate({
    required List<Transacao> transacoes,
    required DateTime dataInicio,
    required DateTime dataFim,
    required double saldoInicial,
    required double saldoFinal,
    required double totalReceitas,
    required double totalDespesas,
    required BusinessProvider businessProvider,
    String? nomePessoal,
    String? emailPessoal,
    String? cpfPessoal,
  }) async {
    final pdf = pw.Document();

    // Carrega dados da empresa
    try {
      await businessProvider.carregarDoFirestore();
    } catch (_) {}

    // Dados com fallback para dados pessoais
    final nomeExibicao = businessProvider.getNomeExibicao(nomePessoal);
    final emailExibicao = businessProvider.getEmailExibicao(emailPessoal);
    final documentoExibicao = businessProvider.getDocumentoExibicao(cpfPessoal);

    final logoBytes = await businessProvider.getLogoBytes();
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFormat = DateFormat('dd/MM/yyyy');
    final dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    // Carrega tema personalizado ou usa cores padrão
    final theme = businessProvider.pdfTheme;

    // Cores principais do tema - Padrão AZUL profissional
    final primary = PdfColorUtils.fromArgbInt(
      theme?['primary'] as int?,
      PdfColor.fromHex('#1565C0'),
    );
    final onPrimary = PdfColorUtils.fromArgbInt(
      theme?['onPrimary'] as int?,
      PdfColors.white,
    );
    final secondaryContainer = PdfColorUtils.fromArgbInt(
      theme?['secondaryContainer'] as int?,
      PdfColor.fromHex('#E3F2FD'),
    );

    // Cores para receitas e despesas
    final corReceita = PdfColor.fromHex('#4CAF50');
    final corDespesa = PdfColor.fromHex('#F44336');

    // Ordenar transações por data
    final transacoesOrdenadas = List<Transacao>.from(transacoes)
      ..sort((a, b) => a.data.compareTo(b.data));

    // Agrupar transações por data
    final transacoesPorData = <String, List<Transacao>>{};
    for (var t in transacoesOrdenadas) {
      final dataStr = dateFormat.format(t.data);
      transacoesPorData.putIfAbsent(dataStr, () => []).add(t);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header:
            (context) => _buildHeader(
              logoBytes: logoBytes,
              nomeEmpresa: nomeExibicao,
              telefone: businessProvider.telefone,
              email: emailExibicao,
              documento: documentoExibicao,
              primary: primary,
              onPrimary: onPrimary,
              font: font,
              boldFont: boldFont,
            ),
        footer:
            (context) =>
                _buildFooter(context: context, font: font, primary: primary),
        build:
            (context) => [
              // Título do extrato
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: secondaryContainer,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'EXTRATO FINANCEIRO',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 18,
                            color: primary,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Período: ${dateFormat.format(dataInicio)} a ${dateFormat.format(dataFim)}',
                          style: pw.TextStyle(font: font, fontSize: 11),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Emitido em:',
                          style: pw.TextStyle(font: font, fontSize: 9),
                        ),
                        pw.Text(
                          dateTimeFormat.format(DateTime.now()),
                          style: pw.TextStyle(font: boldFont, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Resumo do período
              _buildResumo(
                saldoInicial: saldoInicial,
                totalReceitas: totalReceitas,
                totalDespesas: totalDespesas,
                saldoFinal: saldoFinal,
                currency: currency,
                font: font,
                boldFont: boldFont,
                corReceita: corReceita,
                corDespesa: corDespesa,
                primary: primary,
              ),
              pw.SizedBox(height: 24),

              // Tabela de transações
              pw.Text(
                'MOVIMENTAÇÕES',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 14,
                  color: primary,
                ),
              ),
              pw.SizedBox(height: 12),

              // Lista de transações agrupadas por data
              ...transacoesPorData.entries.map((entry) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Cabeçalho da data
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      color: PdfColors.grey200,
                      child: pw.Text(
                        entry.key,
                        style: pw.TextStyle(font: boldFont, fontSize: 10),
                      ),
                    ),
                    // Transações do dia
                    ...entry.value.map(
                      (t) => _buildTransacaoRow(
                        transacao: t,
                        currency: currency,
                        font: font,
                        boldFont: boldFont,
                        corReceita: corReceita,
                        corDespesa: corDespesa,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                  ],
                );
              }),
            ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader({
    required Uint8List? logoBytes,
    required String nomeEmpresa,
    required String telefone,
    required String email,
    required String documento,
    required PdfColor primary,
    required PdfColor onPrimary,
    required pw.Font font,
    required pw.Font boldFont,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (logoBytes != null)
            pw.Container(
              width: 60,
              height: 60,
              margin: const pw.EdgeInsets.only(right: 16),
              child: pw.Image(
                pw.MemoryImage(logoBytes),
                fit: pw.BoxFit.contain,
              ),
            ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  nomeEmpresa,
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 16,
                    color: primary,
                  ),
                ),
                if (telefone.isNotEmpty)
                  pw.Text(
                    'Tel: $telefone',
                    style: pw.TextStyle(font: font, fontSize: 9),
                  ),
                if (email.isNotEmpty)
                  pw.Text(email, style: pw.TextStyle(font: font, fontSize: 9)),
                if (documento.isNotEmpty)
                  pw.Text(
                    documento,
                    style: pw.TextStyle(font: font, fontSize: 9),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter({
    required pw.Context context,
    required pw.Font font,
    required PdfColor primary,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Documento gerado pelo Orcemais',
            style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey),
          ),
          pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildResumo({
    required double saldoInicial,
    required double totalReceitas,
    required double totalDespesas,
    required double saldoFinal,
    required NumberFormat currency,
    required pw.Font font,
    required pw.Font boldFont,
    required PdfColor corReceita,
    required PdfColor corDespesa,
    required PdfColor primary,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildResumoItem(
                  label: 'Saldo Inicial',
                  valor: currency.format(saldoInicial),
                  cor: PdfColors.grey700,
                  font: font,
                  boldFont: boldFont,
                ),
              ),
              pw.Expanded(
                child: _buildResumoItem(
                  label: 'Total Entradas',
                  valor: '+ ${currency.format(totalReceitas)}',
                  cor: corReceita,
                  font: font,
                  boldFont: boldFont,
                ),
              ),
              pw.Expanded(
                child: _buildResumoItem(
                  label: 'Total Saídas',
                  valor: '- ${currency.format(totalDespesas)}',
                  cor: corDespesa,
                  font: font,
                  boldFont: boldFont,
                ),
              ),
              pw.Expanded(
                child: _buildResumoItem(
                  label: 'Saldo Final',
                  valor: currency.format(saldoFinal),
                  cor: saldoFinal >= 0 ? corReceita : corDespesa,
                  font: font,
                  boldFont: boldFont,
                  destaque: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildResumoItem({
    required String label,
    required String valor,
    required PdfColor cor,
    required pw.Font font,
    required pw.Font boldFont,
    bool destaque = false,
  }) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: font,
            fontSize: 9,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          valor,
          style: pw.TextStyle(
            font: boldFont,
            fontSize: destaque ? 14 : 12,
            color: cor,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTransacaoRow({
    required Transacao transacao,
    required NumberFormat currency,
    required pw.Font font,
    required pw.Font boldFont,
    required PdfColor corReceita,
    required PdfColor corDespesa,
  }) {
    final isReceita = transacao.tipo == TipoTransacao.receita;
    final cor = isReceita ? corReceita : corDespesa;
    final sinal = isReceita ? '+' : '-';

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200)),
      ),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 50,
            child: pw.Text(
              DateFormat('HH:mm').format(transacao.data),
              style: pw.TextStyle(
                font: font,
                fontSize: 9,
                color: PdfColors.grey600,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  transacao.descricao,
                  style: pw.TextStyle(font: font, fontSize: 10),
                ),
                pw.Text(
                  transacao.categoria.nome,
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ),
          pw.Text(
            '$sinal ${currency.format(transacao.valor)}',
            style: pw.TextStyle(font: boldFont, fontSize: 10, color: cor),
          ),
        ],
      ),
    );
  }
}
