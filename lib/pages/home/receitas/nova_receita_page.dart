import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/cliente.dart';
import '../../../models/orcamento.dart';
import '../../../models/receita.dart';
import '../../../providers/clients_provider.dart';
import '../../../providers/transacoes_provider.dart';
import '../../../providers/user_provider.dart';
import '../tabs/clientes_page.dart';
import '../tabs/novo_cliente_page.dart';
import '../orcamentos/orcamentos_page.dart';

class CurrencyInputFormatterReceita extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    final numeros = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeros.isEmpty) return const TextEditingValue(text: 'R\$ 0,00');
    final valor = int.parse(numeros) / 100;
    final textoFormatado =
        'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
    return TextEditingValue(
      text: textoFormatado,
      selection: TextSelection.collapsed(offset: textoFormatado.length),
    );
  }
}

/// Página para criar/editar receita (entrada de dinheiro já realizada)
/// Estrutura similar à página de Receita a Receber, mas sem campos de agendamento
class NovaReceitaPage extends StatefulWidget {
  /// Transação para edição (null = criar novo)
  final Transacao? transacao;

  /// Se true, cria receita a receber (futura)
  final bool isFutura;

  /// Callback para voltar ao modal de nova transação
  final VoidCallback? onVoltarParaModal;

  const NovaReceitaPage({
    super.key,
    this.transacao,
    this.isFutura = false,
    this.onVoltarParaModal,
  });

  /// Verifica se está em modo de edição
  bool get isEditMode => transacao != null;

  @override
  State<NovaReceitaPage> createState() => _NovaReceitaPageState();
}

class _NovaReceitaPageState extends State<NovaReceitaPage> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  final _observacoesController = TextEditingController();

  DateTime _dataTransacao = DateTime.now();
  CategoriaTransacao? _categoriaSelecionada;
  bool _salvando = false;

  // Novos campos
  bool _repetirParcelar = false;
  int _quantidadeRepeticoes = 2; // Número de vezes que vai repetir (mínimo 2)
  String _tipoRepeticao = 'mensal'; // mensal, quinzenal, semanal
  Orcamento? _orcamentoSelecionado;
  Cliente? _clienteSelecionado;

  // ID da transação sendo editada (null = novo)
  String? _transacaoId;

  // Lista de arquivos/fotos anexados
  final List<_ArquivoAnexoReceita> _arquivosAnexados = [];
  bool _enviandoArquivo = false;

  @override
  void initState() {
    super.initState();

    final transacao = widget.transacao;

    if (transacao != null) {
      // Modo edição: carregar dados da transação existente
      _transacaoId = transacao.id;
      _dataTransacao = transacao.data;
      _descricaoController.text = transacao.descricao;
      _valorController.text =
          'R\$ ${transacao.valor.toStringAsFixed(2).replaceAll('.', ',')}';
      _categoriaSelecionada = transacao.categoria;
      _observacoesController.text = transacao.observacoes ?? '';
    }
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  MaterialColor get _corTema => Colors.green;

  double? _parseMoeda(String texto) {
    if (texto.isEmpty) return null;
    String limpo = texto.replaceAll('R\$', '').replaceAll(' ', '').trim();
    limpo = limpo.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(limpo);
  }

  Future<void> _selecionarDataTransacao() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataTransacao,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _corTema.shade600,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (data != null) {
      setState(() => _dataTransacao = data);
    }
  }

  List<DropdownMenuItem<CategoriaTransacao>> _getCategorias() {
    final categorias =
        CategoriaTransacao.values.where((cat) => cat.isReceita).toList();
    return categorias.map((cat) {
      return DropdownMenuItem(value: cat, child: Text(cat.nome));
    }).toList();
  }

  // ========== MÉTODOS DE COMPROVANTES ==========

  void _mostrarOpcoesAnexo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Adicionar Comprovante',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildOpcaoAnexo(
                    icone: Icons.camera_alt,
                    label: 'Câmera',
                    cor: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      _capturarFoto();
                    },
                  ),
                  _buildOpcaoAnexo(
                    icone: Icons.photo_library,
                    label: 'Galeria',
                    cor: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      _selecionarDaGaleria();
                    },
                  ),
                  _buildOpcaoAnexo(
                    icone: Icons.attach_file,
                    label: 'Arquivo',
                    cor: Colors.orange,
                    onTap: () {
                      Navigator.pop(context);
                      _selecionarArquivo();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOpcaoAnexo({
    required IconData icone,
    required String label,
    required MaterialColor cor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cor.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icone, color: cor.shade600, size: 32),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: cor.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _capturarFoto() async {
    try {
      final picker = ImagePicker();
      final foto = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      if (foto != null) {
        await _adicionarArquivo(foto.path, foto.name, 'image');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao capturar foto: $e')));
      }
    }
  }

  Future<void> _selecionarDaGaleria() async {
    try {
      final picker = ImagePicker();
      final imagens = await picker.pickMultiImage(imageQuality: 70);
      for (final img in imagens) {
        await _adicionarArquivo(img.path, img.name, 'image');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao selecionar imagens: $e')),
        );
      }
    }
  }

  Future<void> _selecionarArquivo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'doc', 'docx'],
        allowMultiple: true,
      );
      if (result != null) {
        for (final file in result.files) {
          if (file.path != null) {
            final tipo =
                file.extension?.toLowerCase() == 'pdf' ? 'pdf' : 'image';
            await _adicionarArquivo(file.path!, file.name, tipo);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao selecionar arquivo: $e')),
        );
      }
    }
  }

  Future<void> _adicionarArquivo(String path, String nome, String tipo) async {
    setState(() => _enviandoArquivo = true);
    try {
      final userId = context.read<UserProvider>().uid;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = 'receitas/$userId/comprovantes/$timestamp\_$nome';

      final ref = FirebaseStorage.instance.ref().child(storagePath);

      String url;
      if (kIsWeb) {
        final bytes = await File(path).readAsBytes();
        await ref.putData(bytes);
        url = await ref.getDownloadURL();
      } else {
        await ref.putFile(File(path));
        url = await ref.getDownloadURL();
      }

      setState(() {
        _arquivosAnexados.add(
          _ArquivoAnexoReceita(nome: nome, url: url, tipo: tipo),
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar arquivo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _enviandoArquivo = false);
      }
    }
  }

  void _removerArquivo(int index) {
    setState(() {
      _arquivosAnexados.removeAt(index);
    });
  }

  Widget _buildCardAnexos() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.green.shade600),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Comprovantes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              if (_enviandoArquivo)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  onPressed: _mostrarOpcoesAnexo,
                  icon: Icon(Icons.add_circle, color: Colors.green.shade600),
                  tooltip: 'Adicionar comprovante',
                ),
            ],
          ),
          if (_arquivosAnexados.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Nenhum comprovante anexado',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              ),
            )
          else ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _arquivosAnexados.length,
                itemBuilder: (context, index) {
                  final arquivo = _arquivosAnexados[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child:
                                arquivo.tipo == 'image'
                                    ? Image.network(
                                      arquivo.url,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (_, __, ___) => Icon(
                                            Icons.image,
                                            color: Colors.grey.shade400,
                                            size: 40,
                                          ),
                                    )
                                    : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.picture_as_pdf,
                                          color: Colors.red.shade400,
                                          size: 40,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'PDF',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removerArquivo(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 8),
          InkWell(
            onTap: _mostrarOpcoesAnexo,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.green.shade200,
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo,
                    color: Colors.green.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Adicionar foto ou arquivo',
                    style: TextStyle(
                      color: Colors.green.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Navegar para selecionar orçamento
  Future<void> _selecionarOrcamento() async {
    final orcamento = await Navigator.push<Orcamento>(
      context,
      MaterialPageRoute(
        builder: (_) => const OrcamentosPage(isPickerMode: true),
      ),
    );

    if (orcamento != null && mounted) {
      setState(() {
        _orcamentoSelecionado = orcamento;
        _descricaoController.text =
            'Orçamento #${orcamento.numero.toString().padLeft(4, '0')} - ${orcamento.cliente.nome}';
        final valorFormatado =
            'R\$ ${orcamento.valorTotal.toStringAsFixed(2).replaceAll('.', ',')}';
        _valorController.text = valorFormatado;
        _clienteSelecionado = orcamento.cliente;
      });
    }
  }

  // Mostrar opções para selecionar cliente
  Future<void> _mostrarOpcoesCliente() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Selecionar Cliente',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _corTema.shade700,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildOpcaoCliente(
                      icon: Icons.people,
                      label: 'Clientes',
                      cor: Colors.blue,
                      onTap: () {
                        Navigator.pop(ctx);
                        _navegarParaClientes();
                      },
                    ),
                    _buildOpcaoCliente(
                      icon: Icons.contact_phone,
                      label: 'Agenda',
                      cor: Colors.green,
                      onTap: () {
                        Navigator.pop(ctx);
                        _importarDaAgenda();
                      },
                    ),
                    _buildOpcaoCliente(
                      icon: Icons.person_add,
                      label: 'Criar Novo',
                      cor: Colors.purple,
                      onTap: () {
                        Navigator.pop(ctx);
                        _criarNovoCliente();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }

  Widget _buildOpcaoCliente({
    required IconData icon,
    required String label,
    required MaterialColor cor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: cor.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cor.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [cor.shade400, cor.shade600]),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cor.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navegarParaClientes() async {
    final cliente = await Navigator.push<Cliente>(
      context,
      MaterialPageRoute(builder: (_) => const ClientesPage(isPickerMode: true)),
    );

    if (cliente != null && mounted) {
      setState(() {
        _clienteSelecionado = cliente;
      });
    }
  }

  Future<void> _importarDaAgenda() async {
    if (!await FlutterContacts.requestPermission(readonly: true)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Permissão para acessar contatos negada')),
            ],
          ),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    try {
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      if (!mounted) return;

      if (contacts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Nenhum contato encontrado na agenda')),
              ],
            ),
            backgroundColor: Colors.blue.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }

      final selectedContact = await showDialog<Contact>(
        context: context,
        builder: (ctx) => _buildContactPickerDialog(contacts),
      );

      if (selectedContact != null && mounted) {
        final nome = selectedContact.displayName;
        final celular =
            selectedContact.phones.isNotEmpty
                ? selectedContact.phones.first.number
                : '';
        final email =
            selectedContact.emails.isNotEmpty
                ? selectedContact.emails.first.address
                : '';

        setState(() {
          _clienteSelecionado = Cliente(
            nome: nome,
            celular: celular,
            email: email,
          );
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Erro ao buscar contatos: $e')),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Widget _buildContactPickerDialog(List<Contact> contacts) {
    final searchController = TextEditingController();
    List<Contact> filteredContacts = contacts;

    return StatefulBuilder(
      builder: (context, setDialogState) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
              maxWidth: 400,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade600, Colors.green.shade400],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.contact_phone,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Selecionar Contato',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Buscar contato...',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.white,
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.2),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          setDialogState(() {
                            filteredContacts =
                                contacts
                                    .where(
                                      (c) => c.displayName
                                          .toLowerCase()
                                          .contains(value.toLowerCase()),
                                    )
                                    .toList();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredContacts.length,
                    itemBuilder: (ctx, index) {
                      final contact = filteredContacts[index];
                      final phone =
                          contact.phones.isNotEmpty
                              ? contact.phones.first.number
                              : 'Sem telefone';
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          child: Text(
                            contact.displayName.isNotEmpty
                                ? contact.displayName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(contact.displayName),
                        subtitle: Text(phone),
                        onTap: () => Navigator.pop(ctx, contact),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _criarNovoCliente() async {
    final novoCliente = await Navigator.push<Cliente>(
      context,
      MaterialPageRoute(builder: (_) => const NovoClientePage()),
    );

    if (novoCliente != null && mounted) {
      setState(() {
        _clienteSelecionado = novoCliente;
      });
    } else if (mounted) {
      final userProvider = context.read<UserProvider>();
      final clientsProvider = context.read<ClientsProvider>();
      await clientsProvider.carregarTodos(userProvider.uid);
      if (clientsProvider.clientes.isNotEmpty) {
        setState(() {
          _clienteSelecionado = clientsProvider.clientes.last;
        });
      }
    }
  }

  // ========== MÉTODOS DE REPETIÇÃO ==========

  void _mostrarConfigRepeticao() {
    int tempQuantidade = _quantidadeRepeticoes;
    String tempTipo = _tipoRepeticao;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.repeat, color: _corTema.shade600, size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'Configurar Repetição',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Repetir a cada:',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Semana'),
                        selected: tempTipo == 'semanal',
                        onSelected:
                            (v) => setModalState(() => tempTipo = 'semanal'),
                        selectedColor: _corTema.shade100,
                      ),
                      ChoiceChip(
                        label: const Text('Quinzena'),
                        selected: tempTipo == 'quinzenal',
                        onSelected:
                            (v) => setModalState(() => tempTipo = 'quinzenal'),
                        selectedColor: _corTema.shade100,
                      ),
                      ChoiceChip(
                        label: const Text('Mês'),
                        selected: tempTipo == 'mensal',
                        onSelected:
                            (v) => setModalState(() => tempTipo = 'mensal'),
                        selectedColor: _corTema.shade100,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Quantidade de vezes:',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        onPressed:
                            tempQuantidade > 2
                                ? () => setModalState(() => tempQuantidade--)
                                : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: _corTema.shade600,
                        iconSize: 32,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: _corTema.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _corTema.shade200),
                        ),
                        child: Text(
                          '$tempQuantidade',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _corTema.shade700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed:
                            tempQuantidade < 24
                                ? () => setModalState(() => tempQuantidade++)
                                : null,
                        icon: const Icon(Icons.add_circle_outline),
                        color: _corTema.shade600,
                        iconSize: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _getDescricaoRepeticao(tempTipo, tempQuantidade),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() => _repetirParcelar = false);
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _quantidadeRepeticoes = tempQuantidade;
                              _tipoRepeticao = tempTipo;
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _corTema.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Confirmar'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getDescricaoRepeticao(String tipo, int quantidade) {
    final periodo =
        tipo == 'semanal'
            ? 'semanas'
            : (tipo == 'quinzenal' ? 'quinzenas' : 'meses');
    return 'Total: $quantidade receitas ao longo de $quantidade $periodo';
  }

  DateTime _calcularProximaData(DateTime dataBase, String tipo, int indice) {
    switch (tipo) {
      case 'semanal':
        return dataBase.add(Duration(days: 7 * indice));
      case 'quinzenal':
        return dataBase.add(Duration(days: 15 * indice));
      case 'mensal':
      default:
        return DateTime(dataBase.year, dataBase.month + indice, dataBase.day);
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);

    try {
      final userProvider = context.read<UserProvider>();
      final userId = userProvider.uid;

      if (userId.isEmpty) {
        throw Exception('Usuário não identificado');
      }

      final valor = _parseMoeda(_valorController.text) ?? 0.0;

      // Monta observações
      final obsCompletas = StringBuffer();
      if (_clienteSelecionado != null) {
        obsCompletas.writeln('Cliente: ${_clienteSelecionado!.nome}');
      }
      if (_orcamentoSelecionado != null) {
        obsCompletas.writeln(
          'Orçamento: #${_orcamentoSelecionado!.numero.toString().padLeft(4, '0')}',
        );
      }
      if (_repetirParcelar) {
        obsCompletas.writeln('Repetir/Parcelar: Sim');
      }
      if (_observacoesController.text.isNotEmpty) {
        obsCompletas.writeln(_observacoesController.text);
      }
      // Adiciona URLs dos comprovantes
      if (_arquivosAnexados.isNotEmpty) {
        obsCompletas.writeln('[COMPROVANTES]');
        for (final arquivo in _arquivosAnexados) {
          obsCompletas.writeln('${arquivo.nome}|${arquivo.url}');
        }
        obsCompletas.writeln('[/COMPROVANTES]');
      }

      final transacao = Transacao(
        id: _transacaoId,
        descricao: _descricaoController.text,
        valor: valor,
        tipo: TipoTransacao.receita,
        categoria: _categoriaSelecionada!,
        data: _dataTransacao,
        observacoes: obsCompletas.toString().trim(),
        userId: userId,
        isFutura: widget.isFutura,
      );

      final transacoesProvider = context.read<TransacoesProvider>();

      bool sucesso;
      int quantidadeSalva = 1;

      if (_transacaoId != null) {
        // Modo edição - não repete, apenas atualiza
        sucesso = await transacoesProvider.atualizarTransacao(transacao);
      } else {
        // Modo criação
        sucesso = await transacoesProvider.adicionarTransacao(transacao);

        // Se repetir está ativado e salvou com sucesso, cria as repetições
        if (sucesso && _repetirParcelar && _quantidadeRepeticoes > 1) {
          for (int i = 1; i < _quantidadeRepeticoes; i++) {
            final dataRepeticao = _calcularProximaData(
              _dataTransacao,
              _tipoRepeticao,
              i,
            );
            final obsRepeticao = StringBuffer();
            if (_clienteSelecionado != null) {
              obsRepeticao.writeln('Cliente: ${_clienteSelecionado!.nome}');
            }
            if (_orcamentoSelecionado != null) {
              obsRepeticao.writeln(
                'Orçamento: #${_orcamentoSelecionado!.numero.toString().padLeft(4, '0')}',
              );
            }
            obsRepeticao.writeln('Repetição: ${i + 1}/$_quantidadeRepeticoes');
            if (_observacoesController.text.isNotEmpty) {
              obsRepeticao.writeln(_observacoesController.text);
            }

            final transacaoRepeticao = Transacao(
              descricao: _descricaoController.text,
              valor: valor,
              tipo: TipoTransacao.receita,
              categoria: _categoriaSelecionada!,
              data: dataRepeticao,
              observacoes: obsRepeticao.toString().trim(),
              userId: userId,
              isFutura: widget.isFutura,
            );

            final sucessoRepeticao = await transacoesProvider
                .adicionarTransacao(transacaoRepeticao);
            if (sucessoRepeticao) quantidadeSalva++;
          }
        }
      }

      if (!mounted) return;

      if (sucesso) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  _transacaoId != null
                      ? 'Receita atualizada!'
                      : _repetirParcelar && _quantidadeRepeticoes > 1
                      ? '$quantidadeSalva receitas salvas com sucesso!'
                      : 'Receita adicionada!',
                ),
              ],
            ),
            backgroundColor: _corTema.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        throw Exception('Erro ao salvar receita');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  void _voltarParaModal() {
    Navigator.pop(context);
    if (widget.onVoltarParaModal != null) {
      widget.onVoltarParaModal!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final corTema = _corTema;
    final dateFormat = DateFormat('dd/MM/yyyy');

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: corTema.shade600,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _voltarParaModal,
          ),
          title: Text(
            widget.transacao != null ? 'Editar Receita' : 'Nova Receita',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0,
        ),
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [corTema.shade50, Colors.white],
            ),
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ========== REPETIR / PARCELAR ==========
                      InkWell(
                        onTap: () {
                          if (!_repetirParcelar) {
                            setState(() => _repetirParcelar = true);
                            _mostrarConfigRepeticao();
                          } else {
                            setState(() => _repetirParcelar = false);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.repeat,
                                        color: corTema.shade600,
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Repetir / Parcelar',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Switch(
                                    value: _repetirParcelar,
                                    onChanged: (v) {
                                      if (v) {
                                        setState(() => _repetirParcelar = true);
                                        _mostrarConfigRepeticao();
                                      } else {
                                        setState(
                                          () => _repetirParcelar = false,
                                        );
                                      }
                                    },
                                    activeColor: corTema.shade600,
                                  ),
                                ],
                              ),
                              if (_repetirParcelar) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: corTema.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        size: 16,
                                        color: corTema.shade600,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '$_quantidadeRepeticoes x ${_tipoRepeticao == 'semanal'
                                            ? 'Semanal'
                                            : _tipoRepeticao == 'quinzenal'
                                            ? 'Quinzenal'
                                            : 'Mensal'}',
                                        style: TextStyle(
                                          color: corTema.shade700,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: _mostrarConfigRepeticao,
                                        child: Icon(
                                          Icons.edit,
                                          size: 16,
                                          color: corTema.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ========== RECEITA DE ORÇAMENTO ==========
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.description,
                              color: Colors.blue.shade600,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Receita de Orçamento',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _orcamentoSelecionado != null
                                        ? 'Orçamento #${_orcamentoSelecionado!.numero.toString().padLeft(4, '0')} - ${_orcamentoSelecionado!.cliente.nome}'
                                        : 'Nenhum orçamento selecionado',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                          _orcamentoSelecionado != null
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                      color:
                                          _orcamentoSelecionado != null
                                              ? Colors.blue.shade700
                                              : Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _selecionarOrcamento,
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.add,
                                  color: Colors.blue.shade700,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ========== CLIENTE ==========
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.person, color: Colors.purple.shade600),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Cliente',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _clienteSelecionado != null
                                        ? _clienteSelecionado!.nome
                                        : 'Nenhum cliente selecionado',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                          _clienteSelecionado != null
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                      color:
                                          _clienteSelecionado != null
                                              ? Colors.purple.shade700
                                              : Colors.grey.shade500,
                                    ),
                                  ),
                                  if (_clienteSelecionado?.celular.isNotEmpty ==
                                      true)
                                    Text(
                                      _clienteSelecionado!.celular,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _mostrarOpcoesCliente,
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.add,
                                  color: Colors.purple.shade700,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ========== COMPROVANTES ==========
                      _buildCardAnexos(),
                      const SizedBox(height: 24),

                      // Título com indicador do tipo
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [corTema.shade600, corTema.shade400],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.trending_up,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dados da Receita',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Entrada de dinheiro',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Descrição
                      TextFormField(
                        controller: _descricaoController,
                        decoration: InputDecoration(
                          labelText: 'Descrição',
                          prefixIcon: const Icon(Icons.description),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: corTema.shade600,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Digite uma descrição';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Valor
                      TextFormField(
                        controller: _valorController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          CurrencyInputFormatterReceita(),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Valor *',
                          prefixIcon: Icon(
                            Icons.attach_money,
                            color: corTema.shade600,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: corTema.shade600,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              _parseMoeda(value) == 0) {
                            return 'Informe um valor válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Categoria
                      DropdownButtonFormField<CategoriaTransacao>(
                        value: _categoriaSelecionada,
                        decoration: InputDecoration(
                          labelText: 'Categoria',
                          prefixIcon: const Icon(Icons.category),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: _getCategorias(),
                        onChanged:
                            (value) =>
                                setState(() => _categoriaSelecionada = value),
                        validator: (value) {
                          if (value == null) return 'Selecione uma categoria';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Data da Transação
                      ListTile(
                        leading: Icon(
                          Icons.calendar_today,
                          color: corTema.shade600,
                        ),
                        title: const Text('Data da Receita'),
                        subtitle: Text(
                          dateFormat.format(_dataTransacao),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        tileColor: Colors.white,
                        onTap: _selecionarDataTransacao,
                      ),
                      const SizedBox(height: 16),

                      // Observações
                      TextFormField(
                        controller: _observacoesController,
                        decoration: InputDecoration(
                          labelText: 'Observações (opcional)',
                          prefixIcon: const Icon(Icons.notes),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),

                      // Botão salvar
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _salvando ? null : _salvar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: corTema.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child:
                              _salvando
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Text(
                                    _transacaoId != null
                                        ? 'Atualizar Receita'
                                        : 'Salvar Receita',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Classe auxiliar para armazenar informações de arquivos anexados
class _ArquivoAnexoReceita {
  final String nome;
  final String url;
  final String tipo;

  _ArquivoAnexoReceita({
    required this.nome,
    required this.url,
    required this.tipo,
  });
}
