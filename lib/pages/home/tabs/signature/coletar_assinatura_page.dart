import 'package:flutter/material.dart';
import 'package:hand_signature/signature.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../../../../providers/business_provider.dart';

class ColetarAssinaturaPage extends StatefulWidget {
  const ColetarAssinaturaPage({super.key});

  @override
  State<ColetarAssinaturaPage> createState() => _ColetarAssinaturaPageState();
}

class _ColetarAssinaturaPageState extends State<ColetarAssinaturaPage> {
  final control = HandSignatureControl(
    threshold: 3.0,
    smoothRatio: 0.65,
    velocityRange: 2.0,
  );
  bool _salvando = false;

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    try {
      final byteData = await control.toImage(color: Colors.black, fit: true);
      if (byteData == null || byteData.lengthInBytes == 0) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Assinatura vazia.')));
        return;
      }
      final bytes = byteData.buffer.asUint8List();
      String? path;
      try {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/assinatura.png');
        await file.writeAsBytes(bytes);
        path = file.path;
      } catch (_) {
        // prossegue sem path local
      }
      await context.read<BusinessProvider>().uploadAssinaturaBytes(
        bytes,
        filePath: path,
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      setState(() => _salvando = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rotacionar somente o Scaffold (usando RotatedBox) para área horizontal
    return RotatedBox(
      quarterTurns: 1,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Assinatura'),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: () => control.clear(),
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Limpar',
            ),
          ],
        ),
        body: Container(
          color: Colors.grey.shade200,
          padding: const EdgeInsets.all(12),
          child: Center(
            child: AspectRatio(
              aspectRatio: 3 / 1,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: HandSignature(control: control),
              ),
            ),
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _salvando ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _salvando ? null : _salvar,
                  child: Text(_salvando ? 'Salvando...' : 'Salvar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
