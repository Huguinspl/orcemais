import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../models/recibo.dart';
import '../../../providers/business_provider.dart';
import '../../../providers/recibos_provider.dart';
import '../../../utils/recibo_pdf_generator.dart';

class CompartilharReciboPage extends StatelessWidget {
  final Recibo recibo;
  const CompartilharReciboPage({super.key, required this.recibo});

  Future<void> _gerarECompartilharPdf(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final business = context.read<BusinessProvider>();
      await business.carregarDoFirestore();
      final bytes = await ReciboPdfGenerator.generate(recibo, business);
      if (context.mounted) Navigator.pop(context);
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'recibo_${recibo.numero.toString().padLeft(4, '0')}.pdf',
      );
      if (context.mounted) {
        await context.read<RecibosProvider>().atualizarStatus(
          recibo.id,
          'Enviado',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recibo enviado e status atualizado!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar/compartilhar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final business = context.read<BusinessProvider>();
    final link = 'https://seu-app-web.com/recibo/${recibo.id}';
    final texto =
        'Olá, ${recibo.cliente.nome}! Segue o recibo de ${business.nomeEmpresa}:\n$link';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compartilhar Recibo'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            const Icon(Icons.receipt_long, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            const Text(
              'Recibo Salvo!',
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
              label: 'Enviar recibo em PDF',
              onTap: () => _gerarECompartilharPdf(context),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.copy_all_outlined),
                    label: const Text('Copiar Link'),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: link));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Link do recibo copiado!'),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.share),
                    label: const Text('Compartilhar'),
                    onPressed:
                        () => Share.share(
                          texto,
                          subject: 'Recibo de ${business.nomeEmpresa}',
                        ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
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
