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

class _DadosNegocioPageState extends State<DadosNegocioPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _ramoCtrl = TextEditingController();
  final _endCtrl = TextEditingController();
  final _cnpjCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  // <-- MUDANÇA 1: Renomear para _isLoading por consistência
  bool _isLoading = false;
  Uint8List? _logoPreviewBytes;
  String? _logoLocalPath;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
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
        setState(() {}); // Força rebuild para preencher os campos
      }
    });
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _telCtrl.dispose();
    _ramoCtrl.dispose();
    _endCtrl.dispose();
    _cnpjCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  // <-- MUDANÇA 2: Método _salvar com feedback visual aprimorado
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
        const SnackBar(
          content: Text('Dados salvos com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // <-- MUDANÇA 3: AppBar padronizada
      appBar: AppBar(title: const Text('Dados do Negócio'), centerTitle: true),
      // <-- MUDANÇA 4: Layout simplificado com SingleChildScrollView e Column
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 24),
              Text(
                'Mais informações (Opcional)',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.black54,
                ),
              ),
              const Divider(height: 24),
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
                  if (v == null || v.isEmpty) return null; // Opcional
                  return CnpjValidator.isValid(v) ? null : 'CNPJ inválido';
                },
              ),
              _campo(
                controller: _emailCtrl,
                label: 'E-mail',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return null; // Opcional
                  final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
                  return emailRegex.hasMatch(v) ? null : 'E-mail inválido';
                },
              ),
              const SizedBox(height: 32),
              _buildLogoSection(theme),
              const SizedBox(height: 32),
              // <-- MUDANÇA 5: Botão de salvar estilizado e com feedback de loading
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  onPressed: _isLoading ? null : _salvar,
                  label: Text(_isLoading ? 'Salvando...' : 'Salvar Dados'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

  // <-- MUDANÇA 6: Helper de campo refatorado para o novo padrão
  Widget _campo({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildLogoSection(ThemeData theme) {
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
          // Preferir bytes quando disponíveis
          if (snap.hasData && snap.data != null) {
            return Image.memory(snap.data!, height: 100, fit: BoxFit.contain);
          }
          // Fallback imediato por URL (melhor para Web)
          return Image.network(
            prov.logoUrl!,
            height: 100,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Text('Logo indisponível'),
          );
        },
      );
    } else {
      preview = const Text('Nenhuma logo adicionada');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Logo da Empresa', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: Column(
            children: [
              preview,
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Selecionar'),
                    onPressed: () => _pickLogo(source: ImageSource.gallery),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.delete_outline),
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
                                    content: Text('Erro ao remover logo: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Adicione sua logo para aparecer nos PDFs de orçamento e recibo.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
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
        const SnackBar(
          content: Text('Logo atualizada!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Falha ao enviar logo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
