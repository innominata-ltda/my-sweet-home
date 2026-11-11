import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/design_system/components/app_button.dart';
import 'package:my_sweet_home/design_system/components/app_card.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/design_system/theme/app_palette.dart';
import 'package:my_sweet_home/design_system/theme/spacing.dart';
import 'package:my_sweet_home/features/mascot/domain/entities/mascot_config.dart';
import 'package:my_sweet_home/features/mascot/domain/ports/mascot_asset_resolver.dart';
import 'package:my_sweet_home/features/mascot/presentation/controllers/mascot_controller.dart';
import 'package:my_sweet_home/features/mascot/presentation/controllers/mascot_customization_state.dart';
import 'package:my_sweet_home/features/mascot/presentation/widgets/mascot_widget.dart';

/// Mascot Momo customization screen (SPEC-012, RF-110, RN-263, CA-110.2, CA-110.4).
///
/// Allows selecting animal, color palette, accessory and name, with real-time
/// preview in happy expression, state handling and immediate persistence.
class MascotCustomizationPage extends ConsumerStatefulWidget {
  const MascotCustomizationPage({
    super.key,
    this.controller,
    this.resolver,
    this.onSaved,
    this.onCanceled,
  });

  /// Optional injected controller (useful for unit tests/mocks).
  final MascotCustomizationController? controller;

  /// Resolvedor de assets customizado para a mascote.
  final MascotAssetResolver? resolver;

  /// Callback triggered after successful save.
  final VoidCallback? onSaved;

  /// Callback triggered upon cancelling edit.
  final VoidCallback? onCanceled;

  @override
  ConsumerState<MascotCustomizationPage> createState() =>
      _MascotCustomizationPageState();
}

class _MascotCustomizationPageState
    extends ConsumerState<MascotCustomizationPage> {
  late final TextEditingController _nameController;

  MascotCustomizationController get _controller =>
      widget.controller ?? ref.read(mascotCustomizationControllerProvider);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    if (widget.controller != null) {
      _syncNameFromState(widget.controller!.value);
    }
  }

  void _syncNameFromState(MascotCustomizationState state) {
    if (state is MascotCustomizationData) {
      if (_nameController.text != state.config.name) {
        _nameController.text = state.config.name;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final MascotCustomizationController controller =
        widget.controller ?? ref.watch(mascotCustomizationControllerProvider);

    return ValueListenableBuilder<MascotCustomizationState>(
      valueListenable: controller,
      builder: (context, state, _) {
        _syncNameFromState(state);

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.mascotCustomizeTitle),
            leading: IconButton(
              icon: const Icon(AppIcons.back),
              tooltip: l10n.mascotCustomizeCancel,
              onPressed: _handleCancel,
            ),
          ),
          body: switch (state) {
            MascotCustomizationLoading() => const Center(
              key: Key('mascot_loading'),
              child: CircularProgressIndicator(),
            ),
            MascotCustomizationError(:final message) => _buildErrorView(
              context,
              l10n,
              message,
            ),
            MascotCustomizationData() => _buildFormView(
              context,
              l10n,
              state,
              controller,
            ),
          },
        );
      },
    );
  }

  Widget _buildErrorView(
    BuildContext context,
    AppLocalizations l10n,
    String message,
  ) {
    return Center(
      key: const Key('mascot_error_view'),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(AppIcons.error, size: 48, color: Colors.redAccent),
            const SizedBox(height: Spacing.md),
            Text(
              message.isNotEmpty ? message : l10n.mascotSaveError,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: Spacing.lg),
            AppButton.primary(
              key: const Key('mascot_retry_button'),
              label: l10n.mascotCustomizeRetry,
              onPressed: () => _controller.load(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormView(
    BuildContext context,
    AppLocalizations l10n,
    MascotCustomizationData state,
    MascotCustomizationController controller,
  ) {
    final currentPalette = AppPalette.fromId(state.config.palette.name);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Preview em Tempo Real (RN-263, CA-110.2) ────────────────────────
          _buildPreviewCard(context, l10n, state.config, currentPalette),

          const SizedBox(height: Spacing.md),

          // ── Campo de Nome da Mascote (RN-258, CA-110.2) ─────────────────────
          Text(
            l10n.mascotCustomizeNameLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Semantics(
            label: 'Campo para alterar o nome da mascote',
            child: TextField(
              key: const Key('mascot_name_field'),
              controller: _nameController,
              maxLength: 25,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: l10n.mascotCustomizeNameHint,
                helperText:
                    'Se deixar em branco, usaremos "${MascotConfig.defaultMomo.name}" 💕',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Radius.card),
                ),
                prefixIcon: const Icon(AppIcons.edit),
              ),
              onChanged: (value) => controller.updateName(value),
            ),
          ),

          const SizedBox(height: Spacing.md),

          // ── Animal Selection Section (RN-259, CA-110.2) ──────────────────────
          _buildSectionTitle(theme, l10n.mascotCustomizeAnimalSection),
          const SizedBox(height: Spacing.xs),
          _buildAnimalSelector(l10n, state.config, controller),

          const SizedBox(height: Spacing.md),

          // ── Palette Selection Section (RN-266, CA-110.2) ─────────────────────
          _buildSectionTitle(theme, l10n.mascotCustomizePaletteSection),
          const SizedBox(height: Spacing.xs),
          _buildPaletteSelector(l10n, state.config, controller),

          const SizedBox(height: Spacing.md),

          // ── Accessory Selection Section (RN-261, CA-110.2) ───────────────────
          _buildSectionTitle(theme, l10n.mascotCustomizeAccessorySection),
          const SizedBox(height: Spacing.xs),
          _buildAccessorySelector(l10n, state.config, controller),

          const SizedBox(height: Spacing.xl),

          // ── Action Buttons (Save and Cancel) (CA-110.3, CA-110.4) ────────────
          Row(
            children: [
              Expanded(
                child: AppButton.secondary(
                  key: const Key('mascot_cancel_button'),
                  label: l10n.mascotCustomizeCancel,
                  onPressed: _handleCancel,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: AppButton.primary(
                  key: const Key('mascot_save_button'),
                  label: l10n.mascotCustomizeSave,
                  isLoading: state.isSaving,
                  onPressed: state.isSaving ? null : _handleSave,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.lg),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(
    BuildContext context,
    AppLocalizations l10n,
    MascotConfig config,
    AppPalette palette,
  ) {
    final theme = Theme.of(context);
    final seedColor = palette.seedColor;

    return AppCard(
      key: const Key('mascot_preview_card'),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderColor: seedColor.withValues(alpha: 0.5),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.lg,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: seedColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: Spacing.xs),
              Flexible(
                child: Text(
                  l10n.mascotCustomizePreview,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          MascotWidget(
            key: const Key('mascot_preview_widget'),
            config: config,
            expression: MascotExpression.happy,
            size: 140,
            resolver: widget.resolver,
            semanticLabel:
                'Pré-visualização da mascote ${config.displayName} na paleta ${config.palette.label}',
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            config.displayName,
            key: const Key('mascot_preview_name'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            '${config.animal.label} · ${config.palette.label} · ${config.accessory.label}',
            key: const Key('mascot_preview_summary'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }

  Widget _buildAnimalSelector(
    AppLocalizations l10n,
    MascotConfig config,
    MascotCustomizationController controller,
  ) {
    return Wrap(
      spacing: Spacing.xs,
      runSpacing: Spacing.xs,
      children: MascotAnimal.values.map((animal) {
        final isSelected = config.animal == animal;
        final label = switch (animal) {
          MascotAnimal.cat => l10n.mascotAnimalCat,
          MascotAnimal.dog => l10n.mascotAnimalDog,
          MascotAnimal.bunny => l10n.mascotAnimalBunny,
        };

        return ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: ChoiceChip(
            key: Key('mascot_animal_${animal.name}'),
            label: Text(label),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                controller.selectAnimal(animal);
              }
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaletteSelector(
    AppLocalizations l10n,
    MascotConfig config,
    MascotCustomizationController controller,
  ) {
    return Wrap(
      spacing: Spacing.xs,
      runSpacing: Spacing.xs,
      children: MascotPalette.values.map((palette) {
        final isSelected = config.palette == palette;
        final appPalette = AppPalette.fromId(palette.name);
        final label = switch (palette) {
          MascotPalette.rose => l10n.mascotPaletteRose,
          MascotPalette.lavender => l10n.mascotPaletteLavender,
          MascotPalette.mint => l10n.mascotPaletteMint,
        };

        return ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: ChoiceChip(
            key: Key('mascot_palette_${palette.name}'),
            avatar: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: appPalette.seedColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
            label: Text(label),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                controller.selectPalette(palette);
              }
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAccessorySelector(
    AppLocalizations l10n,
    MascotConfig config,
    MascotCustomizationController controller,
  ) {
    return Wrap(
      spacing: Spacing.xs,
      runSpacing: Spacing.xs,
      children: MascotAccessory.values.map((accessory) {
        final isSelected = config.accessory == accessory;
        final label = switch (accessory) {
          MascotAccessory.none => l10n.mascotAccessoryNone,
          MascotAccessory.bow => l10n.mascotAccessoryBow,
          MascotAccessory.collar => l10n.mascotAccessoryCollar,
          MascotAccessory.scarf => l10n.mascotAccessoryScarf,
        };

        return ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: ChoiceChip(
            key: Key('mascot_accessory_${accessory.name}'),
            label: Text(label),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                controller.selectAccessory(accessory);
              }
            },
          ),
        );
      }).toList(),
    );
  }

  void _safeNavigateBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      try {
        GoRouter.of(context).go('/');
      } catch (_) {
        // Ambiente sem GoRouter (ex: teste de widget isolado)
      }
    }
  }

  void _handleCancel() {
    _controller.cancel();
    _nameController.text = _controller.state.name;
    widget.onCanceled?.call();
    _safeNavigateBack(context);
  }

  Future<void> _handleSave() async {
    final l10n = AppLocalizations.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    final result = await _controller.save();
    if (!mounted) return;

    if (result.isOk) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(l10n.mascotSaveSuccess),
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.onSaved?.call();
      _safeNavigateBack(context);
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(l10n.mascotSaveError),
          behavior: SnackBarBehavior.floating,
          backgroundColor: errorColor,
        ),
      );
    }
  }
}
