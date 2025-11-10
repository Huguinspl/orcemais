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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(etapas.length, (index) {
          final etapa = etapas[index];
          final isAtual = index == etapaAtual;
          final isConcluida = index < etapaAtual;

          return Expanded(
            child: GestureDetector(
              onTap: () => onEtapaTapped(index),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          isAtual
                              ? Theme.of(context).primaryColor
                              : isConcluida
                              ? Colors.green
                              : Colors.grey.shade300,
                    ),
                    child: Icon(
                      isConcluida ? Icons.check : etapa['icon'],
                      color:
                          (isAtual || isConcluida)
                              ? Colors.white
                              : Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    etapa['label'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isAtual ? FontWeight.bold : FontWeight.normal,
                      color:
                          isAtual
                              ? Theme.of(context).primaryColor
                              : isConcluida
                              ? Colors.green
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
