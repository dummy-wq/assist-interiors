import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:assist_interiors_dashboard/core/theme/app_colors.dart';

/// A dropdown selector wrapper that:
/// 1. Immediately dismisses the software keyboard and waits for the viewport
///    to restore to regular dimensions BEFORE displaying the dropdown, so the
///    menu comfortably expands downwards rather than being squeezed upwards.
/// 2. Replaces the default Material 300ms "red carpet" expansion animation
///    with a clean, crisp, instantaneous fade-in (100ms) and fade-out (90ms).
/// 3. Maintains full finder compatibility with existing tests targeting
///    [DropdownButtonFormField].
class QuickFadeDropdown<T> extends StatelessWidget {
  final T? value;
  final T? initialValue;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final InputDecoration? decoration;
  final Widget? icon;
  final Color? dropdownColor;
  final bool isExpanded;
  final BorderRadius? borderRadius;
  final double? menuMaxHeight;
  final FormFieldValidator<T>? validator;
  final TextStyle? style;

  const QuickFadeDropdown({
    super.key,
    this.value,
    this.initialValue,
    required this.items,
    required this.onChanged,
    this.decoration,
    this.icon,
    this.dropdownColor,
    this.isExpanded = true,
    this.borderRadius,
    this.menuMaxHeight,
    this.validator,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return _QuickFadeDropdownBody<T>(
      value: value,
      initialValue: initialValue,
      items: items,
      onChanged: onChanged,
      decoration: decoration,
      icon: icon,
      dropdownColor: dropdownColor,
      isExpanded: isExpanded,
      borderRadius: borderRadius,
      menuMaxHeight: menuMaxHeight,
      validator: validator,
      style: style,
    );
  }
}

class _QuickFadeDropdownBody<T> extends StatefulWidget {
  final T? value;
  final T? initialValue;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final InputDecoration? decoration;
  final Widget? icon;
  final Color? dropdownColor;
  final bool isExpanded;
  final BorderRadius? borderRadius;
  final double? menuMaxHeight;
  final FormFieldValidator<T>? validator;
  final TextStyle? style;

  const _QuickFadeDropdownBody({
    super.key,
    this.value,
    this.initialValue,
    required this.items,
    required this.onChanged,
    this.decoration,
    this.icon,
    this.dropdownColor,
    this.isExpanded = true,
    this.borderRadius,
    this.menuMaxHeight,
    this.validator,
    this.style,
  });

  @override
  State<_QuickFadeDropdownBody<T>> createState() =>
      _QuickFadeDropdownBodyState<T>();
}

class _QuickFadeDropdownBodyState<T> extends State<_QuickFadeDropdownBody<T>> {
  bool _isOpen = false;

  Future<void> _handleTap() async {
    if (widget.onChanged == null || widget.items.isEmpty) return;
    if (_isOpen) return;

    // 1. If software keyboard is open or a TextField is focused, dismiss it first
    final currentInsets = MediaQuery.of(context).viewInsets.bottom;
    final primaryFocus = FocusManager.instance.primaryFocus;
    final hasFocus = primaryFocus != null && primaryFocus.hasFocus;
    final keyboardOpen = currentInsets > 0;

    if (hasFocus || keyboardOpen) {
      FocusScope.of(context).unfocus();
      FocusManager.instance.primaryFocus?.unfocus();
      SystemChannels.textInput.invokeMethod('TextInput.hide');

      if (keyboardOpen) {
        // Wait for keyboard dismissal animation to complete and viewport to restore regular height
        await Future.delayed(const Duration(milliseconds: 220));
        if (!mounted) return;
      }
    }

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Rect buttonRect = Rect.fromLTWH(
      offset.dx,
      offset.dy,
      renderBox.size.width,
      renderBox.size.height,
    );

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveValue = widget.value ?? widget.initialValue;

    _isOpen = true;
    try {
      final T? selected = await Navigator.of(context).push<T>(
        _QuickFadePopupRoute<T>(
          buttonRect: buttonRect,
          items: widget.items,
          selectedValue: effectiveValue,
          dropdownColor: widget.dropdownColor,
          borderRadius: widget.borderRadius,
          isDark: isDark,
          menuMaxHeight: widget.menuMaxHeight,
          capturedThemes: InheritedTheme.capture(
            from: context,
            to: Navigator.of(context).context,
          ),
        ),
      );

      if (selected != null && widget.onChanged != null) {
        widget.onChanged!(selected);
      }
    } finally {
      _isOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveValue = widget.value ?? widget.initialValue;

    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        IgnorePointer(
          ignoring: true,
          child: DropdownButtonFormField<T>(
            key: ValueKey<T?>(effectiveValue),
            initialValue: effectiveValue,
            items: widget.items,
            onChanged: widget.onChanged != null ? (_) {} : null,
            decoration: widget.decoration,
            icon:
                widget.icon ??
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.brandPeach,
                ),
            dropdownColor: widget.dropdownColor,
            isExpanded: widget.isExpanded,
            borderRadius: widget.borderRadius,
            validator: widget.validator,
            style: widget.style,
          ),
        ),
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _handleTap,
          ),
        ),
      ],
    );
  }
}

class _QuickFadePopupRoute<T> extends PopupRoute<T> {
  _QuickFadePopupRoute({
    required this.buttonRect,
    required this.items,
    required this.selectedValue,
    required this.dropdownColor,
    required this.borderRadius,
    required this.isDark,
    required this.menuMaxHeight,
    required this.capturedThemes,
  });

  final Rect buttonRect;
  final List<DropdownMenuItem<T>> items;
  final T? selectedValue;
  final Color? dropdownColor;
  final BorderRadius? borderRadius;
  final bool isDark;
  final double? menuMaxHeight;
  final CapturedThemes capturedThemes;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 100);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 90);

  @override
  bool get barrierDismissible => true;

  @override
  Color? get barrierColor => Colors.transparent;

  @override
  String? get barrierLabel => 'Dismiss dropdown';

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
      child: child,
    );
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return capturedThemes.wrap(
      _QuickFadeMenu<T>(
        buttonRect: buttonRect,
        items: items,
        selectedValue: selectedValue,
        dropdownColor: dropdownColor,
        borderRadius: borderRadius,
        isDark: isDark,
        menuMaxHeight: menuMaxHeight,
      ),
    );
  }
}

class _QuickFadeMenu<T> extends StatelessWidget {
  const _QuickFadeMenu({
    required this.buttonRect,
    required this.items,
    required this.selectedValue,
    required this.dropdownColor,
    required this.borderRadius,
    required this.isDark,
    required this.menuMaxHeight,
  });

  final Rect buttonRect;
  final List<DropdownMenuItem<T>> items;
  final T? selectedValue;
  final Color? dropdownColor;
  final BorderRadius? borderRadius;
  final bool isDark;
  final double? menuMaxHeight;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final padding = mediaQuery.padding;

    final double availableHeightBelow =
        screenSize.height - buttonRect.bottom - padding.bottom - 12.0;
    final double availableHeightAbove = buttonRect.top - padding.top - 12.0;

    final double desiredHeight = items.length * 44.0 + 8.0;
    final double maxHeightLimit = menuMaxHeight ?? 360.0;
    final double computedMaxHeight = math.min(desiredHeight, maxHeightLimit);

    final double menuTop;
    final double menuHeight;

    if (availableHeightBelow >= computedMaxHeight) {
      // Comfortably fits downwards
      menuTop = buttonRect.bottom + 4.0;
      menuHeight = computedMaxHeight;
    } else if (availableHeightAbove >= computedMaxHeight) {
      // Doesn't fit downwards, but fits upwards
      menuHeight = computedMaxHeight;
      menuTop = math.max(padding.top + 8.0, buttonRect.top - menuHeight - 4.0);
    } else if (availableHeightBelow >= availableHeightAbove) {
      // More space below than above
      menuTop = buttonRect.bottom + 4.0;
      menuHeight = math.max(80.0, availableHeightBelow);
    } else {
      // More space above than below
      menuHeight = math.max(80.0, availableHeightAbove);
      menuTop = math.max(padding.top + 8.0, buttonRect.top - menuHeight - 4.0);
    }

    final double maxAllowedWidth = screenSize.width - 24.0;
    final double menuWidth = math.min(buttonRect.width, maxAllowedWidth);
    double menuLeft = buttonRect.left;

    if (menuLeft + menuWidth > screenSize.width - 12.0) {
      menuLeft = screenSize.width - 12.0 - menuWidth;
    }
    if (menuLeft < 12.0) {
      menuLeft = 12.0;
    }

    final Color bgColor =
        dropdownColor ?? (isDark ? const Color(0xFF1E212B) : Colors.white);
    final Color borderColor = isDark
        ? const Color(0xFF2C3242)
        : const Color(0xFFE2E8F0);

    return Stack(
      children: [
        Positioned(
          left: menuLeft,
          top: menuTop,
          width: menuWidth,
          child: Material(
            elevation: 8,
            shadowColor: Colors.black.withValues(alpha: isDark ? 0.6 : 0.25),
            color: bgColor,
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius ?? BorderRadius.circular(6.0),
              side: BorderSide(color: borderColor, width: 1.0),
            ),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: menuHeight),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  thickness: 0.5,
                  color: isDark
                      ? const Color(0xFF282D3B)
                      : const Color(0xFFF1F5F9),
                ),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = item.value == selectedValue;

                  return InkWell(
                    onTap: () {
                      Navigator.of(context).pop(item.value);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14.0,
                        vertical: 12.0,
                      ),
                      color: isSelected
                          ? (isDark
                                ? AppColors.brandPeach.withValues(alpha: 0.15)
                                : AppColors.brandPeach.withValues(alpha: 0.10))
                          : Colors.transparent,
                      child: Row(
                        children: [
                          Expanded(child: item.child),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: AppColors.brandPeach,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
