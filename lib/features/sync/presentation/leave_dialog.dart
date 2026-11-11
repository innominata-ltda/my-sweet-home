// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:my_sweet_home/design_system/components/app_button.dart';
import 'package:my_sweet_home/design_system/theme/spacing.dart';

/// Confirmation dialog for leaving shared household (RF-126, CA-7.2, CA-7.3, T-15).
class LeaveHouseholdDialog extends StatefulWidget {
  final Future<void> Function({required bool keepCopy}) onConfirm;

  const LeaveHouseholdDialog({super.key, required this.onConfirm});

  @override
  State<LeaveHouseholdDialog> createState() => _LeaveHouseholdDialogState();
}

class _LeaveHouseholdDialogState extends State<LeaveHouseholdDialog> {
  bool _keepCopy = true;
  bool _secondConfirm = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    if (_secondConfirm) {
      return AlertDialog(
        title: const Text('Confirmar exclusão dos dados'),
        content: const Text(
          'Tem certeza de que deseja apagar todos os dados compartilhados da casa neste aparelho?\n\n'
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: _isLoading
                ? null
                : () => setState(() => _secondConfirm = false),
            child: const Text('Voltar'),
          ),
          AppButton.danger(
            key: const Key('confirm_wipe_leave_button'),
            label: 'Apagar e sair',
            isLoading: _isLoading,
            onPressed: () async {
              setState(() => _isLoading = true);
              await widget.onConfirm(keepCopy: false);
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Text('Sair da casa compartilhada'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ao sair da casa, este aparelho não receberá nem enviará mais atualizações de sincronização.',
          ),
          const SizedBox(height: Spacing.md),
          RadioListTile<bool>(
            key: const Key('leave_keep_copy_radio'),
            title: const Text('Manter uma cópia local (recomendado)'),
            subtitle: const Text(
              'Você continua com todas as despesas e tarefas criadas até agora.',
            ),
            value: true,
            groupValue: _keepCopy,
            onChanged: (val) => setState(() => _keepCopy = val ?? true),
          ),
          RadioListTile<bool>(
            key: const Key('leave_wipe_radio'),
            title: const Text('Apagar dados compartilhados'),
            subtitle: const Text(
              'Remove as despesas, contas e tarefas compartilhadas deste aparelho.',
            ),
            value: false,
            groupValue: _keepCopy,
            onChanged: (val) => setState(() => _keepCopy = val ?? false),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('confirm_leave_button'),
          onPressed: _isLoading
              ? null
              : () async {
                  if (!_keepCopy) {
                    setState(() => _secondConfirm = true);
                    return;
                  }
                  setState(() => _isLoading = true);
                  await widget.onConfirm(keepCopy: true);
                  if (context.mounted) Navigator.of(context).pop();
                },
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
