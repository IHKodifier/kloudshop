import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:rich_field_controller/rich_field_controller.dart';
import 'package:kloudshop/models/catalog.dart';
import 'package:kloudshop/providers/product_editor_provider.dart';
import 'package:kloudshop/services/file_uploader.dart';
import 'package:kloudshop/services/api_service.dart';
import 'package:kloudshop/widgets/glass_card.dart';
import 'package:kloudshop/widgets/product/product_general_info_card.dart';
import 'package:kloudshop/widgets/upload/media_gallery_uploader.dart';

class ProductEditorInfoStep extends ConsumerStatefulWidget {
  final Product? product;
  const ProductEditorInfoStep({super.key, this.product});

  @override
  ConsumerState<ProductEditorInfoStep> createState() => _ProductEditorInfoStepState();
}

class _StyleRange {
  final int start;
  final int end;
  final TextStyle style;
  _StyleRange(this.start, this.end, this.style);
}

void setMarkdownText(RichFieldController controller, String markdown) {
  final regex = RegExp(
    r'(\*\*(.*?)\*\*)|(\*(.*?)\*)|(~~(.*?)~~)|(<u>(.*?)</u>)',
    dotAll: true,
  );

  String plainText = '';
  int lastMatchEnd = 0;
  final List<_StyleRange> ranges = [];

  final matches = regex.allMatches(markdown);
  for (final match in matches) {
    plainText += markdown.substring(lastMatchEnd, match.start);
    final startInPlain = plainText.length;

    TextStyle style;
    String content;

    if (match.group(1) != null) {
      style = const TextStyle(fontWeight: FontWeight.bold);
      content = match.group(2) ?? '';
    } else if (match.group(3) != null) {
      style = const TextStyle(fontStyle: FontStyle.italic);
      content = match.group(4) ?? '';
    } else if (match.group(5) != null) {
      style = const TextStyle(decoration: TextDecoration.lineThrough);
      content = match.group(6) ?? '';
    } else {
      style = const TextStyle(decoration: TextDecoration.underline);
      content = match.group(8) ?? '';
    }

    plainText += content;
    final endInPlain = plainText.length;

    ranges.add(_StyleRange(startInPlain, endInPlain, style));
    lastMatchEnd = match.end;
  }

  plainText += markdown.substring(lastMatchEnd);
  controller.text = plainText;

  for (final range in ranges) {
    controller.selection = TextSelection(
      baseOffset: range.start,
      extentOffset: range.end,
    );
    controller.updateStyle(range.style);
  }

  controller.selection = TextSelection.collapsed(offset: plainText.length);
}

class _ProductEditorInfoStepState extends ConsumerState<ProductEditorInfoStep> {
  late TextEditingController _titleController;
  late TextEditingController _slugController;
  late TextEditingController _descriptionController;
  late final FileUploader _uploader;
  late final FocusNode _descriptionFocusNode;

  @override
  void initState() {
    super.initState();
    _uploader = MockFileUploader(
      apiUpload: (bytes, name) =>
          ref.read(apiServiceProvider).uploadMedia(bytes, name),
    );
    final state = ref.read(productEditorProvider(widget.product));
    _titleController = TextEditingController(text: state.title);
    _slugController = TextEditingController(text: state.slug);
    
    _descriptionFocusNode = FocusNode();
    final richController = RichFieldController(focusNode: _descriptionFocusNode);
    setMarkdownText(richController, state.description);
    _descriptionController = richController;

    _titleController.addListener(_onTitleChanged);
    _slugController.addListener(_onSlugChanged);
    _descriptionController.addListener(_onDescriptionChanged);
  }

  void _onTitleChanged() {
    ref.read(productEditorProvider(widget.product).notifier).updateTitle(_titleController.text);
  }

  void _onSlugChanged() {
    ref.read(productEditorProvider(widget.product).notifier).updateSlug(_slugController.text);
  }

  void _onDescriptionChanged() {
    final md = (_descriptionController as RichFieldController).toMarkdown();
    ref.read(productEditorProvider(widget.product).notifier).updateDescription(md);
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTitleChanged);
    _slugController.removeListener(_onSlugChanged);
    _descriptionController.removeListener(_onDescriptionChanged);
    _titleController.dispose();
    _slugController.dispose();
    _descriptionController.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productEditorProvider(widget.product));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: ProductGeneralInfoCard(
            titleController: _titleController,
            slugController: _slugController,
            descriptionController: _descriptionController,
            isNewProduct: widget.product == null,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 5,
          child: GlassCard(
            title: 'Media Gallery',
            icon: LucideIcons.image,
            color: const Color(0xFFEC4899),
            children: [
              MediaGalleryUploader(
                images: state.images,
                uploader: _uploader,
                onImagesChanged: (newImages) {
                  ref.read(productEditorProvider(widget.product).notifier).updateImages(newImages);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
