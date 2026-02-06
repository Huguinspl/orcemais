import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gestorfy/models/cliente.dart';
import 'package:gestorfy/providers/clients_provider.dart';
import 'package:gestorfy/providers/user_provider.dart';

class NovoClientePage extends StatefulWidget {
  final Cliente? original;
  final Map<String, String>? dadosIniciais;

  const NovoClientePage({super.key, this.original, this.dadosIniciais});

  @override
  State<NovoClientePage> createState() => _NovoClientePageState();
}

class _NovoClientePageState extends State<NovoClientePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  late final TextEditingController _nomeCtrl;
  late final TextEditingController _celularCtrl;
  late final TextEditingController _telefoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _cpfCnpjCtrl;
  late final TextEditingController _obsCtrl;

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

    final c = widget.original;
    final dados = widget.dadosIniciais;

    _nomeCtrl = TextEditingController(text: c?.nome ?? dados?['nome'] ?? '');
    _celularCtrl = TextEditingController(
      text: c?.celular ?? dados?['celular'] ?? '',
    );
    _telefoneCtrl = TextEditingController(
      text: c?.telefone ?? dados?['telefone'] ?? '',
    );
    _emailCtrl = TextEditingController(text: c?.email ?? dados?['email'] ?? '');
    _cpfCnpjCtrl = TextEditingController(
      text: c?.cpfCnpj ?? dados?['cpfCnpj'] ?? '',
    );
    _obsCtrl = TextEditingController(
      text: c?.observacoes ?? dados?['observacoes'] ?? '',
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nomeCtrl.dispose();
    _celularCtrl.dispose();
    _telefoneCtrl.dispose();
    _emailCtrl.dispose();
    _cpfCnpjCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

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
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.original == null
                      ? 'Cliente adicionado com sucesso!'
                      : 'Cliente atualizado com sucesso!',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
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
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.original != null;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: CustomScrollView(
              slivers: [
                _buildAppBar(editando),
                SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.indigo.shade50,
                          Colors.white,
                          Colors.white,
                        ],
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildSectionHeader(
                              icon: Icons.person,
                              title: 'Informações Básicas',
                              subtitle: 'Dados principais do cliente',
                            ),
                            const SizedBox(height: 16),
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
                              label: 'CPF/CNPJ',
                              controller: _cpfCnpjCtrl,
                              icon: Icons.badge_outlined,
                              tipo: TextInputType.number,
                            ),
                            const SizedBox(height: 24),
                            _buildSectionHeader(
                              icon: Icons.contact_phone,
                              title: 'Contato',
                              subtitle: 'Telefones e e-mail',
                            ),
                            const SizedBox(height: 16),
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
                            const SizedBox(height: 24),
                            _buildSectionHeader(
                              icon: Icons.notes,
                              title: 'Observações',
                              subtitle: 'Anotações adicionais',
                            ),
                            const SizedBox(height: 16),
                            _campo(
                              label: 'Observações',
                              controller: _obsCtrl,
                              icon: Icons.comment_outlined,
                              maxLines: 4,
                            ),
                            const SizedBox(height: 32),
                            _buildSaveButton(editando),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(bool editando) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          editando ? 'Editar Cliente' : 'Novo Cliente',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF303F9F), Color(0xFF5C6BC0)],
            ),
          ),
          child: Center(
            child: Icon(
              editando ? Icons.edit : Icons.person_add,
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
        ),
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
            const Color(0xFF303F9F).withOpacity(0.1),
            const Color(0xFF5C6BC0).withOpacity(0.05),
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
                colors: [Color(0xFF303F9F), Color(0xFF5C6BC0)],
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
                    color: Color(0xFF303F9F),
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

  Widget _buildSaveButton(bool editando) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF303F9F), Color(0xFF5C6BC0)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF303F9F).withOpacity(0.3),
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
                  : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(editando ? Icons.update : Icons.save, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        editando ? 'Atualizar Cliente' : 'Salvar Cliente',
                        style: const TextStyle(
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
    required String label,
    required TextEditingController controller,
    IconData? icon,
    TextInputType tipo = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextFormField(
          controller: controller,
          keyboardType: tipo,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon:
                icon != null
                    ? Icon(icon, color: const Color(0xFF303F9F))
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
              borderSide: const BorderSide(color: Color(0xFF303F9F), width: 2),
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
}
