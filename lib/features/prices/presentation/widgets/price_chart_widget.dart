import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_point.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_stats.dart';
import 'package:my_sweet_home/features/prices/domain/store/store.dart';

/// Price trend chart with accessible textual alternative (RF-029, A11Y-9, A11Y-5).
///
/// Estrutura:
/// - `LineChart` is wrapped in `ExcludeSemantics` so screen readers
///   o ignorem.
/// - Um `Semantics` com `label` composto a partir de `purchaseChartA11y`
///   fornece o resumo falado (A11Y-9).
/// - Screen reader navigable table lists each point individually
///   (A11Y-9).
/// - Up and down variations use icon + text, never color alone (A11Y-5).
class PriceChartWidget extends StatelessWidget {
  const PriceChartWidget({
    super.key,
    required this.history,
    required this.stats,
    required this.stores,
  });

  final List<PricePoint> history;
  final PriceStats stats;

  /// Map of storeId -> Store for name lookups. Can be empty; in that case
  /// raw storeId is displayed.
  final Map<String, Store> stores;

  // ── helpers ────────────────────────────────────────────────────────────────

  /// Point with lowest normalized price.
  PricePoint get _cheapest =>
      history.reduce((a, b) => a.normalizedPrice < b.normalizedPrice ? a : b);

  String _storeName(String storeId) => stores[storeId]?.name ?? storeId;

  String _formatDate(DateTime date) =>
      DateFormat('d \'de\' MMMM', 'pt_BR').format(date.toLocal());

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (history.isEmpty) return const SizedBox.shrink();

    // Sorts chronologically for chart.
    final sorted = List<PricePoint>.from(history)
      ..sort((a, b) => a.date.compareTo(b.date));

    final cheapest = _cheapest;

    // Texto falado pelo leitor de tela (A11Y-9).
    final a11yLabel = l10n.purchaseChartA11y(
      stats.averagePrice.formatPtBr(),
      cheapest.normalizedPrice.formatPtBr(),
      _storeName(cheapest.storeId),
      _formatDate(cheapest.date),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Chart section ───────────────────────────────────────────────────
        Semantics(
          label: a11yLabel,
          child: ExcludeSemantics(child: _buildLineChart(sorted, colorScheme)),
        ),

        const SizedBox(height: 8),

        // ── Trend legend (icon + text, A11Y-5) ──────────────────────────────
        _PriceTrendBadge(history: sorted),

        const SizedBox(height: 16),

        // ── Navigable textual table (A11Y-9) ────────────────────────────────
        _AccessiblePriceTable(sorted: sorted, stores: stores),
      ],
    );
  }

  Widget _buildLineChart(List<PricePoint> sorted, ColorScheme colorScheme) {
    if (sorted.isEmpty) return const SizedBox.shrink();

    // Normaliza x como dias desde o primeiro ponto.
    final t0 = sorted.first.date.millisecondsSinceEpoch.toDouble();
    final msPerDay = const Duration(days: 1).inMilliseconds.toDouble();

    final spots = sorted.map((p) {
      final x = (p.date.millisecondsSinceEpoch - t0) / msPerDay;
      final y = p.normalizedPrice.cents / 100.0;
      return FlSpot(x, y);
    }).toList();

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final padding = maxY == minY ? 1.0 : (maxY - minY) * 0.15;

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: LineChart(
        LineChartData(
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minY: minY - padding,
          maxY: maxY + padding,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: colorScheme.primary,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: colorScheme.primary.withValues(alpha: 0.15),
              ),
            ),
          ],
          lineTouchData: const LineTouchData(enabled: false),
        ),
      ),
    );
  }
}

// ── Trend legend ────────────────────────────────────────────────────────────

/// Displays trend direction using icon + text (A11Y-5: never color alone).
class _PriceTrendBadge extends StatelessWidget {
  const _PriceTrendBadge({required this.history});

  final List<PricePoint> history;

  @override
  Widget build(BuildContext context) {
    if (history.length < 2) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final first = history.first.normalizedPrice;
    final last = history.last.normalizedPrice;

    if (last > first) {
      return _badge(
        context,
        icon: AppIcons.trendUp,
        label: l10n.priceTrendUp,
        color: Theme.of(context).colorScheme.error,
      );
    } else if (last < first) {
      return _badge(
        context,
        icon: AppIcons.trendDown,
        label: l10n.priceTrendDown,
        color: Theme.of(context).colorScheme.primary,
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _badge(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18, semanticLabel: ''),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Accessible textual table ────────────────────────────────────────────────

/// Screen reader navigable table listing each price point (A11Y-9).
class _AccessiblePriceTable extends StatelessWidget {
  const _AccessiblePriceTable({required this.sorted, required this.stores});

  final List<PricePoint> sorted;
  final Map<String, Store> stores;

  String _storeName(String storeId) => stores[storeId]?.name ?? storeId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            l10n.priceHistoryTitle,
            style: theme.textTheme.titleSmall,
          ),
        ),
        const SizedBox(height: 4),
        ...sorted.map((point) {
          final dateStr = DateFormat('dd/MM/yyyy').format(point.date.toLocal());
          final priceStr = point.normalizedPrice.formatPtBr();
          final storeName = _storeName(point.storeId);
          final semanticLabel = '$priceStr em $storeName no $dateStr';

          return Semantics(
            label: semanticLabel,
            child: ExcludeSemantics(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(dateStr, style: theme.textTheme.bodySmall),
                    ),
                    Expanded(
                      child: Text(
                        storeName,
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      priceStr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
