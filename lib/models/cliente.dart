import 'package:cloud_firestore/cloud_firestore.dart';

class Cliente {
  final String id;
  final String nome;
  final String celular;
  final String telefone;
  final String email;
  final String cpfCnpj;
  final String observacoes;

  // Construtor principal ajustado para maior flexibilidade
  Cliente({
    this.id = '',
    required this.nome,
    this.celular = '',
    this.telefone = '',
    this.email = '',
    this.cpfCnpj = '',
    this.observacoes = '',
  });

  Cliente copyWith({
    String? id,
    String? nome,
    String? celular,
    String? telefone,
    String? email,
    String? cpfCnpj,
    String? observacoes,
  }) => Cliente(
    id: id ?? this.id,
    nome: nome ?? this.nome,
    celular: celular ?? this.celular,
    telefone: telefone ?? this.telefone,
    email: email ?? this.email,
    cpfCnpj: cpfCnpj ?? this.cpfCnpj,
    observacoes: observacoes ?? this.observacoes,
  );

  /* ───────── Firestore helpers ───────── */

  // Construtor para criar um Cliente a partir de um DocumentSnapshot do Firestore
  factory Cliente.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Cliente(
      id: doc.id,
      nome: d['nome'] ?? '',
      celular: d['celular'] ?? '',
      telefone: d['telefone'] ?? '',
      email: d['email'] ?? '',
      cpfCnpj: d['cpfCnpj'] ?? '',
      observacoes: d['observacoes'] ?? '',
    );
  }

  // ✅ CORREÇÃO: Adicionando o construtor 'fromMap' que estava faltando.
  // Ele é necessário para recriar o objeto Cliente que está salvo dentro de um Orçamento.
  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      celular: map['celular'] ?? '',
      telefone: map['telefone'] ?? '',
      email: map['email'] ?? '',
      cpfCnpj: map['cpfCnpj'] ?? '',
      observacoes: map['observacoes'] ?? '',
    );
  }

  // Converte o objeto Cliente para um Map para salvar no Firestore
  Map<String, dynamic> toMap() => {
    'id': id,
    'nome': nome,
    'celular': celular,
    'telefone': telefone,
    'email': email,
    'cpfCnpj': cpfCnpj,
    'observacoes': observacoes,
  };
}
