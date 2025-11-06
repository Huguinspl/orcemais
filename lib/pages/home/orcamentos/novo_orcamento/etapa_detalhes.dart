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
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informe os detalhes deste orçamento',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          _buildActionCard(
            context: context,
            icon: Icons.percent_outlined,
            corIcone: Colors.blue.shade700,
            label: 'Descontos',
            valor: resumoDescontos ?? 'Aplicar desconto (valor ou %) ',
            onTap: onDescontos,
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            context: context,
            icon: Icons.payment_outlined,
            corIcone: Colors.purple.shade700,
            label: 'Formas de pagamentos e parcelas',
            valor:
                resumoFormaPagamento ?? 'Definir forma de pagamento e parcelas',
            onTap: onFormasPagamentoParcelas,
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            context: context,
            icon: Icons.article_outlined,
            corIcone: Colors.teal.shade700,
            label: 'Laudo técnico',
            valor: resumoLaudoTecnico ?? 'Adicionar observações técnicas',
            onTap: onLaudoTecnico,
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            context: context,
            icon: Icons.rule_folder_outlined,
            corIcone: Colors.indigo.shade700,
            label: 'Condições contratuais e garantia',
            valor: resumoCondicoes ?? 'Inserir condições e termos',
            onTap: onCondicoesContratuais,
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            context: context,
            icon: Icons.verified_outlined,
            corIcone: Colors.green.shade700,
            label: 'Informações adicionais',
            valor: resumoGarantiaData ?? 'Adicionar informações complementares',
            onTap: onInformacoesAdicionais,
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            context: context,
            icon: Icons.photo_library_outlined,
            corIcone: Colors.orange.shade700,
            label: 'Fotos do Orçamento',
            valor: resumoFotos ?? 'Adicionar fotos ao PDF',
            onTap: onGerenciarFotos,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required Color corIcone,
    required String label,
    required String valor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: CircleAvatar(
          backgroundColor: corIcone.withAlpha(26),
          child: Icon(icon, color: corIcone),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          valor,
          style: TextStyle(color: theme.textTheme.bodySmall?.color),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.black45),
      ),
    );
  }
}
