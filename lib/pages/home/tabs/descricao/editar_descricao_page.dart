import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/business_provider.dart';

class EditarDescricaoPage extends StatefulWidget {
  const EditarDescricaoPage({super.key});

  @override
  State<EditarDescricaoPage> createState() => _EditarDescricaoPageState();
}

class _EditarDescricaoPageState extends State<EditarDescricaoPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    final current = context.read<BusinessProvider>().descricao ?? '';
    _ctrl = TextEditingController(text: current);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BusinessProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Descrição do negócio'),
        actions: [
          if ((provider.descricao ?? '').isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Remover descrição',
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder:
                      (ctx) => AlertDialog(
                        title: const Text('Remover descrição?'),
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
                  await context.read<BusinessProvider>().removerDescricao();
                  if (mounted) Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Escreva uma breve descrição do seu negócio. Esse texto pode aparecer no PDF de orçamento.',
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TextFormField(
                  controller: _ctrl,
                  maxLines: null,
                  expands: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Ex.: Somos uma empresa especializada em...',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  await context.read<BusinessProvider>().salvarDescricao(
                    _ctrl.text.trim(),
                  );
                  if (mounted) Navigator.pop(context);
                },
                child: const Text('Salvar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
