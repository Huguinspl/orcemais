import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/cliente.dart';
import '../models/orcamento.dart'; // Importe o modelo de Orçamento
import '../providers/business_provider.dart';
import 'pdf_color_utils.dart';

/// Utilitário para formatação de documentos e telefones no PDF
class _PdfFormatters {
  /// Formata CPF (XXX.XXX.XXX-XX) ou CNPJ (XX.XXX.XXX/XXXX-XX)
  static String formatCpfCnpj(String document) {
    if (document.isEmpty) return '';
    String numbers = document.replaceAll(RegExp(r'\D'), '');
    if (numbers.length == 11) {
      return '${numbers.substring(0, 3)}.${numbers.substring(3, 6)}.${numbers.substring(6, 9)}-${numbers.substring(9)}';
    } else if (numbers.length == 14) {
      return '${numbers.substring(0, 2)}.${numbers.substring(2, 5)}.${numbers.substring(5, 8)}/${numbers.substring(8, 12)}-${numbers.substring(12)}';
    }
    return document;
  }

  /// Formata telefone celular (XX) XXXXX-XXXX ou fixo (XX) XXXX-XXXX
  static String formatPhone(String phone) {
    if (phone.isEmpty) return '';
    String numbers = phone.replaceAll(RegExp(r'\D'), '');
    if (numbers.length == 11) {
      return '(${numbers.substring(0, 2)}) ${numbers.substring(2, 7)}-${numbers.substring(7)}';
    } else if (numbers.length == 10) {
      return '(${numbers.substring(0, 2)}) ${numbers.substring(2, 6)}-${numbers.substring(6)}';
    }
    return phone;
  }
}

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

    // Cores personalizadas para seções específicas
    final laudoBackground = PdfColorUtils.fromArgbInt(
      theme?['laudoBackground'] as int?,
      PdfColors.grey200,
    );
    final laudoText = PdfColorUtils.fromArgbInt(
      theme?['laudoText'] as int?,
      PdfColors.black,
    );
    final garantiaBackground = PdfColorUtils.fromArgbInt(
      theme?['garantiaBackground'] as int?,
      PdfColor.fromHex('#E8F5E9'),
    );
    final garantiaText = PdfColorUtils.fromArgbInt(
      theme?['garantiaText'] as int?,
      PdfColor.fromHex('#1B5E20'),
    );
    final contratoBackground = PdfColorUtils.fromArgbInt(
      theme?['contratoBackground'] as int?,
      PdfColor.fromHex('#FFF3E0'),
    );
    final contratoText = PdfColorUtils.fromArgbInt(
      theme?['contratoText'] as int?,
      PdfColor.fromHex('#E65100'),
    );
    final fotosBackground = PdfColorUtils.fromArgbInt(
      theme?['fotosBackground'] as int?,
      PdfColor.fromHex('#E3F2FD'),
    );
    final fotosText = PdfColorUtils.fromArgbInt(
      theme?['fotosText'] as int?,
      PdfColor.fromHex('#0D47A1'),
    );
    final pagamentoBackground = PdfColorUtils.fromArgbInt(
      theme?['pagamentoBackground'] as int?,
      PdfColor.fromHex('#F3E5F5'),
    );
    final pagamentoText = PdfColorUtils.fromArgbInt(
      theme?['pagamentoText'] as int?,
      PdfColor.fromHex('#4A148C'),
    );
    final valoresBackground = PdfColorUtils.fromArgbInt(
      theme?['valoresBackground'] as int?,
      PdfColor.fromHex('#E0F2F1'),
    );
    final valoresText = PdfColorUtils.fromArgbInt(
      theme?['valoresText'] as int?,
      PdfColor.fromHex('#004D40'),
    );

    // Garante que dados da empresa estejam carregados
    try {
      await businessProvider.carregarDoFirestore();
    } catch (_) {}
    // Carrega mídias
    final logoBytes = await businessProvider.getLogoBytes();
    final assinaturaBytes = await businessProvider.getAssinaturaBytes();

    // Carrega fotos do orçamento
    final List<Uint8List> fotosBytes = [];
    if (orcamento.fotos != null && orcamento.fotos!.isNotEmpty) {
      print('📸 Carregando ${orcamento.fotos!.length} fotos para o PDF...');
      for (final url in orcamento.fotos!) {
        try {
          print('📥 Baixando foto: $url');
          final response = await http.get(Uri.parse(url));
          if (response.statusCode == 200) {
            fotosBytes.add(response.bodyBytes);
            print(
              '✅ Foto baixada com sucesso! (${response.bodyBytes.length} bytes)',
            );
          } else {
            print('❌ Erro ao baixar foto. Status: ${response.statusCode}');
          }
        } catch (e) {
          print('❌ Erro ao baixar foto: $e');
          // Ignora fotos que não puderem ser baixadas
        }
      }
      print('📦 Total de fotos carregadas: ${fotosBytes.length}');
    } else {
      print('ℹ️ Nenhuma foto para adicionar ao PDF');
    }

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
          buildBackground:
              (context) =>
                  pw.FullPage(ignoreMargins: true, child: pw.Container()),
        ),
        maxPages: 100, // Permite até 100 páginas
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
              if ((businessProvider.descricao ?? '').isNotEmpty) ...[
                pw.SizedBox(height: 12),
                pw.Text(
                  businessProvider.descricao!,
                  style: pw.TextStyle(font: font, fontSize: 10),
                ),
              ],
              pw.SizedBox(height: 16),
              _sectionLabel(
                'Dados do Cliente',
                bg: secondaryContainer,
                fg: onSecondaryContainer,
                font: boldFont,
              ),
              pw.SizedBox(height: 8),
              _buildClientInfo(orcamento.cliente, boldFont, font),
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
              _sectionLabel(
                'Condições de pagamento',
                bg: pagamentoBackground,
                fg: pagamentoText,
                font: boldFont,
              ),
              pw.SizedBox(height: 8),
              _buildPagamentoSection(
                orcamento,
                businessProvider,
                boldFont,
                font,
              ),
              pw.SizedBox(height: 24),
              if ((orcamento.laudoTecnico ?? '').trim().isNotEmpty) ...[
                _sectionLabel(
                  'Laudo técnico',
                  bg: laudoBackground,
                  fg: laudoText,
                  font: boldFont,
                ),
                pw.SizedBox(height: 8),
                _buildLaudoTecnicoSection(orcamento, font, outlineVariant),
                pw.SizedBox(height: 24),
              ],
              if ((orcamento.garantia ?? '').trim().isNotEmpty) ...[
                _sectionLabel(
                  'Garantia',
                  bg: garantiaBackground,
                  fg: garantiaText,
                  font: boldFont,
                ),
                pw.SizedBox(height: 8),
                _buildTextSection(orcamento.garantia!, font, outlineVariant),
                pw.SizedBox(height: 24),
              ],
              if ((orcamento.condicoesContratuais ?? '').trim().isNotEmpty) ...[
                _sectionLabel(
                  'Condições Contratuais',
                  bg: contratoBackground,
                  fg: contratoText,
                  font: boldFont,
                ),
                pw.SizedBox(height: 8),
                _buildTextSection(
                  orcamento.condicoesContratuais!,
                  font,
                  outlineVariant,
                ),
                pw.SizedBox(height: 24),
              ],
              if ((orcamento.informacoesAdicionais ?? '')
                  .trim()
                  .isNotEmpty) ...[
                _sectionLabel(
                  'Informações Adicionais',
                  bg: tertiaryContainer,
                  fg: onTertiaryContainer,
                  font: boldFont,
                ),
                pw.SizedBox(height: 8),
                _buildTextSection(
                  orcamento.informacoesAdicionais!,
                  font,
                  outlineVariant,
                ),
                pw.SizedBox(height: 24),
              ],
              if (fotosBytes.isNotEmpty) ...[
                _sectionLabel(
                  'Fotos do Orçamento',
                  bg: fotosBackground,
                  fg: fotosText,
                  font: boldFont,
                ),
                pw.SizedBox(height: 8),
                ..._buildFotosSection(fotosBytes, outlineVariant),
                pw.SizedBox(height: 24),
              ],
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Container(
                    decoration: pw.BoxDecoration(
                      color: valoresBackground,
                      borderRadius: pw.BorderRadius.circular(12),
                      border: pw.Border.all(color: outlineVariant, width: 0.5),
                    ),
                    padding: const pw.EdgeInsets.all(16),
                    child: _buildTotals(
                      orcamento,
                      currencyFormat,
                      boldFont,
                      font,
                      textColor: valoresText,
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
                    if (provider.ramo.isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 2),
                        child: pw.Text(
                          provider.ramo,
                          style: pw.TextStyle(
                            font: regularFont,
                            fontSize: 11,
                            color: textColor,
                          ),
                        ),
                      ),
                    pw.SizedBox(height: 8),
                    if (provider.telefone.isNotEmpty)
                      pw.Text(
                        _PdfFormatters.formatPhone(provider.telefone),
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
                    if (provider.endereco.isNotEmpty)
                      pw.Text(
                        provider.endereco,
                        style: pw.TextStyle(
                          font: regularFont,
                          color: textColor,
                        ),
                      ),
                    if (provider.cnpj.isNotEmpty)
                      pw.Text(
                        _PdfFormatters.formatCpfCnpj(provider.cnpj),
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
            // Título ORÇAMENTO em destaque (maior)
            pw.Text(
              'ORÇAMENTO',
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 28,
                color: textColor,
                letterSpacing: 1.2,
              ),
            ),
            pw.SizedBox(height: 8),
            // Data de criação
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
          pw.Row(
            children: [
              pw.Text(
                'Celular: ',
                style: pw.TextStyle(font: boldFont, fontSize: 10),
              ),
              pw.Text(
                _PdfFormatters.formatPhone(cliente.celular),
                style: pw.TextStyle(font: regularFont, fontSize: 10),
              ),
            ],
          ),
        if (cliente.telefone.isNotEmpty)
          pw.Row(
            children: [
              pw.Text(
                'Telefone: ',
                style: pw.TextStyle(font: boldFont, fontSize: 10),
              ),
              pw.Text(
                _PdfFormatters.formatPhone(cliente.telefone),
                style: pw.TextStyle(font: regularFont, fontSize: 10),
              ),
            ],
          ),
        if (cliente.email.isNotEmpty)
          pw.Row(
            children: [
              pw.Text(
                'E-mail: ',
                style: pw.TextStyle(font: boldFont, fontSize: 10),
              ),
              pw.Text(
                cliente.email,
                style: pw.TextStyle(font: regularFont, fontSize: 10),
              ),
            ],
          ),
        if (cliente.cpfCnpj.isNotEmpty)
          pw.Row(
            children: [
              pw.Text(
                'CPF/CNPJ: ',
                style: pw.TextStyle(font: boldFont, fontSize: 10),
              ),
              pw.Text(
                _PdfFormatters.formatCpfCnpj(cliente.cpfCnpj),
                style: pw.TextStyle(font: regularFont, fontSize: 10),
              ),
            ],
          ),
        if (cliente.observacoes.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Observações:',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  cliente.observacoes,
                  style: pw.TextStyle(
                    font: regularFont,
                    fontSize: 10,
                    color: PdfColors.grey800,
                  ),
                ),
              ],
            ),
          ),
        ],
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
                    font: boldFont,
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
                    font: boldFont,
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
                    font: boldFont,
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
        ...List<pw.Widget>.generate(itens.length, (index) {
          final item = itens[index];
          final nome = item['nome'] ?? 'Item';
          final descricao = item['descricao'] as String? ?? '';
          final preco = item['preco'] as double? ?? 0.0;
          final quantidade = item['quantidade'] as double? ?? 1.0;
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
                              font: boldFont,
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
                                  font: italicFont,
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
                        style: pw.TextStyle(font: regularFont, fontSize: 11),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    // Coluna de total
                    pw.Container(
                      width: 80,
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text(
                        currencyFormat.format(totalItem),
                        style: pw.TextStyle(
                          font: boldFont,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Espaçamento entre itens (não adiciona após o último)
              if (index < itens.length - 1) pw.SizedBox(height: 10),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildTotals(
    Orcamento orcamento,
    NumberFormat currencyFormat,
    pw.Font boldFont,
    pw.Font regularFont, {
    PdfColor? textColor,
  }) {
    final color = textColor ?? PdfColors.black;
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
                pw.Text(
                  'Subtotal:',
                  style: pw.TextStyle(font: regularFont, color: color),
                ),
                pw.Text(
                  currencyFormat.format(orcamento.subtotal),
                  style: pw.TextStyle(font: regularFont, color: color),
                ),
              ],
            ),
            if (custoTotal > 0)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Custos Adicionais:',
                    style: pw.TextStyle(font: regularFont, color: color),
                  ),
                  pw.Text(
                    currencyFormat.format(custoTotal),
                    style: pw.TextStyle(font: regularFont, color: color),
                  ),
                ],
              ),
            if (orcamento.desconto > 0)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Desconto:',
                    style: pw.TextStyle(font: regularFont, color: color),
                  ),
                  pw.Text(
                    '- ${currencyFormat.format(orcamento.desconto)}',
                    style: pw.TextStyle(font: regularFont, color: color),
                  ),
                ],
              ),
            pw.Divider(height: 10, color: color),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Valor Total:',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                    color: color,
                  ),
                ),
                pw.Text(
                  currencyFormat.format(orcamento.valorTotal),
                  style: pw.TextStyle(
                    font: boldFont,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildPagamentoSection(
    Orcamento orcamento,
    BusinessProvider businessProvider,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    final metodo = orcamento.metodoPagamento?.trim() ?? '';
    final parcelas = orcamento.parcelas;

    // Se não há método de pagamento informado
    if (metodo.isEmpty) {
      return pw.Text(
        'Não informado',
        style: pw.TextStyle(
          font: regularFont,
          fontSize: 10,
          color: PdfColors.grey600,
        ),
      );
    }

    // Determina o label de acordo com o método
    String label;
    switch (metodo) {
      case 'dinheiro':
        label = 'Dinheiro';
        break;
      case 'pix':
        label = 'Pix';
        break;
      case 'debito':
        label = 'Débito';
        break;
      case 'credito':
        label =
            'Crédito' + ((parcelas ?? 1) > 1 ? ' em ${parcelas}x' : ' à vista');
        break;
      case 'boleto':
        label = 'Boleto';
        break;
      default:
        label = metodo;
    }

    // Lista de widgets a serem renderizados
    final children = <pw.Widget>[
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Forma de pagamento:',
            style: pw.TextStyle(
              font: boldFont,
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
            ),
          ),
          pw.Text(label, style: pw.TextStyle(font: regularFont, fontSize: 11)),
        ],
      ),
    ];

    // Se for Pix e houver chave cadastrada, adiciona as informações
    if (metodo == 'pix' &&
        businessProvider.pixChave != null &&
        businessProvider.pixChave!.isNotEmpty) {
      final tipo = businessProvider.pixTipo ?? 'chave';
      children.add(pw.SizedBox(height: 8));
      children.add(
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: 16,
              height: 16,
              margin: const pw.EdgeInsets.only(right: 8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey700, width: 1.5),
                borderRadius: pw.BorderRadius.circular(3),
              ),
              child: pw.Center(
                child: pw.Text(
                  '⊞',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                'Chave Pix ($tipo): ${businessProvider.pixChave!}',
                style: pw.TextStyle(font: regularFont, fontSize: 10),
              ),
            ),
          ],
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: children,
    );
  }

  static pw.Widget _buildLaudoTecnicoSection(
    Orcamento orcamento,
    pw.Font regularFont,
    PdfColor borderColor,
  ) {
    final laudoText = orcamento.laudoTecnico?.trim() ?? '';

    if (laudoText.isEmpty) {
      return pw.SizedBox.shrink();
    }

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: borderColor, width: 0.5),
      ),
      child: pw.Text(
        laudoText,
        style: pw.TextStyle(font: regularFont, fontSize: 11, lineSpacing: 1.5),
        overflow: pw.TextOverflow.span,
        textAlign: pw.TextAlign.left,
      ),
    );
  }

  static pw.Widget _buildTextSection(
    String text,
    pw.Font regularFont,
    PdfColor borderColor,
  ) {
    final cleanText = text.trim();

    if (cleanText.isEmpty) {
      return pw.SizedBox.shrink();
    }

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: borderColor, width: 0.5),
      ),
      child: pw.Text(
        cleanText,
        style: pw.TextStyle(font: regularFont, fontSize: 11, lineSpacing: 1.5),
        overflow: pw.TextOverflow.span,
        textAlign: pw.TextAlign.left,
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

  static List<pw.Widget> _buildFotosSection(
    List<Uint8List> fotosBytes,
    PdfColor borderColor,
  ) {
    final widgets = <pw.Widget>[];

    // Adiciona fotos em grade (2 por linha)
    for (int i = 0; i < fotosBytes.length; i += 2) {
      final row = <pw.Widget>[];

      // Primeira foto da linha
      row.add(
        pw.Expanded(
          child: pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: borderColor, width: 0.5),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            padding: const pw.EdgeInsets.all(4),
            child: pw.Image(
              pw.MemoryImage(fotosBytes[i]),
              fit: pw.BoxFit.contain,
            ),
          ),
        ),
      );

      // Segunda foto da linha (se existir)
      if (i + 1 < fotosBytes.length) {
        row.add(pw.SizedBox(width: 8));
        row.add(
          pw.Expanded(
            child: pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: borderColor, width: 0.5),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              padding: const pw.EdgeInsets.all(4),
              child: pw.Image(
                pw.MemoryImage(fotosBytes[i + 1]),
                fit: pw.BoxFit.contain,
              ),
            ),
          ),
        );
      } else {
        // Se for ímpar, adiciona espaço vazio
        row.add(pw.Expanded(child: pw.Container()));
      }

      widgets.add(
        pw.Container(
          height: 150,
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: row,
          ),
        ),
      );

      if (i + 2 < fotosBytes.length) {
        widgets.add(pw.SizedBox(height: 8));
      }
    }

    return widgets;
  }

  // Removidas heurísticas de medição/que bra; o MultiPage faz a paginação natural
}
