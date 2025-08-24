import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RodapeOrcamento extends StatelessWidget {
  // Dados que o rodapé precisa para ser exibido
  final double subtotal;
  final double custoTotal; // ✅ CORREÇÃO 1: Adicionar o custo total
  final double desconto;
  final double valorTotal;
  final bool isUltimaEtapa;
  final bool isSaving;

  // Funções que os botões do rodapé precisam chamar
  final VoidCallback onMostrarDialogoDesconto;
  final VoidCallback onRevisarEEnviar;
  final VoidCallback onProximaEtapa;

  const RodapeOrcamento({
    super.key,
    required this.subtotal,
    required this.custoTotal, // ✅ CORREÇÃO 2: Adicionar ao construtor
    required this.desconto,
    required this.valorTotal,
    required this.isUltimaEtapa,
    required this.isSaving,
    required this.onMostrarDialogoDesconto,
    required this.onRevisarEEnviar,
    required this.onProximaEtapa,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    return Container(
      padding: const EdgeInsets.all(16).copyWith(top: 12, bottom: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Seção de Subtotal e Desconto
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Subtotal (Itens)', style: theme.textTheme.bodyMedium),
                  Text(
                    currencyFormat.format(subtotal),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: isSaving ? null : onMostrarDialogoDesconto,
                icon: const Icon(Icons.percent, size: 18),
                label: Text(
                  desconto > 0
                      ? "- ${currencyFormat.format(desconto)}"
                      : 'Desconto',
                ),
              ),
            ],
          ),

          // ✅ CORREÇÃO 3: Adicionar a linha de Custo Adicional
          // Ela só aparece se houver algum custo.
          if (custoTotal > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Custos Adicionais', style: theme.textTheme.bodyMedium),
                  Text(
                    currencyFormat.format(custoTotal),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          const Divider(height: 12),
          const SizedBox(height: 4),

          // Seção de Valor Total e Botões de Ação
          Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Valor Total', style: theme.textTheme.bodySmall),
                  Text(
                    currencyFormat.format(valorTotal),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: isSaving ? null : onRevisarEEnviar,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Revisar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed:
                        isSaving
                            ? null
                            : (isUltimaEtapa
                                ? onRevisarEEnviar
                                : onProximaEtapa),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      backgroundColor:
                          isUltimaEtapa
                              ? Colors.green
                              : theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        isSaving
                            ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                            : Row(
                              children: [
                                Text(isUltimaEtapa ? 'Salvar' : 'Próximo'),
                                const SizedBox(width: 8),
                                Icon(
                                  isUltimaEtapa
                                      ? Icons.check
                                      : Icons.arrow_forward,
                                ),
                              ],
                            ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
