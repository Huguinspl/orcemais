import 'package:flutter/material.dart';

class EtapaDetalhesWidget extends StatelessWidget {
  final VoidCallback onDescontos;
  final VoidCallback onFormasPagamentoParcelas;
  final VoidCallback onLaudoTecnico;
  final VoidCallback onCondicoesContratuais;
  final VoidCallback onGarantiaEDataVisita;
  final VoidCallback onInformacoesAdicionais;
  final VoidCallback onGerenciarFotos;

  final String? resumoDescontos;
  final String? resumoFormaPagamento;
  final String? resumoLaudoTecnico;
  final String? resumoCondicoes;
  final String? resumoGarantiaData;
  final String? resumoFotos;

  const EtapaDetalhesWidget({
    super.key,
    required this.onDescontos,
    required this.onFormasPagamentoParcelas,
    required this.onLaudoTecnico,
    required this.onCondicoesContratuais,
    required this.onGarantiaEDataVisita,
    required this.onInformacoesAdicionais,
    required this.onGerenciarFotos,
    this.resumoDescontos,
    this.resumoFormaPagamento,
    this.resumoLaudoTecnico,
    this.resumoCondicoes,
    this.resumoGarantiaData,
    this.resumoFotos,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue.shade50, Colors.white, Colors.white],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header moderno
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade600, Colors.blue.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Etapa 3: Detalhes',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Configure opções adicionais do orçamento',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            _buildActionCard(
              context: context,
              icon: Icons.percent_outlined,
              corIcone: Colors.blue,
              label: 'Descontos',
              valor: resumoDescontos ?? 'Aplicar desconto (valor ou %)',
              onTap: onDescontos,
              isConfigured: resumoDescontos != null,
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              context: context,
              icon: Icons.payment_outlined,
              corIcone: Colors.purple,
              label: 'Formas de pagamento',
              valor:
                  resumoFormaPagamento ??
                  'Definir forma de pagamento e parcelas',
              onTap: onFormasPagamentoParcelas,
              isConfigured: resumoFormaPagamento != null,
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              context: context,
              icon: Icons.article_outlined,
              corIcone: Colors.teal,
              label: 'Laudo técnico',
              valor: resumoLaudoTecnico ?? 'Adicionar observações técnicas',
              onTap: onLaudoTecnico,
              isConfigured: resumoLaudoTecnico != null,
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              context: context,
              icon: Icons.rule_folder_outlined,
              corIcone: Colors.indigo,
              label: 'Condições contratuais',
              valor: resumoCondicoes ?? 'Inserir condições e termos',
              onTap: onCondicoesContratuais,
              isConfigured: resumoCondicoes != null,
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              context: context,
              icon: Icons.verified_outlined,
              corIcone: Colors.green,
              label: 'Informações adicionais',
              valor:
                  resumoGarantiaData ?? 'Adicionar informações complementares',
              onTap: onInformacoesAdicionais,
              isConfigured: resumoGarantiaData != null,
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              context: context,
              icon: Icons.photo_library_outlined,
              corIcone: Colors.orange,
              label: 'Fotos do orçamento',
              valor: resumoFotos ?? 'Adicionar fotos ao PDF',
              onTap: onGerenciarFotos,
              isConfigured: resumoFotos != null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required MaterialColor corIcone,
    required String label,
    required String valor,
    required VoidCallback onTap,
    bool isConfigured = false,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [corIcone.shade50, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [corIcone.shade400, corIcone.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: corIcone.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      valor,
                      style: TextStyle(
                        color:
                            isConfigured
                                ? corIcone.shade700
                                : Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight:
                            isConfigured ? FontWeight.w600 : FontWeight.normal,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                isConfigured ? Icons.check_circle : Icons.chevron_right,
                color: isConfigured ? Colors.green.shade600 : corIcone.shade600,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
