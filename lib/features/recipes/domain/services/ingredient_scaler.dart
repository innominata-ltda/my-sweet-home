import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/features/recipes/domain/models/ingredient.dart';

final class ScaledIngredient {
  const ScaledIngredient({
    required this.source,
    this.exact,
    required this.display,
  });

  final Ingredient source;
  final Quantity? exact;
  final String display;

  bool get isScalable => exact != null;
}

abstract interface class IngredientScaler {
  List<ScaledIngredient> scale(
    List<Ingredient> ingredients, {
    required int from,
    required int to,
  });
}

final class StandardIngredientScaler implements IngredientScaler {
  const StandardIngredientScaler();

  @override
  List<ScaledIngredient> scale(
    List<Ingredient> ingredients, {
    required int from,
    required int to,
  }) {
    if (from <= 0 || to <= 0) {
      throw ArgumentError('Porções devem ser maiores que zero.');
    }

    return ingredients.map((ing) {
      if (ing.quantity == null) {
        return ScaledIngredient(source: ing, display: ing.name);
      }

      final exactMilli = (ing.quantity!.valueMilli * to) ~/ from;
      final exactQuantity = Quantity(exactMilli, ing.quantity!.unit);

      final displayValue = exactQuantity.displayValue;
      final displayString = _formatDisplay(displayValue, exactQuantity.unit);

      return ScaledIngredient(
        source: ing,
        exact: exactQuantity,
        display: '$displayString ${ing.name}'.trim(),
      );
    }).toList();
  }

  String _formatDisplay(double value, Unit unit) {
    if (unit.dimension == Dimension.count) {
      if (value == value.roundToDouble()) {
        return value.toInt().toString();
      }
      return '${value.floor()} a ${value.ceil()}';
    }

    String valueStr;
    if (value >= 100) {
      valueStr = value.round().toString();
    } else if (value >= 10) {
      valueStr = value.toStringAsFixed(1);
    } else {
      valueStr = value.toStringAsFixed(2);
    }

    // Remove trailing zeros
    if (valueStr.contains('.')) {
      while (valueStr.endsWith('0')) {
        valueStr = valueStr.substring(0, valueStr.length - 1);
      }
      if (valueStr.endsWith('.')) {
        valueStr = valueStr.substring(0, valueStr.length - 1);
      }
    }
    valueStr = valueStr.replaceAll('.', ',');

    switch (unit) {
      case Unit.un:
      case Unit.pack:
        return valueStr; // Fallback, handled above if dimensions are correct
      case Unit.g:
        return '${valueStr}g';
      case Unit.kg:
        return '${valueStr}kg';
      case Unit.ml:
        return '${valueStr}ml';
      case Unit.l:
        return '${valueStr}L';
    }
  }
}
