import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/core/tasks/task_draft.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/core/trash/trash_policy.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/features/task_presets/data/task_preset_providers.dart';
import 'package:my_sweet_home/features/task_presets/domain/ports/task_from_preset_port.dart';
import 'package:my_sweet_home/features/task_presets/domain/ports/task_preset_catalog_port.dart';
import 'package:my_sweet_home/features/task_presets/domain/task_preset.dart';
import 'package:my_sweet_home/features/task_presets/domain/task_preset_search.dart';
import 'package:my_sweet_home/features/task_presets/presentation/batch_start_dates_sheet.dart';
import 'package:my_sweet_home/features/task_presets/presentation/widgets/duplicate_preset_dialog.dart';
import 'package:my_sweet_home/features/task_presets/presentation/widgets/preset_tile.dart';

/// Screen for household task presets catalog (SPEC-014).
class TaskPresetCatalogPage extends ConsumerStatefulWidget {
  const TaskPresetCatalogPage({
    super.key,
    this.catalogPort,
    this.taskFromPresetPort,
    this.clock,
    this.onOpenDraft,
    this.isOnboarding = false,
    this.onSkipOnboarding,
    this.onConfirmBatch,
  });

  final TaskPresetCatalogPort? catalogPort;
  final TaskFromPresetPort? taskFromPresetPort;
  final Clock? clock;
  final void Function(TaskDraft draft)? onOpenDraft;
  final bool isOnboarding;
  final VoidCallback? onSkipOnboarding;
  final void Function(List<TaskPreset> selected)? onConfirmBatch;

  @override
  ConsumerState<TaskPresetCatalogPage> createState() =>
      _TaskPresetCatalogPageState();
}

class _TaskPresetCatalogPageState extends ConsumerState<TaskPresetCatalogPage> {
  final _searchController = TextEditingController();
  final _search = const TaskPresetSearch();

  bool _loading = true;
  String? _error;
  List<TaskPreset> _allPresets = [];
  Set<String> _alreadyInRoutineIds = {};
  final Set<String> _selectedIds = {};
  String _query = '';

  bool _initialized = false;
  late TaskPresetCatalogPort _catalogPort;
  late TaskFromPresetPort _taskFromPresetPort;
  late Clock _clock;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _clock = widget.clock ?? ref.read(clockProvider);
      _catalogPort = widget.catalogPort ?? ref.read(taskPresetCatalogProvider);
      _taskFromPresetPort =
          widget.taskFromPresetPort ?? ref.read(taskFromPresetPortProvider);
      _loadData();
    }
  }

  void _onSearchChanged() {
    setState(() {
      _query = _searchController.text.trim();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final catRes = await _catalogPort.load();
    if (catRes.isErr) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = catRes.failureOrNull?.toString();
        });
      }
      return;
    }

    Set<String> activeIds = {};
    final activeRes = await _taskFromPresetPort.activeOriginPresetIds();
    if (activeRes.isOk) {
      activeIds = activeRes.valueOrNull!;
    }

    if (mounted) {
      setState(() {
        _loading = false;
        _allPresets = catRes.valueOrNull!.presets;
        _alreadyInRoutineIds = activeIds;
      });
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onPresetTapped(TaskPreset preset) async {
    final isAlready = _alreadyInRoutineIds.contains(preset.id);
    if (isAlready) {
      final confirm = await DuplicatePresetDialog.show(
        context,
        presetTitle: preset.title,
      );
      if (confirm != true) return;
    }

    final draft = TaskDraft(
      title: preset.title,
      firstOccurrence: _clock.todayUtc(),
      allDay: true,
      rrule: preset.recommendedRrule,
      sourcePresetId: preset.id,
    );

    _openDraft(draft);
  }

  void _openCustomTask() {
    final draft = TaskDraft(
      title: _query,
      firstOccurrence: _clock.todayUtc(),
      allDay: true,
    );
    _openDraft(draft);
  }

  void _openDraft(TaskDraft draft) async {
    if (widget.onOpenDraft != null) {
      widget.onOpenDraft!(draft);
      unawaited(_loadData());
    }
  }

  void _onConfirmBatchPressed() async {
    final selected = _allPresets
        .where((p) => _selectedIds.contains(p.id))
        .toList();
    if (selected.isEmpty) return;

    if (widget.onConfirmBatch != null) {
      widget.onConfirmBatch!(selected);
      return;
    }

    final startDates = await BatchStartDatesSheet.show(
      context,
      presets: selected,
      clock: _clock,
    );
    if (startDates == null) return;

    final drafts = selected.map((p) {
      final date = startDates[p.id] ?? _clock.todayUtc();
      return TaskDraft(
        title: p.title,
        firstOccurrence: date,
        allDay: true,
        rrule: p.recommendedRrule,
        sourcePresetId: p.id,
      );
    }).toList();

    final result = await _taskFromPresetPort.createBatch(drafts);
    if (result.isOk) {
      final createdList = result.valueOrNull!;
      setState(_selectedIds.clear);
      unawaited(_loadData());

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.taskPresetsBatchSuccess(createdList.length)),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: l10n.taskPresetsBatchUndo,
              onPressed: () async {
                final tickets = createdList
                    .map(
                      (t) => TrashTicket(
                        id: t.id,
                        table: 'tasks',
                        deletedAt: _clock.nowUtc(),
                      ),
                    )
                    .toList();
                await _taskFromPresetPort.undoBatch(tickets);
                unawaited(_loadData());
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.taskPresetsTitle),
        actions: [
          if (widget.isOnboarding && widget.onSkipOnboarding != null)
            TextButton(
              onPressed: widget.onSkipOnboarding,
              child: Text(l10n.onboardingRoutineSkip),
            ),
        ],
      ),
      body: _buildBody(l10n, theme),
      bottomNavigationBar: _selectedIds.isNotEmpty
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.taskPresetsSelectedCount(_selectedIds.length),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    FilledButton(
                      onPressed: _onConfirmBatchPressed,
                      child: Text(
                        l10n.taskPresetsAddSelected(_selectedIds.length),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBody(AppLocalizations l10n, ThemeData theme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loadData,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    final filtered = _search.filter(presets: _allPresets, query: _query);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n.taskPresetsSearchHint,
              prefixIcon: const Icon(AppIcons.search),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(AppIcons.close),
                      onPressed: _searchController.clear,
                    )
                  : null,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty && _query.isNotEmpty
              ? _buildEmptySearch(l10n, theme)
              : _buildGroupedList(filtered, l10n, theme),
        ),
      ],
    );
  }

  Widget _buildEmptySearch(AppLocalizations l10n, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              AppIcons.search,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.taskPresetsEmptySearch(_query),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _openCustomTask,
              icon: const Icon(AppIcons.add),
              label: Text(l10n.taskPresetsCustomTaskCta),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedList(
    List<TaskPreset> presets,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    // Group by area in enum order
    final grouped = <TaskPresetArea, List<TaskPreset>>{};
    for (final area in TaskPresetArea.values) {
      final items = presets.where((p) => p.area == area).toList();
      if (items.isNotEmpty) {
        grouped[area] = items;
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: grouped.keys.length,
      itemBuilder: (context, index) {
        final area = grouped.keys.elementAt(index);
        final items = grouped[area]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                area.label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            ...items.map(
              (p) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: TaskPresetTile(
                  preset: p,
                  isAlreadyInRoutine: _alreadyInRoutineIds.contains(p.id),
                  isSelected: _selectedIds.contains(p.id),
                  onTap: () => _onPresetTapped(p),
                  onSelectChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedIds.add(p.id);
                      } else {
                        _selectedIds.remove(p.id);
                      }
                    });
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
