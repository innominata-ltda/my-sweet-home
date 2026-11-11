import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_sweet_home/features/ocr/domain/save_receipt_use_case.dart';
import 'package:my_sweet_home/features/ocr/presentation/ocr_review_screen.dart';
import 'package:my_sweet_home/features/ocr/presentation/providers/ocr_providers.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/features/ocr/data/ocr_data_providers.dart';
import 'package:my_sweet_home/features/products/domain/product.dart';
import 'package:my_sweet_home/features/products/presentation/providers/product_list_provider.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';
import 'package:my_sweet_home/features/expenses/presentation/providers/current_month_provider.dart';
import 'package:my_sweet_home/features/expenses/presentation/providers/dashboard_provider.dart';
import 'package:my_sweet_home/features/expenses/presentation/providers/expense_list_provider.dart';
import 'package:my_sweet_home/features/expenses/data/expense_providers.dart';
import 'package:my_sweet_home/features/prices/presentation/providers/purchases_history_provider.dart';

final ocrAvailableProductsProvider = FutureProvider<List<Product>>((ref) async {
  try {
    return await ref.watch(productListProvider.future);
  } catch (_) {
    return const [];
  }
});

class OcrReviewContainer extends ConsumerWidget {
  final String imagePath;

  const OcrReviewContainer({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draftAsync = ref.watch(parseReceiptProvider(imagePath));
    final productsAsync = ref.watch(ocrAvailableProductsProvider);

    return draftAsync.when(
      data: (draft) {
        return OcrReviewScreen(
          draft: draft,
          availableProducts: productsAsync.asData?.value ?? const [],
          onSaveWithOptions: (finalDraft, options) async {
            final saveUseCase = ref.read(saveReceiptUseCaseProvider);
            final result = await saveUseCase(finalDraft, options);

            if (!context.mounted) return;

            if (result.isOk) {
              final purchase = result.valueOrNull!;
              final purchaseMonth = YearMonth.of(purchase.date.toLocal());

              // Invalida os caches do Riverpod
              ref.invalidate(expenseListProvider);
              ref.invalidate(dashboardSummaryProvider);
              ref.invalidate(purchasesListProvider);
              ref.invalidate(expenseCategoriesProvider);

              // Updates expenses screen for month of saved receipt
              ref
                  .read(selectedYearMonthProvider.notifier)
                  .setMonth(purchaseMonth);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Nota Fiscal salva com sucesso!')),
              );
              context.go('/despesas');
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erro ao salvar nota: ${result.failureOrNull}'),
                ),
              );
            }
          },
          onSave: (finalDraft) async {
            final saveUseCase = ref.read(saveReceiptUseCaseProvider);
            final result = await saveUseCase(finalDraft, const SaveOptions());

            if (!context.mounted) return;

            if (result.isOk) {
              final purchase = result.valueOrNull!;
              final purchaseMonth = YearMonth.of(purchase.date.toLocal());

              ref.invalidate(expenseListProvider);
              ref.invalidate(dashboardSummaryProvider);
              ref.invalidate(purchasesListProvider);
              ref.invalidate(expenseCategoriesProvider);

              ref
                  .read(selectedYearMonthProvider.notifier)
                  .setMonth(purchaseMonth);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Nota Fiscal salva com sucesso!')),
              );
              context.go('/despesas');
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erro ao salvar nota: ${result.failureOrNull}'),
                ),
              );
            }
          },
          onCancel: () {
            context.pop();
          },
        );
      },
      loading: () => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Lendo nota fiscal...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(AppIcons.error, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Erro ao processar imagem',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Voltar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
