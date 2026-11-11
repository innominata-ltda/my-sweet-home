part of '../ocr_review_screen.dart';

extension _OcrReviewDialogs on _OcrReviewScreenState {
  Future<void> _showEditHeaderDialog(BuildContext context) async {
    final storeNameCtrl = TextEditingController(text: _draft.store.name ?? '');
    final cnpjCtrl = TextEditingController(
      text: _draft.store.cnpj ?? _draft.store.rawCnpj ?? '',
    );
    final dateCtrl = TextEditingController(
      text: _draft.purchasedAt != null
          ? _formatDateTime(_draft.purchasedAt!)
          : '',
    );
    final accessKeyCtrl = TextEditingController(text: _draft.accessKey ?? '');

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Editar cabeçalho'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: storeNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Estabelecimento *',
                    hintText: 'Nome do supermercado ou loja',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Informe o nome do estabelecimento'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: cnpjCtrl,
                  decoration: const InputDecoration(
                    labelText: 'CNPJ (opcional)',
                    hintText: '00.000.000/0000-00',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: dateCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Data/Hora (dd/MM/yyyy HH:mm) *',
                    hintText: '21/09/2026 14:30',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Informe a data da compra';
                    }
                    if (_tryParseDateTime(v.trim()) == null) {
                      return 'Formato inválido (ex: 21/09/2026 14:30)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: accessKeyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Chave da NFC-e (opcional)',
                    hintText: '44 dígitos da nota fiscal',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(dialogCtx).pop(true);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (result == true) {
      final rawCnpj = cnpjCtrl.text.trim();
      final cleanCnpj = rawCnpj.replaceAll(RegExp(r'[^0-9]'), '');
      final isValidCnpj = HeaderParser.validateCnpjDigits(cleanCnpj);

      final dateText = dateCtrl.text.trim();
      final parsedDate = dateText.isNotEmpty
          ? _tryParseDateTime(dateText)
          : null;
      final clearDate = dateText.isEmpty && _draft.purchasedAt != null;
      final accessKeyText = accessKeyCtrl.text.trim();

      _updateState(() {
        _draft = _draft.copyWith(
          store: _draft.store.copyWith(
            name: storeNameCtrl.text.trim().isNotEmpty
                ? storeNameCtrl.text.trim()
                : null,
            cnpj: cleanCnpj.isNotEmpty ? cleanCnpj : null,
            rawCnpj: rawCnpj.isNotEmpty ? rawCnpj : null,
            isCnpjValid: isValidCnpj,
          ),
          purchasedAt: parsedDate ?? _draft.purchasedAt,
          clearPurchasedAt: clearDate,
          accessKey: accessKeyText.isNotEmpty ? accessKeyText : null,
          clearAccessKey: accessKeyText.isEmpty,
        );
      });
    }
  }

  Future<void> _showEditTotalsDialog(BuildContext context) async {
    final subtotalCtrl = TextEditingController(
      text: _draft.subtotal != null
          ? _draft.subtotal!.formatPtBr().replaceAll('R\$ ', '')
          : '',
    );
    final discountCtrl = TextEditingController(
      text: _draft.discount != null
          ? _draft.discount!.formatPtBr().replaceAll('R\$ ', '')
          : '',
    );
    final totalCtrl = TextEditingController(
      text: _draft.total != null
          ? _draft.total!.formatPtBr().replaceAll('R\$ ', '')
          : '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Editar totais'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: subtotalCtrl,
                decoration: const InputDecoration(labelText: 'Subtotal (R\$)'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: discountCtrl,
                decoration: const InputDecoration(labelText: 'Desconto (R\$)'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: totalCtrl,
                decoration: const InputDecoration(
                  labelText: 'Total lido (R\$)',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (result == true) {
      final subtotalText = subtotalCtrl.text.trim();
      final discountText = discountCtrl.text.trim();
      final totalText = totalCtrl.text.trim();

      final subtotal = Money.tryParsePtBr(subtotalText);
      final discount = Money.tryParsePtBr(discountText);
      final total = Money.tryParsePtBr(totalText);

      _updateState(() {
        _draft = _draft.copyWith(
          subtotal: subtotal,
          clearSubtotal: subtotalText.isEmpty,
          discount: discount,
          clearDiscount: discountText.isEmpty,
          total: total,
          clearTotal: totalText.isEmpty,
        );
      });
    }
  }

  Future<ProductMatch?> _showCreateNewProductDialog(
    BuildContext context, {
    String? initialName,
    Unit? initialUnit,
    String? initialCategory,
  }) async {
    final nameCtrl = TextEditingController(text: initialName ?? '');
    final categoryCtrl = TextEditingController(
      text: (initialCategory != null && initialCategory.isNotEmpty)
          ? initialCategory
          : 'Alimentos',
    );
    final aliasesCtrl = TextEditingController();
    Unit selectedUnit = initialUnit ?? Unit.un;
    final formKey = GlobalKey<FormState>();

    final createdMatch = await showDialog<ProductMatch>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Cadastrar novo produto'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nome canônico *',
                          hintText: 'Ex: Leite Integral 1L',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Informe o nome canônico'
                            : null,
                        autofocus: true,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: categoryCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Categoria *',
                          hintText: 'Ex: Alimentos, Limpeza, etc.',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Informe a categoria'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<Unit>(
                        initialValue: selectedUnit,
                        decoration: const InputDecoration(
                          labelText: 'Unidade padrão *',
                        ),
                        items: Unit.values.map((u) {
                          return DropdownMenuItem(
                            value: u,
                            child: Text(u.name),
                          );
                        }).toList(),
                        onChanged: (u) {
                          if (u != null) {
                            setDialogState(() => selectedUnit = u);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: aliasesCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Sinônimos / Apelidos (opcional)',
                          hintText: 'Separados por vírgula',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      final canonicalName = nameCtrl.text.trim();
                      final cleanSlug = canonicalName.toLowerCase().replaceAll(
                        RegExp(r'[^a-z0-9]'),
                        '-',
                      );
                      final categoryText = categoryCtrl.text.trim();
                      final epochZero = DateTime.fromMillisecondsSinceEpoch(
                        0,
                        isUtc: true,
                      );
                      final newProd = Product(
                        id: 'prod-custom-${cleanSlug.isEmpty ? 'item' : cleanSlug}-${canonicalName.hashCode.abs()}',
                        canonicalName: canonicalName,
                        categoryId: categoryText.isNotEmpty
                            ? categoryText
                            : 'alimentos',
                        defaultUnit: selectedUnit,
                        createdAt: epochZero,
                        updatedAt: epochZero,
                      );

                      _updateState(() {
                        if (!_availableProducts.any(
                          (p) => p.id == newProd.id,
                        )) {
                          _availableProducts.add(newProd);
                        }
                      });

                      Navigator.of(dialogCtx).pop(
                        ProductMatch(
                          product: newProd,
                          origin: const ExactUserAlias(),
                          score: 1.0,
                        ),
                      );
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

    return createdMatch;
  }

  Future<ProductMatch?> _showProductSelectionDialog(
    BuildContext context, [
    String initialQuery = '',
  ]) async {
    final queryCtrl = TextEditingController(text: initialQuery);

    return showDialog<ProductMatch>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final query = queryCtrl.text.trim().toLowerCase();
            final normalizedQuery = normalizeProductName(query);
            final filtered = query.isEmpty
                ? _availableProducts
                : _availableProducts.where((p) {
                    if (p.canonicalName.toLowerCase().contains(query)) {
                      return true;
                    }
                    if (normalizedQuery.isNotEmpty &&
                        normalizeProductName(p.canonicalName)
                            .contains(normalizedQuery)) {
                      return true;
                    }
                    return false;
                  }).toList();

            return AlertDialog(
              title: const Text('Vincular produto'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: queryCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nome do produto',
                        hintText: 'Digite o nome do produto',
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      dense: true,
                      leading: const Icon(AppIcons.add, color: Colors.blue),
                      title: Text(
                        queryCtrl.text.trim().isNotEmpty
                            ? 'Cadastrar "${queryCtrl.text.trim()}" como novo produto'
                            : 'Cadastrar novo produto',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onTap: () async {
                        final created = await _showCreateNewProductDialog(
                          dialogCtx,
                          initialName: queryCtrl.text.trim(),
                        );
                        if (created != null && dialogCtx.mounted) {
                          Navigator.of(dialogCtx).pop(created);
                        }
                      },
                    ),
                    const Divider(),
                    if (filtered.isNotEmpty) ...[
                      const Text(
                        'Produtos sugeridos:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...filtered.map(
                        (p) => ListTile(
                          dense: true,
                          title: Text(p.canonicalName),
                          subtitle: Text(
                            'Categoria: ${p.categoryId} | Unidade: ${p.defaultUnit.name}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          onTap: () {
                            Navigator.of(dialogCtx).pop(
                              ProductMatch(
                                product: p,
                                origin: const ExactUserAlias(),
                                score: 1.0,
                              ),
                            );
                          },
                        ),
                      ),
                    ] else ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Nenhum produto existente encontrado com esse nome.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Cancelar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleRegisterNewProductForItem(int index) async {
    final item = _draft.items[index];
    final match = await _showCreateNewProductDialog(
      context,
      initialName: item.rawDescription,
      initialUnit: item.quantity.unit,
    );
    if (match != null) {
      _updateState(() {
        final updatedList = List<ReceiptItemDraft>.from(_draft.items);
        updatedList[index] = item.copyWith(match: match);
        _draft = _draft.copyWith(items: updatedList);
      });
    }
  }

  Future<void> _handleLinkExistingProductForItem(int index) async {
    final item = _draft.items[index];
    final match = await _showProductSelectionDialog(context);
    if (match != null) {
      _updateState(() {
        final updatedList = List<ReceiptItemDraft>.from(_draft.items);
        updatedList[index] = item.copyWith(match: match);
        _draft = _draft.copyWith(items: updatedList);
      });
    }
  }

  Future<void> _showEditItemDialog(
    BuildContext context, {
    ReceiptItemDraft? item,
    int? index,
  }) async {
    final isEditing = item != null;
    final descCtrl = TextEditingController(text: item?.rawDescription ?? '');

    final initialQtyVal = item != null ? item.quantity.displayValue : 1.0;
    final qtyStr = (initialQtyVal % 1 == 0)
        ? initialQtyVal.toInt().toString()
        : initialQtyVal.toStringAsFixed(3).replaceAll('.', ',');
    final qtyCtrl = TextEditingController(text: qtyStr);

    Unit selectedUnit = item?.quantity.unit ?? Unit.un;

    final unitPriceCtrl = TextEditingController(
      text: item?.unitPrice.formatPtBr().replaceAll('R\$ ', '') ?? '0,00',
    );
    final totalPriceCtrl = TextEditingController(
      text: item?.totalPrice.formatPtBr().replaceAll('R\$ ', '') ?? '0,00',
    );

    bool selected = item?.selected ?? true;
    ProductMatch? currentMatch = item?.match;
    bool clearMatch = false;

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final matchedName = clearMatch
                ? 'Nenhum'
                : (currentMatch?.product.canonicalName ?? 'Nenhum');

            return AlertDialog(
              title: Text(isEditing ? 'Editar item' : 'Adicionar item'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: descCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Descrição lida / Nome *',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Informe o nome ou descrição'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: qtyCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Quantidade *',
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Informe a qtd';
                                }
                                final n = double.tryParse(
                                  v.replaceAll(',', '.'),
                                );
                                if (n == null || n <= 0) {
                                  return 'Qtd inválida';
                                }
                                return null;
                              },
                              onChanged: (_) {
                                final qty =
                                    double.tryParse(
                                      qtyCtrl.text.replaceAll(',', '.'),
                                    ) ??
                                    0;
                                final unitP =
                                    Money.tryParsePtBr(unitPriceCtrl.text) ??
                                    Money.zero;
                                if (unitP.cents > 0 && qty > 0) {
                                  final qtyMilli = (qty * 1000).round();
                                  final tot = unitP.timesRatio(qtyMilli, 1000);
                                  totalPriceCtrl.text = tot
                                      .formatPtBr()
                                      .replaceAll('R\$ ', '');
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<Unit>(
                              initialValue: selectedUnit,
                              decoration: const InputDecoration(
                                labelText: 'Unidade *',
                              ),
                              items: Unit.values.map((u) {
                                return DropdownMenuItem(
                                  value: u,
                                  child: Text(u.name),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() => selectedUnit = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: unitPriceCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Preço unitário (R\$) *',
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onChanged: (_) {
                                final qty =
                                    double.tryParse(
                                      qtyCtrl.text.replaceAll(',', '.'),
                                    ) ??
                                    0;
                                final unitP =
                                    Money.tryParsePtBr(unitPriceCtrl.text) ??
                                    Money.zero;
                                if (unitP.cents > 0 && qty > 0) {
                                  final qtyMilli = (qty * 1000).round();
                                  final tot = unitP.timesRatio(qtyMilli, 1000);
                                  totalPriceCtrl.text = tot
                                      .formatPtBr()
                                      .replaceAll('R\$ ', '');
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: totalPriceCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Preço total (R\$) *',
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Informe o valor';
                                }
                                final p = Money.tryParsePtBr(v);
                                if (p == null || p.cents <= 0) {
                                  return 'Valor inválido';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Incluir item na compra'),
                        value: selected,
                        onChanged: (val) {
                          setDialogState(() => selected = val ?? true);
                        },
                      ),
                      const Divider(),
                      const Text(
                        'Produto vinculado:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        matchedName,
                        style: TextStyle(
                          color: clearMatch || currentMatch == null
                              ? Colors.grey.shade700
                              : Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(AppIcons.search, size: 16),
                              label: const Text('Trocar / Vincular'),
                              onPressed: () async {
                                final newMatch =
                                    await _showProductSelectionDialog(
                                      context,
                                      descCtrl.text.trim(),
                                    );
                                if (newMatch != null) {
                                  setDialogState(() {
                                    currentMatch = newMatch;
                                    clearMatch = false;
                                  });
                                }
                              },
                            ),
                          ),
                          if (currentMatch == null || clearMatch) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(AppIcons.add, size: 16),
                                label: const Text('Cadastrar produto'),
                                onPressed: () async {
                                  final createdMatch =
                                      await _showCreateNewProductDialog(
                                        context,
                                        initialName: descCtrl.text.trim(),
                                        initialUnit: selectedUnit,
                                      );
                                  if (createdMatch != null) {
                                    setDialogState(() {
                                      currentMatch = createdMatch;
                                      clearMatch = false;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                          if (currentMatch != null && !clearMatch) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(AppIcons.close, size: 20),
                              tooltip: 'Remover vínculo',
                              onPressed: () {
                                setDialogState(() {
                                  clearMatch = true;
                                  currentMatch = null;
                                });
                              },
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.of(dialogCtx).pop(true);
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

    if (result == true) {
      final rawDesc = descCtrl.text.trim();
      final parsedQtyNum =
          double.tryParse(qtyCtrl.text.replaceAll(',', '.')) ?? 1.0;
      final qtyMilli = (parsedQtyNum * 1000).round();
      final quantity = Quantity(qtyMilli, selectedUnit);

      final unitPrice = Money.tryParsePtBr(unitPriceCtrl.text) ?? Money.zero;
      final parsedTotal = Money.tryParsePtBr(totalPriceCtrl.text);
      final Money totalPrice;
      if (parsedTotal == null ||
          (parsedTotal.cents == 0 && unitPrice.cents > 0)) {
        totalPrice = unitPrice.cents > 0
            ? unitPrice.timesRatio(qtyMilli, 1000)
            : Money.zero;
      } else {
        totalPrice = parsedTotal;
      }

      final updatedItem = ReceiptItemDraft(
        rawDescription: rawDesc.isNotEmpty
            ? rawDesc
            : (item?.rawDescription ?? 'Item sem nome'),
        ean: item?.ean,
        quantity: quantity,
        unitPrice: unitPrice,
        totalPrice: totalPrice,
        confidence: item?.confidence ?? 1.0,
        match: clearMatch ? null : (currentMatch ?? item?.match),
        selected: selected,
      );

      _updateState(() {
        final updatedList = List<ReceiptItemDraft>.from(_draft.items);
        if (index != null && index >= 0 && index < updatedList.length) {
          updatedList[index] = updatedItem;
        } else {
          updatedList.add(updatedItem);
        }
        _draft = _draft.copyWith(items: updatedList);
      });
    }
  }
}
