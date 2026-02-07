import 'package:flutter/material.dart';
import 'agendamento_vendas_page.dart';
import 'agendamento_servicos_page.dart';
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
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            // Primeira linha: Serviços e Vendas
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  Expanded(
                    child: _buildTipoCardCompacto(
                      context: context,
                      tipo: TipoAgendamento.servicos,
                      titulo: 'Serviços',
                      subtitulo: 'Agendamento de serviços',
                      icone: Icons.build_circle,
                      cor: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTipoCardCompacto(
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
            ),
            const SizedBox(height: 8),

            // Segunda linha: A Receber e A Pagar
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  Expanded(
                    child: _buildTipoCardCompacto(
                      context: context,
                      tipo: TipoAgendamento.aReceber,
                      titulo: 'A Receber',
                      subtitulo: 'Receita futura',
                      icone: Icons.call_received,
                      cor: Colors.teal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTipoCardCompacto(
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
            ),
            const SizedBox(height: 8),

            // Terceira linha: Agendamento Rápido (Diversos)
            SizedBox(
              height: 70,
              child: _buildTipoCardCompacto(
                context: context,
                tipo: TipoAgendamento.diversos,
                titulo: 'Agendamento Rápido',
                subtitulo: 'Trabalhos rápidos (ex: cabeleireiro)',
                icone: Icons.flash_on,
                cor: Colors.purple,
                isFullWidth: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipoCardCompacto({
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [cor.shade400, cor.shade600],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: cor.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child:
            isFullWidth
                ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icone, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titulo,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          subtitulo,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white70,
                      size: 16,
                    ),
                  ],
                )
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icone, color: Colors.white, size: 36),
                    const SizedBox(height: 8),
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitulo,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
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
        pagina = AgendamentoServicosPage(dataInicial: dataInicial);
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

    Navigator.of(context).push(MaterialPageRoute(builder: (_) => pagina));
  }
}
