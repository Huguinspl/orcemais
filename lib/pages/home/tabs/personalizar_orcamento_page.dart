import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/business_provider.dart';
import 'pix/editar_pix_page.dart';
import '../tabs/signature/gerenciar_assinatura_page.dart';
import 'descricao/editar_descricao_page.dart';
import 'pdf/personalizar_pdf_page.dart';

class PersonalizarOrcamentoPage extends StatefulWidget {
  final bool isEmbedded; // Se true, não mostra AppBar e bottomBar
  const PersonalizarOrcamentoPage({super.key, this.isEmbedded = false});

  @override
  State<PersonalizarOrcamentoPage> createState() =>
      _PersonalizarOrcamentoPageState();
}

class _PersonalizarOrcamentoPageState extends State<PersonalizarOrcamentoPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final business = context.watch<BusinessProvider>();

    // Se está sendo usado como etapa embutida, não mostra AppBar e botões
    if (widget.isEmbedded) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.purple.shade50, Colors.white, Colors.white],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header moderno (apenas quando isEmbedded)
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
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
            _buildSectionCards(context, business),
          ],
        ),
      );
    }

    // Se está sendo usado standalone, mostra tudo com SliverAppBar
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.purple.shade50,
                        Colors.white,
                        Colors.white,
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildSectionCards(context, business),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
                    side: const BorderSide(color: Color(0xFF6A1B9A), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      color: Color(0xFF6A1B9A),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6A1B9A).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Salvar',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Personalizar Orçamento',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
            ),
          ),
          child: Center(
            child: Icon(
              Icons.palette_outlined,
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCards(BuildContext context, BusinessProvider business) {
    return Column(
      children: [
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
                MaterialPageRoute(builder: (_) => const EditarDescricaoPage()),
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
                MaterialPageRoute(builder: (_) => const PersonalizarPdfPage()),
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
