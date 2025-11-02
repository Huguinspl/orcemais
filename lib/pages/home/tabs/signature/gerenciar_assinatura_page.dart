import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../widgets/assinatura_uploader.dart';
import '../../../../providers/business_provider.dart';

class GerenciarAssinaturaPage extends StatelessWidget {
  const GerenciarAssinaturaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assinatura'),
        centerTitle: true,
        actions: [
          Builder(
            builder: (ctx) {
              final hasSig =
                  (ctx.watch<BusinessProvider>().assinaturaUrl ?? '')
                      .isNotEmpty;
              if (!hasSig) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Remover assinatura',
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: ctx,
                    builder:
                        (dctx) => AlertDialog(
                          title: const Text('Remover assinatura?'),
                          content: const Text(
                            'Essa ação não pode ser desfeita.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dctx, false),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(dctx, true),
                              child: const Text('Remover'),
                            ),
                          ],
                        ),
                  );
                  if (ok == true) {
                    await ctx.read<BusinessProvider>().removerAssinatura();
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Assinatura removida')),
                      );
                    }
                  }
                },
              );
            },
          ),
        ],
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: AssinaturaUploader(),
      ),
    );
  }
}
