import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

class RichTextToolbar extends StatelessWidget {
  final TextEditingController controller;
  const RichTextToolbar({super.key, required this.controller});

  void _formatText(String prefix, String suffix) {
    final text = controller.text;
    final selection = controller.selection;

    if (selection.start < 0 || selection.end < 0) {
      // If no active selection, append to the end
      final newText = '$text$prefix$suffix';
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: newText.length - suffix.length,
        ),
      );
      return;
    }

    final selectedText = selection.textInside(text);
    final newText =
        selection.textBefore(text) +
        prefix +
        selectedText +
        suffix +
        selection.textAfter(text);

    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: selection.start + prefix.length,
        extentOffset: selection.end + prefix.length,
      ),
    );
  }

  void _formatLine(String prefix) {
    final text = controller.text;
    final selection = controller.selection;

    if (selection.start < 0 || selection.end < 0) {
      // If no active selection, add prefix at the beginning of the current text
      final newText = '$prefix$text';
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
      return;
    }

    // Find the start of the current line
    final beforeText = selection.textBefore(text);
    final lastNewline = beforeText.lastIndexOf('\n');
    final lineStart = lastNewline == -1 ? 0 : lastNewline + 1;

    final newBefore =
        text.substring(0, lineStart) +
        prefix +
        text.substring(lineStart, selection.start);
    final newText =
        newBefore + selection.textInside(text) + selection.textAfter(text);

    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: selection.start + prefix.length,
        extentOffset: selection.end + prefix.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.grey[50],
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : Colors.grey[200]!,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          _buildToolbarButton(
            icon: LucideIcons.bold,
            tooltip: 'Bold',
            onPressed: () => _formatText('**', '**'),
          ),
          _buildToolbarButton(
            icon: LucideIcons.italic,
            tooltip: 'Italic',
            onPressed: () => _formatText('*', '*'),
          ),
          _buildToolbarButton(
            icon: LucideIcons.underline,
            tooltip: 'Underline',
            onPressed: () => _formatText('<u>', '</u>'),
          ),
          _buildToolbarButton(
            icon: LucideIcons.strikethrough,
            tooltip: 'Strikethrough',
            onPressed: () => _formatText('~~', '~~'),
          ),
          const SizedBox(
            height: 20,
            child: VerticalDivider(width: 16, thickness: 1, color: Colors.grey),
          ),
          _buildToolbarButton(
            icon: LucideIcons.list,
            tooltip: 'Bullet List',
            onPressed: () => _formatLine('* '),
          ),
          _buildToolbarButton(
            icon: LucideIcons.listOrdered,
            tooltip: 'Numbered List',
            onPressed: () => _formatLine('1. '),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 16),
        onPressed: onPressed,
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(),
        splashRadius: 18,
      ),
    );
  }
}
