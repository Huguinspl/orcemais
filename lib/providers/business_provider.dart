import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/business_info.dart';

class BusinessProvider extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  DocumentReference<Map<String, dynamic>> get _docRef =>
      _db.doc('users/$_uid/meta/business');

  // ---- estado local ----
  String nomeEmpresa = '';
  String telefone = '';
  String ramo = '';
  String endereco = '';
  String cnpj = '';
  String emailEmpresa = '';
  String? logoUrl; // salva no Firestore
  String? logoLocalPath; // cache local
  Uint8List? _logoCacheBytes; // bytes em memória

  // Pix
  String? pixTipo; // cpf, cnpj, email, celular, aleatoria
  String? pixChave;

  // Assinatura
  String? assinaturaUrl; // URL no Storage
  String? assinaturaLocalPath; // path local
  Uint8List? _assinaturaCacheBytes;

  String get _uid => _auth.currentUser?.uid ?? '';

  /* ================== LER do Firestore ================== */
  BusinessInfo? _cachedInfo;

  BusinessInfo? get info => _cachedInfo;

  Future<void> carregarDoFirestore() async {
    if (_uid.isEmpty) return;
    final doc = await _docRef.get();

    if (doc.exists) {
      _cachedInfo = BusinessInfo.fromMap(doc.data()!);
      nomeEmpresa = _cachedInfo!.nomeEmpresa;
      telefone = _cachedInfo!.telefone;
      ramo = _cachedInfo!.ramo;
      endereco = _cachedInfo!.endereco;
      cnpj = _cachedInfo!.cnpj;
      emailEmpresa = _cachedInfo!.emailEmpresa;
      logoUrl = _cachedInfo!.logoUrl;
      pixTipo = _cachedInfo!.pixTipo;
      pixChave = _cachedInfo!.pixChave;
      assinaturaUrl = _cachedInfo!.assinaturaUrl;
      // tenta carregar path local de prefs
      final prefs = await SharedPreferences.getInstance();
      logoLocalPath = prefs.getString('business_logo_local_path');
      assinaturaLocalPath = prefs.getString('business_assinatura_local_path');
    } else {
      limparDados(); // <- limpa os dados ao logar com conta nova
    }

    notifyListeners();
  }

  /* ================== GRAVAR no Firestore ================== */
  Future<void> salvarNoFirestore({
    required String nomeEmpresa,
    required String telefone,
    required String ramo,
    required String endereco,
    required String cnpj,
    required String emailEmpresa,
    String? logoUrl,
    String? pixTipo,
    String? pixChave,
    String? assinaturaUrl,
  }) async {
    if (_uid.isEmpty) return;

    final info = BusinessInfo(
      nomeEmpresa: nomeEmpresa,
      telefone: telefone,
      ramo: ramo,
      endereco: endereco,
      cnpj: cnpj,
      emailEmpresa: emailEmpresa,
      logoUrl: logoUrl ?? this.logoUrl,
      pixTipo: pixTipo ?? this.pixTipo,
      pixChave: pixChave ?? this.pixChave,
      assinaturaUrl: assinaturaUrl ?? this.assinaturaUrl,
    );
    await _docRef.set(info.toMap(includeNulls: true));

    // Atualiza estado local
    this.nomeEmpresa = nomeEmpresa;
    this.telefone = telefone;
    this.ramo = ramo;
    this.endereco = endereco;
    this.cnpj = cnpj;
    this.emailEmpresa = emailEmpresa;
    if (logoUrl != null) this.logoUrl = logoUrl;
    if (pixTipo != null) this.pixTipo = pixTipo;
    if (pixChave != null) this.pixChave = pixChave;
    if (assinaturaUrl != null) this.assinaturaUrl = assinaturaUrl;

    _cachedInfo = BusinessInfo(
      nomeEmpresa: this.nomeEmpresa,
      telefone: this.telefone,
      ramo: this.ramo,
      endereco: this.endereco,
      cnpj: this.cnpj,
      emailEmpresa: this.emailEmpresa,
      logoUrl: this.logoUrl,
      pixTipo: this.pixTipo,
      pixChave: this.pixChave,
      assinaturaUrl: this.assinaturaUrl,
    );
    notifyListeners();
  }

  Future<void> salvarInfo(BusinessInfo info) async {
    if (_uid.isEmpty) return;
    await _docRef.set(info.toMap(includeNulls: true));
    _cachedInfo = info;
    nomeEmpresa = info.nomeEmpresa;
    telefone = info.telefone;
    ramo = info.ramo;
    endereco = info.endereco;
    cnpj = info.cnpj;
    emailEmpresa = info.emailEmpresa;
    logoUrl = info.logoUrl;
    pixTipo = info.pixTipo;
    pixChave = info.pixChave;
    assinaturaUrl = info.assinaturaUrl;
    notifyListeners();
  }

  Future<void> salvarPix({required String tipo, required String chave}) async {
    pixTipo = tipo;
    pixChave = chave;
    final updated = (_cachedInfo ?? BusinessInfo.empty()).copyWith(
      pixTipo: pixTipo,
      pixChave: pixChave,
    );
    await salvarInfo(updated);
  }

  Future<void> removerPix() async {
    pixTipo = null;
    pixChave = null;
    final updated = (_cachedInfo ?? BusinessInfo.empty()).copyWith(
      pixTipo: null,
      pixChave: null,
    );
    await salvarInfo(updated);
  }

  Future<void> uploadLogoBytes(Uint8List bytes, {String? filePath}) async {
    if (_uid.isEmpty) return;
    final ref = FirebaseStorage.instance.ref().child('users/$_uid/logo.png');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/png'));
    final url = await ref.getDownloadURL();
    logoUrl = url;
    _logoCacheBytes = bytes;
    if (filePath != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('business_logo_local_path', filePath);
      logoLocalPath = filePath;
    }
    final updated = (_cachedInfo ?? BusinessInfo.empty()).copyWith(
      nomeEmpresa: nomeEmpresa,
      telefone: telefone,
      ramo: ramo,
      endereco: endereco,
      cnpj: cnpj,
      emailEmpresa: emailEmpresa,
      logoUrl: logoUrl,
      pixTipo: pixTipo,
      pixChave: pixChave,
      assinaturaUrl: assinaturaUrl,
    );
    await salvarInfo(updated);
  }

  Future<Uint8List?> getLogoBytes() async {
    if (_logoCacheBytes != null) return _logoCacheBytes;
    if (logoLocalPath != null) {
      try {
        final f = File(logoLocalPath!);
        if (await f.exists()) {
          _logoCacheBytes = await f.readAsBytes();
          return _logoCacheBytes;
        }
      } catch (_) {}
    }
    if (logoUrl != null) {
      try {
        final resp = await http.get(Uri.parse(logoUrl!));
        if (resp.statusCode == 200) {
          _logoCacheBytes = resp.bodyBytes;
          return _logoCacheBytes;
        }
      } catch (_) {}
    }
    return null;
  }

  Future<void> uploadAssinaturaBytes(
    Uint8List bytes, {
    String? filePath,
  }) async {
    if (_uid.isEmpty) return;
    final ref = FirebaseStorage.instance.ref().child(
      'users/$_uid/assinatura.png',
    );
    await ref.putData(bytes, SettableMetadata(contentType: 'image/png'));
    final url = await ref.getDownloadURL();
    assinaturaUrl = url;
    _assinaturaCacheBytes = bytes;
    if (filePath != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('business_assinatura_local_path', filePath);
      assinaturaLocalPath = filePath;
    }
    final updated = (_cachedInfo ?? BusinessInfo.empty()).copyWith(
      nomeEmpresa: nomeEmpresa,
      telefone: telefone,
      ramo: ramo,
      endereco: endereco,
      cnpj: cnpj,
      emailEmpresa: emailEmpresa,
      logoUrl: logoUrl,
      pixTipo: pixTipo,
      pixChave: pixChave,
      assinaturaUrl: assinaturaUrl,
    );
    await salvarInfo(updated);
  }

  Future<Uint8List?> getAssinaturaBytes() async {
    if (_assinaturaCacheBytes != null) return _assinaturaCacheBytes;
    if (assinaturaLocalPath != null) {
      try {
        final f = File(assinaturaLocalPath!);
        if (await f.exists()) {
          _assinaturaCacheBytes = await f.readAsBytes();
          return _assinaturaCacheBytes;
        }
      } catch (_) {}
    }
    if (assinaturaUrl != null) {
      try {
        final resp = await http.get(Uri.parse(assinaturaUrl!));
        if (resp.statusCode == 200) {
          _assinaturaCacheBytes = resp.bodyBytes;
          return _assinaturaCacheBytes;
        }
      } catch (_) {}
    }
    return null;
  }

  Future<void> removerAssinatura() async {
    assinaturaUrl = null;
    assinaturaLocalPath = null;
    _assinaturaCacheBytes = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('business_assinatura_local_path');
    final updated = (_cachedInfo ?? BusinessInfo.empty()).copyWith(
      nomeEmpresa: nomeEmpresa,
      telefone: telefone,
      ramo: ramo,
      endereco: endereco,
      cnpj: cnpj,
      emailEmpresa: emailEmpresa,
      logoUrl: logoUrl,
      pixTipo: pixTipo,
      pixChave: pixChave,
      assinaturaUrl: null,
    );
    await salvarInfo(updated);
  }

  /* ================== LIMPAR estado local ================== */
  void limparDados() {
    nomeEmpresa = '';
    telefone = '';
    ramo = '';
    endereco = '';
    cnpj = '';
    emailEmpresa = '';
    logoUrl = null;
    logoLocalPath = null;
    _logoCacheBytes = null;
    pixTipo = null;
    pixChave = null;
    assinaturaUrl = null;
    assinaturaLocalPath = null;
    _assinaturaCacheBytes = null;
    _cachedInfo = BusinessInfo.empty();
    notifyListeners();
  }
}
