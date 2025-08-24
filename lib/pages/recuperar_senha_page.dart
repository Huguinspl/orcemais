import 'package:flutter/material.dart';

class RecuperarSenhaPage extends StatefulWidget {
  const RecuperarSenhaPage({super.key});

  @override
  State<RecuperarSenhaPage> createState() => _RecuperarSenhaPageState();
}

class _RecuperarSenhaPageState extends State<RecuperarSenhaPage> {
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _enviarEmailRecuperacao() {
    if (_formKey.currentState!.validate()) {
      // Aqui você pode integrar com um serviço de envio de email
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Instruções enviadas para o email')),
      );

      Navigator.pop(context); // Volta para o login
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar Senha')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                'Informe seu email para receber instruções',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator:
                    (value) => value!.isEmpty ? 'Digite um email válido' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _enviarEmailRecuperacao,
                  child: const Text('Enviar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
