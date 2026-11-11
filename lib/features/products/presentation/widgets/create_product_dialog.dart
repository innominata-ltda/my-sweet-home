import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Novo Produto'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nome Canônico *',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Informe o nome'
                            : null,
                        autofocus: true,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<Unit>(
                        initialValue: selectedUnit,
                        decoration: const InputDecoration(
                          labelText: 'Unidade Padrão *',
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
                        decoration: const InputDecoration(
                          labelText: 'Apelidos / Sinônimos',
                          hintText: 'Separados por vírgula (opcional)',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancelar'),
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
                                  'Erro ao criar produto',
                            ),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Salvar'),
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
