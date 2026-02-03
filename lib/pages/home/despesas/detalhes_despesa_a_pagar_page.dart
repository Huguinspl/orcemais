import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/receita.dart';
import '../../../providers/agendamentos_provider.dart';
import '../../../providers/transacoes_provider.dart';
import 'nova_despesa_page.dart';

class DetalhesDespesaAPagarPage extends StatefulWidget {
  final Transacao transacao;

  const DetalhesDespesaAPagarPage({super.key, required this.transacao});

  @override
  State<DetalhesDespesaAPagarPage> createState() =>
      _DetalhesDespesaAPagarPageState();
}

class _DetalhesDespesaAPagarPageState extends State<DetalhesDespesaAPagarPage> {
  late Transacao _transacao;

  @override
  void initState() {
    super.initState();
    _transacao = widget.transacao;
  }

  String _getCategoriaName(CategoriaTransacao categoria) {
    switch (categoria) {
      case CategoriaTransacao.vendas:
        return 'Vendas';
      case CategoriaTransacao.servicos:
        return 'Serviços';
      case CategoriaTransacao.investimentos:
        return 'Investimentos';
      case CategoriaTransacao.outros:
        return 'Outros';
      case CategoriaTransacao.fornecedores:
        return 'Fornecedores';
      case CategoriaTransacao.salarios:
        return 'Salários';
      case CategoriaTransacao.aluguel:
        return 'Aluguel';
      case CategoriaTransacao.marketing:
        return 'Marketing';
      case CategoriaTransacao.equipamentos:
        return 'Equipamentos';
      case CategoriaTransacao.impostos:
        return 'Impostos';
      case CategoriaTransacao.utilities:
        return 'Utilidades';
      case CategoriaTransacao.manutencao:
        return 'Manutenção';
    }
  }

  IconData _getCategoriaIcon(CategoriaTransacao categoria) {
    switch (categoria) {
      case CategoriaTransacao.vendas:
        return Icons.shopping_bag;
      case CategoriaTransacao.servicos:
        return Icons.build;
      case CategoriaTransacao.investimentos:
        return Icons.trending_up;
      case CategoriaTransacao.outros:
        return Icons.more_horiz;
      case CategoriaTransacao.fornecedores:
        return Icons.local_shipping;
      case CategoriaTransacao.salarios:
        return Icons.person;
      case CategoriaTransacao.aluguel:
        return Icons.home;
      case CategoriaTransacao.marketing:
        return Icons.campaign;
      case CategoriaTransacao.equipamentos:
        return Icons.computer;
      case CategoriaTransacao.impostos:
        return Icons.receipt_long;
      case CategoriaTransacao.utilities:
        return Icons.electrical_services;
      case CategoriaTransacao.manutencao:
        return Icons.handyman;
    }
  }

  void _abrirEdicao() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NovaDespesaPage(transacao: _transacao, isFutura: true),
      ),
    );

    if (resultado == true && mounted) {
      // Atualiza a transação do provider
      final provider = context.read<TransacoesProvider>();
      final transacaoAtualizada = provider.transacoes.firstWhere(
        (t) => t.id == _transacao.id,
        orElse: () => _transacao,
      );
      setState(() {
        _transacao = transacaoAtualizada;
      });
    }
  }

  Future<void> _marcarComoPaga() async {
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    final statusConfig = {
      'Pendente': {
        'cor': Colors.orange,
        'icone': Icons.pending_outlined,
        'label': 'Pendente',
        'subtitle': null,
      },
      'Pago': {
        'cor': Colors.green,
        'icone': Icons.payments_outlined,
        'label': 'Pago',
        'subtitle': 'Marca como pago e registra despesa',
      },
      'Reagendar': {
        'cor': Colors.blue,
        'icone': Icons.event_repeat,
        'label': 'Reagendar',
        'subtitle': 'Adia para 7 dias depois',
      },
      'Cancelado': {
        'cor': Colors.red,
        'icone': Icons.cancel_outlined,
        'label': 'Cancelado',
        'subtitle': null,
      },
    };

    final novo = await showDialog<String>(
      context: context,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade50, Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.shade400,
                          Colors.orange.shade600,
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.payments,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Despesa a Pagar',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _transacao.descricao,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormat.format(_transacao.valor),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...statusConfig.entries.map((entry) {
                    final statusKey = entry.key;
                    final config = entry.value;
                    final cor = config['cor'] as MaterialColor;
                    final label = config['label'] as String;
                    final subtitle = config['subtitle'] as String?;
                    final isSelected = statusKey == 'Pendente';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        gradient:
                            isSelected
                                ? LinearGradient(
                                  colors: [cor.shade100, cor.shade50],
                                )
                                : null,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? cor : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: ListTile(
                        leading: Icon(
                          config['icone'] as IconData,
                          color: cor,
                          size: 28,
                        ),
                        title: Text(
                          label,
                          style: TextStyle(
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            color:
                                isSelected
                                    ? cor.shade900
                                    : Colors.grey.shade800,
                          ),
                        ),
                        subtitle:
                            subtitle != null
                                ? Text(
                                  subtitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                                : null,
                        trailing:
                            isSelected
                                ? Icon(Icons.check_circle, color: cor, size: 24)
                                : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onTap: () => Navigator.pop(context, statusKey),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
    );

    if (novo == null) return;

    if (novo == 'Pago') {
      final transacoesProvider = context.read<TransacoesProvider>();
      final agendamentosProvider = context.read<AgendamentosProvider>();

      final transacaoAtualizada = Transacao(
        id: _transacao.id,
        descricao: _transacao.descricao,
        valor: _transacao.valor,
        data: DateTime.now(),
        tipo: _transacao.tipo,
        categoria: _transacao.categoria,
        observacoes: _transacao.observacoes,
        userId: _transacao.userId,
        isFutura: false,
        agendamentoId: _transacao.agendamentoId,
      );

      await transacoesProvider.atualizarTransacao(transacaoAtualizada);

      // Atualiza o agendamento vinculado para "Concluido" se existir
      if (_transacao.agendamentoId != null &&
          _transacao.agendamentoId!.isNotEmpty) {
        await agendamentosProvider.atualizarStatus(
          _transacao.agendamentoId!,
          'Concluido',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Despesa paga e registrada (${currencyFormat.format(_transacao.valor)})',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        Navigator.pop(context);
      }
    } else if (novo == 'Reagendar') {
      final transacoesProvider = context.read<TransacoesProvider>();
      final novaData = _transacao.data.add(const Duration(days: 7));
      final transacaoAtualizada = Transacao(
        id: _transacao.id,
        descricao: _transacao.descricao,
        valor: _transacao.valor,
        data: novaData,
        tipo: _transacao.tipo,
        categoria: _transacao.categoria,
        observacoes: _transacao.observacoes,
        userId: _transacao.userId,
        isFutura: true,
        agendamentoId: _transacao.agendamentoId,
      );

      await transacoesProvider.atualizarTransacao(transacaoAtualizada);

      if (mounted) {
        final dateFormat = DateFormat('dd/MM/yyyy');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.event_repeat, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Despesa reagendada para ${dateFormat.format(novaData)}',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.blue.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        Navigator.pop(context);
      }
    } else if (novo == 'Cancelado') {
      final transacoesProvider = context.read<TransacoesProvider>();
      final agendamentosProvider = context.read<AgendamentosProvider>();

      // Cancela o agendamento vinculado se existir
      if (_transacao.agendamentoId != null &&
          _transacao.agendamentoId!.isNotEmpty) {
        await agendamentosProvider.atualizarStatus(
          _transacao.agendamentoId!,
          'Cancelado',
        );
      }

      await transacoesProvider.removerTransacao(_transacao.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.cancel, color: Colors.white),
                SizedBox(width: 12),
                Text('Despesa cancelada'),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );
    final dateFormat = DateFormat('dd/MM/yyyy');
    final diaSemana = DateFormat('EEEE', 'pt_BR').format(_transacao.data);
    const corTema = Colors.orange;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Despesa a Pagar'),
        backgroundColor: corTema,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Editar',
            onPressed: _abrirEdicao,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header colorido
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: corTema,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Descrição e ícone
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        radius: 24,
                        child: const Icon(
                          Icons.call_received,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _transacao.descricao,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _getCategoriaName(_transacao.categoria),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Data e valor
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                dateFormat.format(_transacao.data),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                diaSemana,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 50,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.money_off,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                currencyFormat.format(_transacao.valor),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'valor previsto',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Conteúdo
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange.shade100,
                        child: Icon(
                          Icons.schedule,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      title: const Text('Status Atual'),
                      subtitle: Text(
                        'Pendente',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      trailing: TextButton.icon(
                        onPressed: _marcarComoPaga,
                        icon: Icon(
                          Icons.check_circle_outline,
                          color: Colors.green.shade600,
                        ),
                        label: Text(
                          'Pagar',
                          style: TextStyle(color: Colors.green.shade600),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Detalhes
                  Text(
                    'Detalhes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            icon: _getCategoriaIcon(_transacao.categoria),
                            label: 'Categoria',
                            value: _getCategoriaName(_transacao.categoria),
                          ),
                          const Divider(height: 24),
                          _buildDetailRow(
                            icon: Icons.money_off,
                            label: 'Valor',
                            value: currencyFormat.format(_transacao.valor),
                          ),
                          const Divider(height: 24),
                          _buildDetailRow(
                            icon: Icons.calendar_today,
                            label: 'Data Prevista',
                            value: dateFormat.format(_transacao.data),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Observações
                  if (_transacao.observacoes != null &&
                      _transacao.observacoes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Observações',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.notes,
                              color: Colors.grey.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _transacao.observacoes!,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Informações adicionais
                  Text(
                    'Informações',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildInfoItem(
                          icon: Icons.create,
                          label: 'Criado em',
                          value: DateFormat(
                            'dd/MM/yyyy HH:mm',
                          ).format(_transacao.criadoEm),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Botão de ação
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _marcarComoPaga,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Marcar como Paga'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.orange.shade600, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade600, size: 20),
      title: Text(
        label,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
      ),
      trailing: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
    );
  }
}
