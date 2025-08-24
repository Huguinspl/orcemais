import 'package:flutter/material.dart';
import '../../../../models/cliente.dart';

class EtapaClienteWidget extends StatelessWidget {
  final Cliente? clienteSelecionado;
  final VoidCallback onSelecionarCliente;

  const EtapaClienteWidget({
    super.key,
    required this.clienteSelecionado,
    required this.onSelecionarCliente,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Etapa 1: Defina o Cliente',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildActionCard(
            context: context,
            label: 'Cliente',
            valor:
                clienteSelecionado?.nome ?? 'Toque para selecionar um cliente',
            icon: Icons.person,
            corIcone: Colors.blue.shade700,
            onTap: onSelecionarCliente,
          ),
        ],
      ),
    );
  }

  /// Helper para criar os cards de ação (Cliente, Serviços, etc.)
  Widget _buildActionCard({
    required BuildContext context,
    required String label,
    required String valor,
    required IconData icon,
    required Color corIcone,
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
          style: TextStyle(
            color:
                valor.startsWith('Toque para')
                    ? Colors.grey.shade600
                    : theme.textTheme.bodySmall?.color,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
