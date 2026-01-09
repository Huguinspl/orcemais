import 'package:flutter/material.dart';
import 'novo_agendamento_page.dart';
import 'agendamento_vendas_page.dart';
import 'agendamento_a_receber_page.dart';
import 'agendamento_a_pagar_page.dart';
import 'agendamento_diversos_page.dart';

/// Enum para os tipos de agendamento disponíveis
enum TipoAgendamento { servicos, vendas, aReceber, aPagar, diversos }

/// Página para selecionar o tipo de agendamento
/// Similar ao modal de seleção de nova transação
class SelecionarTipoAgendamentoPage extends StatelessWidget {
  final DateTime? dataInicial;

  const SelecionarTipoAgendamentoPage({super.key, this.dataInicial});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.teal.shade600,
        foregroundColor: Colors.white,
        title: const Text(
          'Novo Agendamento',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade50, Colors.white, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.shade400, Colors.teal.shade600],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.calendar_month,
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
                            'Selecione o Tipo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Escolha o tipo de agendamento que deseja criar',
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
              const SizedBox(height: 24),

              // Seção: Agendamentos de Trabalho
              _buildSectionHeader(
                'Agendamentos de Trabalho',
                Icons.work_outline,
                Colors.blue.shade600,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Card: Agendamento de Serviços
                  Expanded(
                    child: _buildTipoCard(
                      context: context,
                      tipo: TipoAgendamento.servicos,
                      titulo: 'Serviços',
                      subtitulo: 'Agendamento de serviços',
                      icone: Icons.build_circle,
                      cor: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Card: Agendamento de Vendas
                  Expanded(
                    child: _buildTipoCard(
                      context: context,
                      tipo: TipoAgendamento.vendas,
                      titulo: 'Vendas',
                      subtitulo: 'Agendamento de vendas',
                      icone: Icons.shopping_cart,
                      cor: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Seção: Agendamentos Financeiros
              _buildSectionHeader(
                'Agendamentos Financeiros',
                Icons.account_balance_wallet_outlined,
                Colors.green.shade600,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Card: A Receber
                  Expanded(
                    child: _buildTipoCard(
                      context: context,
                      tipo: TipoAgendamento.aReceber,
                      titulo: 'A Receber',
                      subtitulo: 'Receita futura',
                      icone: Icons.call_received,
                      cor: Colors.teal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Card: A Pagar
                  Expanded(
                    child: _buildTipoCard(
                      context: context,
                      tipo: TipoAgendamento.aPagar,
                      titulo: 'A Pagar',
                      subtitulo: 'Despesa futura',
                      icone: Icons.call_made,
                      cor: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Seção: Agendamento Rápido
              _buildSectionHeader(
                'Agendamento Rápido',
                Icons.flash_on,
                Colors.purple.shade600,
              ),
              const SizedBox(height: 12),
              // Card: Diversos (largura total)
              _buildTipoCard(
                context: context,
                tipo: TipoAgendamento.diversos,
                titulo: 'Diversos',
                subtitulo:
                    'Agendamento rápido para trabalhos rápidos (ex: cabeleireiro)',
                icone: Icons.event_available,
                cor: Colors.purple,
                isFullWidth: true,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildTipoCard({
    required BuildContext context,
    required TipoAgendamento tipo,
    required String titulo,
    required String subtitulo,
    required IconData icone,
    required MaterialColor cor,
    bool isFullWidth = false,
  }) {
    return GestureDetector(
      onTap: () => _navegarParaTipo(context, tipo),
      child: Container(
        padding: EdgeInsets.all(isFullWidth ? 20 : 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [cor.shade400, cor.shade600],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: cor.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child:
            isFullWidth
                ? Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icone, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titulo,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitulo,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ],
                )
                : Column(
                  children: [
                    Icon(icone, color: Colors.white, size: 40),
                    const SizedBox(height: 10),
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
      ),
    );
  }

  void _navegarParaTipo(BuildContext context, TipoAgendamento tipo) {
    Widget pagina;

    switch (tipo) {
      case TipoAgendamento.servicos:
        pagina = NovoAgendamentoPage(dataInicial: dataInicial);
        break;
      case TipoAgendamento.vendas:
        pagina = AgendamentoVendasPage(dataInicial: dataInicial);
        break;
      case TipoAgendamento.aReceber:
        pagina = const AgendamentoAReceberPage();
        break;
      case TipoAgendamento.aPagar:
        pagina = const AgendamentoAPagarPage();
        break;
      case TipoAgendamento.diversos:
        pagina = AgendamentoDiversosPage(dataInicial: dataInicial);
        break;
    }

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => pagina));
  }
}
