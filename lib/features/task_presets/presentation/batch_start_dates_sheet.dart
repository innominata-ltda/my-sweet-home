import 'package:flutter/material.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/features/task_presets/domain/task_preset.dart';

/// Modal bottom sheet to configure start date for each batch item (RN-363, CA-4.2).
class BatchStartDatesSheet extends StatefulWidget {
  const BatchStartDatesSheet({
    super.key,
    required this.presets,
    required this.clock,
  });

  final List<TaskPreset> presets;
  final Clock clock;

  static Future<Map<String, DateTime>?> show(
    BuildContext context, {
    required List<TaskPreset> presets,
    required Clock clock,
  }) {
    return showModalBottomSheet<Map<String, DateTime>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => BatchStartDatesSheet(presets: presets, clock: clock),
    );
  }

  @override
  State<BatchStartDatesSheet> createState() => _BatchStartDatesSheetState();
}

class _BatchStartDatesSheetState extends State<BatchStartDatesSheet> {
  late final Map<String, DateTime> _dates;

  @override
  void initState() {
    super.initState();
    final today = widget.clock.todayUtc();
    _dates = {for (final p in widget.presets) p.id: today};
  }

  String _formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString();
    return '$day/$month/$year';
  }

  Future<void> _pickDate(BuildContext context, TaskPreset preset) async {
    final current = _dates[preset.id] ?? widget.clock.todayUtc();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dates[preset.id] = DateTime.utc(picked.year, picked.month, picked.day);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                l10n.taskPresetsBatchTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: widget.presets.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final preset = widget.presets[index];
                    final date = _dates[preset.id]!;
                    final formattedDate = _formatDate(date);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      title: Text(
                        preset.title,
                        style: theme.textTheme.titleMedium,
                      ),
                      subtitle: Text(
                        l10n.taskPresetsBatchStartDateLabel(preset.title),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: OutlinedButton.icon(
                        key: Key('date_picker_${preset.id}'),
                        onPressed: () => _pickDate(context, preset),
                        icon: const Icon(AppIcons.calendar, size: 16),
                        label: Text(formattedDate),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop(_dates);
                },
                child: Text(l10n.taskPresetsBatchConfirm),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
