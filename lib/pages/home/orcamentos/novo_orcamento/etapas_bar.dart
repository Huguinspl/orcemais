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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(etapas.length, (index) {
          final etapa = etapas[index];
          final selecionado = index == etapaAtual;
          final cor =
              selecionado
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withAlpha(179);

          return InkWell(
            onTap: () => onEtapaTapped(index),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(etapa['icon'], color: cor),
                  const SizedBox(height: 4),
                  Text(
                    etapa['label'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          selecionado ? FontWeight.bold : FontWeight.normal,
                      color: cor,
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
