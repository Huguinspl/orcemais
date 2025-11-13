import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/business_provider.dart';
import 'coletar_assinatura_page.dart';

class GerenciarAssinaturaPage extends StatefulWidget {
  const GerenciarAssinaturaPage({super.key});

  @override
  State<GerenciarAssinaturaPage> createState() =>
      _GerenciarAssinaturaPageState();
}

class _GerenciarAssinaturaPageState extends State<GerenciarAssinaturaPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
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

  Widget _buildAppBar(bool hasSig) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Assinatura Digital',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF303F9F), Color(0xFF5C6BC0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(Icons.edit, size: 80, color: Colors.white24),
        ),
      ),
      actions: [
        if (hasSig)
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Remover assinatura',
            onPressed: () => _confirmarRemocao(),
          ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF303F9F).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF303F9F).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: const Color(0xFF303F9F), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Sua assinatura será utilizada nos recibos e documentos gerados pelo aplicativo.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarRemocao() async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.delete_outline, color: Colors.red.shade700),
                ),
                const SizedBox(width: 12),
                const Expanded(child: Text('Remover assinatura?')),
              ],
            ),
            content: const Text(
              'Essa ação não pode ser desfeita. A assinatura será removida dos documentos.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Remover'),
              ),
            ],
          ),
    );

    if (ok == true) {
      await context.read<BusinessProvider>().removerAssinatura();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Assinatura removida com sucesso!'),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BusinessProvider>(
      builder: (context, business, _) {
        final hasSig = (business.assinaturaUrl ?? '').isNotEmpty;

        return Scaffold(
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: CustomScrollView(
                slivers: [
                  _buildAppBar(hasSig),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildInfoCard(),
                          const ModernAssinaturaUploader(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Widget modernizado para AssinaturaUploader
class ModernAssinaturaUploader extends StatefulWidget {
  const ModernAssinaturaUploader({super.key});

  @override
  State<ModernAssinaturaUploader> createState() =>
      _ModernAssinaturaUploaderState();
}

class _ModernAssinaturaUploaderState extends State<ModernAssinaturaUploader> {
  @override
  Widget build(BuildContext context) {
    final business = context.watch<BusinessProvider>();
    final hasSignature =
        business.assinaturaUrl != null && business.assinaturaUrl!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Seção: Assinatura Atual
        if (hasSignature) ...[
          _buildSectionHeader('Assinatura Cadastrada', Icons.check_circle),
          const SizedBox(height: 12),
          _buildCurrentSignature(business),
          const SizedBox(height: 24),
        ],

        // Seção: Nova Assinatura
        _buildSectionHeader(
          hasSignature ? 'Atualizar Assinatura' : 'Criar Assinatura',
          Icons.edit,
        ),
        const SizedBox(height: 12),
        _buildSignatureButton(),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF303F9F), Color(0xFF5C6BC0)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentSignature(BusinessProvider business) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF303F9F).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: FutureBuilder<Uint8List?>(
        future: business.getAssinaturaBytes(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 100,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF303F9F)),
                ),
              ),
            );
          } else if (snap.hasData && snap.data != null) {
            return Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Image.memory(
                  snap.data!,
                  height: 80,
                  fit: BoxFit.contain,
                ),
              ),
            );
          } else {
            // Fallback para URL
            final url = business.assinaturaUrl!;
            final cacheBuster = 't=${DateTime.now().millisecondsSinceEpoch}';
            final sep = url.contains('?') ? '&' : '?';
            final bustedUrl = '$url$sep$cacheBuster';

            return Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Image.network(
                  bustedUrl,
                  height: 80,
                  fit: BoxFit.contain,
                  errorBuilder:
                      (c, e, s) => Icon(
                        Icons.edit,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildSignatureButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF303F9F).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ColetarAssinaturaPage()),
            );
            if (mounted) setState(() {});
          },
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF303F9F), Color(0xFF5C6BC0)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Toque para assinar em tela cheia',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF303F9F),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Use seu dedo ou caneta stylus para desenhar sua assinatura',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
