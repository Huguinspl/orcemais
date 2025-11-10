import 'package:flutter/material.dart';

class EtapasBar extends StatelessWidget {
  final List<Map<String, dynamic>> etapas;
  final int etapaAtual;
  final Function(int) onEtapaTapped;
  final List<bool> etapasCompletas; // Nova propriedade

  const EtapasBar({
    super.key,
    required this.etapas,
    required this.etapaAtual,
    required this.onEtapaTapped,
    required this.etapasCompletas, // Obrigatório
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade50, Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.shade100.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(etapas.length, (index) {
          final etapa = etapas[index];
          final isAtual = index == etapaAtual;
          final isConcluida = etapasCompletas[index]; // Usa a lista de completas

          return Expanded(
            child: GestureDetector(
              onTap: () => onEtapaTapped(index),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient:
                          isAtual || isConcluida
                              ? LinearGradient(
                                colors:
                                    isConcluida
                                        ? [
                                          Colors.green.shade400,
                                          Colors.green.shade600,
                                        ]
                                        : [
                                          Colors.teal.shade400,
                                          Colors.teal.shade600,
                                        ],
                              )
                              : null,
                      color:
                          isAtual || isConcluida ? null : Colors.grey.shade200,
                      boxShadow:
                          isAtual || isConcluida
                              ? [
                                BoxShadow(
                                  color:
                                      isConcluida
                                          ? Colors.green.shade200
                                          : Colors.teal.shade200,
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                              : null,
                    ),
                    child: Icon(
                      isConcluida ? Icons.check_circle : etapa['icon'],
                      color:
                          (isAtual || isConcluida)
                              ? Colors.white
                              : Colors.grey.shade500,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    etapa['label'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isAtual ? FontWeight.bold : FontWeight.w500,
                      color:
                          isAtual
                              ? Colors.teal.shade700
                              : isConcluida
                              ? Colors.green.shade700
                              : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
