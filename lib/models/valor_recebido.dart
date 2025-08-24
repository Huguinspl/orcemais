import 'package:cloud_firestore/cloud_firestore.dart';

class ValorRecebido {
  final Timestamp data;
  final double valor;
  final String formaPagamento; // Credito, Debito, Boleto, Pix, Dinheiro

  ValorRecebido({
    required this.data,
    required this.valor,
    required this.formaPagamento,
  });

  factory ValorRecebido.fromMap(Map<String, dynamic> map) => ValorRecebido(
    data: map['data'] ?? Timestamp.now(),
    valor: (map['valor'] ?? 0).toDouble(),
    formaPagamento: map['formaPagamento'] ?? 'Dinheiro',
  );

  Map<String, dynamic> toMap() => {
    'data': data,
    'valor': valor,
    'formaPagamento': formaPagamento,
  };
}
