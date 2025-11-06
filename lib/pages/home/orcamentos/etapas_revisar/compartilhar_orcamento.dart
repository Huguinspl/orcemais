import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../../../../models/orcamento.dart';
import '../../../../models/servico.dart';
import '../../../../providers/business_provider.dart';
import '../../../../providers/services_provider.dart';
import '../../../../providers/orcamentos_provider.dart';
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
    final businessProvider = context.read<BusinessProvider>();
    final String linkDoOrcamento =
        'https://seu-app-web.com/orcamento/${orcamento.id}';
    final String textoParaCompartilhar =
        'Olá, ${orcamento.cliente.nome}! Aqui está o seu orçamento de ${businessProvider.nomeEmpresa}: \n$linkDoOrcamento';

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
              onTap:
                  () => _gerarECompartilharPdf(
                    context,
                  ), // <-- Conectando a função
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              context,
              icon: Icons.bookmark_border,
              label: 'Salvar como Modelo',
              onTap:
                  () => _salvarComoModelo(context), // <-- Conectando a função
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
                        const SnackBar(
                          content: Text('Link do orçamento copiado!'),
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
                    onPressed: () {
                      Share.share(
                        textoParaCompartilhar,
                        subject: 'Orçamento de ${businessProvider.nomeEmpresa}',
                      );
                    },
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
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
