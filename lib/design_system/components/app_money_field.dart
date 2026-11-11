import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/design_system/components/app_text_field.dart';

/// Monetary input field in pt-BR format.
///
/// Accepts decimal input with comma and returns value in cents ([int]).
/// Uses [TextInputType.numberWithOptions] with `decimal: true`.
class AppMoneyField extends StatefulWidget {
  const AppMoneyField({
    super.key,
    this.controller,
    this.initialCents,
    this.onChanged,
    this.onChangedMoney,
    this.label = 'Valor',
    this.hint = '0,00',
    this.errorText,
    this.helperText,
    this.prefixText = 'R\$ ',
    this.enabled = true,
    this.readOnly = false,
    this.focusNode,
    this.autofocus = false,
    this.validator,
    this.textInputAction,
  });

  final TextEditingController? controller;
  final int? initialCents;
  final ValueChanged<int>? onChanged;
  final ValueChanged<Money>? onChangedMoney;
  final String? label;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final String? prefixText;
  final bool enabled;
  final bool readOnly;
  final FocusNode? focusNode;
  final bool autofocus;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;

  @override
  State<AppMoneyField> createState() => _AppMoneyFieldState();
}

class _AppMoneyFieldState extends State<AppMoneyField> {
  late TextEditingController _controller;
  bool _internalController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _internalController = true;
      final initialText = widget.initialCents != null
          ? _formatCents(widget.initialCents!)
          : '';
      _controller = TextEditingController(text: initialText);
    }
  }

  @override
  void dispose() {
    if (_internalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  static String _formatCents(int cents) {
    final abs = cents.abs();
    final reais = abs ~/ 100;
    final centavos = abs % 100;
    final sign = cents < 0 ? '-' : '';
    return '$sign$reais,${centavos.toString().padLeft(2, '0')}';
  }

  static int _parseCents(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 0;

    // If user typed dot with 1 or 2 decimal places (e.g., 12.34) without comma,
    // normalize to comma for compatibility with keyboards that only have a dot.
    String normalized = trimmed;
    if (RegExp(r'^\d+\.\d{1,2}$').hasMatch(trimmed)) {
      normalized = trimmed.replaceAll('.', ',');
    }

    final parsed = Money.tryParsePtBr(normalized);
    if (parsed != null) return parsed.cents;

    return 0;
  }

  void _handleChanged(String value) {
    final cents = _parseCents(value);
    widget.onChanged?.call(cents);
    widget.onChangedMoney?.call(Money(cents));
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: _controller,
      label: widget.label,
      hint: widget.hint,
      errorText: widget.errorText,
      helperText: widget.helperText,
      prefixText: widget.prefixText,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      validator: widget.validator,
      textInputAction: widget.textInputAction,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
      onChanged: _handleChanged,
    );
  }
}
