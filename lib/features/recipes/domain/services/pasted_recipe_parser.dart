/// Result of pasted recipe import.
final class RecipeDraft {
  const RecipeDraft({
    this.title = '',
    this.ingredients = const [],
    this.prepText = '',
  });

  final String title;
  final List<String> ingredients;
  final String prepText;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RecipeDraft) return false;
    if (title != other.title) return false;
    if (prepText != other.prepText) return false;
    if (ingredients.length != other.ingredients.length) return false;
    for (int i = 0; i < ingredients.length; i++) {
      if (ingredients[i] != other.ingredients[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(title, prepText, Object.hashAll(ingredients));
}

/// PURE. Import heuristic; always opens in edit mode, never saves directly (RN-176).
abstract interface class PastedRecipeParser {
  RecipeDraft parse(String pasted);
}

final class PastedRecipeParserImpl implements PastedRecipeParser {
  @override
  RecipeDraft parse(String pasted) {
    if (pasted.trim().isEmpty) {
      return const RecipeDraft();
    }

    final lines = pasted.split('\n').map((l) => l.trim()).toList();

    String title = '';
    final ingredients = <String>[];
    final prepLines = <String>[];

    // Regular expression to detect if line starts with quantity indicator.
    // Can be number (1, 1/2, 1.5, 1,5), fraction (1/2, 1/4, 3/4) or words (one, two, half)
    // Ignores leading list bullets such as "-", "*", "•"
    final quantityRegex = RegExp(
      r'^[\-\*\â€¢\s]*(\d+|[Â½Â¼Â¾â…“â…”â…•â…–â…—â…˜â…™â…šâ…›â…œâ…â…ž]|um\b|uma\b|dois\b|duas\b|trÃªs\b|tres\b|quatro\b|cinco\b|seis\b|sete\b|oito\b|nove\b|dez\b|meio\b|meia\b|xÃ­cara|xicara|colher|copo|pitada|punhado|pacote|lata|caixa|dente|fatia|pedaÃ§o|pedaÃ§o|ramo|folha|fio\b|sal\b|pimenta\b|azeite\b|Ã¡gua\b|agua\b|Ã³leo\b|oleo\b|suco\b|raspas\b)',
      caseSensitive: false,
    );

    bool isFirstNonEmpty = true;

    for (final line in lines) {
      if (line.isEmpty) continue;

      if (isFirstNonEmpty) {
        // If first line is not an ingredient, it is likely the title.
        if (!quantityRegex.hasMatch(line) &&
            !line.toLowerCase().contains('a gosto') &&
            line.length < 80) {
          title = line;
          isFirstNonEmpty = false;
          continue;
        }
        isFirstNonEmpty = false;
      }

      final lowerLine = line.toLowerCase();

      // Ingredient heuristic: starts with quantity or common term, or contains "a gosto" / "q.b."
      bool isIngredient = false;
      if (line.length <= 120) {
        if (quantityRegex.hasMatch(line)) {
          isIngredient = true;
        } else if (lowerLine.contains('a gosto') ||
            lowerLine.contains('q.b.')) {
          isIngredient = true;
        } else if (line.startsWith('-') ||
            line.startsWith('*') ||
            line.startsWith('â€¢')) {
          // If bullet point and short line, likely an ingredient; avoid catching preparation instructions
          // Limit to 80 characters for non-obvious ingredient bullets
          if (line.length <= 80) isIngredient = true;
        }
      }

      if (isIngredient) {
        final cleanLine = line.replaceFirst(RegExp(r'^[\-\*\â€¢\s]+'), '');
        ingredients.add(cleanLine);
      } else {
        // If "Ingredientes" or "Modo de preparo", ignore if just a header?
        // Either falls into prepText or is ignored.
        final lowerLine = line.toLowerCase();
        if (lowerLine == 'ingredientes' ||
            lowerLine == 'ingredientes:' ||
            lowerLine == 'modo de preparo' ||
            lowerLine == 'modo de preparo:' ||
            lowerLine == 'preparo:' ||
            lowerLine == 'preparo' ||
            lowerLine == 'instruÃ§Ãµes' ||
            lowerLine == 'instruÃ§Ãµes:') {
          continue;
        }

        prepLines.add(line);
      }
    }

    return RecipeDraft(
      title: title,
      ingredients: ingredients,
      prepText: prepLines.join('\n\n'),
    );
  }
}
