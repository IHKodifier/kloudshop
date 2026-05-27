import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/theme/app_theme.dart';

class OptionCategoryEditor extends StatefulWidget {
  final Map<String, dynamic> option;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  const OptionCategoryEditor({
    super.key,
    required this.option,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  State<OptionCategoryEditor> createState() => _OptionCategoryEditorState();
}

class _OptionCategoryEditorState extends State<OptionCategoryEditor> {
  late TextEditingController _nameController;
  late TextEditingController _valueController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.option['name']);
    _valueController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _addValue() {
    final val = _valueController.text.trim();
    if (val.isNotEmpty) {
      final List<String> vals = List<String>.from(widget.option['values']);
      if (!vals.contains(val)) {
        vals.add(val);
        widget.option['values'] = vals;
        widget.onChanged();
        _valueController.clear();
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> values = List<String>.from(widget.option['values']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Option Name (e.g. Color, Size)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) {
                  widget.option['name'] = v.trim();
                  widget.onChanged();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: TextFormField(
                controller: _valueController,
                decoration: InputDecoration(
                  labelText: 'Add Value',
                  suffixIcon: IconButton(
                    icon: const Icon(
                      Icons.add_circle,
                      color: AppTheme.brandEmerald500,
                    ),
                    onPressed: _addValue,
                  ),
                  border: const OutlineInputBorder(),
                ),
                onFieldSubmitted: (_) => _addValue(),
              ),
            ),
            IconButton(
              icon: const Icon(LucideIcons.trash2, color: Colors.redAccent),
              onPressed: widget.onDelete,
            ),
          ],
        ),
        if (values.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values
                .map(
                  (val) => Chip(
                    label: Text(val),
                    onDeleted: () {
                      values.remove(val);
                      widget.option['values'] = values;
                      widget.onChanged();
                      setState(() {});
                    },
                  ),
                )
                .toList(),
          ),
        ],
        const Divider(height: 32),
      ],
    );
  }
}
