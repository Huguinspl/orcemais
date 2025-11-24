import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/business_provider.dart';
import '../../tabs/pix/editar_pix_page.dart';

enum MetodoPagamento { dinheiro, pix, debito, credito, boleto }

class FormasPagamentoPage extends StatefulWidget {
  final MetodoPagamento? metodoInicial;
  final int? parcelasIniciais;
  const FormasPagamentoPage({
    super.key,
    this.metodoInicial,
    this.parcelasIniciais,
  });

  @override
  State<FormasPagamentoPage> createState() => _FormasPagamentoPageState();
}

class _FormasPagamentoPageState extends State<FormasPagamentoPage>
    with SingleTickerProviderStateMixin {
  MetodoPagamento _metodo = MetodoPagamento.pix;
  int _parcelas = 1;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _metodo = widget.metodoInicial ?? MetodoPagamento.pix;
    _parcelas = widget.parcelasIniciais ?? 1;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bp = context.watch<BusinessProvider>();
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Formas de Pagamento',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF3E5F5), Colors.white],
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Selecione a forma de pagamento:'),
                  const SizedBox(height: 8),
                  ..._metodosRadios(),
                  const SizedBox(height: 16),
                  if (_metodo == MetodoPagamento.pix) _pixCard(context, bp),
                  if (_metodo == MetodoPagamento.credito)
                    _parcelamentoCard(context),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Color(0xFF6A1B9A), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6A1B9A),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _aplicar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6A1B9A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: const Text(
                    'Aplicar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _metodosRadios() {
    return [
      _radioTile(MetodoPagamento.dinheiro, 'Dinheiro', Icons.attach_money),
      _radioTile(MetodoPagamento.pix, 'Pix', Icons.qr_code_2_outlined),
      _radioTile(MetodoPagamento.debito, 'Débito', Icons.credit_card),
      _radioTile(MetodoPagamento.credito, 'Crédito', Icons.credit_card_rounded),
      _radioTile(MetodoPagamento.boleto, 'Boleto', Icons.receipt_long_outlined),
    ];
  }

  Widget _radioTile(MetodoPagamento value, String label, IconData icon) {
    final isSelected = _metodo == value;
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Color(0xFF6A1B9A) : Colors.transparent,
          width: 2,
        ),
      ),
      child: RadioListTile<MetodoPagamento>(
        value: value,
        groupValue: _metodo,
        onChanged: (v) => setState(() => _metodo = v!),
        activeColor: Color(0xFF6A1B9A),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? Color(0xFF6A1B9A).withOpacity(0.1)
                        : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? Color(0xFF6A1B9A) : Colors.grey.shade600,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Color(0xFF6A1B9A) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pixCard(BuildContext context, BusinessProvider bp) {
    final pixInfo =
        (bp.pixTipo != null && bp.pixChave != null)
            ? 'Chave (${bp.pixTipo}): ${bp.pixChave}'
            : 'Nenhuma chave cadastrada';
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFF3E5F5)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            backgroundColor: Color(0xFF6A1B9A),
            child: const Icon(Icons.qr_code_2_outlined, color: Colors.white),
          ),
          title: const Text(
            'Chave Pix',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            pixInfo,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          trailing: Icon(Icons.edit_outlined, color: Color(0xFF6A1B9A)),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditarPixPage()),
            );
            if (mounted) setState(() {});
          },
        ),
      ),
    );
  }

  Widget _parcelamentoCard(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFF3E5F5)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF6A1B9A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.credit_card_rounded,
                    color: Color(0xFF6A1B9A),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Condições de Pagamento',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFF6A1B9A).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.payment, color: Color(0xFF6A1B9A), size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Parcelas:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xFF6A1B9A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<int>(
                      value: _parcelas,
                      onChanged: (v) => setState(() => _parcelas = v ?? 1),
                      underline: const SizedBox(),
                      dropdownColor: Colors.white,
                      style: TextStyle(
                        color: Color(0xFF6A1B9A),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      items:
                          List.generate(12, (i) => i + 1)
                              .map(
                                (e) => DropdownMenuItem<int>(
                                  value: e,
                                  child: Text('${e}x'),
                                ),
                              )
                              .toList(),
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

  void _aplicar() {
    String resumo;
    switch (_metodo) {
      case MetodoPagamento.dinheiro:
        resumo = 'Dinheiro';
        break;
      case MetodoPagamento.pix:
        resumo = 'Pix';
        break;
      case MetodoPagamento.debito:
        resumo = 'Débito';
        break;
      case MetodoPagamento.credito:
        resumo = 'Crédito em ${_parcelas}x';
        break;
      case MetodoPagamento.boleto:
        resumo = 'Boleto';
        break;
    }
    Navigator.pop(context, {
      'metodo': _metodo.name,
      'parcelas': _metodo == MetodoPagamento.credito ? _parcelas : null,
      'resumo': resumo,
    });
  }
}
