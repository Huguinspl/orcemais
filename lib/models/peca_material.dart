class PecaMaterial {
  final String id;
  final String nome;
  final double? preco;
  final String? marca;
  final String? modelo;
  final String? codigoProduto;
  final String? codigoInterno;
  final String? unidadeMedida;
  final double? custo;
  final String? descricao;
  final String? uid; // ✅ CORREÇÃO 1: Adicionar o campo uid

  PecaMaterial({
    this.id = '',
    required this.nome,
    this.preco,
    this.marca,
    this.modelo,
    this.codigoProduto,
    this.codigoInterno,
    this.unidadeMedida,
    this.custo,
    this.descricao,
    this.uid, // ✅ CORREÇÃO 2: Adicionar ao construtor
  });

  PecaMaterial copyWith({
    String? id,
    String? nome,
    double? preco,
    String? marca,
    String? modelo,
    String? codigoProduto,
    String? codigoInterno,
    String? unidadeMedida,
    double? custo,
    String? descricao,
    String? uid, // ✅ CORREÇÃO 3: Adicionar ao copyWith
  }) {
    return PecaMaterial(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      preco: preco ?? this.preco,
      marca: marca ?? this.marca,
      modelo: modelo ?? this.modelo,
      codigoProduto: codigoProduto ?? this.codigoProduto,
      codigoInterno: codigoInterno ?? this.codigoInterno,
      unidadeMedida: unidadeMedida ?? this.unidadeMedida,
      custo: custo ?? this.custo,
      descricao: descricao ?? this.descricao,
      uid: uid ?? this.uid, // ✅ CORREÇÃO 4: Adicionar ao copyWith
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'preco': preco,
      'marca': marca,
      'modelo': modelo,
      'codigoProduto': codigoProduto,
      'codigoInterno': codigoInterno,
      'unidadeMedida': unidadeMedida,
      'custo': custo,
      'descricao': descricao,
      'uid': uid, // ✅ CORREÇÃO 5: Adicionar ao toMap para salvar no Firestore
    };
  }

  factory PecaMaterial.fromFirestore(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return PecaMaterial(
      id: documentId,
      nome: data['nome'] ?? '',
      preco: (data['preco'] as num?)?.toDouble(),
      marca: data['marca'],
      modelo: data['modelo'],
      codigoProduto: data['codigoProduto'],
      codigoInterno: data['codigoInterno'],
      unidadeMedida: data['unidadeMedida'],
      custo: (data['custo'] as num?)?.toDouble(),
      descricao: data['descricao'],
      uid: data['uid'], // ✅ CORREÇÃO 6: Ler o uid do Firestore
    );
  }
}
