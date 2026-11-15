import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/design_system/components/app_button.dart';
import 'package:my_sweet_home/design_system/components/app_card.dart';
import 'package:my_sweet_home/design_system/components/app_loading.dart';
import 'package:my_sweet_home/design_system/components/app_money_field.dart';
import 'package:my_sweet_home/design_system/components/app_scaffold.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';

import 'economy_providers.dart';

class EconomyScreen extends ConsumerStatefulWidget {
  const EconomyScreen({super.key});

  @override
  ConsumerState<EconomyScreen> createState() => _EconomyScreenState();
}

class _EconomyScreenState extends ConsumerState<EconomyScreen> {
  void _showSetGoalDialog(BuildContext context, Money? currentTarget) {
    final l10n =
        Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        lookupAppLocalizations(const Locale('pt'));
    int targetCents = currentTarget?.cents ?? 0;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text(l10n.economySetGoalTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppMoneyField(
                label: l10n.economySetGoalFieldLabel,
                initialCents: targetCents > 0 ? targetCents : null,
                onChanged: (cents) {
                  targetCents = cents;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(l10n.commonCancel),
            ),
            AppButton(
              label: l10n.economySaveGoalButton,
              onPressed: () {
                ref.read(economyControllerProvider).setGoal(Money(targetCents));
                Navigator.pop(dialogCtx);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n =
        Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        lookupAppLocalizations(const Locale('pt'));
    final controller = ref.watch(economyControllerProvider);

    return AppScaffold(
      title: l10n.economyTitle,
      body: ValueListenableBuilder<EconomyState>(
        valueListenable: controller,
        builder: (context, state, child) {
          if (state.isLoading && state.assessment == null) {
            return const AppLoading();
          }

          if (state.failure != null && state.assessment == null) {
            return Center(
              child: Text(l10n.economyLoadError('${state.failure}')),
            );
          }

          final assessment = state.assessment;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Card 1: Meta de Economia
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.economyMonthGoalTitle(state.month.iso),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            IconButton(
                              icon: const Icon(AppIcons.edit, size: 20),
                              onPressed: () => _showSetGoalDialog(
                                context,
                                state.goal?.target,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.goal != null && state.goal!.target.cents > 0
                              ? state.goal!.target.formatPtBr()
                              : l10n.economyNoGoalSet,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        AppButton(
                          label: state.goal != null
                              ? l10n.economyChangeGoalButton
                              : l10n.economySetGoalTitle,
                          onPressed: () =>
                              _showSetGoalDialog(context, state.goal?.target),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Card 2: Progresso em Linguagem Neutra (RN-254)
                if (assessment != null) ...[
                  AppCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.economyGoalProgressTitle,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            assessment.statusMessage,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (assessment.progressRatio != null) ...[
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: assessment.progressRatio!.clamp(
                                  0.0,
                                  1.0,
                                ),
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Card 3: Dicas Contextuais (RF-103, RN-254)
                  AppCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.economyContextualTipsTitle,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          ...assessment.contextualTips.map(
                            (tip) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• '),
                                  Expanded(
                                    child: Text(
                                      tip,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
