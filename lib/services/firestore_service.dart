import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  // 👇 Caminho do documento: users/{uid}
  DocumentReference get _doc {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }
    return _db.collection('users').doc(user.uid);
  }

  /// Cria o documento do usuário no Firestore.
  Future<void> createUser({
    required String uid,
    required String email,
    String nome = '',
    String cpf = '',
  }) => _db.collection('users').doc(uid).set({
    'email': email,
    'nome': nome,
    'cpf': cpf,
  });

  /// Busca os dados do usuário logado.
  Future<Map<String, dynamic>?> fetchUser() async {
    final snap = await _doc.get();
    return snap.data() as Map<String, dynamic>?;
  }

  /// Atualiza um ou mais campos no documento do usuário.
  Future<void> updateUser({String? nome, String? email, String? cpf}) async {
    final data = <String, dynamic>{};
    if (nome != null) data['nome'] = nome;
    if (email != null) data['email'] = email;
    if (cpf != null) data['cpf'] = cpf;

    if (data.isNotEmpty) {
      await _doc.update(data);
    }
  }
}
