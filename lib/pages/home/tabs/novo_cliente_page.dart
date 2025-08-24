import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gestorfy/models/cliente.dart';
import 'package:gestorfy/providers/clients_provider.dart';
import 'package:gestorfy/providers/user_provider.dart';

class NovoClientePage extends StatefulWidget {
  final Cliente? original;
  const NovoClientePage({super.key, this.original});

  @override
  State<NovoClientePage> createState() => _NovoClientePageState();
}

class _NovoClientePageState extends State<NovoClientePage> {
  final _formKey = GlobalKey<FormState>();
  // <-- MUDANÇA 1: Adicionar estado para controlar o carregamento
  bool _isLoading = false;

  late final TextEditingController _nomeCtrl;
  late final TextEditingController _celularCtrl;
  late final TextEditingController _telefoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _cpfCnpjCtrl;
  late final TextEditingController _obsCtrl;

  @override
  void initState() {
    super.initState();
    final c = widget.original;
    _nomeCtrl = TextEditingController(text: c?.nome);
    _celularCtrl = TextEditingController(text: c?.celular);
    _telefoneCtrl = TextEditingController(text: c?.telefone);
    _emailCtrl = TextEditingController(text: c?.email);
    _cpfCnpjCtrl = TextEditingController(text: c?.cpfCnpj);
    _obsCtrl = TextEditingController(text: c?.observacoes);
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _celularCtrl.dispose();
    _telefoneCtrl.dispose();
    _emailCtrl.dispose();
    _cpfCnpjCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  // <-- MUDANÇA 2: Método _salvar refatorado com try/catch e feedback
  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uid = context.read<UserProvider>().uid;
      if (uid.isEmpty) {
        throw Exception('Usuário não autenticado.');
      }

      final prov = context.read<ClientsProvider>();
      final cliente = Cliente(
        id: widget.original?.id ?? '',
        nome: _nomeCtrl.text.trim(),
        celular: _celularCtrl.text.trim(),
        telefone: _telefoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        cpfCnpj: _cpfCnpjCtrl.text.trim(),
        observacoes: _obsCtrl.text.trim(),
      );

      if (widget.original == null) {
        await prov.adicionar(uid, cliente);
      } else {
        await prov.atualizar(uid, cliente);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cliente salvo com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.original != null;
    final theme = Theme.of(context);

    return Scaffold(
      // <-- MUDANÇA 3: AppBar padronizada com o tema
      appBar: AppBar(
        title: Text(editando ? 'Editar Cliente' : 'Novo Cliente'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _campo(
                label: 'Nome*',
                controller: _nomeCtrl,
                icon: Icons.person_outline,
                validator:
                    (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Preenchimento obrigatório'
                            : null,
              ),
              _campo(
                label: 'Celular',
                controller: _celularCtrl,
                icon: Icons.phone_iphone,
                tipo: TextInputType.phone,
              ),
              _campo(
                label: 'Telefone',
                controller: _telefoneCtrl,
                icon: Icons.phone_outlined,
                tipo: TextInputType.phone,
              ),
              _campo(
                label: 'E-mail',
                controller: _emailCtrl,
                icon: Icons.email_outlined,
                tipo: TextInputType.emailAddress,
              ),
              _campo(
                label: 'CPF/CNPJ',
                controller: _cpfCnpjCtrl,
                icon: Icons.badge_outlined,
                tipo: TextInputType.number,
              ),
              _campo(
                label: 'Observações',
                controller: _obsCtrl,
                icon: Icons.comment_outlined,
                maxLines: 4,
              ),
              const SizedBox(height: 24),

              // <-- MUDANÇA 4: Botão de salvar estilizado e com loading
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  onPressed: _isLoading ? null : _salvar,
                  label: Text(
                    _isLoading
                        ? 'Salvando...'
                        : (editando ? 'Atualizar' : 'Salvar'),
                  ),
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

  // <-- MUDANÇA 5: Helper _campo refatorado para ser mais versátil
  Widget _campo({
    required String label,
    required TextEditingController controller,
    IconData? icon,
    TextInputType tipo = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: tipo,
        maxLines: maxLines,
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
