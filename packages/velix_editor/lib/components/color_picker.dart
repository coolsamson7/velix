import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ColorInputField extends StatelessWidget {
  final Color? value;
  final ValueChanged<Color> onChanged;
  final String? label;
  final String? hint;
  final bool showAlpha;

  const ColorInputField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.hint,
    this.showAlpha = true,
  });

  @override
  Widget build(BuildContext context) {
    final hexValue = value != null ? _colorToHex(value!) : '';

    return InkWell(
      onTap: () => _showColorPicker(context),
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          hintText: hint ?? '#000000',
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          suffixIcon: Container(
            margin: const EdgeInsets.all(8),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: value ?? Colors.transparent,
              border: Border.all(color: Colors.grey.shade400, width: 1),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
        child: Text(
          hexValue.isEmpty ? (hint ?? '#000000') : hexValue,
          style: TextStyle(
            color: hexValue.isEmpty ? Colors.grey.shade600 : Colors.black87,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  String _colorToHex(Color color) {
    if (showAlpha) {
      return '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
    } else {
      return '#${color.value.toRadixString(16).substring(2).padLeft(6, '0').toUpperCase()}';
    }
  }

  Future<void> _showColorPicker(BuildContext context) async {
    final result = await showDialog<Color>(
      context: context,
      builder: (context) => ColorPickerDialog(
        initialColor: value ?? Colors.blue,
        showAlpha: showAlpha,
      ),
    );

    if (result != null) {
      onChanged(result);
    }
  }
}

class ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final bool showAlpha;

  const ColorPickerDialog({
    super.key,
    required this.initialColor,
    this.showAlpha = true,
  });

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late Color _currentColor;
  late HSVColor _hsvColor;
  late TextEditingController _hexController;

  @override
  void initState() {
    super.initState();
    _currentColor = widget.initialColor;
    _hsvColor = HSVColor.fromColor(_currentColor);
    _hexController = TextEditingController(
      text: _colorToHex(_currentColor),
    );
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  String _colorToHex(Color color) {
    if (widget.showAlpha) {
      return color.value.toRadixString(16).padLeft(8, '0').toUpperCase();
    } else {
      return color.value.toRadixString(16).substring(2).padLeft(6, '0').toUpperCase();
    }
  }

  void _updateColor(Color color) {
    setState(() {
      _currentColor = color;
      _hsvColor = HSVColor.fromColor(color);
      _hexController.text = _colorToHex(color);
    });
  }

  void _updateFromHex(String hex) {
    try {
      hex = hex.replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      if (hex.length == 8) {
        final color = Color(int.parse(hex, radix: 16));
        _updateColor(color);
      }
    } catch (e) {
      // Invalid hex, ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 350,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pick a Color',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Color preview
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: _currentColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Hue slider
            _buildSlider(
              label: 'Hue',
              value: _hsvColor.hue,
              max: 360,
              gradient: LinearGradient(
                colors: [
                  for (var i = 0; i <= 360; i += 30)
                    HSVColor.fromAHSV(1, i.toDouble(), 1, 1).toColor(),
                ],
              ),
              onChanged: (value) {
                _updateColor(_hsvColor.withHue(value).toColor());
              },
            ),
            const SizedBox(height: 12),

            // Saturation slider
            _buildSlider(
              label: 'Saturation',
              value: _hsvColor.saturation,
              max: 1,
              gradient: LinearGradient(
                colors: [
                  _hsvColor.withSaturation(0).toColor(),
                  _hsvColor.withSaturation(1).toColor(),
                ],
              ),
              onChanged: (value) {
                _updateColor(_hsvColor.withSaturation(value).toColor());
              },
            ),
            const SizedBox(height: 12),

            // Value slider
            _buildSlider(
              label: 'Brightness',
              value: _hsvColor.value,
              max: 1,
              gradient: LinearGradient(
                colors: [
                  _hsvColor.withValue(0).toColor(),
                  _hsvColor.withValue(1).toColor(),
                ],
              ),
              onChanged: (value) {
                _updateColor(_hsvColor.withValue(value).toColor());
              },
            ),

            // Alpha slider
            if (widget.showAlpha) ...[
              const SizedBox(height: 12),
              _buildSlider(
                label: 'Opacity',
                value: _hsvColor.alpha,
                max: 1,
                gradient: LinearGradient(
                  colors: [
                    _currentColor.withOpacity(0),
                    _currentColor.withOpacity(1),
                  ],
                ),
                onChanged: (value) {
                  _updateColor(_hsvColor.withAlpha(value).toColor());
                },
              ),
            ],

            const SizedBox(height: 20),

            // Hex input
            TextField(
              controller: _hexController,
              decoration: InputDecoration(
                labelText: 'Hex Color',
                border: const OutlineInputBorder(),
                prefixText: '#',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Fa-f]')),
                LengthLimitingTextInputFormatter(widget.showAlpha ? 8 : 6),
              ],
              onChanged: _updateFromHex,
            ),
            const SizedBox(height: 20),

            // Common colors
            const Text(
              'Common Colors',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Colors.red,
                Colors.pink,
                Colors.purple,
                Colors.deepPurple,
                Colors.indigo,
                Colors.blue,
                Colors.lightBlue,
                Colors.cyan,
                Colors.teal,
                Colors.green,
                Colors.lightGreen,
                Colors.lime,
                Colors.yellow,
                Colors.amber,
                Colors.orange,
                Colors.deepOrange,
                Colors.brown,
                Colors.grey,
                Colors.blueGrey,
                Colors.black,
                Colors.white,
              ].map((color) {
                return InkWell(
                  onTap: () => _updateColor(color),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _currentColor == color
                            ? Colors.blue.shade700
                            : Colors.grey.shade300,
                        width: _currentColor == color ? 2 : 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, _currentColor),
                  child: const Text('Select'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double max,
    required Gradient gradient,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ${(value / max * 100).toStringAsFixed(0)}%',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Container(
          height: 24,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: SliderTheme(
            data: SliderThemeData(
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              trackHeight: 24,
              trackShape: const RoundedRectSliderTrackShape(),
              activeTrackColor: Colors.transparent,
              inactiveTrackColor: Colors.transparent,
            ),
            child: Slider(
              value: value,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

// Example usage
class ColorPickerExample extends StatefulWidget {
  const ColorPickerExample({super.key});

  @override
  State<ColorPickerExample> createState() => _ColorPickerExampleState();
}

class _ColorPickerExampleState extends State<ColorPickerExample> {
  Color selectedColor = Colors.blue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Color Picker Example')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColorInputField(
              label: 'Background Color',
              value: selectedColor,
              onChanged: (color) {
                setState(() => selectedColor = color);
              },
            ),
            const SizedBox(height: 20),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: selectedColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Center(
                child: Text(
                  'Preview',
                  style: TextStyle(
                    color: selectedColor.computeLuminance() > 0.5
                        ? Colors.black
                        : Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}