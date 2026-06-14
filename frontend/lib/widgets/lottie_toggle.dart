import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LottieToggle extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  // Global static duration variable so we change it once and it gets applied everywhere.
  static const Duration defaultDuration = Duration(milliseconds: 20000);

  const LottieToggle({super.key, required this.value, this.onChanged});

  @override
  State<LottieToggle> createState() => _LottieToggleState();
}

class _LottieToggleState extends State<LottieToggle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: LottieToggle.defaultDuration * 2,
    );
    _controller.value = widget.value ? 0.5 : 0.0;
    _initialized = true;
  }

  @override
  void didUpdateWidget(LottieToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && _initialized) {
      if (widget.value) {
        if (_controller.value >= 0.9) {
          _controller.value = 0.0;
        }
        _controller.animateTo(0.5, duration: LottieToggle.defaultDuration);
      } else {
        if (_controller.value <= 0.1) {
          _controller.value = 0.5;
        }
        _controller.animateTo(1.0, duration: LottieToggle.defaultDuration);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (widget.onChanged == null) return;
    if (_controller.isAnimating) return;

    final bool nextVal = !widget.value;
    if (nextVal) {
      if (_controller.value >= 0.9) {
        _controller.value = 0.0;
      }
      _controller.animateTo(0.5, duration: LottieToggle.defaultDuration).then((
        _,
      ) {
        if (mounted) {
          widget.onChanged!(true);
        }
      });
    } else {
      if (_controller.value <= 0.1) {
        _controller.value = 0.5;
      }
      _controller.animateTo(1.0, duration: LottieToggle.defaultDuration).then((
        _,
      ) {
        if (mounted) {
          widget.onChanged!(false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool disabled = widget.onChanged == null;
    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: _toggle,
        child: MouseRegion(
          cursor: disabled
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click,
          child: SizedBox(
            width: 66,
            height: 30,
            child: ClipRect(
              child: OverflowBox(
                minWidth: 84,
                maxWidth: 84,
                minHeight: 63,
                maxHeight: 63,
                child: Lottie.asset(
                  'assets/68be063a-1151-11ee-9102-1b5da2d32f76.json',
                  controller: _controller,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LottieSwitchListTile extends StatelessWidget {
  final Widget? title;
  final Widget? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool dense;
  final EdgeInsetsGeometry? contentPadding;

  const LottieSwitchListTile({
    super.key,
    this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
    this.dense = false,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding:
            contentPadding ??
            const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) ...[
                    DefaultTextStyle(
                      style:
                          Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ) ??
                          const TextStyle(),
                      child: title!,
                    ),
                  ],
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    DefaultTextStyle(
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).hintColor,
                          ) ??
                          const TextStyle(),
                      child: subtitle!,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            LottieToggle(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
