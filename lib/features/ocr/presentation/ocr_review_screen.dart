import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/core/text/normalizer.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/features/ocr/domain/header_parser.dart';
import 'package:my_sweet_home/features/ocr/domain/models/receipt_draft.dart';
import 'package:my_sweet_home/features/ocr/domain/models/receipt_item_draft.dart';
import 'package:my_sweet_home/features/ocr/presentation/widgets/ocr_review_item_tile.dart';
import 'package:my_sweet_home/features/products/domain/matcher.dart';
import 'package:my_sweet_home/features/products/domain/product.dart';
import 'package:my_sweet_home/features/ocr/domain/save_receipt_use_case.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_list.dart';

part 'widgets/ocr_review_dialogs.dart';
part 'widgets/ocr_review_cards.dart';

/// Mandatory review screen for receipt read via OCR (RF-044, RF-045, RN-191, RN-193, RN-194, RN-198, RN-201, CA-3.1, CA-3.2, CA-4.1).
///
/// Allows user to inspect and edit store, read items, quantities, units,
/// unit and total values, product links, read confidence, uncheck or add items,
/// resolve total value discrepancies and offer write-off of items on active shopping list before saving purchase.
class OcrReviewScreen extends StatefulWidget {
  final ReceiptDraft draft;
  final ValueChanged<ReceiptDraft>? onSave;
  final void Function(ReceiptDraft draft, SaveOptions options)?
  onSaveWithOptions;
  final VoidCallback? onCancel;
  final List<Product>? availableProducts;
  final List<ShoppingList>? availableShoppingLists;
  final ScrollController? scrollController;

  const OcrReviewScreen({
    super.key,
    required this.draft,
    this.onSave,
    this.onSaveWithOptions,
    this.onCancel,
    this.availableProducts,
    this.availableShoppingLists,
    this.scrollController,
  });

  @override
  State<OcrReviewScreen> createState() => _OcrReviewScreenState();
}

class _OcrReviewScreenState extends State<OcrReviewScreen> {
  static const _scrollCaptureChannel = MethodChannel(
    'br.com.innominata.mysweethome/scroll_capture',
  );

  late ReceiptDraft _draft;
  late List<Product> _availableProducts;
  SemanticsHandle? _semanticsHandle;

  @override
  void initState() {
    super.initState();
    _draft = widget.draft;
    _availableProducts = List<Product>.from(widget.availableProducts ?? []);
    // Ensure Flutter accessibility/semantics tree is active immediately
    // so Android Smart Capture / Scroll Capture recognizes scrollable list.
    _semanticsHandle = WidgetsBinding.instance.ensureSemantics();
    _scrollCaptureChannel.setMethodCallHandler(_handleScrollCaptureCall);
  }

  @override
  void dispose() {
    _scrollCaptureChannel.setMethodCallHandler(null);
    _semanticsHandle?.dispose();
    super.dispose();
  }

  ScrollController? get _activeScrollController {
    if (widget.scrollController != null) return widget.scrollController;
    if (!mounted) return null;
    return PrimaryScrollController.maybeOf(context);
  }

  Future<dynamic> _handleScrollCaptureCall(MethodCall call) async {
    final ctrl = _activeScrollController;
    if (ctrl == null || !ctrl.hasClients) {
      return {'scrollable': false};
    }
    final pos = ctrl.position;
    switch (call.method) {
      case 'getScrollMetrics':
        return {
          'scrollable': pos.maxScrollExtent > 0,
          'offset': pos.pixels,
          'maxScrollExtent': pos.maxScrollExtent,
          'viewportDimension': pos.viewportDimension,
          'devicePixelRatio': View.of(context).devicePixelRatio,
        };
      case 'scrollToOffset':
        final target = (call.arguments as num?)?.toDouble() ?? pos.pixels;
        final clamped = target.clamp(pos.minScrollExtent, pos.maxScrollExtent);
        final before = pos.pixels;
        ctrl.jumpTo(clamped);
        await WidgetsBinding.instance.endOfFrame;
        return {'offset': pos.pixels, 'consumed': pos.pixels - before};
      default:
        return null;
    }
  }

  @override
  void didUpdateWidget(covariant OcrReviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.draft != widget.draft) {
      _draft = widget.draft;
    }
    if (oldWidget.availableProducts != widget.availableProducts) {
      _availableProducts = List<Product>.from(widget.availableProducts ?? []);
    }
  }

  void _toggleItemSelection(int index) {
    setState(() {
      final updatedItems = List<ReceiptItemDraft>.from(_draft.items);
      final current = updatedItems[index];
      updatedItems[index] = current.copyWith(selected: !current.selected);
      _draft = _draft.copyWith(items: updatedItems);
    });
  }

  void _deleteItem(int index) {
    setState(() {
      final updatedItems = List<ReceiptItemDraft>.from(_draft.items);
      updatedItems.removeAt(index);
      _draft = _draft.copyWith(items: updatedItems);
    });
  }

  Future<void> _handleSave() async {
    // RN-196 / CA-4.1: If total value diverges, asks confirmation before saving.
    if (_draft.isDivergent()) {
      final loc = AppLocalizations.of(context);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Row(
            children: [
              Icon(AppIcons.qualityWarning, color: Colors.orange),
              SizedBox(width: 8),
              Text('Divergência no total'),
            ],
          ),
          content: Text(
            'A soma dos itens selecionados (${_draft.itemsSum.formatPtBr()}) '
            'difere do total lido (${_draft.total?.formatPtBr() ?? "R\$ 0,00"}).\n\n'
            'Divergência de ${_draft.absoluteDivergence?.formatPtBr() ?? "R\$ 0,00"}. '
            'Deseja salvar assim mesmo?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(loc.ocrReviewSave),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    if (!mounted) return;

    String? selectedShoppingListId;
    final activeLists = widget.availableShoppingLists
        ?.where((l) => !l.isArchived)
        .toList();

    // RN-201, RN-087: Salvar oferece baixa dos itens correspondentes na lista de compras ativa
    if (activeLists != null && activeLists.isNotEmpty) {
      if (activeLists.length == 1) {
        final list = activeLists.first;
        final shouldWriteOff = await showDialog<bool>(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: const Text('Baixar itens da lista de compras'),
            content: Text(
              'Deseja dar baixa nos itens desta compra na lista de compras "${list.name}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(false),
                child: const Text('Não'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogCtx).pop(true),
                child: const Text('Sim, dar baixa'),
              ),
            ],
          ),
        );

        if (shouldWriteOff == true) {
          selectedShoppingListId = list.id;
        }
      } else {
        if (!mounted) return;
        String currentSelectedId = activeLists.first.id;
        final chosenListId = await showDialog<String?>(
          context: context,
          builder: (dialogCtx) {
            return StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  title: const Text('Baixar itens da lista de compras'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selecione a lista de compras para dar baixa nos itens comprados:',
                      ),
                      const SizedBox(height: 12),
                      DropdownButton<String>(
                        isExpanded: true,
                        value: currentSelectedId,
                        items: activeLists.map((l) {
                          return DropdownMenuItem<String>(
                            value: l.id,
                            child: Text(l.name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => currentSelectedId = val);
                          }
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                      child: const Text('Salvar sem baixa'),
                    ),
                    ElevatedButton(
                      onPressed: () =>
                          Navigator.of(dialogCtx).pop(currentSelectedId),
                      child: const Text('Dar baixa'),
                    ),
                  ],
                );
              },
            );
          },
        );

        selectedShoppingListId = chosenListId;
      }
    }

    if (!mounted) return;

    final options = SaveOptions(writeOffShoppingListId: selectedShoppingListId);

    if (widget.onSaveWithOptions != null) {
      widget.onSaveWithOptions!(_draft, options);
    } else {
      widget.onSave?.call(_draft);
    }
  }

  DateTime? _tryParseDateTime(String str) {
    if (str.isEmpty) return null;
    final iso = DateTime.tryParse(str);
    if (iso != null) return iso;

    final regex = RegExp(
      r'^(\d{1,2})/(\d{1,2})/(\d{4})(?:\s+(\d{1,2}):(\d{1,2}))?',
    );
    final match = regex.firstMatch(str);
    if (match != null) {
      final day = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final year = int.parse(match.group(3)!);
      final hour = match.group(4) != null ? int.parse(match.group(4)!) : 0;
      final minute = match.group(5) != null ? int.parse(match.group(5)!) : 0;
      return DateTime(year, month, day, hour, minute);
    }
    return null;
  }

  void _updateState(VoidCallback fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final selectedCount = _draft.items.where((i) => i.selected).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.ocrReviewTitle),
        leading: IconButton(
          icon: const Icon(AppIcons.back),
          tooltip: 'Voltar',
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: () {
            if (widget.onCancel != null) {
              widget.onCancel!();
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              primary: widget.scrollController == null ? true : false,
              padding: const EdgeInsets.all(12.0),
              children: [
                // Receipt header
                _buildStoreHeaderCard(context),
                const SizedBox(height: 4),

                // Total discrepancy banner (RN-196, CA-4.1)
                _buildDivergenceBanner(context),

                // Low confidence banner (RN-195, CA-3.1)
                _buildLowConfidenceBanner(context),
                const SizedBox(height: 6),

                // Items section title and add item button (RN-198)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Itens do cupom ($selectedCount/${_draft.items.length})',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(AppIcons.add, size: 18),
                      label: const Text('Adicionar item'),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                      onPressed: () => _showEditItemDialog(context),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Lista de itens
                if (_draft.items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(
                      child: Text('Nenhum item. Toque em Adicionar item.'),
                    ),
                  )
                else
                  ...List.generate(_draft.items.length, (index) {
                    final item = _draft.items[index];
                    final isUnmatched = item.match == null;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OcrReviewItemTile(
                          item: item,
                          onToggleSelected: (_) => _toggleItemSelection(index),
                          onEdit: () => _showEditItemDialog(
                            context,
                            item: item,
                            index: index,
                          ),
                          onDelete: () => _deleteItem(index),
                        ),
                        if (isUnmatched)
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 8.0,
                              right: 8.0,
                              bottom: 6.0,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    key: Key('btn_create_product_$index'),
                                    icon: const Icon(AppIcons.add, size: 16),
                                    label: const Text(
                                      'Cadastrar produto',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: () =>
                                        _handleRegisterNewProductForItem(index),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    key: Key('btn_link_existing_$index'),
                                    icon: const Icon(AppIcons.search, size: 16),
                                    label: const Text(
                                      'Vincular existente',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: () =>
                                        _handleLinkExistingProductForItem(
                                          index,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  }),
                const SizedBox(height: 12),

                // Resumo de totais
                _buildTotalsCard(context),
              ],
            ),
          ),

          // Bottom action bar (Save / Cancel)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                      onPressed: () {
                        if (widget.onCancel != null) {
                          widget.onCancel!();
                        } else {
                          Navigator.of(context).maybePop();
                        }
                      },
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                      onPressed: _handleSave,
                      child: Text(loc.ocrReviewSave),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
