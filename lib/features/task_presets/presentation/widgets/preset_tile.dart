import 'package:flutter/material.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/features/task_presets/domain/recommended_frequency_phrase.dart';
import 'package:my_sweet_home/features/task_presets/domain/task_preset.dart';

/// Card/tile of a task preset (SPEC-014, A11Y-2, A11Y-5).
class TaskPresetTile extends StatelessWidget {
  const TaskPresetTile({
    super.key,
    required this.preset,
    required this.isAlreadyInRoutine,
    required this.isSelected,
    required this.onTap,
    this.onSelectChanged,
  });

  final TaskPreset preset;
  final bool isAlreadyInRoutine;
  final bool isSelected;
  final VoidCallback onTap;
  final ValueChanged<bool?>? onSelectChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final theme = Theme.of(context);
    const frequencyConverter = RecommendedFrequencyPhrase();
    final frequencyPhrase = frequencyConverter.toPtBr(preset.recommendedRrule);
    final alreadyInRoutineText =
        l10n?.taskPresetsAlreadyInRoutine ?? 'Já na sua rotina';

    final semanticLabel = StringBuffer()
      ..write('${preset.title}, ')
      ..write('$frequencyPhrase, ')
      ..write('área ${preset.area.label}');
    if (isAlreadyInRoutine) {
      semanticLabel.write(', $alreadyInRoutineText');
    }

    return Semantics(
      label: semanticLabel.toString(),
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: isSelected ? 2 : 1,
            ),
            color: isSelected
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2)
                : theme.colorScheme.surface,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (onSelectChanged != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: Checkbox(
                      value: isSelected,
                      onChanged: onSelectChanged,
                    ),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            preset.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isAlreadyInRoutine)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  AppIcons.alreadyInRoutine,
                                  size: 14,
                                  color: theme.colorScheme.onSecondaryContainer,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  alreadyInRoutineText,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color:
                                        theme.colorScheme.onSecondaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          AppIcons.recurring,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          frequencyPhrase,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preset.rationale,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
