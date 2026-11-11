import 'package:flutter/material.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/features/ocr/domain/models/receipt_item_draft.dart';
import 'package:my_sweet_home/features/products/domain/matcher.dart';

/// Individual item widget on OCR review screen (RF-044, RN-195, RN-197, CA-3.1, CA-3.2).
///
/// Displays read description, link with canonical product, quantity, unit value, total,
/// low confidence indicator (with icon + text — A11Y-5) and selection checkbox (A11Y-2).
class OcrReviewItemTile extends StatelessWidget {
  final ReceiptItemDraft item;
  final ValueChanged<bool?> onToggleSelected;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const OcrReviewItemTile({
    super.key,
    required this.item,
    required this.onToggleSelected,
    this.onEdit,
    this.onDelete,
  });

  String _formatQuantity(Quantity q) {
    final val = q.displayValue;
    final formattedVal = (val % 1 == 0)
        ? val.toInt().toString()
        : val.toStringAsFixed(3).replaceAll('.', ',');
    return '$formattedVal ${q.unit.name}';
  }

  String _formatMatchOrigin(MatchOrigin origin) {
    return switch (origin) {
      ExactUserAlias() => 'exato (apelido)',
      ExactSeedAlias() => 'semente',
      Fuzzy(:final score) => 'aproximado (${(score * 100).toInt()}%)',
      Unknown() => 'não identificado',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMatched = item.match != null;
    final titleText = isMatched
        ? item.match!.product.canonicalName
        : item.rawDescription;
    final semanticsStatus = item.selected ? 'selecionado' : 'desmarcado';
    final lowConfidenceText = item.isLowConfidence
        ? ', baixa confiança, confira este item'
        : '';
    final matchText = isMatched
        ? ', detectado como ${item.rawDescription}'
        : '';
    final fullSemanticsLabel =
        '$titleText$matchText, ${_formatQuantity(item.quantity)}, '
        '${item.totalPrice.formatPtBr()}$lowConfidenceText, $semanticsStatus';
    final onTapActionHint = item.selected
        ? 'Desmarcar $titleText'
        : 'Selecionar $titleText';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(
          color: item.isLowConfidence
              ? Colors.amber.shade700
              : theme.dividerColor.withValues(alpha: 0.5),
          width: item.isLowConfidence ? 1.5 : 1.0,
        ),
      ),
      color: item.isLowConfidence
          ? Colors.amber.shade50.withValues(alpha: 0.3)
          : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(8.0),
        onTap: () => onToggleSelected(!item.selected),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selection checkbox with touch target of at least 48dp (A11Y-2)
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 48.0,
                      minHeight: 48.0,
                    ),
                    child: Center(
                      child: Checkbox(
                        value: item.selected,
                        onChanged: onToggleSelected,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),

                  // Main item information (with Semantics for screen reader)
                  Expanded(
                    child: Semantics(
                      container: true,
                      excludeSemantics: true,
                      label: fullSemanticsLabel,
                      value: semanticsStatus,
                      checked: item.selected,
                      enabled: true,
                      onTap: () => onToggleSelected(!item.selected),
                      onTapHint: onTapActionHint,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4.0),
                          // Product name (canonical or raw description)
                          Text(
                            titleText,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              decoration: item.selected
                                  ? null
                                  : TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(height: 2.0),

                          // Detected description (CA-3.2)
                          Text(
                            'detectado como ${item.rawDescription}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.8),
                              fontStyle: FontStyle.italic,
                            ),
                          ),

                          // Link origin (RN-197)
                          if (isMatched) ...[
                            const SizedBox(height: 2.0),
                            Text(
                              'Vínculo: ${_formatMatchOrigin(item.match!.origin)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],

                          const SizedBox(height: 4.0),
                          // Quantity and unit price
                          Text(
                            '${_formatQuantity(item.quantity)} x ${item.unitPrice.formatPtBr()}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Total value and actions
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const SizedBox(height: 4.0),
                      Text(
                        item.totalPrice.formatPtBr(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (onEdit != null || onDelete != null) ...[
                        const SizedBox(height: 4.0),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (onEdit != null)
                              IconButton(
                                icon: const Icon(AppIcons.edit, size: 20),
                                tooltip: 'Editar item',
                                constraints: const BoxConstraints(
                                  minWidth: 48.0,
                                  minHeight: 48.0,
                                ),
                                onPressed: onEdit,
                              ),
                            if (onDelete != null)
                              IconButton(
                                icon: const Icon(AppIcons.delete, size: 20),
                                tooltip: 'Apagar item',
                                constraints: const BoxConstraints(
                                  minWidth: 48.0,
                                  minHeight: 48.0,
                                ),
                                onPressed: onDelete,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              // Low confidence badge (RN-195, CA-3.1, A11Y-5)
              if (item.isLowConfidence) ...[
                const Divider(height: 12.0),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                  child: Row(
                    children: [
                      Icon(
                        AppIcons.qualityWarning,
                        size: 18.0,
                        color: Colors.amber.shade800,
                      ),
                      const SizedBox(width: 6.0),
                      Text(
                        'confira este item',
                        style: TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
