import 'package:flutter/material.dart';

class EtapasBar extends StatelessWidget {
  final List<Map<String, dynamic>> etapas;
  final int etapaAtual;
  final Function(int) onEtapaTapped;

  const EtapasBar({
    super.key,
    required this.etapas,
    required this.etapaAtual,
    required this.onEtapaTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(etapas.length, (index) {
          final etapa = etapas[index];
          final selecionado = index == etapaAtual;
          final concluido = index < etapaAtual;

          return Expanded(
            child: InkWell(
              onTap: () => onEtapaTapped(index),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient:
                      selecionado
                          ? LinearGradient(
                            colors: [
                              Colors.blue.shade400,
                              Colors.blue.shade600,
                            ],
                          )
                          : null,
                  color:
                      concluido
                          ? Colors.green.shade50
                          : (selecionado ? null : Colors.transparent),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            selecionado
                                ? Colors.white.withOpacity(0.3)
                                : (concluido
                                    ? Colors.green.shade100
                                    : Colors.grey.shade100),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        concluido ? Icons.check : etapa['icon'],
                        color:
                            selecionado
                                ? Colors.white
                                : (concluido
                                    ? Colors.green.shade700
                                    : Colors.grey.shade600),
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      etapa['label'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            selecionado ? FontWeight.bold : FontWeight.w500,
                        color:
                            selecionado
                                ? Colors.white
                                : (concluido
                                    ? Colors.green.shade700
                                    : Colors.grey.shade700),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
