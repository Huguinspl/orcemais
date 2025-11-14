import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/business_provider.dart';

class PersonalizarPdfPage extends StatefulWidget {
  const PersonalizarPdfPage({super.key});

  @override
  State<PersonalizarPdfPage> createState() => _PersonalizarPdfPageState();
}

class _PersonalizarPdfPageState extends State<PersonalizarPdfPage>
    with SingleTickerProviderStateMixin {
  late Map<String, dynamic> _theme;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final existing = context.read<BusinessProvider>().pdfTheme;
    _theme = Map<String, dynamic>.from(existing ?? {});

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Personalizar PDF',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(Icons.palette, size: 80, color: Colors.white24),
        ),
      ),
      actions: [
        if (_theme.isNotEmpty)
          TextButton.icon(
            onPressed: () async {
              setState(() => _theme.clear());
              await context.read<BusinessProvider>().limparPdfTheme();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.refresh, color: Colors.white),
                        SizedBox(width: 12),
                        Text('Tema restaurado para padrão!'),
                      ],
                    ),
                    backgroundColor: Colors.green.shade700,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text(
              'Restaurar',
              style: TextStyle(color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF6A1B9A).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6A1B9A).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: const Color(0xFF6A1B9A), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Personalize as cores do PDF de orçamento. Toque em cada item para escolher uma cor.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _salvando ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.grey.shade400),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6A1B9A).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _salvando ? null : _salvarTema,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : const Text(
                            'Salvar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _salvarTema() async {
    if (_salvando) return;

    setState(() => _salvando = true);

    try {
      await context.read<BusinessProvider>().salvarPdfTheme(_theme);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Tema do PDF salvo com sucesso!'),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Erro ao salvar: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildInfoCard(),
                      _buildSectionHeader('Cabeçalho', Icons.view_headline),
                      _ColorTile(
                        label: 'Faixa do cabeçalho',
                        keyName: 'primary',
                        color: _getColor('primary') ?? cs.primary,
                        onChanged: (c) => _setColor('primary', c),
                      ),
                      _ColorTile(
                        label: 'Texto no cabeçalho',
                        keyName: 'onPrimary',
                        color: _getColor('onPrimary') ?? cs.onPrimary,
                        onChanged: (c) => _setColor('onPrimary', c),
                      ),
                      _buildSectionHeader(
                        'Dados do Cliente',
                        Icons.person_outline,
                      ),
                      _ColorTile(
                        label: 'Fundo da seção',
                        keyName: 'secondaryContainer',
                        color:
                            _getColor('secondaryContainer') ??
                            cs.secondaryContainer,
                        onChanged: (c) => _setColor('secondaryContainer', c),
                      ),
                      _ColorTile(
                        label: 'Texto da seção',
                        keyName: 'onSecondaryContainer',
                        color:
                            _getColor('onSecondaryContainer') ??
                            cs.onSecondaryContainer,
                        onChanged: (c) => _setColor('onSecondaryContainer', c),
                      ),
                      _buildSectionHeader('Itens', Icons.list_alt),
                      _ColorTile(
                        label: 'Fundo da seção',
                        keyName: 'tertiaryContainer',
                        color:
                            _getColor('tertiaryContainer') ??
                            cs.tertiaryContainer,
                        onChanged: (c) => _setColor('tertiaryContainer', c),
                      ),
                      _ColorTile(
                        label: 'Texto da seção',
                        keyName: 'onTertiaryContainer',
                        color:
                            _getColor('onTertiaryContainer') ??
                            cs.onTertiaryContainer,
                        onChanged: (c) => _setColor('onTertiaryContainer', c),
                      ),
                      _buildSectionHeader(
                        'Bordas e Divisores',
                        Icons.border_all,
                      ),
                      _ColorTile(
                        label: 'Cor das bordas',
                        keyName: 'outlineVariant',
                        color: _getColor('outlineVariant') ?? cs.outlineVariant,
                        onChanged: (c) => _setColor('outlineVariant', c),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildActionButtons(),
    );
  }

  Color? _getColor(String key) {
    final v = _theme[key];
    if (v is int) return Color(v);
    return null;
  }

  void _setColor(String key, Color color) {
    setState(() {
      _theme[key] = color.value; // ARGB int
    });
  }
}

class _ColorTile extends StatelessWidget {
  final String label;
  final String keyName;
  final Color color;
  final ValueChanged<Color> onChanged;
  const _ColorTile({
    required this.label,
    required this.keyName,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6A1B9A).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final picked = await showDialog<Color>(
              context: context,
              builder: (ctx) => _SimpleColorPickerDialog(initial: color),
            );
            if (picked != null) onChanged(picked);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6A1B9A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        keyName,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.edit, color: const Color(0xFF6A1B9A), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SimpleColorPickerDialog extends StatefulWidget {
  final Color initial;
  const _SimpleColorPickerDialog({required this.initial});

  @override
  State<_SimpleColorPickerDialog> createState() =>
      _SimpleColorPickerDialogState();
}

class _SimpleColorPickerDialogState extends State<_SimpleColorPickerDialog>
    with SingleTickerProviderStateMixin {
  late double _hue;
  late double _saturation;
  late double _lightness;
  late TabController _tabController;
  final TextEditingController _hexController = TextEditingController();

  // Paleta de cores populares para negócios
  final List<Color> _presetColors = [
    // Azuis
    const Color(0xFF2196F3), // Blue
    const Color(0xFF1976D2), // Blue Dark
    const Color(0xFF0D47A1), // Blue Darker
    const Color(0xFF03A9F4), // Light Blue
    const Color(0xFF00BCD4), // Cyan
    // Verdes
    const Color(0xFF4CAF50), // Green
    const Color(0xFF388E3C), // Green Dark
    const Color(0xFF1B5E20), // Green Darker
    const Color(0xFF8BC34A), // Light Green
    const Color(0xFF009688), // Teal
    // Laranjas e Amarelos
    const Color(0xFFFF9800), // Orange
    const Color(0xFFF57C00), // Orange Dark
    const Color(0xFFFF5722), // Deep Orange
    const Color(0xFFFFEB3B), // Yellow
    const Color(0xFFFFC107), // Amber
    // Roxos e Rosas
    const Color(0xFF9C27B0), // Purple
    const Color(0xFF6A1B9A), // Purple Dark
    const Color(0xFF4A148C), // Purple Darker
    const Color(0xFFE91E63), // Pink
    const Color(0xFFC2185B), // Pink Dark
    // Vermelhos
    const Color(0xFFF44336), // Red
    const Color(0xFFD32F2F), // Red Dark
    const Color(0xFFB71C1C), // Red Darker
    // Neutros
    const Color(0xFF607D8B), // Blue Grey
    const Color(0xFF455A64), // Blue Grey Dark
    const Color(0xFF263238), // Blue Grey Darker
    const Color(0xFF9E9E9E), // Grey
    const Color(0xFF212121), // Almost Black
  ];

  @override
  void initState() {
    super.initState();
    final hsl = HSLColor.fromColor(widget.initial);
    _hue = hsl.hue;
    _saturation = hsl.saturation;
    _lightness = hsl.lightness;
    _tabController = TabController(length: 3, vsync: this);
    _updateHexFromColor(widget.initial);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _hexController.dispose();
    super.dispose();
  }

  Color get _currentColor =>
      HSLColor.fromAHSL(1, _hue, _saturation, _lightness).toColor();

  void _updateHexFromColor(Color color) {
    _hexController.text =
        '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  void _setColorFromHex(String hex) {
    try {
      String cleanHex = hex.replaceAll('#', '');
      if (cleanHex.length == 6) {
        final color = Color(int.parse('FF$cleanHex', radix: 16));
        final hsl = HSLColor.fromColor(color);
        setState(() {
          _hue = hsl.hue;
          _saturation = hsl.saturation;
          _lightness = hsl.lightness;
        });
      }
    } catch (e) {
      // Ignora entrada inválida
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _currentColor;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: EdgeInsets.zero,
      title: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.palette, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text('Escolher cor'),
            ],
          ),
          const SizedBox(height: 16),
          // Preview da cor selecionada
          Container(
            width: double.infinity,
            height: 80,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: Colors.grey.shade300, width: 2),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#${color.value.toRadixString(16).substring(2).toUpperCase()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Abas de seleção
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey.shade700,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(icon: Icon(Icons.palette, size: 20), text: 'Paleta'),
                  Tab(icon: Icon(Icons.tune, size: 20), text: 'Ajustar'),
                  Tab(icon: Icon(Icons.tag, size: 20), text: 'Hex'),
                ],
              ),
            ),
            // Conteúdo das abas
            SizedBox(
              height: 280,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPaletaTab(),
                  _buildAjustarTab(),
                  _buildHexTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text('Cancelar', style: TextStyle(fontSize: 15)),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context, color),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Selecionar',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Aba com paleta de cores pré-definidas
  Widget _buildPaletaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children:
            _presetColors.map((presetColor) {
              final isSelected = presetColor.value == _currentColor.value;
              return GestureDetector(
                onTap: () {
                  final hsl = HSLColor.fromColor(presetColor);
                  setState(() {
                    _hue = hsl.hue;
                    _saturation = hsl.saturation;
                    _lightness = hsl.lightness;
                    _updateHexFromColor(presetColor);
                  });
                },
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: presetColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.grey.shade300,
                      width: isSelected ? 3 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: presetColor.withOpacity(0.4),
                        blurRadius: isSelected ? 12 : 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child:
                      isSelected
                          ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 28,
                          )
                          : null,
                ),
              );
            }).toList(),
      ),
    );
  }

  // Aba de ajuste fino (sliders HSL)
  Widget _buildAjustarTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _slider('Matiz', _hue, 0, 360, (v) {
            setState(() {
              _hue = v;
              _updateHexFromColor(_currentColor);
            });
          }, Icons.color_lens),
          const SizedBox(height: 12),
          _slider('Saturação', _saturation, 0, 1, (v) {
            setState(() {
              _saturation = v;
              _updateHexFromColor(_currentColor);
            });
          }, Icons.opacity),
          const SizedBox(height: 12),
          _slider('Luminosidade', _lightness, 0, 1, (v) {
            setState(() {
              _lightness = v;
              _updateHexFromColor(_currentColor);
            });
          }, Icons.brightness_6),
        ],
      ),
    );
  }

  // Aba de entrada manual de código hex
  Widget _buildHexTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.tag, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Digite o código da cor',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _hexController,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
            decoration: InputDecoration(
              hintText: '#FF9800',
              prefixIcon: const Icon(Icons.tag),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF6A1B9A),
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            onChanged: _setColorFromHex,
            maxLength: 7,
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 16),
          Text(
            'Ex: #2196F3, #FF5722, #4CAF50',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _slider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF6A1B9A)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6A1B9A),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF6A1B9A),
            inactiveTrackColor: const Color(0xFF6A1B9A).withOpacity(0.2),
            thumbColor: const Color(0xFF6A1B9A),
            overlayColor: const Color(0xFF6A1B9A).withOpacity(0.2),
            trackHeight: 4,
          ),
          child: Slider(value: value, onChanged: onChanged, min: min, max: max),
        ),
      ],
    );
  }
}
