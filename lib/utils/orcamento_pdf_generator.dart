import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/cliente.dart';
import '../models/orcamento.dart'; // Importe o modelo de Orçamento
import '../providers/business_provider.dart';
import 'pdf_color_utils.dart';

class OrcamentoPdfGenerator {
  // ✅ CORREÇÃO 1: O método agora recebe o objeto Orcamento completo
  static Future<Uint8List> generate(
    Orcamento orcamento,
    BusinessProvider businessProvider,
  ) async {
    final pdf = pw.Document();
    // Paleta com suporte a tema salvo no provider
    final theme = businessProvider.pdfTheme;
    // Cores principais do tema
    final primary = PdfColorUtils.fromArgbInt(
      theme?['primary'] as int?,
      PdfColors.blue900,
    );
    final onPrimary = PdfColorUtils.fromArgbInt(
      theme?['onPrimary'] as int?,
      PdfColors.white,
    );
    final secondaryContainer = PdfColorUtils.fromArgbInt(
      theme?['secondaryContainer'] as int?,
      PdfColors.grey200,
    );
    final onSecondaryContainer = PdfColorUtils.fromArgbInt(
      theme?['onSecondaryContainer'] as int?,
      PdfColors.black,
    );
    final tertiaryContainer = PdfColorUtils.fromArgbInt(
      theme?['tertiaryContainer'] as int?,
      PdfColors.grey300,
    );
    final onTertiaryContainer = PdfColorUtils.fromArgbInt(
      theme?['onTertiaryContainer'] as int?,
      PdfColors.black,
    );
    final outlineVariant = PdfColorUtils.fromArgbInt(
      theme?['outlineVariant'] as int?,
      PdfColors.grey400,
    );
    // Garante que dados da empresa estejam carregados
    try {
      await businessProvider.carregarDoFirestore();
    } catch (_) {}
    // Carrega mídias
    final logoBytes = await businessProvider.getLogoBytes();
    final assinaturaBytes = await businessProvider.getAssinaturaBytes();

    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();
    final italicFont = await PdfGoogleFonts.robotoItalic();

    // Texto opcional da descrição do negócio (usado mais abaixo se existir)

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(32, 32, 32, 44),
        ),
        // Sem header/footer custom: vamos usar o cabeçalho clássico no conteúdo
        build:
            (context) => [
              // Cabeçalho clássico com faixa colorida
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: primary,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                padding: const pw.EdgeInsets.all(16),
                child: _buildHeader(
                  orcamento,
                  businessProvider,
                  boldFont,
                  font,
                  logoBytes,
                  textColor: onPrimary,
                ),
              ),
              pw.SizedBox(height: 16),
              _sectionLabel(
                'Dados do Cliente',
                bg: secondaryContainer,
                fg: onSecondaryContainer,
                font: boldFont,
              ),
              pw.SizedBox(height: 8),
              _buildClientInfo(orcamento.cliente, boldFont, font),
              if ((businessProvider.descricao ?? '').isNotEmpty) ...[
                pw.SizedBox(height: 12),
                pw.Text(
                  _hyphenatePtBr(businessProvider.descricao!),
                  style: pw.TextStyle(font: font, fontSize: 10),
                ),
              ],
              pw.SizedBox(height: 24),
              _sectionLabel(
                'Itens do Orçamento',
                bg: tertiaryContainer,
                fg: onTertiaryContainer,
                font: boldFont,
              ),
              pw.SizedBox(height: 16),
              _buildItemsTable(
                orcamento.itens,
                currencyFormat,
                boldFont,
                font,
                italicFont,
              ),
              pw.SizedBox(height: 24),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Container(
                    decoration: pw.BoxDecoration(
                      color: secondaryContainer,
                      borderRadius: pw.BorderRadius.circular(12),
                      border: pw.Border.all(color: outlineVariant, width: 0.5),
                    ),
                    padding: const pw.EdgeInsets.all(16),
                    child: _buildTotals(
                      orcamento,
                      currencyFormat,
                      boldFont,
                      font,
                    ),
                  ),
                  if (assinaturaBytes != null &&
                      assinaturaBytes.isNotEmpty) ...[
                    pw.SizedBox(height: 24),
                    _buildAssinaturaSection(assinaturaBytes, boldFont, font),
                  ],
                ],
              ),
            ],
      ),
    );

    return pdf.save();
  }

  // Cabeçalho clássico com faixa colorida, logo e dados
  static pw.Widget _buildHeader(
    Orcamento orcamento,
    BusinessProvider provider,
    pw.Font boldFont,
    pw.Font regularFont,
    Uint8List? logoBytes, {
    PdfColor? textColor,
  }) {
    pw.ImageProvider? logoImage;
    if (logoBytes != null && logoBytes.isNotEmpty) {
      logoImage = pw.MemoryImage(logoBytes);
    }
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (logoImage != null)
                pw.Container(
                  width: 60,
                  height: 60,
                  margin: const pw.EdgeInsets.only(right: 12),
                  child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      provider.nomeEmpresa,
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 20,
                        color: textColor,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    if (provider.telefone.isNotEmpty)
                      pw.Text(
                        provider.telefone,
                        style: pw.TextStyle(
                          font: regularFont,
                          color: textColor,
                        ),
                      ),
                    if (provider.emailEmpresa.isNotEmpty)
                      pw.Text(
                        provider.emailEmpresa,
                        style: pw.TextStyle(
                          font: regularFont,
                          color: textColor,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 20),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'Orçamento #${orcamento.numero.toString().padLeft(4, '0')}',
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 14,
                color: textColor,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Data: ${DateFormat('dd/MM/yyyy').format(orcamento.dataCriacao.toDate())}',
              style: pw.TextStyle(
                font: regularFont,
                fontSize: 10,
                color: textColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildClientInfo(
    Cliente cliente,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Cliente:',
          style: pw.TextStyle(font: regularFont, fontSize: 10),
        ),
        pw.Text(
          cliente.nome,
          style: pw.TextStyle(font: boldFont, fontSize: 14),
        ),
        if (cliente.celular.isNotEmpty)
          pw.Text(cliente.celular, style: pw.TextStyle(font: regularFont)),
        if (cliente.email.isNotEmpty)
          pw.Text(cliente.email, style: pw.TextStyle(font: regularFont)),
      ],
    );
  }

  static pw.Widget _buildItemsTable(
    List<Map<String, dynamic>> itens,
    NumberFormat currencyFormat,
    pw.Font boldFont,
    pw.Font regularFont,
    pw.Font italicFont,
  ) {
    const tableHeaders = ['Descrição', 'Qtd.', 'Total'];
    return pw.Table.fromTextArray(
      headers: tableHeaders,
      data: List<List<dynamic>>.generate(itens.length, (index) {
        final item = itens[index];
        final nome = item['nome'] ?? 'Item';
        final descricao = item['descricao'] as String? ?? '';
        final preco = item['preco'] as double? ?? 0.0;
        final quantidade = item['quantidade'] as double? ?? 1.0;
        final totalItem = preco * quantidade;

        return [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                nome,
                style: pw.TextStyle(
                  font: regularFont,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (descricao.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 4),
                  child: pw.Text(
                    descricao,
                    style: pw.TextStyle(
                      font: italicFont,
                      fontSize: 9,
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
            ],
          ),
          quantidade.toStringAsFixed(2),
          currencyFormat.format(totalItem),
        ];
      }),
      headerStyle: pw.TextStyle(font: boldFont, fontWeight: pw.FontWeight.bold),
      cellStyle: pw.TextStyle(font: regularFont),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.centerRight,
      },
      cellPadding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
    );
  }

  static pw.Widget _buildTotals(
    Orcamento orcamento,
    NumberFormat currencyFormat,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    double custoTotal = 0.0;
    for (var item in orcamento.itens) {
      final custo = item['custo'] as double? ?? 0.0;
      custoTotal += custo;
    }

    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 220,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Subtotal:', style: pw.TextStyle(font: regularFont)),
                pw.Text(
                  currencyFormat.format(orcamento.subtotal),
                  style: pw.TextStyle(font: regularFont),
                ),
              ],
            ),
            if (custoTotal > 0)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Custos Adicionais:',
                    style: pw.TextStyle(font: regularFont),
                  ),
                  pw.Text(
                    currencyFormat.format(custoTotal),
                    style: pw.TextStyle(font: regularFont),
                  ),
                ],
              ),
            if (orcamento.desconto > 0)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Desconto:', style: pw.TextStyle(font: regularFont)),
                  pw.Text(
                    '- ${currencyFormat.format(orcamento.desconto)}',
                    style: pw.TextStyle(font: regularFont),
                  ),
                ],
              ),
            pw.Divider(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Valor Total:',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                pw.Text(
                  currencyFormat.format(orcamento.valorTotal),
                  style: pw.TextStyle(
                    font: boldFont,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // (Seção de condições de pagamento removida para voltar ao layout anterior do PDF)

  static pw.Widget _buildAssinaturaSection(
    Uint8List assinatura,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    final img = pw.MemoryImage(assinatura);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          height: 80,
          alignment: pw.Alignment.center,
          child: pw.Image(img, fit: pw.BoxFit.contain),
        ),
        pw.Container(
          height: 1,
          color: PdfColors.grey400,
          margin: const pw.EdgeInsets.symmetric(horizontal: 80, vertical: 8),
        ),
        pw.Text(
          'Assinatura',
          style: pw.TextStyle(
            font: regularFont,
            fontSize: 10,
            color: PdfColors.grey700,
          ),
        ),
      ],
    );
  }

  static pw.Widget _sectionLabel(
    String text, {
    required PdfColor bg,
    required PdfColor fg,
    required pw.Font font,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontWeight: pw.FontWeight.bold,
          fontSize: 14,
          color: fg,
        ),
      ),
    );
  }

  // Hifenização básica PT-BR (heurística): insere Soft Hyphen em palavras muito longas
  // para permitir quebra de linha automática no PDF sem artefatos visuais.
  static String _hyphenatePtBr(String text) {
    if (text.isEmpty) return text;
    final buf = StringBuffer();
    final parts = text.split(RegExp(r'(\s+)'));
    for (final part in parts) {
      // Mantém separadores (espaços/linhas) intactos
      if (RegExp(r'^\s+$').hasMatch(part)) {
        buf.write(part);
        continue;
      }
      // Palavras curtas ficam como estão
      if (part.length <= 14) {
        buf.write(part);
        continue;
      }
      // Para palavras longas, insere soft hyphen a cada 8-10 caracteres
      const chunk = 8;
      for (int i = 0; i < part.length; i += chunk) {
        final end = (i + chunk < part.length) ? i + chunk : part.length;
        buf.write(part.substring(i, end));
        if (end < part.length) buf.write('\u00AD'); // soft hyphen
      }
    }
    return buf.toString();
  }

  // Removidas heurísticas de medição/que bra; o MultiPage faz a paginação natural
}
