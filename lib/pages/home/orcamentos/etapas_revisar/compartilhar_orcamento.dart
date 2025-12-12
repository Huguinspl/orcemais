import 'package:deep_link/models/link_model.dart';
import 'package:deep_link/services/link_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';

import '../../../../models/orcamento.dart';
import '../../../../models/servico.dart';
import '../../../../providers/business_provider.dart';
import '../../../../providers/services_provider.dart';
import '../../../../providers/orcamentos_provider.dart';
import '../../../../providers/user_provider.dart';
import '../../../../utils/orcamento_pdf_generator.dart';

class CompartilharOrcamentoPage extends StatefulWidget {
  final Orcamento orcamento;

  const CompartilharOrcamentoPage({super.key, required this.orcamento});

  @override
  State<CompartilharOrcamentoPage> createState() =>
      _CompartilharOrcamentoPageState();
}

class _CompartilharOrcamentoPageState extends State<CompartilharOrcamentoPage> {
  String? _linkGerado; // Armazena o link gerado

  @override
  void initState() {
    super.initState();
    // Se o orçamento já tem link, usar ele
    _linkGerado = widget.orcamento.linkWeb;
  }

  Orcamento get orcamento => widget.orcamento;

  // ✅ CORREÇÃO 1: Adicionando a função para gerar e compartilhar o PDF
  Future<void> _gerarECompartilharPdf(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      debugPrint('🔵 Iniciando geração do PDF...');
      final businessProvider = context.read<BusinessProvider>();

      // Garante que os dados do negócio estejam carregados
      debugPrint('🔵 Carregando dados do negócio...');
      await businessProvider.carregarDoFirestore();
      debugPrint('✅ Dados do negócio carregados');

      debugPrint('🔵 Gerando PDF...');
      final pdfBytes = await OrcamentoPdfGenerator.generate(
        orcamento, // Passa o objeto Orcamento inteiro
        businessProvider,
      );
      debugPrint('✅ PDF gerado com sucesso: ${pdfBytes.length} bytes');

      // Fecha o diálogo de carregamento ANTES de abrir o compartilhamento
      if (context.mounted) {
        Navigator.of(context).pop();
        debugPrint('🔵 Dialog fechado');
      }

      // Compartilha o PDF com formato explícito
      debugPrint('🔵 Abrindo compartilhamento...');
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename:
            'orcamento_${orcamento.cliente.nome.replaceAll(' ', '_')}.pdf',
      );
      debugPrint('✅ Compartilhamento concluído');

      // Após o compartilhamento, atualiza o status para "Enviado"
      if (context.mounted) {
        debugPrint('🔵 Atualizando status para Enviado...');
        await context.read<OrcamentosProvider>().atualizarStatus(
          orcamento.id,
          'Enviado',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Orçamento enviado e status atualizado!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        debugPrint('✅ Status atualizado');
      }
    } catch (e, stackTrace) {
      if (context.mounted) Navigator.of(context).pop();
      debugPrint('❌ ERRO ao gerar ou compartilhar PDF: $e');
      debugPrint('Stack trace: $stackTrace');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao processar PDF: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // ✅ NOVO: Método para compartilhar link existente
  Future<void> _compartilharLinkExistente(BuildContext context) async {
    try {
      final businessProvider = context.read<BusinessProvider>();

      // Carregar dados do negócio se necessário
      if (businessProvider.nomeEmpresa.isEmpty) {
        await businessProvider.carregarDoFirestore();
      }

      // Texto de compartilhamento personalizado
      final numeroFormatado = '#${orcamento.numero.toString().padLeft(4, '0')}';
      final String textoParaCompartilhar = '''
Olá, ${orcamento.cliente.nome}! 👋

Segue o orçamento ${numeroFormatado} de ${businessProvider.nomeEmpresa}.

🔗 Visualize seu orçamento:
${orcamento.linkWeb}

${businessProvider.telefone.isNotEmpty ? '📞 Contato: ${businessProvider.telefone}' : ''}
${businessProvider.emailEmpresa.isNotEmpty ? '📧 Email: ${businessProvider.emailEmpresa}' : ''}

Obrigado pela preferência! 😊
''';

      // Compartilha o link
      await Share.share(
        textoParaCompartilhar,
        subject: 'Orçamento $numeroFormatado - ${businessProvider.nomeEmpresa}',
      );

      // Após o compartilhamento, atualiza o status para "Enviado"
      if (context.mounted) {
        await context.read<OrcamentosProvider>().atualizarStatus(
          orcamento.id,
          'Enviado',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Orçamento enviado e status atualizado!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erro ao compartilhar link existente: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao compartilhar link: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // Função para gerar o link (sem compartilhar automaticamente)
  Future<String?> _gerarLink(
    BuildContext context, {
    bool mostrarLoading = true,
  }) async {
    // ✅ Verificar se o link já foi gerado
    if (_linkGerado != null && _linkGerado!.isNotEmpty) {
      debugPrint('✅ Usando link web já gerado: $_linkGerado');
      return _linkGerado;
    }

    if (orcamento.linkWeb != null && orcamento.linkWeb!.isNotEmpty) {
      debugPrint(
        '✅ Usando link web existente do orçamento: ${orcamento.linkWeb}',
      );
      setState(() => _linkGerado = orcamento.linkWeb);
      return orcamento.linkWeb;
    }

    // Se não existe, gerar novo link
    debugPrint('🌐 Link web não existe, gerando novo...');

    if (mostrarLoading) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      debugPrint('🌐 Iniciando geração do Link Web...');
      final businessProvider = context.read<BusinessProvider>();
      final userProvider = context.read<UserProvider>();
      final orcamentosProvider = context.read<OrcamentosProvider>();

      debugPrint('🌐 UserId: ${userProvider.uid}');
      debugPrint('🌐 OrcamentoId: ${orcamento.id}');

      // Preparar parâmetros personalizados
      final parametrosPersonalizados = <String, dynamic>{
        'userId': userProvider.uid,
        'documentoId': orcamento.id,
        'tipoDocumento': 'orcamento',
      };

      debugPrint('🌐 Criando Deep Link...');
      final link = await DeepLink.createLink(
        LinkModel(
          dominio: 'link.orcemais.com',
          titulo:
              'Orçamento ${orcamento.numero} - ${businessProvider.nomeEmpresa}',
          slug: orcamento.id,
          onlyWeb: true,
          urlImage: businessProvider.logoUrl,
          urlDesktop: 'https://gestorfy-cliente.web.app',
          parametrosPersonalizados: parametrosPersonalizados,
        ),
      );

      debugPrint('✅ Link criado: ${link.link}');

      // ✅ Salvar o link no orçamento
      await orcamentosProvider.atualizarLinkWeb(orcamento.id, link.link);
      debugPrint('✅ Link salvo no orçamento');

      // ✅ NOVO: Salvar snapshot completo para carregamento rápido no link web
      debugPrint('🌐 Salvando snapshot de compartilhamento...');
      await orcamentosProvider.salvarSnapshotCompartilhamento(
        orcamento: orcamento,
        businessInfo: {
          'nomeEmpresa': businessProvider.nomeEmpresa,
          'telefone': businessProvider.telefone,
          'ramo': businessProvider.ramo,
          'endereco': businessProvider.endereco,
          'cnpj': businessProvider.cnpj,
          'emailEmpresa': businessProvider.emailEmpresa,
          'logoUrl': businessProvider.logoUrl,
          'pixTipo': businessProvider.pixTipo,
          'pixChave': businessProvider.pixChave,
          'descricao': businessProvider.descricao,
          'assinaturaUrl': businessProvider.assinaturaUrl,
        },
        linkWeb: link.link,
      );
      debugPrint('✅ Snapshot salvo para carregamento rápido');

      // Atualizar o estado local
      setState(() => _linkGerado = link.link);

      if (mostrarLoading && context.mounted) {
        Navigator.of(context).pop();
      }

      return link.link;
    } catch (e) {
      if (mostrarLoading && context.mounted) {
        Navigator.of(context).pop();
      }
      debugPrint('Erro ao gerar link: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  // Função para gerar e compartilhar o link do orçamento
  Future<void> _gerarECompartilharLink(BuildContext context) async {
    // Gerar o link primeiro (se ainda não foi gerado)
    final link = await _gerarLink(context);

    if (link == null) return;

    // Agora compartilhar o link gerado
    try {
      final businessProvider = context.read<BusinessProvider>();

      // Carregar dados do negócio se necessário
      if (businessProvider.nomeEmpresa.isEmpty) {
        await businessProvider.carregarDoFirestore();
      }

      // Texto de compartilhamento personalizado
      final numeroFormatado = '#${orcamento.numero.toString().padLeft(4, '0')}';
      final String textoParaCompartilhar = '''
Olá, ${orcamento.cliente.nome}! 👋

Segue o orçamento ${numeroFormatado} de ${businessProvider.nomeEmpresa}.

🔗 Visualize seu orçamento:
$link

${businessProvider.telefone.isNotEmpty ? '📞 Contato: ${businessProvider.telefone}' : ''}
${businessProvider.emailEmpresa.isNotEmpty ? '📧 Email: ${businessProvider.emailEmpresa}' : ''}

Obrigado pela preferência! 😊
''';

      // Compartilha o link
      await Share.share(
        textoParaCompartilhar,
        subject: 'Orçamento $numeroFormatado - ${businessProvider.nomeEmpresa}',
      );

      // Após o compartilhamento, atualiza o status para "Enviado"
      if (context.mounted) {
        await context.read<OrcamentosProvider>().atualizarStatus(
          orcamento.id,
          'Enviado',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Orçamento enviado e status atualizado!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Fecha o loading em caso de erro
      if (context.mounted) Navigator.of(context).pop();

      debugPrint('Erro ao compartilhar link: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao compartilhar link: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // ✅ CORREÇÃO 2: Adicionando a função para salvar o orçamento como modelo
  Future<void> _salvarComoModelo(BuildContext context) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Salvar como Modelo'),
            content: const Text(
              'Deseja salvar os itens deste orçamento no seu catálogo de serviços?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Salvar'),
              ),
            ],
          ),
    );

    if (confirmado == true && context.mounted) {
      final provider = context.read<ServicesProvider>();
      int itensSalvos = 0;
      for (final item in orcamento.itens) {
        final novoServico = Servico.fromMap(item);
        try {
          await provider.adicionarServico(novoServico);
          itensSalvos++;
        } catch (e) {
          debugPrint('Erro ao salvar item "${novoServico.titulo}": $e');
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$itensSalvos itens foram salvos no seu catálogo!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final numeroFormatado = '#${orcamento.numero.toString().padLeft(4, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Compartilhar Orçamento',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.blue.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                // Ícone de sucesso com animação
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.shade200.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    color: Colors.green.shade600,
                    size: 80,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Orçamento Salvo!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Agora você pode compartilhá-lo com seu cliente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 40),
                _buildActionCard(
                  context,
                  icon: Icons.picture_as_pdf_outlined,
                  label: 'Enviar orçamento em PDF',
                  subtitle: 'Gerar e compartilhar arquivo PDF',
                  color: Colors.red,
                  onTap: () => _gerarECompartilharPdf(context),
                ),
                const SizedBox(height: 14),
                _buildActionCard(
                  context,
                  icon: Icons.link_rounded,
                  label: 'Enviar orçamento em Link',
                  subtitle: 'Cliente visualiza direto no navegador',
                  color: Colors.blue,
                  onTap: () => _gerarECompartilharLink(context),
                ),
                const SizedBox(height: 14),
                _buildActionCard(
                  context,
                  icon: Icons.bookmark_border,
                  label: 'Salvar como Modelo',
                  subtitle: 'Adicionar itens ao catálogo',
                  color: Colors.orange,
                  onTap: () => _salvarComoModelo(context),
                ),
                const SizedBox(height: 32),
                // Botões de ação rápida
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(
                          Icons.copy_all_outlined,
                          color: Colors.blue.shade700,
                        ),
                        label: Text(
                          'Copiar Link',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () async {
                          // ✅ Gerar link automaticamente se não existir
                          final link = await _gerarLink(context);

                          if (link == null || link.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: const [
                                    Icon(Icons.error, color: Colors.white),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Erro ao gerar link. Tente novamente.',
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: Colors.red.shade600,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                            return;
                          }

                          Clipboard.setData(ClipboardData(text: link));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Link do orçamento $numeroFormatado copiado!',
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: Colors.green.shade600,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: Colors.blue.shade700,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade700,
                              Colors.blue.shade500,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.shade300.withOpacity(0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.share, color: Colors.white),
                          label: const Text(
                            'Compartilhar',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () => _gerarECompartilharLink(context),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: Text(
                    'Voltar ao início',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.chevron_right, color: color, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
