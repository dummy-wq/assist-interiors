import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'quick_fade_dropdown.dart';

/// A dropdown selector built on [QuickFadeDropdown] that appends a
/// `'Custom...'` option to static [options] lists, revealing an inline
/// text field so the user can enter any custom value.
class CustomEntryDropdown extends StatefulWidget {
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final InputDecoration? decoration;
  final TextStyle? style;
  final BorderRadius? borderRadius;
  final String customOptionLabel;
  final String customFieldLabel;
  final String customFieldHint;
  final Widget Function(String option)? itemLabelBuilder;

  const CustomEntryDropdown({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.decoration,
    this.style,
    this.borderRadius,
    this.customOptionLabel = 'Custom...',
    this.customFieldLabel = 'Custom Entry',
    this.customFieldHint = 'Type custom value...',
    this.itemLabelBuilder,
  });

  @override
  State<CustomEntryDropdown> createState() => _CustomEntryDropdownState();
}

class _CustomEntryDropdownState extends State<CustomEntryDropdown> {
  static const String _customSentinel = '__assist_custom_entry__';

  late final TextEditingController _customController;
  bool _isCustomMode = false;

  @override
  void initState() {
    super.initState();
    final matchesPreset = widget.options.contains(widget.value);
    _isCustomMode = !matchesPreset && widget.value.isNotEmpty;
    _customController = TextEditingController(
      text: _isCustomMode ? widget.value : '',
    );
  }

  @override
  void didUpdateWidget(covariant CustomEntryDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (widget.options.contains(widget.value)) {
        _isCustomMode = false;
      } else if (!_isCustomMode && widget.value.isNotEmpty) {
        _isCustomMode = true;
        _customController.text = widget.value;
      }
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dropdownValue = _isCustomMode
        ? _customSentinel
        : (widget.options.contains(widget.value)
            ? widget.value
            : (widget.options.isNotEmpty
                ? widget.options.first
                : _customSentinel));

    final items = <DropdownMenuItem<String>>[
      for (final option in widget.options)
        DropdownMenuItem<String>(
          value: option,
          child: widget.itemLabelBuilder != null
              ? widget.itemLabelBuilder!(option)
              : Text(
                  option,
                  overflow: TextOverflow.ellipsis,
                  style: widget.style,
                ),
        ),
      DropdownMenuItem<String>(
        value: _customSentinel,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.edit_outlined,
              size: 14,
              color: AppColors.brandPeach,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                widget.customOptionLabel,
                overflow: TextOverflow.ellipsis,
                style: (widget.style ?? const TextStyle()).copyWith(
                  color: AppColors.brandPeach,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QuickFadeDropdown<String>(
          value: dropdownValue,
          isExpanded: true,
          decoration: widget.decoration,
          borderRadius: widget.borderRadius,
          style: widget.style,
          items: items,
          onChanged: (val) {
            if (val == null) return;
            if (val == _customSentinel) {
              setState(() => _isCustomMode = true);
              final currentCustom = _customController.text.trim();
              if (currentCustom.isNotEmpty) {
                widget.onChanged(currentCustom);
              }
            } else {
              setState(() => _isCustomMode = false);
              widget.onChanged(val);
            }
          },
        ),
        if (_isCustomMode) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _customController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              label: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(widget.customFieldLabel),
              ),
              hintText: widget.customFieldHint,
              isDense: true,
              prefixIcon: const Icon(Icons.edit_note_rounded, size: 18),
              filled: true,
              fillColor: isDark
                  ? AppColors.darkBackground
                  : AppColors.lightBackground,
            ),
            onChanged: (text) {
              final trimmed = text.trim();
              if (trimmed.isNotEmpty) {
                widget.onChanged(trimmed);
              }
            },
          ),
        ],
      ],
    );
  }
}
