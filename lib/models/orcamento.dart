import 'package:cloud_firestore/cloud_firestore.dart';
import 'cliente.dart';

class Orcamento {
  final String id;
  final int numero; // <-- NOVO CAMPO
  final Cliente cliente;
  final List<Map<String, dynamic>> itens;
  final double subtotal;
  final double desconto;
  final double valorTotal;
  final String status;
  final Timestamp dataCriacao;
  // Novos campos: pagamento
  final String? metodoPagamento; // dinheiro, pix, debito, credito, boleto
  final int? parcelas; // quando crédito
  final String? laudoTecnico; // texto livre
  final String? condicoesContratuais; // texto livre
  final String? garantia; // texto livre
  final String? informacoesAdicionais; // texto livre
  final List<String>? fotos; // URLs das fotos do orçamento

  Orcamento({
    required this.id,
    this.numero = 0, // <-- NOVO CAMPO
    required this.cliente,
    required this.itens,
    required this.subtotal,
    required this.desconto,
    required this.valorTotal,
    required this.status,
    required this.dataCriacao,
    this.metodoPagamento,
    this.parcelas,
    this.laudoTecnico,
    this.condicoesContratuais,
    this.garantia,
    this.informacoesAdicionais,
    this.fotos,
  });

  factory Orcamento.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Orcamento(
      id: doc.id,
      numero: data['numero'] ?? 0, // <-- NOVO CAMPO
      cliente: Cliente.fromMap(data['cliente'] ?? {}),
      itens: List<Map<String, dynamic>>.from(data['itens'] ?? []),
      subtotal: (data['subtotal'] ?? 0.0).toDouble(),
      desconto: (data['desconto'] ?? 0.0).toDouble(),
      valorTotal: (data['valorTotal'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'Aberto',
      dataCriacao: data['dataCriacao'] ?? Timestamp.now(),
      metodoPagamento: data['metodoPagamento'],
      parcelas: data['parcelas'],
      laudoTecnico: data['laudoTecnico'],
      condicoesContratuais: data['condicoesContratuais'],
      garantia: data['garantia'],
      informacoesAdicionais: data['informacoesAdicionais'],
      fotos: data['fotos'] != null ? List<String>.from(data['fotos']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'numero': numero, // <-- NOVO CAMPO
      'cliente': cliente.toMap(),
      'itens': itens,
      'subtotal': subtotal,
      'desconto': desconto,
      'valorTotal': valorTotal,
      'status': status,
      'dataCriacao': dataCriacao,
      'metodoPagamento': metodoPagamento,
      'parcelas': parcelas,
      'laudoTecnico': laudoTecnico,
      'condicoesContratuais': condicoesContratuais,
      'garantia': garantia,
      'informacoesAdicionais': informacoesAdicionais,
      'fotos': fotos,
    };
  }
}
