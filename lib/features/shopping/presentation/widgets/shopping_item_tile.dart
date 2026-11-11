import 'package:flutter/material.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/design_system/components/app_list_tile.dart';
import 'package:my_sweet_home/design_system/components/cute_checkbox.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/design_system/theme/spacing.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_item.dart';

class ShoppingItemTile extends StatelessWidget {
  const ShoppingItemTile({
    super.key,
    required this.item,
    required this.onToggle,
    this.onDelete,
    this.onRegisterSingle,
    this.animal,
    this.shape,
    this.useCuteCheckbox = true,
  });

  final ShoppingItem item;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onDelete;
  final VoidCallback? onRegisterSingle;
  final MascotAnimal? animal;
  final CuteCheckboxShape? shape;
  final bool useCuteCheckbox;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBought = item.isBought;

    final l10n = AppLocalizations.of(context);
    final itemName = item.parsedName.trim().isNotEmpty
        ? item.parsedName
        : item.rawText;
    final String semanticsActionLabel = isBought
        ? l10n.shoppingListUnmarkAsBought(itemName)
        : l10n.shoppingListMarkAsBought(itemName);

    Widget titleChild;
    if (isBought) {
      titleChild = Text(
        item.rawText,
        style: theme.textTheme.bodyLarge?.copyWith(
          decoration: TextDecoration.lineThrough,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      );
    } else {
      titleChild = Text(item.rawText, style: theme.textTheme.bodyLarge);
    }

    Widget? subtitleChild;
    if (item.parsedQuantity != null) {
      final qty = item.parsedQuantity!;
      final displayVal = qty.displayValue % 1 == 0
          ? qty.displayValue.toInt().toString()
          : qty.displayValue.toString();
      subtitleChild = Text(
        l10n.shoppingListItemQuantity(displayVal, qty.unit.name),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.outline,
        ),
      );
    }

    return Semantics(
      label: semanticsActionLabel,
      button: true,
      enabled: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: Spacing.touchTarget),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
          child: AppListTile(
            onTap: () => onToggle(!isBought),
            onLongPress: onRegisterSingle,
            leading: useCuteCheckbox
                ? CuteCheckbox(
                    value: isBought,
                    onChanged: onToggle,
                    animal: animal,
                    shape: shape,
                    excludeSemantics: true,
                  )
                : Icon(
                    isBought ? AppIcons.checkBox : AppIcons.checkBoxBlank,
                    color: isBought
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                    size: 24,
                  ),
            title: titleChild,
            subtitle: subtitleChild,
            trailing: (onRegisterSingle != null || onDelete != null)
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onRegisterSingle != null)
                        IconButton(
                          icon: const Icon(AppIcons.purchase, size: 20),
                          tooltip: 'Registrar compra deste item',
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          onPressed: onRegisterSingle,
                        ),
                      if (onDelete != null)
                        IconButton(
                          icon: const Icon(AppIcons.delete, size: 20),
                          tooltip: 'Remover item',
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          onPressed: onDelete,
                        ),
                    ],
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
