import 'package:my_sweet_home/core/quantity/quantity.dart';

class ParsedShoppingItem {
  const ParsedShoppingItem({required this.name, this.quantity});

  final String name;
  final Quantity? quantity;
}

abstract interface class ShoppingItemParser {
  ParsedShoppingItem parse(String rawText);
}

class DefaultShoppingItemParser implements ShoppingItemParser {
  const DefaultShoppingItemParser();

  static final _qtyRegex = RegExp(
    r'(\d+(?:[.,]\d+)?|\d+/\d+)\s*(kg|g|l|litros?|ml|un|unidades?|pc|pacotes?|cx|caixas?)\b(?:\s+de\s+)?',
    caseSensitive: false,
  );

  @override
  ParsedShoppingItem parse(String rawText) {
    final match = _qtyRegex.firstMatch(rawText);
    if (match == null) {
      return ParsedShoppingItem(name: rawText.trim());
    }

    final qtyStr = match.group(1)!;
    final unitStr = match.group(2)!;

    final name = rawText
        .replaceFirst(match.group(0)!, ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
    final unit = _parseUnit(unitStr);
    final valueMilli = _parseMilli(qtyStr);

    return ParsedShoppingItem(
      name: name.isEmpty
          ? rawText.trim()
          : name, // fallback if regex consumes all
      quantity: Quantity(valueMilli, unit),
    );
  }

  Unit _parseUnit(String unitStr) {
    switch (unitStr.toLowerCase()) {
      case 'kg':
        return Unit.kg;
      case 'g':
        return Unit.g;
      case 'l':
      case 'litro':
      case 'litros':
        return Unit.l;
      case 'ml':
        return Unit.ml;
      case 'un':
      case 'unidade':
      case 'unidades':
        return Unit.un;
      case 'pc':
      case 'pacote':
      case 'pacotes':
      case 'cx':
      case 'caixa':
      case 'caixas':
        return Unit.pack;
      default:
        return Unit.un;
    }
  }

  int _parseMilli(String qtyStr) {
    if (qtyStr.contains('/')) {
      final parts = qtyStr.split('/');
      final num = double.parse(parts[0]);
      final den = double.parse(parts[1]);
      return ((num / den) * 1000).round();
    } else {
      final cleanStr = qtyStr.replaceAll(',', '.');
      return (double.parse(cleanStr) * 1000).round();
    }
  }
}
