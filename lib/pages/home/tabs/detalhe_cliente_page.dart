import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gestorfy/providers/clients_provider.dart';
import 'package:gestorfy/pages/home/tabs/novo_cliente_page.dart'; // ← IMPORT NECESSÁRIO

class DetalheClientePage extends StatelessWidget {
  const DetalheClientePage({super.key});

  @override
  Widget build(BuildContext context) {
    final id = ModalRoute.of(context)!.settings.arguments as String;
    final cliente = context.watch<ClientsProvider>().porId(id);

    if (cliente == null) {
      return const Scaffold(
        body: Center(child: Text('Cliente não encontrado')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(cliente.nome)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _linha('Celular', cliente.celular),
            _linha('Telefone', cliente.telefone),
            _linha('E‑mail', cliente.email),
            _linha('CPF/CNPJ', cliente.cpfCnpj),
            const SizedBox(height: 12),
            const Text(
              'Observações',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(cliente.observacoes),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NovoClientePage(original: cliente),
              ),
            ),
        label: const Text('Editar'),
        icon: const Icon(Icons.edit),
      ),
    );
  }

  Widget _linha(String rotulo, String valor) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Text('$rotulo: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(valor)),
      ],
    ),
  );
}
