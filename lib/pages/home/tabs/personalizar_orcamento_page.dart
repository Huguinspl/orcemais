import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/business_provider.dart';
import 'pix/editar_pix_page.dart';
import '../tabs/signature/gerenciar_assinatura_page.dart';
import 'descricao/editar_descricao_page.dart';
import 'pdf/personalizar_pdf_page.dart';

class PersonalizarOrcamentoPage extends StatelessWidget {
  const PersonalizarOrcamentoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final business = context.watch<BusinessProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personalizar orçamento'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            icon: Icons.description_outlined,
            title: 'Descrição do negócio',
            subtitle:
                (business.descricao != null && business.descricao!.isNotEmpty)
                    ? 'Descrição cadastrada'
                    : 'Adicionar uma breve descrição',
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
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditarPixPage()),
                ),
            trailing:
                business.pixChave != null
                    ? IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _confirmarRemocaoPix(context),
                    )
                    : null,
          ),
          const SizedBox(height: 16),
          _SectionCard(
            icon: Icons.edit,
            title: 'Cadastrar assinatura',
            subtitle:
                (business.assinaturaUrl != null &&
                        business.assinaturaUrl!.isNotEmpty)
                    ? 'Assinatura cadastrada'
                    : 'Adicionar/atualizar a assinatura',
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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Salvar'),
              ),
            ),
          ],
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
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: Colors.blueAccent),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
            if (trailing != null) trailing!,
            const Icon(Icons.chevron_right, color: Colors.black45),
          ],
        ),
      ),
    );
  }
}
