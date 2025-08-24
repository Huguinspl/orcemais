import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/recibo.dart';
import '../models/valor_recebido.dart';
import '../providers/business_provider.dart';

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
    final dateFormat = DateFormat('dd/MM/yyyy');
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();
    final italicFont = await PdfGoogleFonts.robotoItalic();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build:
            (ctx) => [
              _buildHeader(
                recibo,
                businessProvider,
                boldFont,
                font,
                dateFormat,
                logoBytes,
              ),
              pw.SizedBox(height: 24),
              _buildClientInfo(recibo, boldFont, font),
              pw.SizedBox(height: 24),
              if (recibo.itens.isNotEmpty)
                pw.Column(
                  children: [
                    pw.Text(
                      'Itens / Serviços',
                      style: pw.TextStyle(font: boldFont, fontSize: 16),
                    ),
                    pw.SizedBox(height: 12),
                    _buildItemsTable(
                      recibo,
                      currency,
                      boldFont,
                      font,
                      italicFont,
                    ),
                    pw.SizedBox(height: 24),
                  ],
                )
              else
                pw.Column(
                  children: [
                    pw.Text(
                      'Valores Recebidos',
                      style: pw.TextStyle(font: boldFont, fontSize: 16),
                    ),
                    pw.SizedBox(height: 12),
                    _buildValoresRecebidosTable(
                      recibo.valoresRecebidos,
                      currency,
                      boldFont,
                      font,
                    ),
                    pw.SizedBox(height: 24),
                  ],
                ),
              _buildTotals(recibo, currency, boldFont, font),
              if (assinaturaBytes != null && assinaturaBytes.isNotEmpty) ...[
                pw.SizedBox(height: 40),
                _buildAssinaturaSection(assinaturaBytes, boldFont, font),
              ],
            ],
      ),
    );
    return pdf.save();
  }

  static pw.Widget _buildHeader(
    Recibo r,
    BusinessProvider b,
    pw.Font bold,
    pw.Font regular,
    DateFormat df,
    Uint8List? logoBytes,
  ) {
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
                      style: pw.TextStyle(font: bold, fontSize: 20),
                    ),
                    if (b.telefone.isNotEmpty)
                      pw.Text(b.telefone, style: pw.TextStyle(font: regular)),
                    if (b.emailEmpresa.isNotEmpty)
                      pw.Text(
                        b.emailEmpresa,
                        style: pw.TextStyle(font: regular),
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
              'Recibo #${r.numero.toString().padLeft(4, '0')}',
              style: pw.TextStyle(font: bold, fontSize: 14),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Data: ${df.format(r.criadoEm.toDate())}',
              style: pw.TextStyle(font: regular, fontSize: 10),
            ),
            pw.SizedBox(height: 4),
            pw.Container(
              height: 40,
              width: 40,
              child: pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: 'Recibo #${r.numero}',
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

  static pw.Widget _buildItemsTable(
    Recibo r,
    NumberFormat currency,
    pw.Font bold,
    pw.Font regular,
    pw.Font italic,
  ) {
    const headers = ['Descrição', 'Qtd.', 'Total'];
    return pw.Table.fromTextArray(
      headers: headers,
      data: List.generate(r.itens.length, (i) {
        final item = r.itens[i];
        final nome = item['nome'] ?? 'Item';
        final descricao = item['descricao'] ?? '';
        final preco = (item['preco'] ?? 0).toDouble();
        final quantidade = (item['quantidade'] ?? 1).toDouble();
        final total = preco * quantidade;
        return [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                nome,
                style: pw.TextStyle(
                  font: regular,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (descricao.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 4),
                  child: pw.Text(
                    descricao,
                    style: pw.TextStyle(
                      font: italic,
                      fontSize: 9,
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
            ],
          ),
          quantidade.toStringAsFixed(2),
          currency.format(total),
        ];
      }),
      headerStyle: pw.TextStyle(font: bold, fontWeight: pw.FontWeight.bold),
      cellStyle: pw.TextStyle(font: regular),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.centerRight,
      },
      cellPadding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
    );
  }

  static pw.Widget _buildValoresRecebidosTable(
    List<ValorRecebido> valores,
    NumberFormat currency,
    pw.Font bold,
    pw.Font regular,
  ) {
    const headers = ['Data', 'Forma', 'Valor'];
    final df = DateFormat('dd/MM/yyyy');
    return pw.Table.fromTextArray(
      headers: headers,
      data:
          valores
              .map(
                (v) => [
                  df.format(v.data.toDate()),
                  v.formaPagamento,
                  currency.format(v.valor),
                ],
              )
              .toList(),
      headerStyle: pw.TextStyle(font: bold, fontWeight: pw.FontWeight.bold),
      cellStyle: pw.TextStyle(font: regular),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.centerRight,
      },
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
