import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kloudshop/theme/app_theme.dart';

class CustomColorPicker extends StatefulWidget {
  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;

  const CustomColorPicker({
    super.key,
    required this.pickerColor,
    required this.onColorChanged,
  });

  @override
  State<CustomColorPicker> createState() => _CustomColorPickerState();
}

class _CustomColorPickerState extends State<CustomColorPicker> {
  late HSVColor _hsvColor;
  String _activeMode = 'hex'; // 'rgb', 'hsv', 'hsl', 'hex'

  // Text inputs
  final _input1Controller = TextEditingController();
  final _input2Controller = TextEditingController();
  final _input3Controller = TextEditingController();
  final _input4Controller = TextEditingController();

  final _focus1 = FocusNode();
  final _focus2 = FocusNode();
  final _focus3 = FocusNode();
  final _focus4 = FocusNode();

  bool _isUpdatingFromText = false;

  @override
  void initState() {
    super.initState();
    _hsvColor = HSVColor.fromColor(widget.pickerColor);
    _updateTextFromColor();
  }

  @override
  void dispose() {
    _input1Controller.dispose();
    _input2Controller.dispose();
    _input3Controller.dispose();
    _input4Controller.dispose();
    _focus1.dispose();
    _focus2.dispose();
    _focus3.dispose();
    _focus4.dispose();
    super.dispose();
  }

  void _onColorUpdated() {
    if (!_isUpdatingFromText) {
      _updateTextFromColor();
    }
    widget.onColorChanged(_hsvColor.toColor());
  }

  void _updateTextFromColor() {
    final color = _hsvColor.toColor();
    if (_activeMode == 'hex') {
      final r = color.red.toRadixString(16).padLeft(2, '0');
      final g = color.green.toRadixString(16).padLeft(2, '0');
      final b = color.blue.toRadixString(16).padLeft(2, '0');
      final a = color.alpha.toRadixString(16).padLeft(2, '0');
      final hexVal = '#$a$r$g$b'.toUpperCase();
      if (_input1Controller.text != hexVal) {
        _input1Controller.text = hexVal;
      }
    } else if (_activeMode == 'rgb') {
      _setTextIfChanged(_input1Controller, color.red.toString());
      _setTextIfChanged(_input2Controller, color.green.toString());
      _setTextIfChanged(_input3Controller, color.blue.toString());
      _setTextIfChanged(_input4Controller, '${(color.opacity * 100).round()}%');
    } else if (_activeMode == 'hsv') {
      _setTextIfChanged(_input1Controller, _hsvColor.hue.round().toString());
      _setTextIfChanged(_input2Controller, '${(_hsvColor.saturation * 100).round()}%');
      _setTextIfChanged(_input3Controller, '${(_hsvColor.value * 100).round()}%');
      _setTextIfChanged(_input4Controller, '${(_hsvColor.alpha * 100).round()}%');
    } else if (_activeMode == 'hsl') {
      final hsl = HSLColor.fromColor(color);
      _setTextIfChanged(_input1Controller, hsl.hue.round().toString());
      _setTextIfChanged(_input2Controller, '${(hsl.saturation * 100).round()}%');
      _setTextIfChanged(_input3Controller, '${(hsl.lightness * 100).round()}%');
      _setTextIfChanged(_input4Controller, '${(hsl.alpha * 100).round()}%');
    }
  }

  void _setTextIfChanged(TextEditingController controller, String text) {
    if (controller.text != text) {
      final selection = controller.selection;
      controller.text = text;
      // Preserve selection if possible
      try {
        controller.selection = selection;
      } catch (_) {}
    }
  }

  void _parseColorFromText() {
    _isUpdatingFromText = true;
    try {
      if (_activeMode == 'hex') {
        String hex = _input1Controller.text.trim();
        if (hex.startsWith('#')) hex = hex.substring(1);
        if (hex.length == 6) {
          final r = int.parse(hex.substring(0, 2), radix: 16);
          final g = int.parse(hex.substring(2, 4), radix: 16);
          final b = int.parse(hex.substring(4, 6), radix: 16);
          final col = Color.fromARGB(255, r, g, b);
          setState(() {
            _hsvColor = HSVColor.fromColor(col);
            _onColorUpdated();
          });
        } else if (hex.length == 8) {
          final a = int.parse(hex.substring(0, 2), radix: 16);
          final r = int.parse(hex.substring(2, 4), radix: 16);
          final g = int.parse(hex.substring(4, 6), radix: 16);
          final b = int.parse(hex.substring(6, 8), radix: 16);
          final col = Color.fromARGB(a, r, g, b);
          setState(() {
            _hsvColor = HSVColor.fromColor(col);
            _onColorUpdated();
          });
        }
      } else if (_activeMode == 'rgb') {
        final r = int.tryParse(_input1Controller.text) ?? _hsvColor.toColor().red;
        final g = int.tryParse(_input2Controller.text) ?? _hsvColor.toColor().green;
        final b = int.tryParse(_input3Controller.text) ?? _hsvColor.toColor().blue;
        
        String aText = _input4Controller.text.replaceAll('%', '').trim();
        final aVal = double.tryParse(aText);
        final a = aVal != null ? (aVal / 100).clamp(0.0, 1.0) : _hsvColor.alpha;

        final col = Color.fromARGB((a * 255).round(), r.clamp(0, 255), g.clamp(0, 255), b.clamp(0, 255));
        setState(() {
          _hsvColor = HSVColor.fromColor(col);
          _onColorUpdated();
        });
      } else if (_activeMode == 'hsv') {
        final h = double.tryParse(_input1Controller.text) ?? _hsvColor.hue;
        
        final sText = _input2Controller.text.replaceAll('%', '').trim();
        final sVal = double.tryParse(sText);
        final s = sVal != null ? (sVal / 100).clamp(0.0, 1.0) : _hsvColor.saturation;

        final vText = _input3Controller.text.replaceAll('%', '').trim();
        final vVal = double.tryParse(vText);
        final v = vVal != null ? (vVal / 100).clamp(0.0, 1.0) : _hsvColor.value;

        final aText = _input4Controller.text.replaceAll('%', '').trim();
        final aVal = double.tryParse(aText);
        final a = aVal != null ? (aVal / 100).clamp(0.0, 1.0) : _hsvColor.alpha;

        setState(() {
          _hsvColor = HSVColor.fromAHSV(a, h.clamp(0.0, 360.0), s, v);
          _onColorUpdated();
        });
      } else if (_activeMode == 'hsl') {
        final h = double.tryParse(_input1Controller.text) ?? _hsvColor.hue;
        
        final sText = _input2Controller.text.replaceAll('%', '').trim();
        final sVal = double.tryParse(sText);
        final s = sVal != null ? (sVal / 100).clamp(0.0, 1.0) : 0.5;

        final lText = _input3Controller.text.replaceAll('%', '').trim();
        final lVal = double.tryParse(lText);
        final l = lVal != null ? (lVal / 100).clamp(0.0, 1.0) : 0.5;

        final aText = _input4Controller.text.replaceAll('%', '').trim();
        final aVal = double.tryParse(aText);
        final a = aVal != null ? (aVal / 100).clamp(0.0, 1.0) : _hsvColor.alpha;

        final hsl = HSLColor.fromAHSL(a, h.clamp(0.0, 360.0), s, l);
        setState(() {
          _hsvColor = HSVColor.fromColor(hsl.toColor());
          _onColorUpdated();
        });
      }
    } catch (_) {}
    _isUpdatingFromText = false;
  }

  void _handleSVDrag(double localX, double localY, double width, double height) {
    final s = (localX / width).clamp(0.0, 1.0);
    final v = (1.0 - (localY / height)).clamp(0.0, 1.0);
    setState(() {
      _hsvColor = HSVColor.fromAHSV(_hsvColor.alpha, _hsvColor.hue, s, v);
      _onColorUpdated();
    });
  }

  void _handleHueDrag(double localX, double width) {
    final h = ((localX / width) * 360.0).clamp(0.0, 360.0);
    setState(() {
      _hsvColor = HSVColor.fromAHSV(_hsvColor.alpha, h, _hsvColor.saturation, _hsvColor.value);
      _onColorUpdated();
    });
  }

  void _handleAlphaDrag(double localX, double width) {
    final a = (localX / width).clamp(0.0, 1.0);
    setState(() {
      _hsvColor = HSVColor.fromAHSV(a, _hsvColor.hue, _hsvColor.saturation, _hsvColor.value);
      _onColorUpdated();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseColor = HSVColor.fromAHSV(1.0, _hsvColor.hue, 1.0, 1.0).toColor();
    final currentColor = _hsvColor.toColor();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Grid + preview side-by-side
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Saturation-Value box
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.2,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final height = constraints.maxHeight;
                    return GestureDetector(
                      onPanDown: (details) => _handleSVDrag(details.localPosition.dx, details.localPosition.dy, width, height),
                      onPanUpdate: (details) => _handleSVDrag(details.localPosition.dx, details.localPosition.dy, width, height),
                      child: Container(
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Stack(
                          children: [
                            // Saturation gradient (horizontal)
                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.white, Colors.transparent],
                                ),
                              ),
                            ),
                            // Value gradient (vertical)
                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Colors.black],
                                ),
                              ),
                            ),
                            // Draggable cursor
                            Positioned(
                              left: (_hsvColor.saturation * width) - 6,
                              top: ((1.0 - _hsvColor.value) * height) - 6,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // 2. Right Pane: Preview Circle and Sliders
            Column(
              children: [
                // Preview Circle
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: CustomPaint(
                      painter: CheckerboardPainter(),
                      child: Container(
                        color: currentColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Hue track
                SizedBox(
                  width: 120,
                  height: 12,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      return GestureDetector(
                        onPanDown: (details) => _handleHueDrag(details.localPosition.dx, width),
                        onPanUpdate: (details) => _handleHueDrag(details.localPosition.dx, width),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            gradient: const LinearGradient(
                              colors: [
                                Colors.red,
                                Colors.yellow,
                                Colors.green,
                                Colors.cyan,
                                Colors.blue,
                                const Color(0xFFFF00FF),
                                Colors.red,
                              ],
                            ),
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                left: ((_hsvColor.hue / 360.0) * width) - 6,
                                top: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.grey.withOpacity(0.8), width: 1.5),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 2),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Alpha track
                SizedBox(
                  width: 120,
                  height: 12,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      return GestureDetector(
                        onPanDown: (details) => _handleAlphaDrag(details.localPosition.dx, width),
                        onPanUpdate: (details) => _handleAlphaDrag(details.localPosition.dx, width),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: CustomPaint(
                            painter: CheckerboardPainter(),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    currentColor.withOpacity(0.0),
                                    currentColor.withOpacity(1.0),
                                  ],
                                ),
                              ),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned(
                                    left: (_hsvColor.alpha * width) - 6,
                                    top: 0,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.grey.withOpacity(0.8), width: 1.5),
                                        boxShadow: [
                                          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 2),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 3. Selection Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildModeChip('HEX', 'hex'),
              const SizedBox(width: 8),
              _buildModeChip('RGB', 'rgb'),
              const SizedBox(width: 8),
              _buildModeChip('HSV', 'hsv'),
              const SizedBox(width: 8),
              _buildModeChip('HSL', 'hsl'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 4. Input Fields
        _buildInputRow(isDark),
      ],
    );
  }

  Widget _buildModeChip(String label, String mode) {
    final active = _activeMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeMode = mode;
          _updateTextFromColor();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppTheme.brandEmerald500 : Colors.transparent,
          border: Border.all(
            color: active ? AppTheme.brandEmerald500 : Colors.grey.withOpacity(0.3),
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: active ? Colors.white : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildInputRow(bool isDark) {
    if (_activeMode == 'hex') {
      return Row(
        children: [
          Expanded(
            child: _buildTextField(
              controller: _input1Controller,
              label: 'HEX',
              focusNode: _focus1,
            ),
          ),
        ],
      );
    } else if (_activeMode == 'rgb') {
      return Row(
        children: [
          Expanded(child: _buildTextField(controller: _input1Controller, label: 'R', focusNode: _focus1, isNumericOnly: true)),
          const SizedBox(width: 8),
          Expanded(child: _buildTextField(controller: _input2Controller, label: 'G', focusNode: _focus2, isNumericOnly: true)),
          const SizedBox(width: 8),
          Expanded(child: _buildTextField(controller: _input3Controller, label: 'B', focusNode: _focus3, isNumericOnly: true)),
          const SizedBox(width: 8),
          Expanded(child: _buildTextField(controller: _input4Controller, label: 'A', focusNode: _focus4)),
        ],
      );
    } else if (_activeMode == 'hsv') {
      return Row(
        children: [
          Expanded(child: _buildTextField(controller: _input1Controller, label: 'H', focusNode: _focus1, isNumericOnly: true)),
          const SizedBox(width: 8),
          Expanded(child: _buildTextField(controller: _input2Controller, label: 'S', focusNode: _focus2)),
          const SizedBox(width: 8),
          Expanded(child: _buildTextField(controller: _input3Controller, label: 'V', focusNode: _focus3)),
          const SizedBox(width: 8),
          Expanded(child: _buildTextField(controller: _input4Controller, label: 'A', focusNode: _focus4)),
        ],
      );
    } else {
      // HSL
      return Row(
        children: [
          Expanded(child: _buildTextField(controller: _input1Controller, label: 'H', focusNode: _focus1, isNumericOnly: true)),
          const SizedBox(width: 8),
          Expanded(child: _buildTextField(controller: _input2Controller, label: 'S', focusNode: _focus2)),
          const SizedBox(width: 8),
          Expanded(child: _buildTextField(controller: _input3Controller, label: 'L', focusNode: _focus3)),
          const SizedBox(width: 8),
          Expanded(child: _buildTextField(controller: _input4Controller, label: 'A', focusNode: _focus4)),
        ],
      );
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required FocusNode focusNode,
    bool isNumericOnly = false,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: theme.hintColor,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 32,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: AppTheme.brandEmerald500, width: 1.5),
              ),
            ),
            keyboardType: isNumericOnly ? TextInputType.number : TextInputType.text,
            onChanged: (val) {
              _parseColorFromText();
            },
          ),
        ),
      ],
    );
  }
}

class CheckerboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.grey.withOpacity(0.18);
    const squareSize = 6.0;
    for (double y = 0; y < size.height; y += squareSize) {
      final useOdd = (y / squareSize).floor() % 2 == 1;
      for (double x = 0; x < size.width; x += squareSize) {
        if (((x / squareSize).floor() % 2 == 1) != useOdd) {
          canvas.drawRect(Rect.fromLTWH(x, y, squareSize, squareSize), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
