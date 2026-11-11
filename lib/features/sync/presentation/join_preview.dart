import 'package:flutter/material.dart';
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
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _deviceNameController = TextEditingController(
      text: widget.initialDeviceName?.isNotEmpty == true
          ? widget.initialDeviceName
          : 'Meu celular',
    );
    _loadPreview();
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
        _errorMessage = 'Falha ao carregar prévia: ${result.failureOrNull}';
      }
    });
  }

  Future<void> _handleJoin() async {
    final deviceName = _deviceNameController.text.trim();
    if (deviceName.isEmpty) {
      setState(() => _errorMessage = 'Informe o nome do aparelho');
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
                      'Entrar em "${widget.householdName}"',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.md),
              const Text(
                'Ao entrar na casa, seus dados locais serão unidos com os da casa. '
                'Nenhum dado seu será apagado ou duplicado.',
              ),
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
                        'Código de autenticação (6 dígitos):',
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
                        'Confira se este código é idêntico ao exibido no outro aparelho.',
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
                        'Registros locais a unir:',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: Spacing.sm),
                      _buildRow(
                        'Casa (listas, tarefas, receitas):',
                        '${_previewData!.homeRecordsCount}',
                      ),
                      const SizedBox(height: 4),
                      _buildRow(
                        'Finanças (despesas, contas):',
                        '${_previewData!.financeRecordsCount}',
                      ),
                      const SizedBox(height: 4),
                      _buildRow(
                        'Catálogo de produtos:',
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
                    const Expanded(
                      child: Text(
                        'Um backup automático de segurança será gerado antes da adesão.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.md),
              TextField(
                controller: _deviceNameController,
                decoration: const InputDecoration(
                  labelText: 'Nome deste aparelho na casa',
                  hintText: 'Ex.: Celular do Alex',
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: Spacing.sm),
                Text(
                  _errorMessage!,
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
                    label: 'Cancelar',
                    variant: AppButtonVariant.text,
                  ),
                  const SizedBox(width: Spacing.sm),
                  AppButton(
                    onPressed: _isSubmitting ? null : _handleJoin,
                    label: _isSubmitting ? 'Entrando...' : 'Entrar na casa',
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
