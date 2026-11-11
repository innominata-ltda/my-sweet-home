import 'package:flutter/material.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';

class ProductSuggestionDialog extends StatelessWidget {
  const ProductSuggestionDialog({
    super.key,
    required this.productName,
    required this.alias,
  });

  final String productName;
  final String alias;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.productSuggestionTitle(productName)),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            l10n.productSuggestionNo,
            semanticsLabel: l10n.productSuggestionNo,
          ),
        ),
        OutlinedButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            'Sim', // The visible text can be shorter, but semantics must be full
            semanticsLabel: l10n.productSuggestionYes(alias, productName),
          ),
        ),
      ],
    );
  }
}
