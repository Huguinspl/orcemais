import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/business_provider.dart';
import 'pix/editar_pix_page.dart';
import '../tabs/signature/gerenciar_assinatura_page.dart';
import 'descricao/editar_descricao_page.dart';
import 'pdf/personalizar_pdf_page.dart';

class PersonalizarOrcamentoPage extends StatelessWidget {
  final bool isEmbedded; // Se true, não mostra AppBar e bottomBar
  const PersonalizarOrcamentoPage({super.key, this.isEmbedded = false});

  @override
  Widget build(BuildContext context) {
    final business = context.watch<BusinessProvider>();

    final listViewContent = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue.shade50, Colors.white, Colors.white],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header moderno (apenas quando isEmbedded)
          if (isEmbedded) ...[
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade600, Colors.blue.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.palette_outlined,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Etapa 4: Aparência',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Personalize o visual do orçamento',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          _SectionCard(
            icon: Icons.description_outlined,
            title: 'Descrição do negócio',
            subtitle:
                (business.descricao != null && business.descricao!.isNotEmpty)
                    ? 'Descrição cadastrada'
                    : 'Adicionar uma breve descrição',
            corIcone: Colors.blue,
            isConfigured:
                business.descricao != null && business.descricao!.isNotEmpty,
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EditarDescricaoPage(),
                  ),
                ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            icon: Icons.color_lens_outlined,
            title: 'Personalizar PDF',
            subtitle:
                (business.pdfTheme != null && business.pdfTheme!.isNotEmpty)
                    ? 'Tema personalizado ativo'
                    : 'Ajustar cores do PDF',
            corIcone: Colors.purple,
            isConfigured:
                business.pdfTheme != null && business.pdfTheme!.isNotEmpty,
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PersonalizarPdfPage(),
                  ),
                ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            icon: Icons.qr_code_2_outlined,
            title: 'Chave Pix',
            subtitle:
                business.pixChave == null
                    ? 'Adicionar chave Pix'
                    : 'Chave (${business.pixTipo}): ${business.pixChave}',
            corIcone: Colors.teal,
            isConfigured: business.pixChave != null,
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditarPixPage()),
                ),
            trailing:
                business.pixChave != null
                    ? IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red.shade400,
                      ),
                      onPressed: () => _confirmarRemocaoPix(context),
                    )
                    : null,
          ),
          const SizedBox(height: 16),
          _SectionCard(
            icon: Icons.edit_outlined,
            title: 'Cadastrar assinatura',
            subtitle:
                (business.assinaturaUrl != null &&
                        business.assinaturaUrl!.isNotEmpty)
                    ? 'Assinatura cadastrada'
                    : 'Adicionar/atualizar a assinatura',
            corIcone: Colors.indigo,
            isConfigured:
                business.assinaturaUrl != null &&
                business.assinaturaUrl!.isNotEmpty,
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GerenciarAssinaturaPage(),
                  ),
                ),
          ),
        ],
      ),
    );

    // Se está sendo usado como etapa embutida, não mostra AppBar e botões
    if (isEmbedded) {
      return listViewContent;
    }

    // Se está sendo usado standalone, mostra tudo
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Personalizar orçamento',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.blue.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: listViewContent,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.blue.shade600, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      color: Colors.blue.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: const Text(
                    'Salvar',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmarRemocaoPix(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Remover chave Pix?'),
            content: const Text('Essa ação não pode ser desfeita.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Remover'),
              ),
            ],
          ),
    );
    if (ok == true) {
      await context.read<BusinessProvider>().removerPix();
    }
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final MaterialColor corIcone;
  final bool isConfigured;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.corIcone,
    this.trailing,
    this.isConfigured = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [corIcone.shade50, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [corIcone.shade400, corIcone.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: corIcone.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color:
                            isConfigured
                                ? corIcone.shade700
                                : Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight:
                            isConfigured ? FontWeight.w600 : FontWeight.normal,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              Icon(
                isConfigured ? Icons.check_circle : Icons.chevron_right,
                color: isConfigured ? Colors.green.shade600 : corIcone.shade600,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
