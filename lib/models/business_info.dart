import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa os dados do negócio salvos no Firestore.
class BusinessInfo {
  final String nomeEmpresa;
  final String telefone;
  final String ramo;
  final String endereco;
  final String cnpj;
  final String emailEmpresa;
  final String? logoUrl;
  final String? pixTipo; // cpf, cnpj, email, celular, aleatoria
  final String? pixChave;
  final String? assinaturaUrl;
  // Nova descrição do negócio (texto livre)
  final String? descricao;
  // Tema de cores do PDF (hex strings ex: #RRGGBB)
  final Map<String, dynamic>? pdfTheme;

  const BusinessInfo({
    required this.nomeEmpresa,
    required this.telefone,
    required this.ramo,
    required this.endereco,
    required this.cnpj,
    required this.emailEmpresa,
    this.logoUrl,
    this.pixTipo,
    this.pixChave,
    this.assinaturaUrl,
    this.descricao,
    this.pdfTheme,
  });

  BusinessInfo copyWith({
    String? nomeEmpresa,
    String? telefone,
    String? ramo,
    String? endereco,
    String? cnpj,
    String? emailEmpresa,
    String? logoUrl,
    String? pixTipo,
    String? pixChave,
    String? assinaturaUrl,
    String? descricao,
    Map<String, dynamic>? pdfTheme,
  }) => BusinessInfo(
    nomeEmpresa: nomeEmpresa ?? this.nomeEmpresa,
    telefone: telefone ?? this.telefone,
    ramo: ramo ?? this.ramo,
    endereco: endereco ?? this.endereco,
    cnpj: cnpj ?? this.cnpj,
    emailEmpresa: emailEmpresa ?? this.emailEmpresa,
    logoUrl: logoUrl ?? this.logoUrl,
    pixTipo: pixTipo ?? this.pixTipo,
    pixChave: pixChave ?? this.pixChave,
    assinaturaUrl: assinaturaUrl ?? this.assinaturaUrl,
    descricao: descricao ?? this.descricao,
    pdfTheme: pdfTheme ?? this.pdfTheme,
  );

  factory BusinessInfo.empty() => const BusinessInfo(
    nomeEmpresa: '',
    telefone: '',
    ramo: '',
    endereco: '',
    cnpj: '',
    emailEmpresa: '',
  );

  factory BusinessInfo.fromMap(Map<String, dynamic> map) => BusinessInfo(
    nomeEmpresa: map['nomeEmpresa'] ?? '',
    telefone: map['telefone'] ?? '',
    ramo: map['ramo'] ?? '',
    endereco: map['endereco'] ?? '',
    cnpj: map['cnpj'] ?? '',
    emailEmpresa: map['emailEmpresa'] ?? '',
    logoUrl: map['logoUrl'],
    pixTipo: map['pixTipo'],
    pixChave: map['pixChave'],
    assinaturaUrl: map['assinaturaUrl'],
    descricao: map['descricao'],
    pdfTheme: map['pdfTheme'] as Map<String, dynamic>?,
  );

  factory BusinessInfo.fromDoc(DocumentSnapshot doc) =>
      BusinessInfo.fromMap(doc.data() as Map<String, dynamic>);

  Map<String, dynamic> toMap({bool includeNulls = false}) {
    final data = <String, dynamic>{
      'nomeEmpresa': nomeEmpresa,
      'telefone': telefone,
      'ramo': ramo,
      'endereco': endereco,
      'cnpj': cnpj,
      'emailEmpresa': emailEmpresa,
    };
    void put(String key, dynamic value) {
      if (includeNulls || value != null) data[key] = value;
    }

    put('logoUrl', logoUrl);
    put('pixTipo', pixTipo);
    put('pixChave', pixChave);
    put('assinaturaUrl', assinaturaUrl);
    put('descricao', descricao);
    put('pdfTheme', pdfTheme);
    return data;
  }

  @override
  String toString() =>
      'BusinessInfo(nome="$nomeEmpresa", telefone="$telefone")';

  @override
  int get hashCode => Object.hash(
    nomeEmpresa,
    telefone,
    ramo,
    endereco,
    cnpj,
    emailEmpresa,
    logoUrl,
    pixTipo,
    pixChave,
    assinaturaUrl,
    descricao,
    pdfTheme,
  );

  @override
  bool operator ==(Object other) =>
      other is BusinessInfo &&
      nomeEmpresa == other.nomeEmpresa &&
      telefone == other.telefone &&
      ramo == other.ramo &&
      endereco == other.endereco &&
      cnpj == other.cnpj &&
      emailEmpresa == other.emailEmpresa &&
      logoUrl == other.logoUrl &&
      pixTipo == other.pixTipo &&
      pixChave == other.pixChave &&
      assinaturaUrl == other.assinaturaUrl &&
      descricao == other.descricao &&
      _mapEquals(pdfTheme, other.pdfTheme);
}

bool _mapEquals(Map<String, dynamic>? a, Map<String, dynamic>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return a == b;
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key)) return false;
    if (a[key] != b[key]) return false;
  }
  return true;
}
