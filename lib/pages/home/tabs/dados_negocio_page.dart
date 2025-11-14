import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../../providers/business_provider.dart';
import '../../../models/business_info.dart';
import '../../../utils/cnpj_validator.dart';

class DadosNegocioPage extends StatefulWidget {
  const DadosNegocioPage({super.key});

  @override
  State<DadosNegocioPage> createState() => _DadosNegocioPageState();
}

class _DadosNegocioPageState extends State<DadosNegocioPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _ramoCtrl = TextEditingController();
  final _endCtrl = TextEditingController();
  final _cnpjCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  bool _isLoading = false;
  Uint8List? _logoPreviewBytes;
  String? _logoLocalPath;
  final _picker = ImagePicker();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Inicializar animações
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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prov = context.read<BusinessProvider>();
      await prov.carregarDoFirestore();

      if (mounted) {
        _nomeCtrl.text = prov.nomeEmpresa;
        _telCtrl.text = prov.telefone;
        _ramoCtrl.text = prov.ramo;
        _endCtrl.text = prov.endereco;
        _cnpjCtrl.text = prov.cnpj;
        _emailCtrl.text = prov.emailEmpresa;
        _logoLocalPath = prov.logoLocalPath;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nomeCtrl.dispose();
    _telCtrl.dispose();
    _ramoCtrl.dispose();
    _endCtrl.dispose();
    _cnpjCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  // Método _salvar com feedback visual aprimorado
  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);

    try {
      final prov = context.read<BusinessProvider>();
      final info = BusinessInfo(
        nomeEmpresa: _nomeCtrl.text.trim(),
        telefone: _telCtrl.text.trim(),
        ramo: _ramoCtrl.text.trim(),
        endereco: _endCtrl.text.trim(),
        cnpj: _cnpjCtrl.text.trim(),
        emailEmpresa: _emailCtrl.text.trim(),
        logoUrl: prov.logoUrl,
        pixTipo: prov.pixTipo,
        pixChave: prov.pixChave,
        assinaturaUrl: prov.assinaturaUrl,
      );
      await prov.salvarInfo(info);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Dados salvos com sucesso!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Erro ao salvar: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: CustomScrollView(
              slivers: [
                // AppBar com gradiente
                _buildAppBar(),

                // Conteúdo principal
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([_buildForm()]),
                  ),
                ),
              ],
            ),
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
          'Dados do Negócio',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
            ),
          ),
          child: Center(
            child: Icon(
              Icons.business_center,
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seção: Informações Básicas
          _buildSectionHeader(
            icon: Icons.business,
            title: 'Informações Básicas',
            subtitle: 'Dados principais do seu negócio',
          ),
          const SizedBox(height: 16),
          _campo(
            controller: _nomeCtrl,
            label: 'Nome da sua empresa*',
            icon: Icons.business,
            validator:
                (v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'Campo obrigatório'
                        : null,
          ),
          _campo(
            controller: _telCtrl,
            label: 'Telefone*',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator:
                (v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'Campo obrigatório'
                        : null,
          ),
          _campo(
            controller: _ramoCtrl,
            label: 'Ramo de atividade*',
            icon: Icons.storefront_outlined,
            validator:
                (v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'Campo obrigatório'
                        : null,
          ),

          const SizedBox(height: 32),

          // Seção: Informações Adicionais
          _buildSectionHeader(
            icon: Icons.info_outline,
            title: 'Informações Adicionais',
            subtitle: 'Dados complementares (opcional)',
          ),
          const SizedBox(height: 16),
          _campo(
            controller: _endCtrl,
            label: 'Endereço',
            icon: Icons.location_on_outlined,
          ),
          _campo(
            controller: _cnpjCtrl,
            label: 'CNPJ',
            icon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v == null || v.isEmpty) return null;
              return CnpjValidator.isValid(v) ? null : 'CNPJ inválido';
            },
          ),
          _campo(
            controller: _emailCtrl,
            label: 'E-mail',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return null;
              final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
              return emailRegex.hasMatch(v) ? null : 'E-mail inválido';
            },
          ),

          const SizedBox(height: 32),

          // Seção: Logo
          _buildLogoSection(),

          const SizedBox(height: 32),

          // Botão Salvar
          _buildSaveButton(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1565C0).withOpacity(0.1),
            const Color(0xFF42A5F5).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _salvar,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child:
              _isLoading
                  ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                  : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Salvar Dados',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }

  Widget _campo({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon:
                icon != null
                    ? Icon(icon, color: const Color(0xFF1565C0))
                    : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    final prov = context.watch<BusinessProvider>();
    Widget preview;
    if (_logoPreviewBytes != null) {
      preview = Image.memory(
        _logoPreviewBytes!,
        height: 100,
        fit: BoxFit.contain,
      );
    } else if (!kIsWeb &&
        _logoLocalPath != null &&
        File(_logoLocalPath!).existsSync()) {
      preview = Image.file(
        File(_logoLocalPath!),
        height: 100,
        fit: BoxFit.contain,
      );
    } else if (prov.logoUrl != null && prov.logoUrl!.isNotEmpty) {
      preview = FutureBuilder<Uint8List?>(
        future: prov.getLogoBytes(),
        builder: (ctx, snap) {
          if (snap.hasData && snap.data != null) {
            return Image.memory(snap.data!, height: 100, fit: BoxFit.contain);
          }
          return Image.network(
            prov.logoUrl!,
            height: 100,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Text('Logo indisponível'),
          );
        },
      );
    } else {
      preview = Column(
        children: [
          Icon(Icons.image_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(
            'Nenhuma logo adicionada',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1565C0).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.image, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Logo da Empresa',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(child: preview),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.photo_library_outlined, size: 20),
                  label: const Text('Selecionar'),
                  onPressed: () => _pickLogo(source: ImageSource.gallery),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  label: const Text('Remover'),
                  onPressed:
                      prov.logoUrl == null &&
                              _logoPreviewBytes == null &&
                              _logoLocalPath == null
                          ? null
                          : () async {
                            setState(() {
                              _logoPreviewBytes = null;
                              _logoLocalPath = null;
                            });
                            try {
                              await prov.removerLogo();
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text('Erro ao remover logo: $e'),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  margin: const EdgeInsets.all(16),
                                ),
                              );
                            }
                          },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Adicione sua logo para aparecer nos PDFs de orçamento e recibo.',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickLogo({required ImageSource source}) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (picked == null) return;
    try {
      final bytes = await picked.readAsBytes();
      final filePath = kIsWeb ? null : picked.path;
      if (!mounted) return;
      setState(() {
        _logoPreviewBytes = bytes;
        _logoLocalPath = filePath;
      });
      await context.read<BusinessProvider>().uploadLogoBytes(
        bytes,
        filePath: filePath,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Logo atualizada com sucesso!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Falha ao enviar logo: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
}
