import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/business_provider.dart';

class PersonalizarPdfPage extends StatefulWidget {
  const PersonalizarPdfPage({super.key});

  @override
  State<PersonalizarPdfPage> createState() => _PersonalizarPdfPageState();
}

class _PersonalizarPdfPageState extends State<PersonalizarPdfPage> {
  late Map<String, dynamic> _theme;

  @override
  void initState() {
    super.initState();
    final existing = context.read<BusinessProvider>().pdfTheme;
    _theme = Map<String, dynamic>.from(existing ?? {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personalizar PDF'),
        actions: [
          if (_theme.isNotEmpty)
            TextButton(
              onPressed: () async {
                setState(() => _theme.clear());
                await context.read<BusinessProvider>().limparPdfTheme();
              },
              child: const Text(
                'Restaurar',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
          const Divider(),
          _ColorTile(
            label: 'Seção: Dados do Cliente (fundo)',
            keyName: 'secondaryContainer',
            color: _getColor('secondaryContainer') ?? cs.secondaryContainer,
            onChanged: (c) => _setColor('secondaryContainer', c),
          ),
          _ColorTile(
            label: 'Seção: Dados do Cliente (texto)',
            keyName: 'onSecondaryContainer',
            color: _getColor('onSecondaryContainer') ?? cs.onSecondaryContainer,
            onChanged: (c) => _setColor('onSecondaryContainer', c),
          ),
          const Divider(),
          _ColorTile(
            label: 'Seção: Itens (fundo)',
            keyName: 'tertiaryContainer',
            color: _getColor('tertiaryContainer') ?? cs.tertiaryContainer,
            onChanged: (c) => _setColor('tertiaryContainer', c),
          ),
          _ColorTile(
            label: 'Seção: Itens (texto)',
            keyName: 'onTertiaryContainer',
            color: _getColor('onTertiaryContainer') ?? cs.onTertiaryContainer,
            onChanged: (c) => _setColor('onTertiaryContainer', c),
          ),
          const Divider(),
          _ColorTile(
            label: 'Bordas/Divisores',
            keyName: 'outlineVariant',
            color: _getColor('outlineVariant') ?? cs.outlineVariant,
            onChanged: (c) => _setColor('outlineVariant', c),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  await context.read<BusinessProvider>().salvarPdfTheme(_theme);
                  if (mounted) Navigator.pop(context);
                },
                child: const Text('Salvar'),
              ),
            ),
          ],
        ),
      ),
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(keyName),
      trailing: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade400),
        ),
      ),
      onTap: () async {
        final picked = await showDialog<Color>(
          context: context,
          builder: (ctx) => _SimpleColorPickerDialog(initial: color),
        );
        if (picked != null) onChanged(picked);
      },
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

class _SimpleColorPickerDialogState extends State<_SimpleColorPickerDialog> {
  late double _hue;
  late double _saturation;
  late double _lightness;

  @override
  void initState() {
    super.initState();
    final hsl = HSLColor.fromColor(widget.initial);
    _hue = hsl.hue;
    _saturation = hsl.saturation;
    _lightness = hsl.lightness;
  }

  @override
  Widget build(BuildContext context) {
    final color = HSLColor.fromAHSL(1, _hue, _saturation, _lightness).toColor();
    return AlertDialog(
      title: const Text('Escolher cor'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 12),
          _slider('Matiz', _hue, 0, 360, (v) => setState(() => _hue = v)),
          _slider(
            'Saturação',
            _saturation,
            0,
            1,
            (v) => setState(() => _saturation = v),
          ),
          _slider(
            'Luminosidade',
            _lightness,
            0,
            1,
            (v) => setState(() => _lightness = v),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, color),
          child: const Text('Selecionar'),
        ),
      ],
    );
  }

  Widget _slider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(width: 100, child: Text(label)),
        Expanded(
          child: Slider(value: value, onChanged: onChanged, min: min, max: max),
        ),
      ],
    );
  }
}
