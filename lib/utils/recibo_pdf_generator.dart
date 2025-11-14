import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/recibo.dart';
import '../models/valor_recebido.dart';
import '../providers/business_provider.dart';
import 'pdf_color_utils.dart';

class ReciboPdfGenerator {
  static Future<Uint8List> generate(
    Recibo recibo,
    BusinessProvider businessProvider,
  ) async {
    final pdf = pw.Document();
    // Carrega dados da empresa e logo uma vez
    try {
      await businessProvider.carregarDoFirestore();
    } catch (_) {}
    final logoBytes = await businessProvider.getLogoBytes();
    final assinaturaBytes = await businessProvider.getAssinaturaBytes();
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();
    final italicFont = await PdfGoogleFonts.robotoItalic();

    // Carrega tema personalizado ou usa cores padrão
    final theme = businessProvider.pdfTheme;
    final primary = PdfColorUtils.fromArgbInt(
      theme?['primary'],
      PdfColor.fromHex('#FF6B00'), // Laranja padrão para recibos
    );
    final onPrimary = PdfColorUtils.fromArgbInt(
      theme?['onPrimary'],
      PdfColors.white,
    );
    final secondaryContainer = PdfColorUtils.fromArgbInt(
      theme?['secondaryContainer'],
      PdfColor.fromHex('#FFE0B2'),
    );
    final onSecondaryContainer = PdfColorUtils.fromArgbInt(
      theme?['onSecondaryContainer'],
      PdfColor.fromHex('#2E1500'),
    );
    final tertiaryContainer = PdfColorUtils.fromArgbInt(
      theme?['tertiaryContainer'],
      PdfColor.fromHex('#FFD8CC'),
    );
    final onTertiaryContainer = PdfColorUtils.fromArgbInt(
      theme?['onTertiaryContainer'],
      PdfColor.fromHex('#311300'),
    );
    final outlineVariant = PdfColorUtils.fromArgbInt(
      theme?['outlineVariant'],
      PdfColors.grey300,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        maxPages: 100,
        build:
            (ctx) => [
              // Header com faixa colorida
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: primary,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                padding: const pw.EdgeInsets.all(16),
                child: _buildHeader(
                  recibo,
                  businessProvider,
                  boldFont,
                  font,
                  logoBytes,
                  textColor: onPrimary,
                ),
              ),
              if ((businessProvider.descricao ?? '').isNotEmpty) ...[
                pw.SizedBox(height: 16),
                pw.Text(
                  businessProvider.descricao!,
                  style: pw.TextStyle(font: font, fontSize: 12),
                ),
              ],
              pw.SizedBox(height: 24),
              _sectionLabel(
                'Dados do Cliente',
                bg: secondaryContainer,
                fg: onSecondaryContainer,
                font: boldFont,
              ),
              pw.SizedBox(height: 12),
              _buildClientInfo(recibo, boldFont, font),
              pw.SizedBox(height: 24),
              if (recibo.itens.isNotEmpty) ...[
                _sectionLabel(
                  'Itens / Serviços',
                  bg: tertiaryContainer,
                  fg: onTertiaryContainer,
                  font: boldFont,
                ),
                pw.SizedBox(height: 16),
                _buildItemsList(
                  recibo,
                  currency,
                  boldFont,
                  font,
                  italicFont,
                  outlineVariant,
                ),
                pw.SizedBox(height: 24),
              ] else ...[
                _sectionLabel(
                  'Valores Recebidos',
                  bg: tertiaryContainer,
                  fg: onTertiaryContainer,
                  font: boldFont,
                ),
                pw.SizedBox(height: 16),
                _buildValoresRecebidosList(
                  recibo.valoresRecebidos,
                  currency,
                  boldFont,
                  font,
                  outlineVariant,
                ),
                pw.SizedBox(height: 24),
              ],
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: secondaryContainer,
                  borderRadius: pw.BorderRadius.circular(12),
                  border: pw.Border.all(color: outlineVariant, width: 0.5),
                ),
                padding: const pw.EdgeInsets.all(16),
                child: _buildTotals(recibo, currency, boldFont, font),
              ),
              if (assinaturaBytes != null && assinaturaBytes.isNotEmpty) ...[
                pw.SizedBox(height: 24),
                _buildAssinaturaSection(assinaturaBytes, boldFont, font),
              ],
            ],
      ),
    );
    return pdf.save();
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
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

  static pw.Widget _buildHeader(
    Recibo r,
    BusinessProvider b,
    pw.Font bold,
    pw.Font regular,
    Uint8List? logoBytes, {
    PdfColor? textColor,
  }) {
    pw.ImageProvider? logoImage;
    if (logoBytes != null && logoBytes.isNotEmpty) {
      logoImage = pw.MemoryImage(logoBytes);
    }
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
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
                      b.nomeEmpresa,
                      style: pw.TextStyle(
                        font: bold,
                        fontSize: 20,
                        color: textColor,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    if (b.telefone.isNotEmpty)
                      pw.Text(
                        b.telefone,
                        style: pw.TextStyle(font: regular, color: textColor),
                      ),
                    if (b.emailEmpresa.isNotEmpty)
                      pw.Text(
                        b.emailEmpresa,
                        style: pw.TextStyle(font: regular, color: textColor),
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
            // Título RECIBO em destaque (maior)
            pw.Text(
              'RECIBO',
              style: pw.TextStyle(
                font: bold,
                fontSize: 28,
                color: textColor,
                letterSpacing: 1.2,
              ),
            ),
            pw.SizedBox(height: 8),
            // Data de criação
            pw.Text(
              'Data: ${DateFormat('dd/MM/yyyy').format(r.criadoEm.toDate())}',
              style: pw.TextStyle(
                font: regular,
                fontSize: 10,
                color: textColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildClientInfo(Recibo r, pw.Font bold, pw.Font regular) {
    final c = r.cliente;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Cliente:', style: pw.TextStyle(font: regular, fontSize: 10)),
        pw.Text(c.nome, style: pw.TextStyle(font: bold, fontSize: 14)),
        if (c.celular.isNotEmpty)
          pw.Text(c.celular, style: pw.TextStyle(font: regular)),
        if (c.email.isNotEmpty)
          pw.Text(c.email, style: pw.TextStyle(font: regular)),
      ],
    );
  }

  static pw.Widget _buildItemsList(
    Recibo r,
    NumberFormat currency,
    pw.Font bold,
    pw.Font regular,
    pw.Font italic,
    PdfColor borderColor,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // Cabeçalho da tabela
        pw.Container(
          decoration: pw.BoxDecoration(
            color: PdfColors.grey200,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 5,
                child: pw.Text(
                  'Descrição',
                  style: pw.TextStyle(
                    font: bold,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Container(
                width: 60,
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'Qtd.',
                  style: pw.TextStyle(
                    font: bold,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Container(
                width: 80,
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Total',
                  style: pw.TextStyle(
                    font: bold,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
        // Itens da tabela
        ...List<pw.Widget>.generate(r.itens.length, (index) {
          final item = r.itens[index];
          final nome = item['nome'] ?? 'Item';
          final descricao = item['descricao'] as String? ?? '';
          final preco = (item['preco'] ?? 0).toDouble();
          final quantidade = (item['quantidade'] ?? 1).toDouble();
          final totalItem = preco * quantidade;

          return pw.Column(
            children: [
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey50,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                ),
                padding: const pw.EdgeInsets.all(12),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Coluna de descrição
                    pw.Expanded(
                      flex: 5,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            nome,
                            style: pw.TextStyle(
                              font: bold,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          if (descricao.isNotEmpty) ...[
                            pw.SizedBox(height: 6),
                            pw.Container(
                              padding: const pw.EdgeInsets.all(8),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.white,
                                borderRadius: pw.BorderRadius.circular(6),
                                border: pw.Border.all(
                                  color: PdfColors.grey200,
                                  width: 0.5,
                                ),
                              ),
                              child: pw.Text(
                                descricao,
                                style: pw.TextStyle(
                                  font: italic,
                                  fontSize: 9,
                                  color: PdfColors.grey700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    // Coluna de quantidade
                    pw.Container(
                      width: 60,
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        quantidade.toStringAsFixed(2),
                        style: pw.TextStyle(font: regular, fontSize: 11),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    // Coluna de total
                    pw.Container(
                      width: 80,
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text(
                        currency.format(totalItem),
                        style: pw.TextStyle(
                          font: bold,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Espaçamento entre itens (não adiciona após o último)
              if (index < r.itens.length - 1) pw.SizedBox(height: 10),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildValoresRecebidosList(
    List<ValorRecebido> valores,
    NumberFormat currency,
    pw.Font bold,
    pw.Font regular,
    PdfColor borderColor,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // Cabeçalho
        pw.Container(
          decoration: pw.BoxDecoration(
            color: PdfColors.grey200,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Data',
                  style: pw.TextStyle(
                    font: bold,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                flex: 3,
                child: pw.Text(
                  'Forma de Pagamento',
                  style: pw.TextStyle(
                    font: bold,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Container(
                width: 100,
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Valor',
                  style: pw.TextStyle(
                    font: bold,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
        // Lista de valores
        ...List<pw.Widget>.generate(valores.length, (index) {
          final valor = valores[index];
          final df = DateFormat('dd/MM/yyyy');

          return pw.Column(
            children: [
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey50,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                ),
                padding: const pw.EdgeInsets.all(12),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        df.format(valor.data.toDate()),
                        style: pw.TextStyle(font: regular, fontSize: 11),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        valor.formaPagamento,
                        style: pw.TextStyle(font: regular, fontSize: 11),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Container(
                      width: 100,
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text(
                        currency.format(valor.valor),
                        style: pw.TextStyle(
                          font: bold,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (index < valores.length - 1) pw.SizedBox(height: 10),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildTotals(
    Recibo r,
    NumberFormat currency,
    pw.Font bold,
    pw.Font regular,
  ) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 220,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (r.itens.isNotEmpty)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Subtotal Itens:',
                    style: pw.TextStyle(font: regular),
                  ),
                  pw.Text(
                    currency.format(r.subtotalItens),
                    style: pw.TextStyle(font: regular),
                  ),
                ],
              )
            else
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total Recebido:',
                    style: pw.TextStyle(font: regular),
                  ),
                  pw.Text(
                    currency.format(r.totalValoresRecebidos),
                    style: pw.TextStyle(font: regular),
                  ),
                ],
              ),
            pw.Divider(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Valor Total:',
                  style: pw.TextStyle(font: bold, fontSize: 14),
                ),
                pw.Text(
                  currency.format(r.valorTotal),
                  style: pw.TextStyle(font: bold, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildAssinaturaSection(
    Uint8List assinatura,
    pw.Font bold,
    pw.Font regular,
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
            font: regular,
            fontSize: 10,
            color: PdfColors.grey700,
          ),
        ),
      ],
    );
  }
}
