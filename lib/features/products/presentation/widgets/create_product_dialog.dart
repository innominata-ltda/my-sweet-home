import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/features/products/data/product_repository_provider.dart';
import 'package:my_sweet_home/features/products/domain/product.dart';
import 'package:my_sweet_home/features/products/presentation/providers/product_list_provider.dart';

/// Displays quick product creation dialog with optional alias/synonym registration.
/// Returns created [Product] if operation succeeds, or `null` if cancelled.
Future<Product?> showCreateProductDialog(
  BuildContext context,
  WidgetRef ref, {
  String? initialName,
  Unit? initialUnit,
}) async {
  final nameCtrl = TextEditingController(text: initialName ?? '');
  final aliasesCtrl = TextEditingController();
  Unit selectedUnit = initialUnit ?? Unit.un;
  final formKey = GlobalKey<FormState>();

  try {
    return await showDialog<Product?>(
      context: context,
      builder: (ctx) {
        final l10n =
            Localizations.of<AppLocalizations>(ctx, AppLocalizations) ??
            lookupAppLocalizations(const Locale('pt'));
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: Text(l10n.productNewDialogTitle),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.productCanonicalNameRequiredLabel,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? l10n.productCanonicalNameError
                            : null,
                        autofocus: true,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<Unit>(
                        initialValue: selectedUnit,
                        decoration: InputDecoration(
                          labelText: l10n.productDefaultUnitRequiredLabel,
                        ),
                        items: Unit.values
                            .map(
                              (u) => DropdownMenuItem(
                                value: u,
                                child: Text(u.name),
                              ),
                            )
                            .toList(),
                        onChanged: (u) {
                          if (u != null) {
                            setState(() => selectedUnit = u);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: aliasesCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.productAliasesLabel,
                          hintText: l10n.productAliasesHint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(l10n.commonCancel),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState?.validate() ?? false) {
                      final repo = ref.read(productRepositoryProvider);
                      final newProd = NewProduct(
                        canonicalName: nameCtrl.text.trim(),
                        categoryId: 'cat_food',
                        defaultUnit: selectedUnit,
                      );
                      final result = await repo.create(newProd);
                      if (result.isOk) {
                        final product = result.valueOrNull!;
                        final rawAliases = aliasesCtrl.text.split(',');
                        for (final raw in rawAliases) {
                          final alias = raw.trim();
                          if (alias.isNotEmpty) {
                            await repo.addAlias(
                              product.id,
                              alias,
                              AliasSource.user,
                            );
                          }
                        }
                        ref.invalidate(productListProvider);
                        if (ctx.mounted) Navigator.of(ctx).pop(product);
                      } else if (ctx.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              result.failureOrNull?.toString() ??
                                  l10n.productCreateError,
                            ),
                          ),
                        );
                      }
                    }
                  },
                  child: Text(l10n.commonSave),
                ),
              ],
            );
          },
        );
      },
    );
  } finally {
    nameCtrl.dispose();
    aliasesCtrl.dispose();
  }
}
