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
    threshold: 0.5,
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
          title: const Text(
            'Desenhe sua Assinatura',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF303F9F), Color(0xFF5C6BC0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                onPressed: () => control.clear(),
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                tooltip: 'Limpar',
              ),
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFE8EAF6),
                Colors.grey.shade100,
              ],
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: const Color(0xFF303F9F),
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF303F9F).withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: HandSignature(control: control),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _salvando ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(
                      color: Color(0xFF303F9F),
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(
                    Icons.close,
                    color: Color(0xFF303F9F),
                  ),
                  label: const Text(
                    'Cancelar',
                    style: TextStyle(
                      color: Color(0xFF303F9F),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF303F9F), Color(0xFF5C6BC0)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF303F9F).withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _salvando ? null : _salvar,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      disabledBackgroundColor: Colors.grey.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _salvando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(
                            Icons.check_circle_outline,
                            color: Colors.white,
                          ),
                    label: Text(
                      _salvando ? 'Salvando...' : 'Salvar',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
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
}
