import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/agendamento.dart';
import '../../../providers/agendamentos_provider.dart';
import '../despesas/nova_despesa_a_pagar_page.dart';
import 'agendamento_a_receber_page.dart';
import 'agendamento_vendas_page.dart';
import 'agendamento_diversos_page.dart';

class DetalhesAgendamentoPage extends StatefulWidget {
  final String agendamentoId;

  const DetalhesAgendamentoPage({super.key, required this.agendamentoId});

  @override
  State<DetalhesAgendamentoPage> createState() =>
      _DetalhesAgendamentoPageState();
}

class _DetalhesAgendamentoPageState extends State<DetalhesAgendamentoPage> {
  Agendamento? _agendamento;
  bool _isLoading = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarAgendamento();
  }

  Future<void> _carregarAgendamento() async {
    try {
      final provider = context.read<AgendamentosProvider>();

      // Tenta encontrar no provider primeiro
      Agendamento? agendamento;
      try {
        agendamento = provider.agendamentos.firstWhere(
          (a) => a.id == widget.agendamentoId,
        );
      } catch (_) {
        // Não encontrou no provider, busca do Firestore
        agendamento = null;
      }

      // Se não encontrou no provider, busca do Firestore
      if (agendamento == null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('Usuário não autenticado');
        }

        final doc =
            await FirebaseFirestore.instance
                .collection('business')
                .doc(user.uid)
                .collection('agendamentos')
                .doc(widget.agendamentoId)
                .get();

        if (!doc.exists) {
          throw Exception('Agendamento não encontrado');
        }

        agendamento = Agendamento.fromFirestore(doc);
      }

      if (!mounted) return;

      setState(() {
        _agendamento = agendamento;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pendente':
        return Colors.orange;
      case 'Confirmado':
        return Colors.blue;
      case 'Concluido':
        return Colors.green;
      case 'Cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Pendente':
        return Icons.schedule;
      case 'Confirmado':
        return Icons.check_circle_outline;
      case 'Concluido':
        return Icons.task_alt;
      case 'Cancelado':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  String _getTipoAgendamento() {
    if (_agendamento == null) return '';
    final obs = _agendamento!.observacoes;
    if (obs.contains('[DESPESA A PAGAR]')) {
      return 'Despesa a Pagar';
    } else if (obs.contains('[RECEITA A RECEBER]')) {
      return 'Receita a Receber';
    } else if (obs.contains('[VENDA]')) {
      return 'Venda';
    } else if (obs.contains('[DIVERSOS]')) {
      return 'Diversos';
    }
    return 'Agendamento';
  }

  IconData _getTipoIcon() {
    if (_agendamento == null) return Icons.event;
    final obs = _agendamento!.observacoes;
    if (obs.contains('[DESPESA A PAGAR]')) {
      return Icons.money_off;
    } else if (obs.contains('[RECEITA A RECEBER]')) {
      return Icons.attach_money;
    } else if (obs.contains('[VENDA]')) {
      return Icons.shopping_cart;
    }
    return Icons.event;
  }

  Color _getTipoColor() {
    if (_agendamento == null) return Colors.teal;
    final obs = _agendamento!.observacoes;
    if (obs.contains('[DESPESA A PAGAR]')) {
      return Colors.red;
    } else if (obs.contains('[RECEITA A RECEBER]')) {
      return Colors.green;
    } else if (obs.contains('[VENDA]')) {
      return Colors.blue;
    }
    return Colors.teal;
  }

  Future<void> _alterarStatus(String novoStatus) async {
    if (_agendamento == null) return;

    final provider = context.read<AgendamentosProvider>();

    try {
      await provider.atualizarStatus(_agendamento!.id, novoStatus);

      if (!mounted) return;

      // Recarrega o agendamento atualizado
      _carregarAgendamento();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(_getStatusIcon(novoStatus), color: Colors.white),
              const SizedBox(width: 12),
              Text('Status alterado para $novoStatus'),
            ],
          ),
          backgroundColor: _getStatusColor(novoStatus),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao alterar status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _mostrarDialogoAlterarStatus() {
    if (_agendamento == null) return;

    final statusAtual = _agendamento!.status;
    final statusDisponiveis =
        [
          'Pendente',
          'Confirmado',
          'Concluido',
          'Cancelado',
        ].where((s) => s != statusAtual).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Alterar Status',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ...statusDisponiveis.map(
                  (status) => ListTile(
                    leading: Icon(
                      _getStatusIcon(status),
                      color: _getStatusColor(status),
                    ),
                    title: Text(status),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey.shade400,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _alterarStatus(status);
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }

  void _abrirEdicao() async {
    if (_agendamento == null) return;

    final obs = _agendamento!.observacoes;

    Widget? paginaEdicao;

    if (obs.contains('[DESPESA A PAGAR]')) {
      // Navegar para página de edição de despesa a pagar
      paginaEdicao = NovaDespesaAPagarPage(
        agendamento: _agendamento,
        fromControleFinanceiro: false,
      );
    } else if (obs.contains('[RECEITA A RECEBER]')) {
      // Navegar para página de edição de receita a receber
      paginaEdicao = AgendamentoAReceberPage(
        agendamento: _agendamento,
        fromControleFinanceiro: false,
      );
    } else if (obs.contains('[VENDA]')) {
      // Navegar para página de edição de venda
      paginaEdicao = AgendamentoVendasPage(agendamento: _agendamento);
    } else if (obs.contains('[DIVERSOS]')) {
      // Navegar para página de edição de diversos
      paginaEdicao = AgendamentoDiversosPage(agendamento: _agendamento);
    }

    if (paginaEdicao != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => paginaEdicao!),
      );
      // Recarrega os dados após edição
      if (mounted) {
        _carregarAgendamento();
      }
    } else {
      // Fallback: abre o modal de edição simples
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder:
            (context) => _EditarAgendamentoModal(
              agendamento: _agendamento!,
              onSalvar: () {
                _carregarAgendamento();
              },
            ),
      );
    }
  }

  String _formatarObservacoes(String obs) {
    // Remove as tags de tipo do início
    return obs
        .replaceAll('[DESPESA A PAGAR]\n', '')
        .replaceAll('[RECEITA A RECEBER]\n', '')
        .replaceAll('[VENDA]\n', '')
        .replaceAll('[DIVERSOS]\n', '')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final corTema = _getTipoColor();

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Carregando...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_erro != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Erro')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Erro ao carregar agendamento',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _erro!,
                  style: TextStyle(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _erro = null;
                    });
                    _carregarAgendamento();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar Novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_agendamento == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Agendamento')),
        body: const Center(child: Text('Agendamento não encontrado')),
      );
    }

    final dataHora = _agendamento!.dataHora.toDate();
    final dataFormatada = DateFormat('dd/MM/yyyy').format(dataHora);
    final horaFormatada = DateFormat('HH:mm').format(dataHora);
    final diaSemana = DateFormat('EEEE', 'pt_BR').format(dataHora);
    final obsFormatadas = _formatarObservacoes(_agendamento!.observacoes);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTipoAgendamento()),
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
                  // Nome do cliente/fornecedor
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        radius: 24,
                        child: Icon(
                          _getTipoIcon(),
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
                              _agendamento!.clienteNome ?? 'Sem nome',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_agendamento!.orcamentoNumero != null)
                              Text(
                                'Orçamento #${_agendamento!.orcamentoNumero.toString().padLeft(4, '0')}',
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
                  // Data e hora
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
                                dataFormatada,
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
                                Icons.access_time,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                horaFormatada,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'horário',
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
                  // Status atual
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(
                          _agendamento!.status,
                        ).withValues(alpha: 0.2),
                        child: Icon(
                          _getStatusIcon(_agendamento!.status),
                          color: _getStatusColor(_agendamento!.status),
                        ),
                      ),
                      title: const Text('Status Atual'),
                      subtitle: Text(
                        _agendamento!.status,
                        style: TextStyle(
                          color: _getStatusColor(_agendamento!.status),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      trailing: TextButton.icon(
                        onPressed: _mostrarDialogoAlterarStatus,
                        icon: const Icon(Icons.swap_horiz),
                        label: const Text('Alterar'),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Observações
                  if (obsFormatadas.isNotEmpty) ...[
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children:
                              obsFormatadas.split('\n').map((linha) {
                                if (linha.contains(':')) {
                                  final partes = linha.split(':');
                                  final label = partes[0].trim();
                                  final valor =
                                      partes.sublist(1).join(':').trim();
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 100,
                                          child: Text(
                                            label,
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            valor,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Text(linha),
                                );
                              }).toList(),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Botões de ação rápida
                  Text(
                    'Ações Rápidas',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildAcaoRapida(
                          icon: Icons.check_circle,
                          label: 'Concluir',
                          color: Colors.green,
                          onTap:
                              _agendamento!.status != 'Concluido'
                                  ? () => _alterarStatus('Concluido')
                                  : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildAcaoRapida(
                          icon: Icons.cancel,
                          label: 'Cancelar',
                          color: Colors.red,
                          onTap:
                              _agendamento!.status != 'Cancelado'
                                  ? () => _alterarStatus('Cancelado')
                                  : null,
                        ),
                      ),
                    ],
                  ),

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
                          ).format(_agendamento!.criadoEm.toDate()),
                        ),
                        const Divider(height: 1),
                        _buildInfoItem(
                          icon: Icons.update,
                          label: 'Atualizado em',
                          value: DateFormat(
                            'dd/MM/yyyy HH:mm',
                          ).format(_agendamento!.atualizadoEm.toDate()),
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
    );
  }

  Widget _buildAcaoRapida({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    final isDisabled = onTap == null;
    return Material(
      color: isDisabled ? Colors.grey.shade200 : color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: isDisabled ? Colors.grey : color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isDisabled ? Colors.grey : color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
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

// Modal de edição do agendamento
class _EditarAgendamentoModal extends StatefulWidget {
  final Agendamento agendamento;
  final VoidCallback onSalvar;

  const _EditarAgendamentoModal({
    required this.agendamento,
    required this.onSalvar,
  });

  @override
  State<_EditarAgendamentoModal> createState() =>
      _EditarAgendamentoModalState();
}

class _EditarAgendamentoModalState extends State<_EditarAgendamentoModal> {
  late TextEditingController _observacoesController;
  late DateTime _dataHora;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _observacoesController = TextEditingController(
      text: widget.agendamento.observacoes,
    );
    _dataHora = widget.agendamento.dataHora.toDate();
  }

  @override
  void dispose() {
    _observacoesController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataHora,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      locale: const Locale('pt', 'BR'),
    );
    if (data != null) {
      setState(() {
        _dataHora = DateTime(
          data.year,
          data.month,
          data.day,
          _dataHora.hour,
          _dataHora.minute,
        );
      });
    }
  }

  Future<void> _selecionarHora() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dataHora),
    );
    if (hora != null) {
      setState(() {
        _dataHora = DateTime(
          _dataHora.year,
          _dataHora.month,
          _dataHora.day,
          hora.hour,
          hora.minute,
        );
      });
    }
  }

  Future<void> _salvar() async {
    setState(() => _isSaving = true);

    try {
      final provider = context.read<AgendamentosProvider>();
      final agendamentoAtualizado = widget.agendamento.copyWith(
        dataHora: Timestamp.fromDate(_dataHora),
        observacoes: _observacoesController.text,
      );

      await provider.atualizarAgendamento(agendamentoAtualizado);

      if (!mounted) return;

      widget.onSalvar();
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Agendamento atualizado!'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.edit, color: Colors.teal),
                const SizedBox(width: 12),
                Text(
                  'Editar Agendamento',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Conteúdo
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Data e Hora
                  Text(
                    'Data e Hora',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _selecionarData,
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            DateFormat('dd/MM/yyyy').format(_dataHora),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _selecionarHora,
                          icon: const Icon(Icons.access_time),
                          label: Text(DateFormat('HH:mm').format(_dataHora)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Observações
                  Text(
                    'Observações',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _observacoesController,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText: 'Digite suas observações...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Botão salvar
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _salvar,
                icon:
                    _isSaving
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.save),
                label: Text(_isSaving ? 'Salvando...' : 'Salvar Alterações'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
