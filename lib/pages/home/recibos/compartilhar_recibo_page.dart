import 'package:deep_link/models/link_model.dart';
import 'package:deep_link/services/link_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orcemais/providers/user_provider.dart';
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
      debugPrint('📄 Iniciando geração do PDF do recibo...');
      final business = context.read<BusinessProvider>();

      debugPrint('🔄 Carregando dados do negócio...');
      await business.carregarDoFirestore();
      debugPrint('✅ Dados do negócio carregados');

      debugPrint('🔄 Gerando PDF do recibo...');
      final bytes = await ReciboPdfGenerator.generate(recibo, business);
      debugPrint('✅ PDF gerado com sucesso: ${bytes.length} bytes');

      if (context.mounted) {
        Navigator.pop(context);
        debugPrint('🔄 Dialog fechado');
      }

      debugPrint('🔄 Abrindo compartilhamento...');
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'recibo_${recibo.numero.toString().padLeft(4, '0')}.pdf',
      );
      debugPrint('✅ Compartilhamento concluído');

      if (context.mounted) {
        debugPrint('🔄 Atualizando status para Enviado...');
        await context.read<RecibosProvider>().atualizarStatus(
          recibo.id,
          'Enviado',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recibo enviado e status atualizado!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        debugPrint('✅ Status atualizado');
      }
    } catch (e, stackTrace) {
      if (context.mounted) Navigator.pop(context);
      debugPrint('❌ ERRO ao gerar ou compartilhar PDF do recibo: $e');
      debugPrint('Stack trace: $stackTrace');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar/compartilhar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final business = context.read<BusinessProvider>();
    final link = recibo.link ?? 'Link não disponível';
    final numeroFormatado = '#${recibo.numero.toString().padLeft(4, '0')}';
    final texto =
        'Olá, ${recibo.cliente.nome}! Segue o recibo $numeroFormatado de ${business.nomeEmpresa}:\n$link';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Compartilhar Recibo',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade600, Colors.teal.shade400],
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
            colors: [Colors.teal.shade50, Colors.white, Colors.white],
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
                  'Recibo Salvo!',
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
                  label: 'Enviar recibo em PDF',
                  subtitle: 'Gerar e compartilhar arquivo PDF',
                  color: Colors.red,
                  onTap: () => _gerarECompartilharPdf(context),
                ),
                const SizedBox(height: 14),
                _buildActionCard(
                  context,
                  icon: Icons.link_rounded,
                  label: 'Enviar recibo em Link',
                  subtitle: 'Cliente visualiza direto no navegador',
                  color: Colors.blue,
                  onTap: () => _compartilharLink(context),
                ),
                const SizedBox(height: 14),
                _buildActionCard(
                  context,
                  icon: Icons.receipt_long_outlined,
                  label: 'Ver Detalhes do Recibo',
                  subtitle: 'Visualizar informações completas',
                  color: Colors.teal,
                  onTap: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: 32),
                // Botões de ação rápida
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(
                          Icons.copy_all_outlined,
                          color: Colors.teal.shade600,
                        ),
                        label: Text(
                          'Copiar Link',
                          style: TextStyle(
                            color: Colors.teal.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () => _copiarLink(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: Colors.teal.shade600,
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
                              Colors.teal.shade600,
                              Colors.teal.shade400,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.teal.shade300.withOpacity(0.5),
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
                          onPressed: () => _compartilharLinkSimples(context),
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
                  onPressed:
                      () => Navigator.of(context).popUntil((r) => r.isFirst),
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

  void _compartilharLink(BuildContext context) async {
    if (recibo.link == null || recibo.link!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link não disponível. Tente gerar novamente.'),
          backgroundColor: Colors.teal,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      final businessProvider = context.read<BusinessProvider>();
      final numeroFormatado = '#${recibo.numero.toString().padLeft(4, '0')}';

      final String textoParaCompartilhar = '''
Olá, ${recibo.cliente.nome}! 👋

Segue o recibo ${numeroFormatado} de ${businessProvider.nomeEmpresa}.
🔗 Visualize seu recibo:
${recibo.link}

${businessProvider.telefone.isNotEmpty ? '📞 Contato: ${businessProvider.telefone}' : ''}
${businessProvider.emailEmpresa.isNotEmpty ? '📧 Email: ${businessProvider.emailEmpresa}' : ''}

Obrigado pela preferência! 🙏
''';

      await Share.share(
        textoParaCompartilhar,
        subject: 'Recibo $numeroFormatado - ${businessProvider.nomeEmpresa}',
      );

      // Após o compartilhamento, atualiza o status para "Enviado"
      if (context.mounted) {
        await context.read<RecibosProvider>().atualizarStatus(
          recibo.id,
          'Enviado',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recibo enviado e status atualizado!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
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

  void _copiarLink(BuildContext context) {
    if (recibo.link == null || recibo.link!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link não disponível. Tente gerar novamente.'),
          backgroundColor: Colors.teal,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    Clipboard.setData(ClipboardData(text: recibo.link!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copiado para a área de transferência!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _compartilharLinkSimples(BuildContext context) async {
    if (recibo.link == null || recibo.link!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link não disponível. Tente gerar novamente.'),
          backgroundColor: Colors.teal,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      await Share.share(
        recibo.link!,
        subject: 'Link do Recibo #${recibo.numero.toString().padLeft(4, '0')}',
      );
    } catch (e) {
      debugPrint('Erro ao compartilhar link: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao compartilhar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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
