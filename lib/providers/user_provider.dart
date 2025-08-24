import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProvider extends ChangeNotifier {
  final _fs = FirestoreService();
  final _auth = FirebaseAuth.instance;

  /* ---------------- UID ---------------- */
  String? _uid; // ← novo campo
  String get uid => _uid ?? ''; // ← getter público

  /* ---------------- FLAG DE CARGA ÚNICA ---------------- */
  bool _carregado = false;
  bool get carregado => _carregado;

  /* --------------------- ESTADO ----------------------- */
  String _nome = '';
  String _email = '';
  String _cpf = '';
  String _emailCadastro = '';

  /* -------------------- GETTERS ----------------------- */
  String get nome => _nome;
  String get email => _email;
  String get cpf => _cpf;
  String get emailCadastro => _emailCadastro;

  /* --------------- CARREGA DADOS DO USUÁRIO ---------------- */
  Future<void> carregarDoFirestore() async {
    try {
      // Verifica se há usuário logado
      final user = _auth.currentUser;
      if (user == null) {
        _limparDados();
        return;
      }

      _uid = user.uid; // ← garante que UID esteja preenchido
      _carregado = false; // força recarga

      final data = await _fs.fetchUser();
      if (data != null) {
        _nome = data['nome'] ?? '';
        _email = data['email'] ?? user.email ?? '';
        _cpf = data['cpf'] ?? '';
      } else {
        _email = user.email ?? '';
      }
      _emailCadastro = user.email ?? '';

      _carregado = true;
      notifyListeners();
    } catch (e) {
      _limparDados();
      rethrow;
    }
  }

  /* ----------- LIMPA DADOS AO DESLOGAR -------------- */
  void _limparDados() {
    _uid = null; // ← zera UID
    _nome = '';
    _email = '';
    _cpf = '';
    _emailCadastro = '';
    _carregado = false;
    notifyListeners();
  }

  /* --------- MÉTODO PARA DEFINIR UID APÓS LOGIN ------- */
  void setUid(String value) {
    // ← chame logo após autenticar
    _uid = value;
    notifyListeners();
  }

  /* ----------- ATUALIZAÇÕES VINDAS DA UI -------------- */
  void atualizarDados(String nome, String email, String cpf) {
    _nome = nome;
    _email = email;
    _cpf = cpf;
    notifyListeners();
    _fs.updateUser(nome: nome, email: email, cpf: cpf);
  }

  void atualizarNome(String nome) {
    _nome = nome;
    notifyListeners();
    _fs.updateUser(nome: nome);
  }

  /* -------------- E-MAIL FIXO DO LOGIN ---------------- */
  Future<void> setEmailCadastro(String email) async {
    _emailCadastro = email;
    _email = email;
    notifyListeners();
    await _fs.updateUser(email: email);
  }

  /* -------------- SALVA CAMPOS INDIVIDUAIS ------------- */
  Future<void> salvarNoFirestore({
    String? nome,
    String? email,
    String? cpf,
  }) async {
    if (nome != null) _nome = nome;
    if (email != null) _email = email;
    if (cpf != null) _cpf = cpf;

    notifyListeners();
    await _fs.updateUser(nome: nome, email: email, cpf: cpf);
  }

  /* ------------ VERIFICA E CARREGA DADOS --------------- */
  Future<void> verificarECarregarDados() async {
    if (!_carregado || _nome.isEmpty) {
      await carregarDoFirestore();
    }
  }

  void limparDados() => _limparDados();
}
