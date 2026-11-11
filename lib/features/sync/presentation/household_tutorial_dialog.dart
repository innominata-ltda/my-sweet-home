import 'package:flutter/material.dart';
import 'package:my_sweet_home/design_system/components/app_button.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/design_system/theme/spacing.dart';

/// Step-by-step tutorial dialog for Shared Household (RN-392, CA-4.1).
///
/// Exibido automaticamente ao criar ou entrar numa casa pela primeira vez,
/// and can be reopened anytime from HouseholdScreen AppBar.
/// In final step, asks whether user wishes to enable sync or not
/// remota (`household_sync_remote`).
class HouseholdTutorialDialog extends StatefulWidget {
  final bool initialRemoteSyncEnabled;
  final Future<void> Function(bool enableRemoteSync) onComplete;

  const HouseholdTutorialDialog({
    super.key,
    required this.initialRemoteSyncEnabled,
    required this.onComplete,
  });

  @override
  State<HouseholdTutorialDialog> createState() =>
      _HouseholdTutorialDialogState();
}

class _HouseholdTutorialDialogState extends State<HouseholdTutorialDialog> {
  int _currentStep = 0;
  late bool _enableRemoteSync;
  bool _submitting = false;

  static const _steps = <_TutorialStepInfo>[
    _TutorialStepInfo(
      icon: AppIcons.household,
      title: 'Bem-vindo à Casa Compartilhada!',
      description:
          'Aqui você divide listas de compras, tarefas, estoque, receitas e finanças '
          'com quem mora com você, sem criar conta em servidor e com criptografia '
          'de ponta a ponta (chave secreta de 256 bits).',
    ),
    _TutorialStepInfo(
      icon: AppIcons.qrCode,
      title: 'Pareamento seguro com QR Code e 6 dígitos',
      description:
          'Para adicionar outro celular, toque em "Convidar aparelho". '
          'O novo aparelho lê o QR Code pela câmera (ou usa o link de convite) e '
          'ambos confirmam o mesmo código de autenticação de 6 dígitos.',
    ),
    _TutorialStepInfo(
      icon: AppIcons.wifi,
      title: 'Sincronização no Wi-Fi e por Pacotes',
      description:
          'Quando os aparelhos estão no mesmo Wi-Fi com o app aberto, as mudanças '
          'sincronizam direto na rede local. Você também pode tocar em "Gerar pacote" '
          'para enviar atualizações por qualquer app de mensagens.',
    ),
    _TutorialStepInfo(
      icon: AppIcons.sync,
      title: 'Sincronização fora de casa (Nuvem)',
      description:
          'Quando vocês não estão no mesmo Wi-Fi (ex.: alguém no mercado), o app pode '
          'usar uma caixa postal criptografada na sua nuvem para entregar as mudanças '
          'automaticamente.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _enableRemoteSync = widget.initialRemoteSyncEnabled;
  }

  Future<void> _finish() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    await widget.onComplete(_enableRemoteSync);
    if (mounted) {
      Navigator.of(context).pop(_enableRemoteSync);
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];
    final isLastStep = _currentStep == _steps.length - 1;
    final theme = Theme.of(context);

    return Dialog(
      key: const Key('household_tutorial_dialog'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Passo ${_currentStep + 1} de ${_steps.length}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    key: const Key('tutorial_close_button'),
                    icon: const Icon(AppIcons.close),
                    tooltip: 'Fechar tutorial',
                    onPressed: _finish,
                  ),
                ],
              ),
              const SizedBox(height: Spacing.sm),
              CircleAvatar(
                radius: 32,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  step.icon,
                  size: 32,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: Spacing.md),
              Text(
                step.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                step.description,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              if (isLastStep) ...[
                const SizedBox(height: Spacing.lg),
                Text(
                  'Deseja habilitar a sincronização remota agora?',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                _RemoteSyncOptionTile(
                  tileKey: const Key('tutorial_remote_sync_enable_option'),
                  selected: _enableRemoteSync,
                  title: 'Sim, habilitar sincronização remota',
                  subtitle: 'Sincroniza fora do Wi-Fi com criptografia de ponta a ponta',
                  icon: AppIcons.sync,
                  onTap: () => setState(() => _enableRemoteSync = true),
                ),
                const SizedBox(height: Spacing.xs),
                _RemoteSyncOptionTile(
                  tileKey: const Key('tutorial_remote_sync_disable_option'),
                  selected: !_enableRemoteSync,
                  title: 'Não, usar apenas Wi-Fi local e pacotes',
                  subtitle: 'Você poderá ativar depois dentro da tela da Casa Compartilhada',
                  icon: AppIcons.wifi,
                  onTap: () => setState(() => _enableRemoteSync = false),
                ),
              ],
              const SizedBox(height: Spacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_steps.length, (index) {
                  final active = index == _currentStep;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: Spacing.lg),
              Row(
                children: [
                  if (_currentStep > 0) ...[
                    Expanded(
                      child: AppButton.secondary(
                        key: const Key('tutorial_back_button'),
                        label: 'Anterior',
                        onPressed: () => setState(() => _currentStep--),
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                  ],
                  Expanded(
                    child: AppButton.primary(
                      key: Key(
                        isLastStep
                            ? 'tutorial_finish_button'
                            : 'tutorial_next_button',
                      ),
                      label: isLastStep ? 'Concluir' : 'Próximo',
                      onPressed: isLastStep
                          ? _finish
                          : () => setState(() => _currentStep++),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TutorialStepInfo {
  final IconData icon;
  final String title;
  final String description;

  const _TutorialStepInfo({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _RemoteSyncOptionTile extends StatelessWidget {
  final Key tileKey;
  final bool selected;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _RemoteSyncOptionTile({
    required this.tileKey,
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      key: tileKey,
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
          color: selected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Icon(
              selected ? AppIcons.radioButtonChecked : AppIcons.radioButtonOff,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
