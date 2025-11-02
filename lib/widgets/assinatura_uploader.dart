import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import removido: assinatura agora é coletada em tela dedicada
import '../pages/home/tabs/signature/coletar_assinatura_page.dart';
import '../providers/business_provider.dart';

class AssinaturaUploader extends StatefulWidget {
  const AssinaturaUploader({super.key});

  @override
  State<AssinaturaUploader> createState() => _AssinaturaUploaderState();
}

class _AssinaturaUploaderState extends State<AssinaturaUploader> {
  bool _uploading = false;

  // Método local de salvar não é mais usado; agora abrimos tela dedicada.

  @override
  Widget build(BuildContext context) {
    final business = context.watch<BusinessProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Assinatura cadastrada:'),
        const SizedBox(height: 8),
        if (business.assinaturaUrl != null &&
            business.assinaturaUrl!.isNotEmpty)
          FutureBuilder<Uint8List?>(
            future: business.getAssinaturaBytes(),
            builder: (context, snap) {
              Widget content;
              if (snap.connectionState == ConnectionState.waiting) {
                content = const SizedBox(
                  height: 60,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              } else if (snap.hasData && snap.data != null) {
                content = Image.memory(
                  snap.data!,
                  height: 80,
                  fit: BoxFit.contain,
                );
              } else {
                // Fallback por URL com cache-buster correto
                final url = business.assinaturaUrl!;
                final cacheBuster =
                    't=${DateTime.now().millisecondsSinceEpoch}';
                final sep = url.contains('?') ? '&' : '?';
                final bustedUrl = '$url$sep$cacheBuster';
                content = Image.network(
                  bustedUrl,
                  height: 80,
                  fit: BoxFit.contain,
                  errorBuilder:
                      (c, e, s) =>
                          const Icon(Icons.edit, size: 32, color: Colors.grey),
                );
              }
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: content,
              );
            },
          )
        else
          const Text('Nenhuma assinatura cadastrada.'),
        const SizedBox(height: 16),
        const Text('Nova assinatura:'),
        const SizedBox(height: 8),
        InkWell(
          onTap:
              _uploading
                  ? null
                  : () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ColetarAssinaturaPage(),
                      ),
                    );
                    if (mounted) setState(() {}); // Atualiza prévia cadastrada
                  },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 70, // menor conforme solicitado
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blueAccent),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.edit, color: Colors.blueAccent),
                SizedBox(width: 8),
                Text('Toque para assinar em tela cheia'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
