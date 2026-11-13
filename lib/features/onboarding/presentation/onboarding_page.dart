import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/core/tasks/task_draft.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/design_system/theme/spacing.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/features/mascot/domain/entities/mascot_config.dart';
import 'package:my_sweet_home/features/mascot/presentation/widgets/mascot_widget.dart';
import 'package:my_sweet_home/features/onboarding/presentation/onboarding_step.dart';
import 'package:my_sweet_home/features/task_presets/data/task_preset_providers.dart';
import 'package:my_sweet_home/features/task_presets/domain/ports/task_from_preset_port.dart';
import 'package:my_sweet_home/features/task_presets/domain/ports/task_preset_catalog_port.dart';
import 'package:my_sweet_home/features/task_presets/domain/task_preset.dart';
import 'package:my_sweet_home/features/task_presets/presentation/batch_start_dates_sheet.dart';
import 'package:my_sweet_home/features/task_presets/presentation/onboarding_routine_step.dart';
import 'package:my_sweet_home/core/settings/settings_providers.dart';

/// Tela de onboarding interativo do My Sweet Home guiado pela Momo (SPEC-012, SPEC-014).
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({
    super.key,
    this.onComplete,
    this.onCustomize,
    this.onCompleteWithChecklist,
    this.initialStep = 0,
    this.disableAnimations,
    this.catalogPort,
    this.taskFromPresetPort,
    this.clock,
  });

  /// Optional callback invoked when onboarding is completed or skipped.
  /// Se omitido, navega para a rota raiz (`/`).
  final VoidCallback? onComplete;

  /// Callback opcional executado ao finalizar indicando se o checklist da 1a casa deve ser ativado.
  final Future<void> Function(bool activateChecklist)? onCompleteWithChecklist;

  /// Optional callback invoked when user accepts mascot customization in final step (RN-277, CA-009.3).
  /// Se omitido, navega para `/mascot/customize`.
  final VoidCallback? onCustomize;

  /// Initial step to display (default: 0).
  final int initialStep;

  /// Optional manual control to disable animations (CA-290.1).
  final bool? disableAnimations;

  final TaskPresetCatalogPort? catalogPort;
  final TaskFromPresetPort? taskFromPresetPort;
  final Clock? clock;

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  late final PageController _pageController;
  late int _currentPage;
  List<TaskPreset> _selectedRoutinePresets = [];
  bool _activateFirstHomeChecklist = false;

  static const _pageCount = 8;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialStep.clamp(0, _pageCount - 1);
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    try {
      final settingsRepo = ref.read(settingsRepositoryProvider);
      await settingsRepo.setOnboardingCompleted(true);
    } catch (_) {}

    if (widget.onCompleteWithChecklist != null) {
      try {
        await widget.onCompleteWithChecklist!(_activateFirstHomeChecklist);
      } catch (_) {}
    }

    if (widget.onComplete != null) {
      widget.onComplete!();
      return;
    }
    if (!mounted) return;
    try {
      context.go('/');
    } catch (_) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  void _goToCustomize() {
    if (widget.onCustomize != null) {
      widget.onCustomize!();
      return;
    }
    try {
      context.push('/mascot/customize');
    } catch (_) {
      try {
        context.go('/mascot/customize');
      } catch (_) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    }
  }

  void _nextPage() async {
    if (_currentPage == 5 && _selectedRoutinePresets.isNotEmpty) {
      final Clock clock = widget.clock ?? ref.read(clockProvider);
      final startDates = await BatchStartDatesSheet.show(
        context,
        presets: _selectedRoutinePresets,
        clock: clock,
      );
      if (startDates == null) {
        return;
      }

      final drafts = _selectedRoutinePresets.map((p) {
        final date = startDates[p.id] ?? clock.todayUtc();
        return TaskDraft(
          title: p.title,
          firstOccurrence: date,
          allDay: true,
          rrule: p.recommendedRrule,
          sourcePresetId: p.id,
        );
      }).toList();

      TaskFromPresetPort? port = widget.taskFromPresetPort;
      if (port == null) {
        try {
          port = ref.read(taskFromPresetPortProvider);
        } catch (_) {
          port = null;
        }
      }

      if (port != null) {
        await port.createBatch(drafts);
      }
    }

    if (_currentPage < _pageCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final visualEffectsEnabled = ref.watch(visualEffectsEnabledProvider);
    final animationsDisabled =
        widget.disableAnimations ?? !visualEffectsEnabled;
    final isLastPage = _currentPage == _pageCount - 1;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: TextButton(
              key: const Key('onboarding_skip_button'),
              style: TextButton.styleFrom(
                minimumSize: const Size(
                  Spacing.touchTarget,
                  Spacing.touchTarget,
                ),
              ),
              onPressed: _finish,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  l10n?.onboardingSkip ?? 'Pular introdução',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  OnboardingStep(
                    expression: MascotExpression.waving,
                    title: l10n?.onboardingStep1Title ?? 'Oi! Eu sou a Momo 💕',
                    subtitle: l10n?.onboardingStep1Description ?? 'Estou aqui para cuidar do seu cantinho com você e tornar tudo mais leve!',
                    disableAnimations: animationsDisabled,
                    extraContent: Container(
                      key: const Key('onboarding_open_source_badge'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.md,
                        vertical: Spacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            AppIcons.openSource,
                            size: 18,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                          const SizedBox(width: Spacing.sm),
                          Flexible(
                            child: Text(
                              '100% gratuito, de código aberto e com dados salvos apenas no seu aparelho',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  OnboardingStep(
                    expression: MascotExpression.pointing,
                    title:
                        l10n?.onboardingStep2Title ??
                        'Aqui a gente cuida do dinheirinho juntas',
                    subtitle: l10n?.onboardingStep2Description ?? 'Acompanhe seus gastos, registre comprinhas e mantenha o orçamento sem sustos no fim do mês.',
                    disableAnimations: animationsDisabled,
                  ),
                  OnboardingStep(
                    expression: MascotExpression.shopping,
                    title:
                        l10n?.onboardingStep3Title ??
                        'E também das comprinhas!',
                    subtitle: l10n?.onboardingStep3Description ?? 'Monte sua listinha de compras no mercado e escaneie a nota fiscal num piscar de olhos.',
                    disableAnimations: animationsDisabled,
                  ),
                  OnboardingStep(
                    expression: MascotExpression.happy,
                    title:
                        l10n?.onboardingStep4Title ??
                        'Não esquece das tarefinhas do dia',
                    subtitle: l10n?.onboardingStep4Description ?? 'Organize tarefas de limpeza, cuidados com a casa e rotinas para manter seu lar acolhedor.',
                    disableAnimations: animationsDisabled,
                  ),
                  OnboardingStep(
                    expression: MascotExpression.budget,
                    title:
                        l10n?.onboardingStep5Title ??
                        'Eu te aviso quando algo precisa de atenção',
                    subtitle: l10n?.onboardingStep5Description ?? 'Fique tranquila com os lembretes de contas a vencer para nunca mais pagar juros ou multas.',
                    disableAnimations: animationsDisabled,
                  ),
                  OnboardingRoutineStep(
                    catalogPort: widget.catalogPort,
                    taskFromPresetPort: widget.taskFromPresetPort,
                    clock: widget.clock,
                    headerVisual: MascotEntrance(
                      disableAnimations: animationsDisabled,
                      child: MascotWidget(
                        expression: MascotExpression.pointing,
                        size: 100,
                        disableAnimations: animationsDisabled,
                      ),
                    ),
                    onSelectionChanged: (selected) {
                      _selectedRoutinePresets = selected;
                    },
                    onSkip: () {
                      _selectedRoutinePresets.clear();
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                  OnboardingStep(
                    expression: MascotExpression.happy,
                    title: 'Está montando sua casa nova?',
                    subtitle: 'Se você acabou de se mudar ou está organizando seu cantinho pela primeira vez, posso ativar um checklist especial com itens essenciais no seu início!',
                    disableAnimations: animationsDisabled,
                    extraContent: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FilledButton.icon(
                          key: const Key('onboarding_enable_checklist_button'),
                          icon: const Icon(AppIcons.tasks),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(
                              Spacing.touchTarget,
                              Spacing.touchTarget,
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _activateFirstHomeChecklist = true;
                            });
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          label: const Text(
                            'Sim, ativar checklist da primeira casa',
                          ),
                        ),
                        const SizedBox(height: Spacing.sm),
                        OutlinedButton(
                          key: const Key('onboarding_skip_checklist_button'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(
                              Spacing.touchTarget,
                              Spacing.touchTarget,
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _activateFirstHomeChecklist = false;
                            });
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: const Text('Já tenho tudo / Pular'),
                        ),
                      ],
                    ),
                  ),
                  OnboardingStep(
                    expression: MascotExpression.relaxed,
                    title:
                        l10n?.onboardingStep6Title ??
                        'Pode personalizar meu visual quando quiser!',
                    subtitle: l10n?.onboardingStep6Description ?? 'Você pode trocar meu animalzinho, colocar acessórios e escolher as cores que mais combinam com você.',
                    disableAnimations: animationsDisabled,
                    extraContent: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n?.onboardingCustomizePrompt ??
                              'Quer personalizar meu visual agora?',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: Spacing.sm),
                        FilledButton.tonal(
                          key: const Key('onboarding_customize_button'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(
                              Spacing.touchTarget,
                              Spacing.touchTarget,
                            ),
                          ),
                          onPressed: _goToCustomize,
                          child: Text(
                            l10n?.onboardingCustomizeButton ??
                                'Personalizar agora',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Page indicator (dots)
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: textScale >= 1.5 ? Spacing.xs : Spacing.md,
              ),
              child: Semantics(
                label: 'Página ${_currentPage + 1} de $_pageCount',
                child: Row(
                  key: const Key('page_indicator'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pageCount, (index) {
                    final isSelected = index == _currentPage;
                    return AnimatedContainer(
                      key: Key('page_indicator_dot_$index'),
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(
                        horizontal: Spacing.xs,
                      ),
                      height: Spacing.sm,
                      width: isSelected ? Spacing.lg : Spacing.sm,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(Radius.full),
                      ),
                    );
                  }),
                ),
              ),
            ),
            // Action button (Next / Get Started)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Spacing.lg,
                vertical: textScale >= 1.5 ? Spacing.sm : Spacing.lg,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: double.infinity,
                  minHeight: Spacing.touchTarget,
                ),
                child: FilledButton(
                  key: Key(
                    isLastPage
                        ? 'onboarding_start_button'
                        : 'onboarding_next_button',
                  ),
                  onPressed: isLastPage ? _finish : _nextPage,
                  child: Text(
                    isLastPage
                        ? (l10n?.onboardingStart ?? 'Começar')
                        : (l10n?.onboardingNext ?? 'Próximo'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
