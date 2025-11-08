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

class CompartilharOrcamentoPage extends StatelessWidget {
  final Orcamento orcamento;

  const CompartilharOrcamentoPage({super.key, required this.orcamento});

  // ✅ CORREÇÃO 1: Adicionando a função para gerar e compartilhar o PDF
  Future<void> _gerarECompartilharPdf(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final businessProvider = context.read<BusinessProvider>();
      // Garante que os dados do negócio estejam carregados
      await businessProvider.carregarDoFirestore();

      final pdfBytes = await OrcamentoPdfGenerator.generate(
        orcamento, // Passa o objeto Orcamento inteiro
        businessProvider,
      );

      // Fecha o diálogo de carregamento ANTES de abrir o compartilhamento
      if (context.mounted) Navigator.of(context).pop();

      // Compartilha o PDF com formato explícito
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename:
            'orcamento_${orcamento.cliente.nome.replaceAll(' ', '_')}.pdf',
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
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      debugPrint('Erro ao gerar ou compartilhar PDF: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao processar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Função para gerar e compartilhar o link do orçamento
  Future<void> _gerarECompartilharLink(BuildContext context) async {
    // Mostra loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final businessProvider = context.read<BusinessProvider>();
      final userProvider = context.read<UserProvider>();

      final link = await DeepLink.createLink(
        LinkModel(
          dominio: 'link.orcemais.com',
          prefixo: 'orcamento',
          titulo:
              'Orçamento ${orcamento.numero} - ${businessProvider.nomeEmpresa}',
          slug: '${userProvider.uid}-${orcamento.id}',
          onlyWeb: true,
          urlImage: businessProvider.logoUrl,
          urlDesktop:
              'https://gestorfy-cliente.web.app/orcamento/${userProvider.uid}-${orcamento.id}',
        ),
      );

      final linkDoOrcamento =
          'https://${link.dominio}/${link.prefixo}/${link.slug}';

      print('(${link.dominio}) (${link.prefixo})');

      // Obter o userId (necessário para buscar o orçamento no Firestore)
      final userId = userProvider.uid;
      if (userId.isEmpty) {
        throw Exception('Usuário não autenticado');
      }

      // Gerar o link do orçamento
      // Formato: https://orcamentos.gestorfy.com/view?u={userId}&o={orcamentoId}

      // Texto de compartilhamento personalizado
      final numeroFormatado = '#${orcamento.numero.toString().padLeft(4, '0')}';
      final String textoParaCompartilhar = '''
Olá, ${orcamento.cliente.nome}! 👋

Segue o orçamento ${numeroFormatado} de ${businessProvider.nomeEmpresa}.

🔗 Visualize seu orçamento:
$linkDoOrcamento

${businessProvider.telefone.isNotEmpty ? '📞 Contato: ${businessProvider.telefone}' : ''}
${businessProvider.emailEmpresa.isNotEmpty ? '📧 Email: ${businessProvider.emailEmpresa}' : ''}

Obrigado pela preferência! 😊
''';

      // Fecha o loading
      if (context.mounted) Navigator.of(context).pop();

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
    final userProvider = context.read<UserProvider>();

    // Gerar o link com os parâmetros corretos
    final userId = userProvider.uid;
    final linkDoOrcamento =
        userId.isNotEmpty
            ? 'https://orcamentos.gestorfy.com/view?u=$userId&o=${orcamento.id}'
            : 'https://orcamentos.gestorfy.com/view?o=${orcamento.id}';

    final numeroFormatado = '#${orcamento.numero.toString().padLeft(4, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compartilhar Orçamento'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 80,
            ),
            const SizedBox(height: 16),
            const Text(
              'Orçamento Salvo!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Agora você pode compartilhá-lo com seu cliente.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            _buildActionCard(
              context,
              icon: Icons.picture_as_pdf_outlined,
              label: 'Enviar orçamento em PDF',
              subtitle: 'Gerar e compartilhar arquivo PDF',
              onTap: () => _gerarECompartilharPdf(context),
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              context,
              icon: Icons.link_rounded,
              label: 'Enviar orçamento em Link',
              subtitle: 'Cliente visualiza direto no navegador',
              onTap: () => _gerarECompartilharLink(context),
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              context,
              icon: Icons.bookmark_border,
              label: 'Salvar como Modelo',
              subtitle: 'Adicionar itens ao catálogo',
              onTap: () => _salvarComoModelo(context),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.copy_all_outlined),
                    label: const Text('Copiar Link'),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: linkDoOrcamento));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Link do orçamento $numeroFormatado copiado!',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.share),
                    label: const Text('Compartilhar'),
                    onPressed: () => _gerarECompartilharLink(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
              child: const Text('Voltar ao início'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle:
            subtitle != null
                ? Text(subtitle, style: const TextStyle(fontSize: 12))
                : null,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
