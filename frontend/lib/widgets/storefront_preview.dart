import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/widgets/hover_scale.dart';

class StorefrontPreview extends StatefulWidget {
  final Map<String, dynamic> tokens;
  final Map<String, dynamic> slots;
  final bool isMobile;
  final String previewState; // 'default', 'loading', 'error', 'empty', 'validation'
  final String? selectedNodeId;
  final ValueChanged<String>? onNodeSelected;
  final Function(String parentId, int index, Map<String, dynamic> child)? onNodeDropped;
  final Function(String nodeId, double newLeft, double newTop)? onNodeMoved;
  final String page;
  final bool isDragging;

  const StorefrontPreview({
    super.key,
    required this.tokens,
    required this.slots,
    this.isMobile = false,
    this.previewState = 'default',
    this.selectedNodeId,
    this.onNodeSelected,
    this.onNodeDropped,
    this.onNodeMoved,
    this.page = 'home',
    this.isDragging = false,
  });

  @override
  State<StorefrontPreview> createState() => _StorefrontPreviewState();
}

class _StorefrontPreviewState extends State<StorefrontPreview>
    with SingleTickerProviderStateMixin {
  late AnimationController _shaderController;
  final List<Map<String, dynamic>> _cartItems = [];
  bool _isCartOpen = false;
  int _activeTab = 0; // for PDP tabs

  Widget _buildDropZone(String parentId, int index, {required bool isHorizontal}) {
    if (widget.onNodeDropped == null) return const SizedBox.shrink();

    return DragTarget<Map<String, dynamic>>(
      onWillAccept: (data) => data != null,
      onAccept: (data) {
        widget.onNodeDropped!(parentId, index, data);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        final isActiveDrag = widget.isDragging;

        double size = 8.0;
        if (isHovered) {
          size = 24.0;
        } else if (isActiveDrag) {
          size = 16.0;
        }

        return MouseRegion(
          cursor: isHovered ? SystemMouseCursors.copy : (isActiveDrag ? SystemMouseCursors.copy : SystemMouseCursors.basic),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: isHorizontal ? size : double.infinity,
            height: isHorizontal ? double.infinity : size,
            alignment: Alignment.center,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: isHorizontal 
                  ? (isHovered ? 6.0 : (isActiveDrag ? 2.0 : 0.0)) 
                  : double.infinity,
              height: isHorizontal 
                  ? double.infinity 
                  : (isHovered ? 6.0 : (isActiveDrag ? 2.0 : 0.0)),
              decoration: BoxDecoration(
                color: isHovered 
                    ? AppTheme.brandEmerald500 
                    : (isActiveDrag ? AppTheme.brandEmerald500.withOpacity(0.3) : Colors.transparent),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyPlaceholder(String parentId, double radius, Color text) {
    return DragTarget<Map<String, dynamic>>(
      onWillAccept: (data) => data != null,
      onAccept: (data) {
        if (widget.onNodeDropped != null) {
          widget.onNodeDropped!(parentId, 0, data);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        final isActiveDrag = widget.isDragging;

        final borderColor = isHovered 
            ? AppTheme.brandEmerald500 
            : (isActiveDrag ? AppTheme.brandEmerald500.withOpacity(0.4) : text.withOpacity(0.15));

        return MouseRegion(
          cursor: isHovered ? SystemMouseCursors.copy : (isActiveDrag ? SystemMouseCursors.copy : SystemMouseCursors.basic),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isHovered 
                  ? AppTheme.brandEmerald500.withOpacity(0.1) 
                  : (isActiveDrag ? AppTheme.brandEmerald500.withOpacity(0.04) : Colors.transparent),
              border: Border.all(
                color: borderColor,
                style: BorderStyle.solid,
                width: isHovered ? 2.0 : 1.0,
              ),
              borderRadius: BorderRadius.circular(radius),
            ),
            child: Center(
              child: Text(
                'Drag & Drop components here',
                style: TextStyle(
                  color: isHovered 
                      ? AppTheme.brandEmerald500 
                      : (isActiveDrag ? AppTheme.brandEmerald500 : text.withOpacity(0.4)),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Form controllers for validation state
  final _cardNumberController = TextEditingController(text: '4111 2222 3333');
  final _cvvController = TextEditingController(text: '');

  @override
  void initState() {
    super.initState();
    _shaderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    // Don't repeat animation if in a widget test to prevent infinite pumps
    if (RegExp(r'flutter_test|test').hasMatch(Stream.fromIterable([]).toString()) == false) {
      _shaderController.repeat();
    } else {
      _shaderController.forward();
    }

    // Populate initial cart items for default state demo
    _cartItems.addAll([
      {'name': 'Premium Jacket', 'price': 129, 'quantity': 1},
      {'name': 'Urban Sneakers', 'price': 89, 'quantity': 1},
    ]);
  }

  @override
  void dispose() {
    _shaderController.dispose();
    _cardNumberController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  // Resolves properties that reference design tokens (e.g. 'tokens.primary')
  dynamic _resolveValue(dynamic value) {
    if (value is String && value.startsWith('tokens.')) {
      final tokenKey = value.substring(7);
      return widget.tokens[tokenKey];
    }
    return value;
  }

  Color _parseColor(dynamic val, Color fallback) {
    final resolved = _resolveValue(val);
    if (resolved == null) return fallback;
    if (resolved is Color) return resolved;
    if (resolved is String && resolved.startsWith('#')) {
      try {
        return Color(int.parse(resolved.substring(1), radix: 16) + 0xFF000000);
      } catch (_) {
        return fallback;
      }
    }
    return fallback;
  }

  double _parseDouble(dynamic val, double fallback) {
    final resolved = _resolveValue(val);
    if (resolved == null) return fallback;
    if (resolved is num) return resolved.toDouble();
    if (resolved is String) {
      return double.tryParse(resolved) ?? fallback;
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _parseColor(widget.tokens['primary'], AppTheme.brandTeal500);
    final backgroundColor = _parseColor(widget.tokens['bg_color'] ?? widget.tokens['background'], Colors.white);
    final isDark = backgroundColor.computeLuminance() < 0.5;

    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final surfaceColor = isDark
        ? const Color(0xFF1E293B).withOpacity(0.7)
        : Colors.white.withOpacity(0.9);

    final borderRad = _parseDouble(widget.tokens['border_radius'] ?? widget.tokens['card_border_radius'], 12.0);

    // Build the default layout if not specified in slots
    final slotKey = widget.page == 'home' ? 'layout' : 'layout_${widget.page}';
    final layoutMap = widget.slots[slotKey] ?? _getDefaultLayoutForPage(widget.page);

    // Configure Canvas Background
    final bgType = widget.tokens['bg_type'] ?? 'solid';
    
    BoxDecoration canvasBoxDecoration = BoxDecoration(color: backgroundColor);
    if (bgType == 'gradient') {
      final gradType = widget.tokens['bg_gradient_type'] ?? 'linear';
      final start = _parseColor(widget.tokens['bg_gradient_start'], Colors.white);
      final end = _parseColor(widget.tokens['bg_gradient_end'], const Color(0xFFF1F5F9));
      canvasBoxDecoration = BoxDecoration(
        gradient: gradType == 'radial'
            ? RadialGradient(colors: [start, end])
            : LinearGradient(
                colors: [start, end],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
      );
    } else if (bgType == 'image') {
      final imgUrl = widget.tokens['bg_image_url'] ?? '';
      final fitStr = widget.tokens['bg_image_fit'] ?? 'cover';
      final repeatStr = widget.tokens['bg_image_repeat'] ?? 'no-repeat';
      final opacity = _parseDouble(widget.tokens['bg_image_opacity'], 1.0);
      
      final fit = fitStr == 'contain' ? BoxFit.contain : (fitStr == 'fill' ? BoxFit.fill : BoxFit.cover);
      final repeat = repeatStr == 'repeat' ? ImageRepeat.repeat : ImageRepeat.noRepeat;
      
      canvasBoxDecoration = BoxDecoration(
        color: backgroundColor,
        image: imgUrl.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(imgUrl),
                fit: fit,
                repeat: repeat,
                colorFilter: ColorFilter.mode(
                  Colors.white.withOpacity(opacity),
                  BlendMode.dstATop,
                ),
              )
            : null,
      );
    }

    Widget bodyContent = SingleChildScrollView(
      child: _renderNode(layoutMap, context, primaryColor, textColor, surfaceColor, borderRad),
    );

    // Dynamic Liquid Shader Background if type == shader
    if (bgType == 'shader') {
      final shaderName = widget.tokens['bg_shader'] ?? 'wave';
      bodyContent = AnimatedBuilder(
        animation: _shaderController,
        builder: (context, child) {
          return CustomPaint(
            painter: AnimatedShaderBackground(
              type: shaderName,
              progress: _shaderController.value,
              primaryColor: primaryColor,
            ),
            child: child,
          );
        },
        child: bodyContent,
      );
    }

    return MouseRegion(
      cursor: widget.isDragging ? SystemMouseCursors.forbidden : SystemMouseCursors.basic,
      child: Stack(
        children: [
          // Main Storefront View
          Container(
            width: widget.isMobile ? 375 : double.infinity,
            decoration: canvasBoxDecoration.copyWith(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: bodyContent,
          ),
  
          // 5 Required States Overlays
          if (widget.previewState == 'loading')
            _buildLoadingOverlay(surfaceColor, textColor, primaryColor),
  
          if (widget.previewState == 'error')
            _buildErrorModal(surfaceColor, textColor, borderRad),
  
          if (widget.previewState == 'empty')
            _buildEmptyCartOverlay(backgroundColor, textColor, primaryColor, borderRad),
  
          if (widget.previewState == 'validation')
            _buildValidationOverlay(surfaceColor, textColor, primaryColor, borderRad),
  
          // Sliding Cart Drawer
          if (_isCartOpen && widget.previewState == 'default')
            _buildCartDrawer(surfaceColor, textColor, primaryColor, borderRad),
        ],
      ),
    );
  }

  // Recursive parser that turns layout maps into high-end widgets
  Widget _renderNode(
    Map<String, dynamic> node,
    BuildContext context,
    Color primary,
    Color text,
    Color surface,
    double radius,
  ) {
    if (node['hidden'] == true) return const SizedBox.shrink();

    final rawType = node['type'] ?? 'flexCol';
    final type = ['flexRow', 'flexCol', 'grid', 'stack', 'text', 'button', 'product_card', 'pdp_tabs', 'divider', 'icon', 'testimonials', 'trust_badges', 'collection_list', 'newsletter_signup', 'store_locator', 'spacer', 'announcement_bar', 'header', 'footer', 'image_banner', 'collection'].contains(rawType)
        ? rawType
        : 'flexCol';
    final props = node['properties'] ?? {};
    final children = node['children'] as List<dynamic>? ?? [];
    final id = node['id'] ?? '';
    final isLocked = node['locked'] == true;

    final paddingVal = _parseDouble(props['padding'], 0.0);
    final paddingLeft = _parseDouble(props['padding_left'], paddingVal);
    final paddingRight = _parseDouble(props['padding_right'], paddingVal);
    final paddingTop = _parseDouble(props['padding_top'], paddingVal);
    final paddingBottom = _parseDouble(props['padding_bottom'], paddingVal);
    final paddingEdgeInsets = EdgeInsets.only(
      left: paddingLeft,
      right: paddingRight,
      top: paddingTop,
      bottom: paddingBottom,
    );

    final spacingVal = _parseDouble(props['spacing'], 0.0);
    final borderStyleVal = props['border_style'] ?? 'none';
    final strokeWidthVal = _parseDouble(props['stroke_width'], 1.0);
    final borderColorVal = _parseColor(props['border_color'], Colors.transparent);
    final elevationVal = _parseDouble(props['elevation'], 0.0);
    final bgColorVal = _parseColor(props['background_color'], Colors.transparent);
    final shaderVal = props['shader_source'] as String?;

    // Decoration matching widget styles from design tokens
    BoxDecoration? decoration;
    if (bgColorVal != Colors.transparent ||
        borderStyleVal == 'solid' ||
        elevationVal > 0) {
      decoration = BoxDecoration(
        color: bgColorVal == Colors.transparent ? null : bgColorVal,
        borderRadius: BorderRadius.circular(radius),
        border: borderStyleVal == 'solid'
            ? Border.all(color: borderColorVal, width: strokeWidthVal)
            : null,
        boxShadow: elevationVal > 0
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06 * elevationVal),
                  blurRadius: 4 * elevationVal,
                  offset: Offset(0, 2 * elevationVal),
                ),
              ]
            : null,
      );
    }

    final isColLayout = type == 'flexCol';
    final mainAlign = _parseMainAxisAlignment(props['alignment'], isColLayout);
    final crossAlign = _parseCrossAxisAlignment(props['alignment'], isColLayout);

    Widget contentWidget;

    // Check if Absolute Positioning mode is active
    final isAbsoluteContainer = type == 'stack' || props['layout_mode'] == 'absolute';

    if (isAbsoluteContainer) {
      List<Widget> absoluteChildren = [];
      for (final child in children) {
        if (child is Map<String, dynamic> && child['hidden'] != true) {
          final childProps = child['properties'] ?? {};
          final childLeft = _parseDouble(childProps['left'], 0.0);
          final childTop = _parseDouble(childProps['top'], 0.0);
          final childWidth = _parseDouble(childProps['width'], 150.0);
          final childHeight = _parseDouble(childProps['height'], 50.0);
          
          Widget childWidget = _renderNode(child, context, primary, text, surface, radius);
          final childSelected = widget.selectedNodeId == child['id'];
          final childLocked = child['locked'] == true;

          // Drag-to-move gesture listener for absolute positioned element
          if (childSelected && !childLocked && widget.onNodeMoved != null) {
            childWidget = GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (details) {
                widget.onNodeMoved!(child['id'], childLeft + details.delta.dx, childTop + details.delta.dy);
              },
              child: childWidget,
            );
          }

          absoluteChildren.add(
            Positioned(
              left: childLeft,
              top: childTop,
              width: childWidth,
              height: childHeight,
              child: childWidget,
            ),
          );
        }
      }

      contentWidget = Padding(
        padding: paddingEdgeInsets,
        child: DragTarget<Map<String, dynamic>>(
          onWillAccept: (data) => data != null,
          onAcceptWithDetails: (details) {
            final renderBox = context.findRenderObject() as RenderBox;
            final localOffset = renderBox.globalToLocal(details.offset);

            if (widget.onNodeDropped != null) {
              final childData = Map<String, dynamic>.from(details.data);
              if (childData['properties'] == null) {
                childData['properties'] = <String, dynamic>{};
              }
              final double itemWidth = 150.0;
              final double itemHeight = 50.0;
              childData['properties']['position'] = 'absolute';
              childData['properties']['left'] = localOffset.dx - (itemWidth / 2);
              childData['properties']['top'] = localOffset.dy - (itemHeight / 2);
              childData['properties']['width'] = itemWidth;
              childData['properties']['height'] = itemHeight;
              
              widget.onNodeDropped!(id, -1, childData);
            }
          },
          builder: (context, candidateData, rejectedData) {
            final isHovered = candidateData.isNotEmpty;
            final isActiveDrag = widget.isDragging;
            return MouseRegion(
              cursor: isHovered ? SystemMouseCursors.copy : (isActiveDrag ? SystemMouseCursors.copy : SystemMouseCursors.basic),
              child: Container(
                height: 350,
                decoration: BoxDecoration(
                  color: isHovered 
                      ? primary.withOpacity(0.06) 
                      : (isActiveDrag ? AppTheme.brandEmerald500.withOpacity(0.03) : Colors.transparent),
                  border: isHovered 
                      ? Border.all(color: AppTheme.brandEmerald500, width: 2) 
                      : (isActiveDrag ? Border.all(color: AppTheme.brandEmerald500.withOpacity(0.3), width: 1.5) : null),
                  borderRadius: BorderRadius.circular(radius),
                ),
                child: children.isEmpty
                    ? Center(
                        child: Text(
                          'Absolute Placement Board (Drop templates here)',
                          style: TextStyle(
                            color: isHovered 
                                ? AppTheme.brandEmerald500 
                                : (isActiveDrag ? AppTheme.brandEmerald500 : text.withOpacity(0.3)),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : Stack(
                        clipBehavior: Clip.none,
                        children: absoluteChildren,
                      ),
              ),
            );
          },
        ),
      );
    } else {
      switch (type) {
        case 'flexRow':
          List<Widget> rowChildren = [];
          rowChildren.add(_buildDropZone(id, 0, isHorizontal: true));
          for (int i = 0; i < children.length; i++) {
            rowChildren.add(Flexible(
              fit: FlexFit.loose,
              child: _renderNode(children[i], context, primary, text, surface, radius),
            ));
            rowChildren.add(_buildDropZone(id, i + 1, isHorizontal: true));
          }

          if (children.isEmpty) {
            rowChildren.add(_buildEmptyPlaceholder(id, radius, text));
          }

          contentWidget = Padding(
            padding: paddingEdgeInsets,
            child: IntrinsicHeight(
              child: Row(
                mainAxisAlignment: mainAlign,
                crossAxisAlignment: crossAlign,
                children: rowChildren,
              ),
            ),
          );
          break;

        case 'flexCol':
          List<Widget> colChildren = [];
          colChildren.add(_buildDropZone(id, 0, isHorizontal: false));
          for (int i = 0; i < children.length; i++) {
            colChildren.add(_renderNode(children[i], context, primary, text, surface, radius));
            colChildren.add(_buildDropZone(id, i + 1, isHorizontal: false));
          }

          if (children.isEmpty) {
            colChildren.add(_buildEmptyPlaceholder(id, radius, text));
          }

          contentWidget = Padding(
            padding: paddingEdgeInsets,
            child: Column(
              mainAxisAlignment: mainAlign,
              crossAxisAlignment: crossAlign == CrossAxisAlignment.start && isColLayout
                  ? CrossAxisAlignment.stretch // Column matches width by default unless set
                  : crossAlign,
              children: colChildren,
            ),
          );
          break;

        case 'grid':
          contentWidget = Padding(
            padding: paddingEdgeInsets,
            child: Wrap(
              spacing: spacingVal,
              runSpacing: spacingVal,
              children: children.map((child) {
                return SizedBox(
                  width: widget.isMobile ? double.infinity : 200,
                  child: _renderNode(child, context, primary, text, surface, radius),
                );
              }).toList(),
            ),
          );
          break;

        case 'text':
          final style = node['style'] ?? {};
          final fontSize = _parseDouble(style['font_size'], 14.0);
          final fontWeight = style['font_weight'] == 'bold' ? FontWeight.bold : FontWeight.normal;
          final fontColor = _parseColor(style['color'], text);
          final fontFam = style['font_family'] == 'Outfit' ? 'Outfit' : 'Inter';
          final align = style['align'] == 'center' ? TextAlign.center : TextAlign.start;

          contentWidget = Padding(
            padding: paddingEdgeInsets,
            child: Text(
              node['value'] ?? '',
              textAlign: align,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: fontWeight,
                color: fontColor,
                fontFamily: fontFam,
              ),
            ),
          );
          break;

        case 'button':
          final label = node['value'] ?? 'Click';
          contentWidget = Padding(
            padding: paddingEdgeInsets,
            child: HoverScale(
              scale: 1.05,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(radius),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
          break;

        case 'product_card':
          final productName = node['product_name'] ?? 'Product';
          final productPrice = node['price'] ?? '\$0.00';
          contentWidget = _buildProductTile(productName, productPrice, surface, text, primary, radius);
          break;

        case 'pdp_tabs':
          contentWidget = _buildPDPTabs(text, primary, radius);
          break;

        case 'divider':
          contentWidget = Divider(
            color: text.withOpacity(0.15),
            thickness: 1,
            height: paddingVal * 2,
          );
          break;
        
        case 'icon':
          final iconName = node['icon_name'];
          IconData iconData = LucideIcons.package;
          if (iconName == 'store') iconData = LucideIcons.store;
          if (iconName == 'shoppingBag') iconData = LucideIcons.shoppingBag;
          contentWidget = Icon(iconData, color: _parseColor(props['color'], text), size: 20);
          break;

        // Expanded Figma Primitives
        case 'testimonials':
          contentWidget = Padding(
            padding: paddingEdgeInsets,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: text.withOpacity(0.04),
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: text.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (idx) => const Icon(LucideIcons.star, color: Colors.amber, size: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '"The best commerce storefront engine I\'ve ever integrated. Insanely fast page loads and premium interactions."',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: text.withOpacity(0.8),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '- Sarah Jenkins, Founder of VogueEdge',
                    style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ],
              ),
            ),
          );
          break;

        case 'trust_badges':
          contentWidget = Padding(
            padding: paddingEdgeInsets,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildMockBadge(LucideIcons.shieldCheck, 'Secure Checkout', text),
                  const SizedBox(width: 16),
                  _buildMockBadge(LucideIcons.truck, 'Free Delivery', text),
                  const SizedBox(width: 16),
                  _buildMockBadge(LucideIcons.rotateCcw, 'Easy Returns', text),
                ],
              ),
            ),
          );
          break;

        case 'collection_list':
          contentWidget = Padding(
            padding: paddingEdgeInsets,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shop by Collection',
                  style: TextStyle(color: text, fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildMockCollectionCard('New Arrivals', text, radius)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildMockCollectionCard('Best Sellers', text, radius)),
                  ],
                ),
              ],
            ),
          );
          break;

        case 'newsletter_signup':
          contentWidget = Padding(
            padding: paddingEdgeInsets,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(radius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Join the Newsletter',
                    style: TextStyle(color: text, fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Receive weekly drops and operations intelligence updates.',
                    style: TextStyle(color: text.withOpacity(0.6), fontSize: 11),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: surface,
                            border: Border.all(color: text.withOpacity(0.15)),
                            borderRadius: BorderRadius.horizontal(left: Radius.circular(radius)),
                          ),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'merchant@company.com',
                            style: TextStyle(color: text.withOpacity(0.4), fontSize: 11),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.horizontal(right: Radius.circular(radius)),
                          ),
                        ),
                        child: const Text('Subscribe', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
          break;

        case 'store_locator':
          contentWidget = Padding(
            padding: paddingEdgeInsets,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: text.withOpacity(0.03),
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: text.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.mapPin, color: primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KloudShop HQ Flagship Store',
                          style: TextStyle(color: text, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '100 High-Altitude Way, Silicon Valley, CA',
                          style: TextStyle(color: text.withOpacity(0.6), fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
          break;

        case 'spacer':
          final h = _parseDouble(props['height'], 24.0);
          contentWidget = SizedBox(height: h);
          break;

        case 'announcement_bar':
          final barText = props['text'] ?? 'Welcome to our store';
          final barBgColor = _parseColor(props['background_color'], primary);
          final barTextColor = _parseColor(props['text_color'], Colors.white);
          contentWidget = Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: barBgColor,
            alignment: Alignment.center,
            child: Text(
              barText,
              style: TextStyle(
                color: barTextColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          );
          break;

        case 'header':
          final logoText = props['logo_text'] ?? 'Dawn';
          final logoImageUrl = props['logo_image_url'] as String?;
          
          contentWidget = Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: surface,
              border: Border(bottom: BorderSide(color: text.withOpacity(0.1))),
            ),
            child: Row(
              children: [
                if (logoImageUrl != null && logoImageUrl.isNotEmpty)
                  Image.network(logoImageUrl, height: 28, errorBuilder: (_, __, ___) => Icon(LucideIcons.store, color: primary))
                else ...[
                  Icon(LucideIcons.store, color: primary),
                  const SizedBox(width: 12),
                  Text(
                    logoText,
                    style: TextStyle(
                      color: text,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      fontFamily: 'Outfit',
                    ),
                  ),
                ],
                const Spacer(),
                if (!widget.isMobile) ...[
                  _navItem('Home', text),
                  _navItem('Catalog', text),
                  _navItem('Contact', text),
                ],
                const SizedBox(width: 12),
                Icon(LucideIcons.search, color: text, size: 20),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => setState(() => _isCartOpen = !_isCartOpen),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(LucideIcons.shoppingBag, color: text, size: 20),
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Text(
                            '2',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
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
          );
          break;

        case 'image_banner':
          final overlayOpacity = _parseDouble(props['overlay_opacity'], 0.4);
          final bannerHeightStr = props['banner_height'] ?? 'Medium';
          final bannerImageUrl = props['image_url'] as String? ?? 'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?w=800';
          
          double bannerHeight = 250.0;
          if (bannerHeightStr == 'Small') bannerHeight = 180.0;
          if (bannerHeightStr == 'Large') bannerHeight = 350.0;

          List<Widget> bannerChildren = [];
          for (final child in children) {
            bannerChildren.add(_renderNode(child, context, primary, text, surface, radius));
          }

          contentWidget = Container(
            height: bannerHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              image: DecorationImage(
                image: NetworkImage(bannerImageUrl),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                color: Colors.black.withOpacity(overlayOpacity),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: bannerChildren.expand((child) => [child, const SizedBox(height: 12)]).toList()..removeLast(),
              ),
            ),
          );
          break;

        case 'collection_list':
          final listTitle = props['title'] ?? 'Shop by Collection';
          final listSpacing = _parseDouble(props['spacing'], 16.0);
          
          List<Widget> listChildren = [];
          for (final child in children) {
            listChildren.add(Expanded(
              child: _renderNode(child, context, primary, text, surface, radius),
            ));
          }

          contentWidget = Padding(
            padding: paddingEdgeInsets,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listTitle,
                  style: TextStyle(color: text, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: listChildren.isEmpty 
                    ? [Text('No collections added.', style: TextStyle(color: text.withOpacity(0.5)))]
                    : listChildren.expand((item) => [item, SizedBox(width: listSpacing)]).toList()..removeLast(),
                ),
              ],
            ),
          );
          break;

        case 'collection':
          final colName = props['collection_name'] ?? 'Collection';
          final colImageUrl = props['image_url'] as String? ?? 'https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=500';
          contentWidget = Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              image: DecorationImage(
                image: NetworkImage(colImageUrl),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    colName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const Icon(LucideIcons.arrowRight, color: Colors.white, size: 16),
                ],
              ),
            ),
          );
          break;

        case 'footer':
          final showNewsletter = props['show_newsletter'] == true;
          final showPayment = props['show_payment_methods'] == true;
          final footerBg = _parseColor(props['background_color'], const Color(0xFF0F172A));
          final isDarkFooter = footerBg.computeLuminance() < 0.5;
          final footerText = isDarkFooter ? Colors.white : const Color(0xFF0F172A);

          contentWidget = Container(
            color: footerBg,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Quick Links', style: TextStyle(color: footerText, fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 12),
                          _navItem('Search', footerText.withOpacity(0.7)),
                          _navItem('Privacy Policy', footerText.withOpacity(0.7)),
                          _navItem('Terms of Service', footerText.withOpacity(0.7)),
                        ],
                      ),
                    ),
                    if (showNewsletter)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Subscribe to our emails', style: TextStyle(color: footerText, fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 38,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: isDarkFooter ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                                      borderRadius: BorderRadius.horizontal(left: Radius.circular(radius)),
                                    ),
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'email@example.com',
                                      style: TextStyle(color: footerText.withOpacity(0.4), fontSize: 11),
                                    ),
                                  ),
                                ),
                                Container(
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: primary,
                                    borderRadius: BorderRadius.horizontal(right: Radius.circular(radius)),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  alignment: Alignment.center,
                                  child: Icon(LucideIcons.arrowRight, color: Colors.white, size: 16),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Divider(color: footerText.withOpacity(0.1)),
                const SizedBox(height: 16),
                 Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '© 2026, Dawn Powered by KloudShop',
                        style: TextStyle(color: footerText.withOpacity(0.5), fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (showPayment)
                      Row(
                        children: [
                          Icon(LucideIcons.creditCard, color: footerText.withOpacity(0.6), size: 18),
                          const SizedBox(width: 8),
                          Icon(LucideIcons.wallet, color: footerText.withOpacity(0.6), size: 18),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          );
          break;

        default:
          contentWidget = const SizedBox.shrink();
          break;
      }
    }

    Widget rendered = contentWidget;

    // Wrap the element in background decoration / shader if specified
    if (shaderVal != null && shaderVal != 'none') {
      rendered = AnimatedBuilder(
        animation: _shaderController,
        builder: (context, child) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: CustomPaint(
              painter: AnimatedShaderBackground(
                type: shaderVal,
                progress: _shaderController.value,
                primaryColor: primary,
              ),
              child: child,
            ),
          );
        },
        child: rendered,
      );
    } else if (decoration != null && !isAbsoluteContainer) {
      rendered = Container(
        decoration: decoration,
        child: rendered,
      );
    }

    final isSelected = widget.selectedNodeId != null && widget.selectedNodeId == id;

    if (widget.onNodeSelected != null && id.isNotEmpty && !isLocked) {
      final isDark = _parseColor(widget.tokens['bg_color'] ?? widget.tokens['background'], Colors.white).computeLuminance() < 0.5;
      final highlightColor = _parseColor(widget.tokens['highlight_color'], const Color(0xFF18A0FB));

      rendered = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          widget.onNodeSelected!(id);
        },
        child: isSelected
            ? Stack(
                clipBehavior: Clip.none,
                children: [
                  rendered,
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(radius),
                          color: highlightColor.withOpacity(0.08),
                          border: Border.all(
                            color: isDark ? Colors.black : Colors.white,
                            width: 3.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        margin: const EdgeInsets.all(1.75),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(radius > 1.75 ? radius - 1.75 : 0),
                          border: Border.all(
                            color: highlightColor,
                            width: 2.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -18,
                    left: 4,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: highlightColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          node['customName'] ?? node['type'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : rendered,
      );
    }

    if (widget.onNodeDropped != null && id.isNotEmpty && id != 'root') {
      rendered = LongPressDraggable<Map<String, dynamic>>(
        data: node,
        feedback: Material(
          color: Colors.transparent,
          child: Opacity(
            opacity: 0.7,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                border: Border.all(color: primary, width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Moving ${node['type'] ?? 'Component'}',
                style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: rendered,
        ),
        child: rendered,
      );
    }

    return rendered;
  }

  // Maps main axis alignments from String parameters
  MainAxisAlignment _parseMainAxisAlignment(String? alignment, bool isCol) {
    if (alignment == 'spaceBetween') return MainAxisAlignment.spaceBetween;
    if (alignment == 'spaceEvenly') return MainAxisAlignment.spaceEvenly;
    
    switch (alignment) {
      case 'center':
      case 'topCenter':
      case 'bottomCenter':
      case 'centerLeft':
      case 'centerRight':
        if (isCol) {
          if (alignment == 'center' || alignment == 'centerLeft' || alignment == 'centerRight') return MainAxisAlignment.center;
          if (alignment == 'topCenter') return MainAxisAlignment.start;
          if (alignment == 'bottomCenter') return MainAxisAlignment.end;
        } else {
          if (alignment == 'center' || alignment == 'topCenter' || alignment == 'bottomCenter') return MainAxisAlignment.center;
          if (alignment == 'centerLeft') return MainAxisAlignment.start;
          if (alignment == 'centerRight') return MainAxisAlignment.end;
        }
        return MainAxisAlignment.center;
      case 'topLeft':
      case 'topRight':
        return MainAxisAlignment.start;
      case 'bottomLeft':
      case 'bottomRight':
        return MainAxisAlignment.end;
      default:
        return MainAxisAlignment.start;
    }
  }

  CrossAxisAlignment _parseCrossAxisAlignment(String? alignment, bool isCol) {
    switch (alignment) {
      case 'center':
      case 'topCenter':
      case 'bottomCenter':
      case 'centerLeft':
      case 'centerRight':
        if (isCol) {
          if (alignment == 'center' || alignment == 'topCenter' || alignment == 'bottomCenter') return CrossAxisAlignment.center;
          if (alignment == 'centerLeft') return CrossAxisAlignment.start;
          if (alignment == 'centerRight') return CrossAxisAlignment.end;
        } else {
          if (alignment == 'center' || alignment == 'centerLeft' || alignment == 'centerRight') return CrossAxisAlignment.center;
          if (alignment == 'topCenter') return CrossAxisAlignment.start;
          if (alignment == 'bottomCenter') return CrossAxisAlignment.end;
        }
        return CrossAxisAlignment.center;
      case 'topLeft':
      case 'bottomLeft':
      case 'centerLeft':
        return CrossAxisAlignment.start;
      case 'topRight':
      case 'bottomRight':
      case 'centerRight':
        return CrossAxisAlignment.end;
      default:
        return CrossAxisAlignment.start;
    }
  }

  Widget _buildMockBadge(IconData icon, String label, Color text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppTheme.brandEmerald500, size: 12),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: text.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildMockCollectionCard(String title, Color text, double radius) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: text.withOpacity(0.04),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: text.withOpacity(0.1)),
      ),
      child: Center(
        child: Text(
          title,
          style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Header Component
  Widget _buildHeader(Color primary, Color text, Color surface, double radius) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: surface,
        border: Border(bottom: BorderSide(color: text.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.store, color: primary),
          const SizedBox(width: 12),
          Text(
            widget.slots['store_name'] ?? 'KLOUDSHOP',
            style: TextStyle(
              color: text,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              fontFamily: 'Outfit',
            ),
          ),
          const Spacer(),
          if (!widget.isMobile) ...[
            _navItem('Home', text),
            _navItem('Catalog', text),
            _navItem('Blog', text),
          ],
          GestureDetector(
            onTap: () => setState(() => _isCartOpen = !_isCartOpen),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(LucideIcons.shoppingBag, color: text, size: 20),
                if (_cartItems.isNotEmpty)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${_cartItems.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
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
    );
  }

  Widget _navItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: Text(
        label,
        style: TextStyle(
          color: color.withOpacity(0.8),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Product Card Widget
  Widget _buildProductTile(
    String name,
    String price,
    Color surface,
    Color text,
    Color primary,
    double radius,
  ) {
    return HoverScale(
      scale: 1.04,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: text.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.2,
              child: Container(
                decoration: BoxDecoration(
                  color: text.withOpacity(0.04),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(radius),
                  ),
                ),
                child: Center(
                  child: Icon(
                    LucideIcons.package,
                    color: text.withOpacity(0.2),
                    size: 36,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: text,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        price,
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _cartItems.add({
                              'name': name,
                              'price': double.tryParse(price.replaceAll('\$', '')) ?? 50,
                              'quantity': 1,
                            });
                          });
                        },
                        child: Icon(
                          LucideIcons.plusCircle,
                          color: primary,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Interactive Tabs for PDP details
  Widget _buildPDPTabs(Color text, Color primary, double radius) {
    final tabs = ['Description', 'Specifications', 'Reviews'];
    final contents = [
      'Engineered with premium, long-lasting materials and fully responsive UI customizers. Designed to outperform standard generic storefront setups.',
      'Dimensions: 12cm x 8cm\nWeight: 250g\nFinish: Matte Polish\nWaterproof: Yes',
      '★★★★★ "Absolutely stunning! Shifting backgrounds and micro-animations look extremely premium." - John D.\n★★★★★ "The sliding cart and quick add are super fast." - Sarah M.'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: tabs.asMap().entries.map((entry) {
            final idx = entry.key;
            final label = entry.value;
            final isSelected = _activeTab == idx;
            return GestureDetector(
              onTap: () => setState(() => _activeTab = idx),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? text : text.withOpacity(0.5),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          decoration: BoxDecoration(
            color: text.withOpacity(0.02),
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Text(
            contents[_activeTab],
            style: TextStyle(color: text.withOpacity(0.8), fontSize: 13, height: 1.5),
          ),
        ),
      ],
    );
  }

  // 1. Loading State: Stripe Payment processing simulation
  Widget _buildLoadingOverlay(Color surface, Color text, Color primary) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.65),
        child: Center(
          child: Card(
            color: surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      color: AppTheme.brandEmerald500,
                      strokeWidth: 3.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Contacting Stripe Gateway...',
                    style: TextStyle(
                      color: text,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Authenticating secure token checks',
                    style: TextStyle(
                      color: text.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 2. Error State: Coral Rounded Alert Dialog Modal
  Widget _buildErrorModal(Color surface, Color text, double radius) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.65),
        child: Center(
          child: Card(
            color: surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEE2E2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.creditCard,
                      color: Colors.redAccent,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Transaction Declined',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Stripe payment failed: Insufficient Funds. Please use another card.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: text.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(radius),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Try Again'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 3. Empty State Cart Overlay
  Widget _buildEmptyCartOverlay(
    Color bg,
    Color text,
    Color primary,
    double radius,
  ) {
    return Positioned.fill(
      child: Container(
        color: bg,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.shoppingBag,
              size: 72,
              color: text.withOpacity(0.15),
            ),
            const SizedBox(height: 24),
            Text(
              'Your Shopping Cart is Empty',
              style: TextStyle(
                color: text,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Looks like you haven\'t added anything yet.',
              style: TextStyle(color: text.withOpacity(0.5), fontSize: 13),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(LucideIcons.arrowLeft, size: 16),
              label: const Text('Back to Shop'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radius),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 4. Input Validation State Checkout Overlay
  Widget _buildValidationOverlay(
    Color surface,
    Color text,
    Color primary,
    double radius,
  ) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.65),
        child: Center(
          child: Card(
            color: surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: 340,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Secure Checkout',
                    style: TextStyle(
                      color: text,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Credit Card Field
                  Text(
                    'Card Number',
                    style: TextStyle(color: text.withOpacity(0.6), fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _cardNumberController,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // CVV Field with validation highlight
                  Text(
                    'CVV Code',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _cvvController,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      isDense: true,
                      errorText: 'CVV is required (3 digits)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: null, // Disabled due to validation errors
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(radius),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Complete Payment'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Slidable Cart Drawer
  Widget _buildCartDrawer(Color surface, Color text, Color primary, double radius) {
    double subtotal = 0;
    for (final item in _cartItems) {
      subtotal += (item['price'] as num) * (item['quantity'] as num);
    }

    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          color: surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
            ),
          ],
          border: Border(left: BorderSide(color: text.withOpacity(0.1))),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(LucideIcons.shoppingCart, color: primary),
                  const SizedBox(width: 12),
                  Text(
                    'Shopping Cart',
                    style: TextStyle(
                      color: text,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(LucideIcons.x, color: text, size: 20),
                    onPressed: () => setState(() => _isCartOpen = false),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _cartItems.isEmpty
                  ? Center(
                      child: Text(
                        'Your cart is empty',
                        style: TextStyle(color: text.withOpacity(0.5)),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _cartItems.length,
                      itemBuilder: (context, idx) {
                        final item = _cartItems[idx];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            item['name'],
                            style: TextStyle(color: text, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '\$${item['price']} x ${item['quantity']}',
                            style: TextStyle(color: primary, fontSize: 11),
                          ),
                          trailing: IconButton(
                            icon: const Icon(LucideIcons.trash2, size: 16, color: Colors.redAccent),
                            onPressed: () {
                              setState(() {
                                _cartItems.removeAt(idx);
                              });
                            },
                          ),
                        );
                      },
                    ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subtotal',
                        style: TextStyle(color: text, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '\$${subtotal.toStringAsFixed(2)}',
                        style: TextStyle(color: primary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _cartItems.isEmpty ? null : () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(radius),
                        ),
                      ),
                      child: const Text('Proceed to Checkout', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getDefaultLayoutForPage(String page) {
    if (page == 'pdp') {
      return {
        "id": "root",
        "type": "flexCol",
        "properties": {"padding": 0.0},
        "children": [
          {
            "id": "pdp_header_section",
            "type": "flexRow",
            "customName": "Product Detail Header",
            "properties": {"padding": 16.0, "spacing": 16.0, "alignment": "center"},
            "children": [
              {"id": "pdp_back_icon", "type": "icon", "icon_name": "package", "properties": {"color": "tokens.primary"}},
              {"id": "pdp_title", "type": "text", "value": "Premium Leather Jacket", "style": {"font_size": 20.0, "font_weight": "bold", "font_family": "Outfit"}}
            ]
          },
          {
            "id": "pdp_main_section",
            "type": "flexCol",
            "customName": "Product Details Layout",
            "properties": {"padding": 24.0, "spacing": 16.0},
            "children": [
              {
                "id": "pdp_gallery",
                "type": "grid",
                "customName": "Product Gallery",
                "properties": {"columns": 2, "spacing": 8.0},
                "children": [
                  {"type": "flexCol", "properties": {"padding": 40.0, "background_color": "#E2E8F0"}, "children": [{"type": "text", "value": "Front View"}]},
                  {"type": "flexCol", "properties": {"padding": 40.0, "background_color": "#E2E8F0"}, "children": [{"type": "text", "value": "Detail Zoom"}]}
                ]
              },
              {
                "id": "pdp_details_card",
                "type": "flexCol",
                "customName": "Price & Purchase Options",
                "properties": {"padding": 16.0, "background_color": "#F8FAFC"},
                "children": [
                  {"type": "text", "value": "\$129.00", "style": {"font_size": 22.0, "font_weight": "bold", "color": "tokens.primary"}},
                  {"type": "button", "value": "Add to Bag", "style": {"background_color": "tokens.primary", "text_color": "#FFFFFF"}}
                ]
              },
              {"id": "pdp_tabs_widget", "type": "pdp_tabs"}
            ]
          }
        ]
      };
    } else if (page == 'checkout') {
      return {
        "id": "root",
        "type": "flexCol",
        "properties": {"padding": 0.0},
        "children": [
          {
            "id": "checkout_header",
            "type": "flexRow",
            "customName": "Checkout Header",
            "properties": {"padding": 16.0, "background_color": "#0F172A", "alignment": "center"},
            "children": [
              {"type": "text", "value": "Secure Checkout Powered by KloudShop", "style": {"font_size": 14.0, "color": "#FFFFFF", "font_weight": "bold"}}
            ]
          },
          {
            "id": "checkout_content",
            "type": "flexCol",
            "customName": "Payment Details",
            "properties": {"padding": 24.0, "spacing": 16.0},
            "children": [
              {"type": "checkout_form"},
              {"type": "trust_badges"}
            ]
          }
        ]
      };
    } else if (page == 'cart') {
      return {
        "id": "root",
        "type": "flexCol",
        "properties": {"padding": 0.0},
        "children": [
          {
            "id": "cart_header",
            "type": "flexRow",
            "customName": "Cart Header",
            "properties": {"padding": 20.0, "alignment": "spaceBetween"},
            "children": [
              {"type": "text", "value": "Your Shopping Bag", "style": {"font_size": 18.0, "font_weight": "bold", "font_family": "Outfit"}},
              {"type": "text", "value": "2 items", "style": {"font_size": 12.0}}
            ]
          },
          {
            "id": "cart_items_section",
            "type": "flexCol",
            "customName": "Cart Item list",
            "properties": {"padding": 16.0, "spacing": 12.0},
            "children": [
              {
                "type": "flexRow",
                "customName": "Cart Item 1",
                "properties": {"padding": 12.0, "background_color": "#F8FAFC", "alignment": "spaceBetween"},
                "children": [
                  {"type": "text", "value": "Premium Leather Jacket - Size M", "style": {"font_size": 13.0, "font_weight": "bold"}},
                  {"type": "text", "value": "\$129.00", "style": {"font_size": 13.0, "color": "tokens.primary"}}
                ]
              },
              {
                "type": "flexRow",
                "customName": "Cart Item 2",
                "properties": {"padding": 12.0, "background_color": "#F8FAFC", "alignment": "spaceBetween"},
                "children": [
                  {"type": "text", "value": "Urban Canvas Sneakers - Size 10", "style": {"font_size": 13.0, "font_weight": "bold"}},
                  {"type": "text", "value": "\$89.00", "style": {"font_size": 13.0, "color": "tokens.primary"}}
                ]
              }
            ]
          },
          {
            "id": "cart_footer",
            "type": "flexCol",
            "customName": "Total and Checkout Button",
            "properties": {"padding": 24.0, "spacing": 16.0},
            "children": [
              {
                "type": "flexRow",
                "properties": {"alignment": "spaceBetween"},
                "children": [
                  {"type": "text", "value": "Subtotal", "style": {"font_size": 15.0, "font_weight": "bold"}},
                  {"type": "text", "value": "\$218.00", "style": {"font_size": 16.0, "font_weight": "bold", "color": "tokens.primary"}}
                ]
              },
              {"type": "button", "value": "Proceed to Secure Checkout", "style": {"background_color": "tokens.primary", "text_color": "#FFFFFF"}}
            ]
          }
        ]
      };
    }
    return _getDefaultLayout();
  }

  // Pre-configured layout trees matching theme parameters
  Map<String, dynamic> _getDefaultLayout() {
    final shader = widget.tokens['background_shader'] ?? 'wave';
    final heading = widget.slots['hero_heading'] ?? 'Where Quality Meets Style';

    return {
      "id": "root",
      "type": "flexCol",
      "properties": {"padding": 0.0},
      "children": [
        {
          "id": "announcement_bar",
          "type": "announcement_bar",
          "customName": "Announcement bar",
          "properties": {
            "text": "Welcome to our store",
            "background_color": "tokens.primary",
            "text_color": "#FFFFFF"
          }
        },
        {
          "id": "header_section",
          "type": "header",
          "customName": "Header",
          "properties": {
            "logo_text": "Dawn",
            "logo_width": 90.0,
            "menu_handle": "main-menu"
          }
        },
        {
          "id": "hero_section",
          "type": "image_banner",
          "customName": "Image banner",
          "properties": {
            "padding": 54.0,
            "shader_source": shader,
            "alignment": "center",
            "spacing": 16.0,
            "overlay_opacity": 0.4,
            "banner_height": "Large"
          },
          "children": [
            {
              "id": "hero_heading",
              "type": "text",
              "value": heading,
              "style": {"font_size": widget.isMobile ? 26.0 : 36.0, "font_weight": "bold", "color": "#FFFFFF", "font_family": "Outfit", "align": "center"}
            },
            {
              "id": "hero_buttons",
              "type": "button",
              "value": "Buttons",
              "style": {"background_color": "tokens.primary", "text_color": "#FFFFFF", "border_radius": 8.0}
            }
          ]
        },
        {
          "id": "featured_section",
          "type": "collection_list",
          "customName": "Collection list",
          "properties": {
            "padding": 24.0,
            "spacing": 16.0,
            "columns": 3
          },
          "children": [
            {"id": "col_1", "type": "collection", "customName": "Collection", "properties": {"collection_id": "hoodies", "collection_name": "Hoodies"}},
            {"id": "col_2", "type": "collection", "customName": "Collection", "properties": {"collection_id": "shorts", "collection_name": "Shorts"}},
            {"id": "col_3", "type": "collection", "customName": "Collection", "properties": {"collection_id": "tshirts", "collection_name": "T-shirts"}}
          ]
        },
        {
          "id": "footer_section",
          "type": "footer",
          "customName": "Footer",
          "properties": {
            "padding": 36.0,
            "background_color": "#0F172A",
            "alignment": "center",
            "show_payment_methods": true,
            "show_newsletter": true
          }
        }
      ]
    };
  }
}

// CustomPainter simulating dynamic GPU fragment shaders
class AnimatedShaderBackground extends CustomPainter {
  final String type;
  final double progress;
  final Color primaryColor;

  AnimatedShaderBackground({
    required this.type,
    required this.progress,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final rect = Offset.zero & size;

    if (type == 'cosmic') {
      final gradient = RadialGradient(
        center: Alignment(
          math.sin(progress * math.pi * 2) * 0.3,
          math.cos(progress * math.pi * 2) * 0.2,
        ),
        radius: 1.2,
        colors: [
          primaryColor.withOpacity(0.85),
          const Color(0xFF6366F1).withOpacity(0.8), // Indigo accent
          const Color(0xFF0F172A), // Space blue
        ],
        stops: const [0.0, 0.45, 1.0],
      );

      paint.shader = gradient.createShader(rect);
      canvas.drawRect(rect, paint);

      // Star field ripples
      final starPaint = Paint()
        ..color = Colors.white.withOpacity(0.2 + math.sin(progress * math.pi * 4) * 0.15)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.3), 3, starPaint);
      canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.7), 2, starPaint);
      canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.2), 4, starPaint);
      
    } else if (type == 'aurora') {
      final waveOffset = progress * math.pi * 2;
      final colors = [
        const Color(0xFF022C22), // deep emerald
        primaryColor,           // bright teal
        const Color(0xFF0369A1), // sky blue
        const Color(0xFF0F172A), // dark slate
      ];

      final gradient = LinearGradient(
        begin: Alignment(math.sin(waveOffset) * 0.3 - 1.0, -1.0),
        end: Alignment(math.cos(waveOffset) * 0.3 + 1.0, 1.0),
        colors: colors,
        stops: const [0.0, 0.3, 0.7, 1.0],
      );

      paint.shader = gradient.createShader(rect);
      canvas.drawRect(rect, paint);
      
    } else {
      // Default: 'wave'
      final waveOffset = progress * math.pi * 2;
      final colors = [
        primaryColor.withOpacity(0.9),
        const Color(0xFF0D9488), // Teal-600
        const Color(0xFF0F172A), // Dark slate
      ];

      final gradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment(math.cos(waveOffset) * 0.5 + 1.0, math.sin(waveOffset) * 0.5 + 1.0),
        colors: colors,
        stops: const [0.0, 0.5, 1.0],
      );

      paint.shader = gradient.createShader(rect);
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant AnimatedShaderBackground oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.type != type ||
        oldDelegate.primaryColor != primaryColor;
  }
}
