import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/agendamento.dart';
import '../../../models/cliente.dart';
import '../../../providers/agendamentos_provider.dart';
import '../../../providers/clients_provider.dart';
import '../../../providers/user_provider.dart';
import '../tabs/clientes_page.dart';
import '../tabs/novo_cliente_page.dart';

class CurrencyInputFormatterDiversos extends TextInputFormatter {
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

/// Arquivo de comprovante anexado
class _ArquivoAnexoDiversos {
  final String nome;
  final String url;
  final String tipo; // 'image' ou 'pdf'

  _ArquivoAnexoDiversos({
    required this.nome,
    required this.url,
    required this.tipo,
  });
}

/// Página para criar agendamento rápido/diversos
/// Estilo igual às outras páginas de agendamento
class AgendamentoDiversosPage extends StatefulWidget {
  final Agendamento? agendamento;
  final DateTime? dataInicial;

  const AgendamentoDiversosPage({
    super.key,
    this.agendamento,
    this.dataInicial,
  });

  @override
  State<AgendamentoDiversosPage> createState() =>
      _AgendamentoDiversosPageState();
}

class _AgendamentoDiversosPageState extends State<AgendamentoDiversosPage> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  final _observacoesController = TextEditingController();

  DateTime? _dataAgendamento;
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFim;
  String _status = 'Confirmado';
  Cliente? _clienteSelecionado;
  bool _salvando = false;

  // Duração em minutos
  int _duracaoMinutos = 30;

  // Tipo de serviço selecionado
  Map<String, dynamic>? _tipoServicoSelecionado;

  // Lista de arquivos/fotos anexados
  final List<_ArquivoAnexoDiversos> _arquivosAnexados = [];
  bool _enviandoArquivo = false;

  // Campos para repetir/parcelar
  bool _repetirParcelar = false;
  int _quantidadeRepeticoes = 2;
  String _tipoRepeticao = 'semanal'; // semanal, quinzenal, mensal

  // Cor tema (roxo para diversos)
  MaterialColor get _corTema => Colors.purple;

  // Lista de serviços rápidos predefinidos
  final List<Map<String, dynamic>> _servicosRapidos = [
    {'nome': 'Corte de Cabelo', 'duracao': 30, 'icone': Icons.content_cut},
    {'nome': 'Manicure', 'duracao': 45, 'icone': Icons.brush},
    {'nome': 'Pedicure', 'duracao': 45, 'icone': Icons.spa},
    {'nome': 'Escova', 'duracao': 40, 'icone': Icons.air},
    {'nome': 'Barba', 'duracao': 20, 'icone': Icons.face},
    {'nome': 'Sobrancelha', 'duracao': 15, 'icone': Icons.visibility},
    {'nome': 'Hidratação', 'duracao': 60, 'icone': Icons.water_drop},
    {'nome': 'Coloração', 'duracao': 90, 'icone': Icons.color_lens},
    {'nome': 'Maquiagem', 'duracao': 60, 'icone': Icons.face_retouching_natural},
    {'nome': 'Depilação', 'duracao': 45, 'icone': Icons.auto_fix_high},
    {'nome': 'Massagem', 'duracao': 60, 'icone': Icons.self_improvement},
    {'nome': 'Limpeza de Pele', 'duracao': 50, 'icone': Icons.clean_hands},
  ];

  // Durações predefinidas
  final List<Map<String, dynamic>> _duracoesPredefinidas = [
    {'label': '15 min', 'minutos': 15},
    {'label': '30 min', 'minutos': 30},
    {'label': '45 min', 'minutos': 45},
    {'label': '1 hora', 'minutos': 60},
    {'label': '1h30', 'minutos': 90},
    {'label': '2 horas', 'minutos': 120},
  ];

  @override
  void initState() {
    super.initState();

    _dataAgendamento = widget.dataInicial ?? DateTime.now();
    _horaInicio = TimeOfDay.now();
    _atualizarHoraFim();

    final ag = widget.agendamento;
    if (ag != null) {
      final dateTime = ag.dataHora.toDate();
      _dataAgendamento = dateTime;
      _horaInicio = TimeOfDay.fromDateTime(dateTime);
      _status = ag.status;
      _parseObservacoesAgendamento(ag.observacoes);

      // Buscar cliente pelo nome
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (ag.clienteNome?.isNotEmpty == true) {
          final uid = context.read<UserProvider>().uid;
          final clientesProv = context.read<ClientsProvider>();
          await clientesProv.carregarTodos(uid);

          if (mounted) {
            final clienteEncontrado = clientesProv.clientes.where(
              (c) => c.nome == ag.clienteNome,
            );
            if (clienteEncontrado.isNotEmpty) {
              setState(() => _clienteSelecionado = clienteEncontrado.first);
            }
          }
        }
      });
    }

    // Carrega clientes
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final uid = context.read<UserProvider>().uid;
      if (context.read<ClientsProvider>().clientes.isEmpty) {
        await context.read<ClientsProvider>().carregarTodos(uid);
      }
    });
  }

  void _parseObservacoesAgendamento(String observacoes) {
    final linhas = observacoes.split('\n');
    for (final linha in linhas) {
      if (linha.startsWith('Título: ')) {
        _descricaoController.text = linha.replaceFirst('Título: ', '');
      } else if (linha.startsWith('Duração: ')) {
        final duracaoStr = linha.replaceFirst('Duração: ', '').replaceAll(' minutos', '');
        _duracaoMinutos = int.tryParse(duracaoStr) ?? 30;
      } else if (linha.startsWith('Valor: ')) {
        _valorController.text = linha.replaceFirst('Valor: ', '');
      } else if (linha.startsWith('Observações: ')) {
        _observacoesController.text = linha.replaceFirst('Observações: ', '');
      }
    }
    _atualizarHoraFim();
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  void _atualizarHoraFim() {
    if (_horaInicio != null) {
      final inicioMinutos = _horaInicio!.hour * 60 + _horaInicio!.minute;
      final fimMinutos = inicioMinutos + _duracaoMinutos;
      _horaFim = TimeOfDay(
        hour: (fimMinutos ~/ 60) % 24,
        minute: fimMinutos % 60,
      );
    }
  }

  // ========== DATA E HORA ==========

  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataAgendamento ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
      setState(() => _dataAgendamento = data);
    }
  }

  Future<void> _selecionarHoraInicio() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: _horaInicio ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              dialBackgroundColor: _corTema.shade50,
              hourMinuteTextColor: _corTema.shade700,
            ),
          ),
          child: child!,
        );
      },
    );
    if (hora != null) {
      setState(() {
        _horaInicio = hora;
        _atualizarHoraFim();
      });
    }
  }

  // ========== SERVIÇO RÁPIDO ==========

  void _mostrarServicosRapidos() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _corTema.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.flash_on,
                        color: _corTema.shade700,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Serviços Rápidos',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: _servicosRapidos.length,
                  itemBuilder: (_, i) {
                    final servico = _servicosRapidos[i];
                    final isSelected = _tipoServicoSelecionado?['nome'] == servico['nome'];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _tipoServicoSelecionado = servico;
                          _descricaoController.text = servico['nome'];
                          _duracaoMinutos = servico['duracao'];
                          _atualizarHoraFim();
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [_corTema.shade400, _corTema.shade600],
                                )
                              : null,
                          color: isSelected ? null : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? _corTema : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              servico['icone'] as IconData,
                              color: isSelected ? Colors.white : _corTema.shade600,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                servico['nome'],
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : Colors.grey.shade800,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${servico['duracao']} min',
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected ? Colors.white70 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ========== DURAÇÃO ==========

  void _mostrarDuracoes() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
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
                'Duração do Serviço',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _duracoesPredefinidas.map((d) {
                  final isSelected = d['minutos'] == _duracaoMinutos;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _duracaoMinutos = d['minutos'];
                        _atualizarHoraFim();
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [_corTema.shade400, _corTema.shade600],
                              )
                            : null,
                        color: isSelected ? null : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? _corTema : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        d['label'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.grey.shade800,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // ========== CLIENTE ==========

  Future<void> _mostrarOpcoesCliente() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
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
                  label: 'Novo',
                  cor: Colors.orange,
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
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cor.shade400, cor.shade600],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navegarParaClientes() async {
    final cliente = await Navigator.push<Cliente>(
      context,
      MaterialPageRoute(builder: (_) => const ClientesPage(isPickerMode: true)),
    );
    if (cliente != null && mounted) {
      setState(() => _clienteSelecionado = cliente);
    }
  }

  Future<void> _importarDaAgenda() async {
    try {
      if (await FlutterContacts.requestPermission()) {
        final contacts = await FlutterContacts.getContacts(withProperties: true);
        if (!mounted) return;

        final contatoSelecionado = await showModalBottomSheet<Contact>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Selecionar da Agenda',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: contacts.length,
                    itemBuilder: (_, i) {
                      final c = contacts[i];
                      final telefone = c.phones.isNotEmpty ? c.phones.first.number : '';
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _corTema.shade100,
                          child: Text(
                            c.displayName.isNotEmpty ? c.displayName[0].toUpperCase() : '?',
                            style: TextStyle(color: _corTema.shade700),
                          ),
                        ),
                        title: Text(c.displayName),
                        subtitle: telefone.isNotEmpty ? Text(telefone) : null,
                        onTap: () => Navigator.pop(context, c),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );

        if (contatoSelecionado != null && mounted) {
          setState(() {
            _clienteSelecionado = Cliente(
              nome: contatoSelecionado.displayName,
              celular: contatoSelecionado.phones.isNotEmpty
                  ? contatoSelecionado.phones.first.number
                  : '',
            );
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao acessar agenda: $e')),
        );
      }
    }
  }

  Future<void> _criarNovoCliente() async {
    final novoCliente = await Navigator.push<Cliente>(
      context,
      MaterialPageRoute(builder: (_) => const NovoClientePage()),
    );
    if (novoCliente != null && mounted) {
      setState(() => _clienteSelecionado = novoCliente);
    }
  }

  // ========== COMPROVANTES ==========

  Future<void> _mostrarOpcoesAnexo() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
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
              'Adicionar Comprovante',
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
                _buildOpcaoAnexo(
                  icon: Icons.camera_alt,
                  label: 'Câmera',
                  cor: Colors.blue,
                  onTap: () {
                    Navigator.pop(ctx);
                    _capturarFoto();
                  },
                ),
                _buildOpcaoAnexo(
                  icon: Icons.photo_library,
                  label: 'Galeria',
                  cor: Colors.green,
                  onTap: () {
                    Navigator.pop(ctx);
                    _selecionarDaGaleria();
                  },
                ),
                _buildOpcaoAnexo(
                  icon: Icons.picture_as_pdf,
                  label: 'PDF',
                  cor: Colors.red,
                  onTap: () {
                    Navigator.pop(ctx);
                    _selecionarPDF();
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

  Widget _buildOpcaoAnexo({
    required IconData icon,
    required String label,
    required MaterialColor cor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cor.shade400, cor.shade600],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _capturarFoto() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Câmera não disponível na web')),
      );
      return;
    }

    final picker = ImagePicker();
    final foto = await picker.pickImage(source: ImageSource.camera);
    if (foto != null) {
      await _uploadArquivo(File(foto.path), 'image');
    }
  }

  Future<void> _selecionarDaGaleria() async {
    final picker = ImagePicker();
    final foto = await picker.pickImage(source: ImageSource.gallery);
    if (foto != null) {
      if (kIsWeb) {
        final bytes = await foto.readAsBytes();
        await _uploadArquivoWeb(bytes, foto.name, 'image');
      } else {
        await _uploadArquivo(File(foto.path), 'image');
      }
    }
  }

  Future<void> _selecionarPDF() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (kIsWeb) {
        if (file.bytes != null) {
          await _uploadArquivoWeb(file.bytes!, file.name, 'pdf');
        }
      } else if (file.path != null) {
        await _uploadArquivo(File(file.path!), 'pdf');
      }
    }
  }

  Future<void> _uploadArquivo(File arquivo, String tipo) async {
    setState(() => _enviandoArquivo = true);
    try {
      final uid = context.read<UserProvider>().uid;
      final nome = '${DateTime.now().millisecondsSinceEpoch}_${arquivo.path.split('/').last}';
      final ref = FirebaseStorage.instance.ref().child('comprovantes/$uid/$nome');
      await ref.putFile(arquivo);
      final url = await ref.getDownloadURL();

      setState(() {
        _arquivosAnexados.add(_ArquivoAnexoDiversos(nome: nome, url: url, tipo: tipo));
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar arquivo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _enviandoArquivo = false);
    }
  }

  Future<void> _uploadArquivoWeb(Uint8List bytes, String nomeOriginal, String tipo) async {
    setState(() => _enviandoArquivo = true);
    try {
      final uid = context.read<UserProvider>().uid;
      final nome = '${DateTime.now().millisecondsSinceEpoch}_$nomeOriginal';
      final ref = FirebaseStorage.instance.ref().child('comprovantes/$uid/$nome');
      await ref.putData(bytes);
      final url = await ref.getDownloadURL();

      setState(() {
        _arquivosAnexados.add(_ArquivoAnexoDiversos(nome: nome, url: url, tipo: tipo));
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar arquivo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _enviandoArquivo = false);
    }
  }

  // ========== SALVAR ==========

  Future<void> _salvar() async {
    if (_descricaoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Selecione um serviço ou digite a descrição'),
          backgroundColor: _corTema.shade600,
        ),
      );
      return;
    }
    if (_dataAgendamento == null || _horaInicio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Selecione data e hora'),
          backgroundColor: _corTema.shade600,
        ),
      );
      return;
    }

    setState(() => _salvando = true);

    try {
      final agProv = context.read<AgendamentosProvider>();
      final dataHora = DateTime(
        _dataAgendamento!.year,
        _dataAgendamento!.month,
        _dataAgendamento!.day,
        _horaInicio!.hour,
        _horaInicio!.minute,
      );

      // Monta observações
      final observacoesCompletas = StringBuffer();
      observacoesCompletas.writeln('Título: ${_descricaoController.text}');
      observacoesCompletas.writeln('Duração: $_duracaoMinutos minutos');
      if (_valorController.text.isNotEmpty) {
        observacoesCompletas.writeln('Valor: ${_valorController.text}');
      }
      if (_observacoesController.text.isNotEmpty) {
        observacoesCompletas.writeln('Observações: ${_observacoesController.text}');
      }

      // Adiciona comprovantes
      if (_arquivosAnexados.isNotEmpty) {
        observacoesCompletas.writeln('[COMPROVANTES]');
        for (final arq in _arquivosAnexados) {
          observacoesCompletas.writeln('${arq.tipo}:${arq.url}');
        }
        observacoesCompletas.writeln('[/COMPROVANTES]');
      }

      // Calcula quantas vezes salvar
      final quantidadeTotal = _repetirParcelar ? _quantidadeRepeticoes : 1;

      for (int i = 0; i < quantidadeTotal; i++) {
        DateTime dataItem = dataHora;

        if (i > 0) {
          switch (_tipoRepeticao) {
            case 'semanal':
              dataItem = dataHora.add(Duration(days: 7 * i));
              break;
            case 'quinzenal':
              dataItem = dataHora.add(Duration(days: 14 * i));
              break;
            case 'mensal':
              dataItem = DateTime(
                dataHora.year,
                dataHora.month + i,
                dataHora.day,
                dataHora.hour,
                dataHora.minute,
              );
              break;
          }
        }

        // Usa o método do provider com parâmetros nomeados
        // A notificação já é agendada automaticamente pelo provider
        await agProv.adicionarAgendamento(
          orcamentoId: 'agendamento_diversos',
          orcamentoNumero: null,
          clienteNome: _clienteSelecionado?.nome ?? _descricaoController.text,
          dataHora: Timestamp.fromDate(dataItem),
          status: _status,
          observacoes: observacoesCompletas.toString(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              quantidadeTotal > 1
                  ? '$quantidadeTotal agendamentos criados!'
                  : 'Agendamento salvo!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  // ========== BUILD ==========

  @override
  Widget build(BuildContext context) {
    final corTema = _corTema;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: corTema.shade600,
        foregroundColor: Colors.white,
        title: Text(
          widget.agendamento != null ? 'Editar Agendamento' : 'Agendamento Rápido',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_salvando)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _salvar,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ========== SERVIÇO RÁPIDO ==========
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.flash_on, color: corTema.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tipo de Serviço',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _tipoServicoSelecionado != null
                                ? '${_tipoServicoSelecionado!['nome']} (${_tipoServicoSelecionado!['duracao']} min)'
                                : 'Selecionar serviço rápido',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: _tipoServicoSelecionado != null
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: _tipoServicoSelecionado != null
                                  ? corTema.shade700
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _mostrarServicosRapidos,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: corTema.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.add, color: corTema.shade700, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ========== DESCRIÇÃO ==========
              TextFormField(
                controller: _descricaoController,
                decoration: InputDecoration(
                  labelText: 'Descrição do Serviço',
                  hintText: 'Ex: Corte de cabelo masculino',
                  prefixIcon: Icon(Icons.description, color: corTema.shade600),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: corTema, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ========== DATA E HORA ==========
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _selecionarData,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: corTema.shade600),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Data',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                Text(
                                  _dataAgendamento != null
                                      ? DateFormat('dd/MM/yyyy').format(_dataAgendamento!)
                                      : 'Selecionar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: corTema.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _selecionarHoraInicio,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.access_time, color: corTema.shade600),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Início',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                Text(
                                  _horaInicio != null
                                      ? _horaInicio!.format(context)
                                      : 'Selecionar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: corTema.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ========== DURAÇÃO E HORA FIM ==========
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _mostrarDuracoes,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.timer, color: corTema.shade600),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Duração',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                Text(
                                  _duracaoMinutos >= 60
                                      ? '${_duracaoMinutos ~/ 60}h${_duracaoMinutos % 60 > 0 ? '${_duracaoMinutos % 60}min' : ''}'
                                      : '$_duracaoMinutos min',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: corTema.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: corTema.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: corTema.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time_filled, color: corTema.shade600),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Término',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              Text(
                                _horaFim != null ? _horaFim!.format(context) : '--:--',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: corTema.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ========== CLIENTE ==========
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.teal.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cliente',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _clienteSelecionado?.nome ?? 'Nenhum cliente selecionado',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: _clienteSelecionado != null
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: _clienteSelecionado != null
                                  ? Colors.teal.shade700
                                  : Colors.grey.shade500,
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
                          color: Colors.teal.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.add, color: Colors.teal.shade700, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ========== VALOR (OPCIONAL) ==========
              TextFormField(
                controller: _valorController,
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatterDiversos()],
                decoration: InputDecoration(
                  labelText: 'Valor (opcional)',
                  hintText: 'R\$ 0,00',
                  prefixIcon: Icon(Icons.attach_money, color: Colors.green.shade600),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.green, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ========== REPETIR/PARCELAR ==========
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.repeat, color: corTema.shade600),
                        const SizedBox(width: 12),
                        const Text(
                          'Repetir Agendamento',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        Switch(
                          value: _repetirParcelar,
                          onChanged: (v) => setState(() => _repetirParcelar = v),
                          activeColor: corTema,
                        ),
                      ],
                    ),
                    if (_repetirParcelar) ...[
                      const Divider(),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Quantidade',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: _quantidadeRepeticoes > 2
                                          ? () => setState(() => _quantidadeRepeticoes--)
                                          : null,
                                      icon: Icon(
                                        Icons.remove_circle,
                                        color: _quantidadeRepeticoes > 2
                                            ? corTema
                                            : Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      '$_quantidadeRepeticoes',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: corTema.shade700,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: _quantidadeRepeticoes < 52
                                          ? () => setState(() => _quantidadeRepeticoes++)
                                          : null,
                                      icon: Icon(
                                        Icons.add_circle,
                                        color: _quantidadeRepeticoes < 52
                                            ? corTema
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Frequência',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                DropdownButton<String>(
                                  value: _tipoRepeticao,
                                  isExpanded: true,
                                  items: const [
                                    DropdownMenuItem(value: 'semanal', child: Text('Semanal')),
                                    DropdownMenuItem(value: 'quinzenal', child: Text('Quinzenal')),
                                    DropdownMenuItem(value: 'mensal', child: Text('Mensal')),
                                  ],
                                  onChanged: (v) {
                                    if (v != null) setState(() => _tipoRepeticao = v);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ========== COMPROVANTES ==========
              Container(
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
                        Icon(Icons.attach_file, color: corTema.shade600),
                        const SizedBox(width: 8),
                        const Text(
                          'Comprovantes',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        if (_enviandoArquivo)
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: corTema,
                            ),
                          ),
                      ],
                    ),
                    if (_arquivosAnexados.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _arquivosAnexados.map((arq) {
                          return Chip(
                            avatar: Icon(
                              arq.tipo == 'image' ? Icons.image : Icons.picture_as_pdf,
                              size: 18,
                              color: corTema,
                            ),
                            label: Text(
                              arq.nome.length > 15
                                  ? '${arq.nome.substring(0, 12)}...'
                                  : arq.nome,
                              style: const TextStyle(fontSize: 12),
                            ),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () {
                              setState(() => _arquivosAnexados.remove(arq));
                            },
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _mostrarOpcoesAnexo,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: corTema.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: corTema.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, color: corTema.shade600, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Adicionar foto ou arquivo',
                              style: TextStyle(
                                color: corTema.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ========== OBSERVAÇÕES ==========
              TextFormField(
                controller: _observacoesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Observações (opcional)',
                  hintText: 'Anotações adicionais...',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(bottom: 50),
                    child: Icon(Icons.notes, color: corTema.shade600),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: corTema, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ========== BOTÃO SALVAR ==========
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _salvando ? null : _salvar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: corTema.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: _salvando
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              _repetirParcelar
                                  ? 'Salvar $_quantidadeRepeticoes Agendamentos'
                                  : 'Salvar Agendamento',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
