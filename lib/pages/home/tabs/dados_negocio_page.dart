import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/business_provider.dart';
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
      await context.read<BusinessProvider>().salvarNoFirestore(
        nomeEmpresa: _nomeCtrl.text.trim(),
        telefone: _telCtrl.text.trim(),
        ramo: _ramoCtrl.text.trim(),
        endereco: _endCtrl.text.trim(),
        cnpj: _cnpjCtrl.text.trim(),
        emailEmpresa: _emailCtrl.text.trim(),
      );

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
}
