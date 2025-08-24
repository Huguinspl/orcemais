import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../routes/app_routes.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Meu Perfil', style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          const _TituloSecao('Dados pessoais'),
          GestureDetector(
            onTap: () => _abrirEdicaoPerfil(context, user),
            child: _QuadroCinza(
              children: [
                _LinhaTexto('Seu nome', user.nome),
                _LinhaTexto('Email', user.email),
                _LinhaTexto('CPF', user.cpf),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const _TituloSecao('Outras opções'),
          _QuadroCinza(
            children: [
              Row(
                children: [
                  const Icon(Icons.email_outlined, color: Colors.black54),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      user.emailCadastro,
                      style: const TextStyle(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
          InkWell(
            onTap: () => Navigator.pushNamed(context, AppRoutes.termos),
            child: _QuadroCinza(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(top: 8, left: 16, right: 16),
              children: const [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Termos de uso e Política de privacidade',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.black54),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /* ─────────────── BOTTOM-SHEET ─────────────── */
  void _abrirEdicaoPerfil(BuildContext pageCtx, UserProvider user) {
    final nomeCtrl = TextEditingController(text: user.nome);
    final emailCtrl = TextEditingController(text: user.email);
    final cpfCtrl = TextEditingController(text: user.cpf);

    showModalBottomSheet(
      context: pageCtx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Alterar seu perfil',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nomeCtrl,
                decoration: const InputDecoration(labelText: 'Seu nome'),
              ),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: cpfCtrl,
                decoration: const InputDecoration(labelText: 'CPF'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                child: const Text('Salvar alterações'),
                onPressed: () async {
                  // 1) captura o messenger ANTES de fechar o sheet
                  final messenger = ScaffoldMessenger.of(pageCtx);

                  // 2) atualiza o provider (sincrono)
                  final prov = pageCtx.read<UserProvider>();
                  prov.atualizarDados(
                    nomeCtrl.text,
                    emailCtrl.text,
                    cpfCtrl.text,
                  );

                  // 3) fecha o bottom-sheet antes de qualquer await
                  Navigator.pop(sheetCtx);

                  // 4) persiste no Firestore
                  await prov.salvarNoFirestore();

                  // 5) feedback ao usuário usando o messenger seguro
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Dados atualizados com sucesso!'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

/* ─────────── WIDGETS AUXILIARES ─────────── */

class _TituloSecao extends StatelessWidget {
  final String texto;
  const _TituloSecao(this.texto);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Text(
      texto,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    ),
  );
}

class _QuadroCinza extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets margin;
  final EdgeInsets padding;

  const _QuadroCinza({
    required this.children,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: margin,
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
}

class _LinhaTexto extends StatelessWidget {
  final String label;
  final String valor;
  const _LinhaTexto(this.label, this.valor);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          const Icon(Icons.chevron_right, size: 20, color: Colors.black54),
        ],
      ),
      if (valor.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 12),
          child: Text(
            valor,
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),
        ),
      const Divider(thickness: 1),
    ],
  );
}
