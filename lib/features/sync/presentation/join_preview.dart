import 'package:flutter/material.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/errors/user_message.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/sync/domain/sync_table_registry.dart';
import 'package:my_sweet_home/design_system/components/app_button.dart';
import 'package:my_sweet_home/design_system/components/app_card.dart';
import 'package:my_sweet_home/design_system/components/app_loading.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/design_system/theme/spacing.dart';
import 'package:my_sweet_home/features/sync/domain/models/household.dart';
import 'package:my_sweet_home/features/sync/domain/sync_batch.dart';
import 'package:my_sweet_home/features/sync/domain/usecases/join_household_usecase.dart';

/// Preview dialog/screen before joining a shared household (RF-121, RN-314, CA-5.5, T-10).
///
/// Shows local records of each area to be merged with household data,
/// generates automatic prior export and unifies everything without duplication.
class JoinPreviewDialog extends StatefulWidget {
  final String householdId;
  final String householdName;
  final Set<SyncArea> sharedAreas;
  final HouseholdKey householdKey;
  final List<Member> existingMembers;
  final JoinHouseholdUseCase useCase;
  final VoidCallback? onJoined;
  final String? initialDeviceName;
  final String? sasCode;

  const JoinPreviewDialog({
    super.key,
    required this.householdId,
    required this.householdName,
    required this.sharedAreas,
    required this.householdKey,
    required this.useCase,
    this.existingMembers = const [],
    this.onJoined,
    this.initialDeviceName,
    this.sasCode,
  });

  @override
  State<JoinPreviewDialog> createState() => _JoinPreviewDialogState();
}

class _JoinPreviewDialogState extends State<JoinPreviewDialog> {
  late final TextEditingController _deviceNameController;
  HouseholdJoinPreviewData? _previewData;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _initializedDeviceName = false;
  Object? _previewFailure;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _deviceNameController = TextEditingController(
      text: widget.initialDeviceName?.isNotEmpty == true
          ? widget.initialDeviceName
          : '',
    );
    _loadPreview();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedDeviceName) {
      _initializedDeviceName = true;
      if (_deviceNameController.text.isEmpty) {
        _deviceNameController.text = AppLocalizations.of(context)
            .householdDefaultDeviceName;
      }
    }
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    super.dispose();
  }

  Future<void> _loadPreview() async {
    final result = await widget.useCase.getPreview();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.isOk) {
        _previewData = result.valueOrNull;
      } else {
        _previewFailure = result.failureOrNull;
      }
    });
  }

  Future<void> _handleJoin() async {
    final l10n = AppLocalizations.of(context);
    final deviceName = _deviceNameController.text.trim();
    if (deviceName.isEmpty) {
      setState(() => _errorMessage = l10n.householdJoinPreviewEmptyDeviceError);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final result = await widget.useCase.execute(
      householdId: widget.householdId,
      householdName: widget.householdName,
      deviceName: deviceName,
      sharedAreas: widget.sharedAreas,
      key: widget.householdKey,
      existingMembers: widget.existingMembers,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.isOk) {
      widget.onJoined?.call();
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _errorMessage = userMessageFor((result as Err).failure);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final displayedError =
        _errorMessage ??
        (_previewFailure != null
            ? l10n.householdJoinPreviewError(_previewFailure.toString())
            : null);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    AppIcons.household,
                    size: 28,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Text(
                      l10n.householdJoinPreviewTitle(widget.householdName),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.md),
              Text(l10n.householdJoinPreviewMergeInfo),
              if (widget.sasCode != null) ...[
                const SizedBox(height: Spacing.md),
                Container(
                  padding: const EdgeInsets.all(Spacing.md),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        l10n.householdJoinPreviewSasLabel,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                      ),
                      const SizedBox(height: Spacing.xs),
                      Text(
                        widget.sasCode!,
                        key: const Key('join_preview_sas_code'),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.householdJoinPreviewSasHint,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: Spacing.md),
              if (_isLoading)
                const Center(child: AppLoading())
              else if (_previewData != null)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.householdJoinPreviewLocalRecordsTitle,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: Spacing.sm),
                      _buildRow(
                        l10n.householdJoinPreviewHomeLabel,
                        '${_previewData!.homeRecordsCount}',
                      ),
                      const SizedBox(height: 4),
                      _buildRow(
                        l10n.householdJoinPreviewFinanceLabel,
                        '${_previewData!.financeRecordsCount}',
                      ),
                      const SizedBox(height: 4),
                      _buildRow(
                        l10n.householdJoinPreviewProductsLabel,
                        '${_previewData!.catalogRecordsCount}',
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: Spacing.md),
              Container(
                padding: const EdgeInsets.all(Spacing.sm),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      AppIcons.lockBackup,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: Text(
                        l10n.householdJoinPreviewBackupNotice,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.md),
              TextField(
                controller: _deviceNameController,
                decoration: InputDecoration(
                  labelText: l10n.householdJoinPreviewDeviceNameLabel,
                  hintText: l10n.householdJoinPreviewDeviceNameHint,
                ),
              ),
              if (displayedError != null) ...[
                const SizedBox(height: Spacing.sm),
                Text(
                  displayedError,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: Spacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(false),
                    label: l10n.commonCancel,
                    variant: AppButtonVariant.text,
                  ),
                  const SizedBox(width: Spacing.sm),
                  AppButton(
                    onPressed: _isSubmitting ? null : _handleJoin,
                    label: _isSubmitting
                        ? l10n.householdJoinPreviewJoining
                        : l10n.householdJoinPreviewJoinButton,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }
}
