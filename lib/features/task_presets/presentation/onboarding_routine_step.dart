import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/tasks/task_draft.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/core/trash/trash_policy.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/features/task_presets/data/task_preset_providers.dart';
import 'package:my_sweet_home/features/task_presets/domain/ports/task_from_preset_port.dart';
import 'package:my_sweet_home/features/task_presets/domain/ports/task_preset_catalog_port.dart';
import 'package:my_sweet_home/features/task_presets/domain/task_preset.dart';
import 'package:my_sweet_home/features/task_presets/domain/task_preset_search.dart';
import 'package:my_sweet_home/features/task_presets/presentation/widgets/preset_tile.dart';

/// Passo "Monte sua rotina da casa" no onboarding (SPEC-014, RN-364, RN-365, RN-366).
class OnboardingRoutineStep extends ConsumerStatefulWidget {
  const OnboardingRoutineStep({
    super.key,
    this.catalogPort,
    this.taskFromPresetPort,
    this.clock,
    this.headerVisual,
    this.onSelectionChanged,
    this.onSkip,
  });

  final TaskPresetCatalogPort? catalogPort;
  final TaskFromPresetPort? taskFromPresetPort;
  final Clock? clock;
  final Widget? headerVisual;
  final ValueChanged<List<TaskPreset>>? onSelectionChanged;
  final VoidCallback? onSkip;

  @override
  ConsumerState<OnboardingRoutineStep> createState() =>
      _OnboardingRoutineStepState();
}

class _OnboardingRoutineStepState extends ConsumerState<OnboardingRoutineStep> {
  final _searchController = TextEditingController();
  final _search = const TaskPresetSearch();

  bool _initialized = false;
  bool _loading = true;
  List<TaskPreset> _allPresets = [];
  Set<String> _alreadyInRoutineIds = {};
  final Set<String> _selectedIds = {};
  String _query = '';

  late TaskPresetCatalogPort _catalogPort;
  late TaskFromPresetPort _taskFromPresetPort;

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
      if (widget.catalogPort != null) {
        _catalogPort = widget.catalogPort!;
      } else {
        try {
          _catalogPort = ref.read(taskPresetCatalogProvider);
        } catch (_) {
          _catalogPort = const _NoopTaskPresetCatalog();
        }
      }
      if (widget.taskFromPresetPort != null) {
        _taskFromPresetPort = widget.taskFromPresetPort!;
      } else {
        try {
          _taskFromPresetPort = ref.read(taskFromPresetPortProvider);
        } catch (_) {
          _taskFromPresetPort = const _NoopTaskFromPreset();
        }
      }
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
    });

    final catRes = await _catalogPort.load();
    Set<String> activeIds = {};
    final activeRes = await _taskFromPresetPort.activeOriginPresetIds();
    if (activeRes.isOk) {
      activeIds = activeRes.valueOrNull!;
    }

    if (mounted) {
      setState(() {
        _loading = false;
        _allPresets = catRes.valueOrNull?.presets ?? [];
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

  void _toggleSelection(TaskPreset preset) {
    setState(() {
      if (_selectedIds.contains(preset.id)) {
        _selectedIds.remove(preset.id);
      } else {
        _selectedIds.add(preset.id);
      }
    });

    final selectedList = _allPresets
        .where((p) => _selectedIds.contains(p.id))
        .toList();
    widget.onSelectionChanged?.call(selectedList);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = _search.filter(presets: _allPresets, query: _query);

    final grouped = <TaskPresetArea, List<TaskPreset>>{};
    for (final area in TaskPresetArea.values) {
      final items = filtered.where((p) => p.area == area).toList();
      if (items.isNotEmpty) {
        grouped[area] = items;
      }
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (widget.headerVisual != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Center(child: widget.headerVisual!),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
          child: Column(
            children: [
              Text(
                l10n?.onboardingRoutineTitle ?? 'Monte sua rotina da casa',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n?.onboardingRoutineDescription ?? 'Escolha tarefas comuns para começar sua rotina sem complicação. Você pode mudar tudo depois!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (widget.onSkip != null)
                TextButton(
                  onPressed: widget.onSkip,
                  child: Text(
                    l10n?.onboardingRoutineSkip ?? 'Pular este passo',
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText:
                  l10n?.taskPresetsSearchHint ??
                  'Buscar por título ou cômodo...',
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
                vertical: 10,
              ),
            ),
          ),
        ),
        for (final entry in grouped.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              entry.key.label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          for (final p in entry.value)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
              child: TaskPresetTile(
                preset: p,
                isAlreadyInRoutine: _alreadyInRoutineIds.contains(p.id),
                isSelected: _selectedIds.contains(p.id),
                onTap: () => _toggleSelection(p),
                onSelectChanged: (_) => _toggleSelection(p),
              ),
            ),
        ],
      ],
    );
  }
}

class _NoopTaskFromPreset implements TaskFromPresetPort {
  const _NoopTaskFromPreset();

  @override
  Future<Result<CreatedTask, Failure>> create(TaskDraft draft) async =>
      const Err(StorageFailure(detail: 'No database available'));

  @override
  Future<Result<List<CreatedTask>, Failure>> createBatch(
    List<TaskDraft> drafts,
  ) async => const Ok([]);

  @override
  Future<Result<void, Failure>> undoBatch(List<TrashTicket> tickets) async =>
      const Ok(null);

  @override
  Future<Result<Set<String>, Failure>> activeOriginPresetIds() async =>
      const Ok({});
}

class _NoopTaskPresetCatalog implements TaskPresetCatalogPort {
  const _NoopTaskPresetCatalog();

  @override
  Future<Result<TaskPresetCatalog, Failure>> load() async =>
      const Ok(TaskPresetCatalog(version: 1, presets: []));
}
