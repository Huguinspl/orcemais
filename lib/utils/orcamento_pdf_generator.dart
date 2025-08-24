import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/cliente.dart';
import '../models/orcamento.dart'; // Importe o modelo de Orçamento
import '../providers/business_provider.dart';

class OrcamentoPdfGenerator {
  // ✅ CORREÇÃO 1: O método agora recebe o objeto Orcamento completo
  static Future<Uint8List> generate(
    Orcamento orcamento,
    BusinessProvider businessProvider,
  ) async {
    final pdf = pw.Document();
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();
    final italicFont = await PdfGoogleFonts.robotoItalic();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build:
            (context) => [
              _buildHeader(orcamento, businessProvider, boldFont, font),
              pw.Divider(height: 40),
              _buildClientInfo(orcamento.cliente, boldFont, font),
              pw.SizedBox(height: 24),
              pw.Text(
                'Itens do Orçamento',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  font: boldFont,
                  fontSize: 16,
                ),
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
              _buildTotals(orcamento, currencyFormat, boldFont, font),
            ],
      ),
    );

    return pdf.save();
  }

  // ✅ CORREÇÃO 2: Os helpers agora extraem os dados do objeto Orcamento
  static pw.Widget _buildHeader(
    Orcamento orcamento,
    BusinessProvider provider,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                provider.nomeEmpresa,
                style: pw.TextStyle(font: boldFont, fontSize: 20),
              ),
              pw.SizedBox(height: 8),
              if (provider.telefone.isNotEmpty)
                pw.Text(
                  provider.telefone,
                  style: pw.TextStyle(font: regularFont),
                ),
              if (provider.emailEmpresa.isNotEmpty)
                pw.Text(
                  provider.emailEmpresa,
                  style: pw.TextStyle(font: regularFont),
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
              style: pw.TextStyle(font: boldFont, fontSize: 14),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Data: ${DateFormat('dd/MM/yyyy').format(orcamento.dataCriacao.toDate())}',
              style: pw.TextStyle(font: regularFont, fontSize: 10),
            ),
            pw.SizedBox(height: 4),
            pw.Container(
              height: 40,
              width: 40,
              child: pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: 'Orçamento #${orcamento.numero}',
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
}
