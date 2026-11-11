import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/features/backup/data/wipe_all_data_provider.dart';
import 'package:my_sweet_home/features/backup/domain/wipe_all_data_use_case.dart';
import 'package:my_sweet_home/features/backup/presentation/wipe_all_data_controller.dart';

/// Screen for wiping all application data with double confirmation (RF-006, RN-233, CA-2.1).
///
/// Complies with accessibility requirements (A11Y-5): destructive button labeled
/// "Apagar tudo permanentemente", default action is non-destructive.
class WipeAllDataScreen extends ConsumerStatefulWidget {
  const WipeAllDataScreen({
    super.key,
    this.wipeAllDataUseCase,
    this.controller,
  });

  final WipeAllDataUseCase? wipeAllDataUseCase;
  final WipeAllDataController? controller;

  @override
  ConsumerState<WipeAllDataScreen> createState() => _WipeAllDataScreenState();
}

class _WipeAllDataScreenState extends ConsumerState<WipeAllDataScreen> {
  late final WipeAllDataController _controller;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      final WipeAllDataUseCase useCase =
          widget.wipeAllDataUseCase ?? ref.read(wipeAllDataUseCaseProvider);
      _controller = WipeAllDataController(wipeAllDataUseCase: useCase);
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _startDoubleConfirmationFlow() async {
    // First confirmation
    final firstConfirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar exclusão de dados'),
          content: const Text(
            'Você tem certeza de que deseja apagar todos os dados do aplicativo? '
            'Esta é a primeira confirmação.',
          ),
          actions: [
            // Default non-destructive action
            TextButton(
              focusNode: FocusNode()..requestFocus(),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );

    if (firstConfirmed != true || !mounted) return;

    // Second confirmation (Final Confirmation - A11Y-5)
    final secondConfirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirmação Final'),
          content: const Text(
            'ESTA AÇÃO É DEFINITIVA E IRREVERSÍVEL. Todos os seus registros, '
            'fotos, tarefas, despesas e configurações serão apagados sem resíduo.',
          ),
          actions: [
            // Default non-destructive action
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            // Explicitly labeled destructive button (A11Y-5)
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
                foregroundColor: Theme.of(dialogContext).colorScheme.onError,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Apagar tudo permanentemente'),
            ),
          ],
        );
      },
    );

    if (secondConfirmed == true && mounted) {
      await _controller.executeWipe();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apagar Tudo')),
      body: ValueListenableBuilder<WipeAllDataState>(
        valueListenable: _controller,
        builder: (context, state, child) {
          if (state is WipeAllDataLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Apagando todos os dados...'),
                ],
              ),
            );
          }

          if (state is WipeAllDataSuccess) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      AppIcons.check,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Todos os dados foram apagados permanentemente.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'O banco de dados, arquivos e configurações foram limpos sem deixar resíduos.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text('Concluído'),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              AppIcons.warning,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Atenção: Ação Irreversível',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Ao apagar tudo, todos os registros cadastrados (produtos, despesas, '
                          'contas fixas, tarefas, receitas, compras e estoque), fotos de cupons e '
                          'preferências do aplicativo serão apagados permanentemente.',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onErrorContainer,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nenhum token ou arquivo temporário permanecerá no dispositivo.',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context)
                                .colorScheme
                                .onErrorContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (state is WipeAllDataError)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      state.message,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  onPressed: _startDoubleConfirmationFlow,
                  icon: const Icon(AppIcons.deleteForever),
                  label: const Text(
                    'Apagar todos os dados',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
